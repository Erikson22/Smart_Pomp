// ============================================================
//   SMART PUMP - VEICHI SI23 + FIREBASE
//   ESP32 + SIM808 + RS485 Modbus
//   Version finale corrigée
// ============================================================

// ==================== BIBLIOTHÈQUES ====================
#define TINY_GSM_MODEM_SIM808
#include <TinyGsmClient.h>
#include <HardwareSerial.h>
#include <ModbusMaster.h>
#include <TinyGPS++.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <WebServer.h>
#include <Preferences.h>
#include <time.h>

// Credentials et certificat TLS dans un fichier séparé (non commité).
// Copier config.h.example → config.h et remplir les valeurs.
#include "config.h"

// ==================== PINS ====================
#define SIM808_TX_PIN  26
#define SIM808_RX_PIN  27
#define RS485_RX_PIN   16
#define RS485_TX_PIN   17

// ==================== OBJETS ====================
HardwareSerial SerialSIM(1);
TinyGsm        modem(SerialSIM);
TinyGsmClientSecure gsmClient(modem);  // SSL requis pour Firebase Functions (port 443)
TinyGPSPlus    gps;
ModbusMaster   variateur;
WebServer      apServer(80);           // Portail de configuration WiFi (mode AP)
Preferences    wifiPrefs;              // Stockage NVS des credentials WiFi

// ==================== CONFIGURATION ====================
// WiFi/GPRS/Firebase : voir config.h (gitignored)

// Firebase URL (construit depuis FIREBASE_HOST défini dans config.h)
const String FIREBASE_URL = String("https://") + FIREBASE_HOST;

// Relay Cloud Function (GPRS → Firebase RTDB)
// FIREBASE_HOST / FIREBASE_SECRET définis dans config.h (REST API directe, pas de relay)

// ==================== MODES DE CONNEXION ====================
enum ModeConnexion {
  CONNEXION_WIFI,
  CONNEXION_GPRS,
  CONNEXION_AUCUNE
};
ModeConnexion modeActuel = CONNEXION_AUCUNE;

// ==================== MINUTERIE ====================
enum TimerMode {
  TIMER_NONE,
  TIMER_RUN,
  TIMER_STOP
};

struct Minuterie {
  bool          active        = false;
  TimerMode     mode          = TIMER_NONE;
  unsigned long dureeMs       = 0;
  unsigned long debutMs       = 0;
};
Minuterie minuterie;

// ==================== SEUILS DE PROTECTION ====================
float seuilVeille      = 0;
float seuilReveil      = 0;
float seuilBasseFreq   = 0;
float seuilMarcheSec   = 0;
float seuilSurintens   = 0;
float seuilPuissMin    = 0;

// ==================== VARIABLES ÉTAT ====================
float   consigneFrequence    = 20.0;
bool    moteurEnMarche       = false;
String  dernierAvertissement = "";
uint8_t dernierEtatDefaut    = 0;

// Dernières mesures (pour historique)
float derniereTensPanneaux = 0;
float derniereCourSortie   = 0;
float dernierePuisSortie   = 0;
float derniereFreqSortie   = 0;
float derniereTensSortie   = 0;

// ==================== TIMING ====================
unsigned long dernierEnvoiMesures   = 0;
unsigned long dernierLectureCmd     = 0;
unsigned long dernierEnvoiGPS       = 0;
unsigned long dernierVerifConnexion = 0;
unsigned long dernierCheckDefaut    = 0;

// ==================== ERREURS VARIATEUR ====================
struct ErreurInfo {
  String code;
  String description;
  String cause;
  String solution;
};

ErreurInfo erreurs[] = {
  {"E.LU2", "Sous-tension en marche",
   "Tension d'alimentation trop faible",
   "Verifier tension DC entree, connexions panneaux, augmenter F14.11"},
  {"E.OU1", "Surtension a l acceleration",
   "Fluctuation de tension",
   "Augmenter F00.14, verifier stabilite reseau"},
  {"A.LPn", "Fonction Sommeil",
   "Tension panneaux trop basse",
   "Attendre meilleur ensoleillement, augmenter F14.11"},
  {"A.LFr", "Basse frequence",
   "Frequence trop basse",
   "Augmenter F14.14, verifier la charge"},
  {"A.LuT", "Marche a sec",
   "Pompe sans eau",
   "Verifier niveau eau, ajuster F14.17"},
  {"A.OLd", "Surintensite",
   "Courant trop eleve",
   "Augmenter F14.20, verifier pompe"},
  {"A.LPr", "Puissance minimale",
   "Puissance trop faible",
   "Verifier ensoleillement, augmenter F14.23"}
};
int nbErreurs = sizeof(erreurs) / sizeof(erreurs[0]);

// ==================== PROTOTYPES ====================
void connecter();
bool connecterWiFi();
bool connecterGPRS();
void verifierConnexion();
void synchroniserHeure();
String getTimestamp();
String getDateJour();
String getHeure();
bool envoyerDonnee(String chemin, String json);
String lireDonnee(String chemin);
int  envoyerViaGPRS(String methode, String chemin, String json);
String lireViaGPRS(String chemin);
void envoyerMesures();
void lireCommandes();
void envoyerGPS();
void gererMinuterie();
void demarrerMinuterie(int heures, int minutes, TimerMode mode);
void arreterMinuterie();
void demarrerMoteur();
void arreterMoteur();
void setFrequence(float freq);
void lireSeuilsProtection();
void diagnostiquerAvertissements(float tens, float freq, float cour, float puis);
void lireEtatDefaut();
void sauvegarderHistoriqueHoraire(String date, String heure, float tens, float cour, float puis, float freq);
void envoyerErreurFirebase(ErreurInfo err);
bool ecrireParametreFirebase(String nomParam, int valeur);
void traiterCommandeSerial(String cmd);
void lireParametreConsole(String nomParam);
void afficherMenuAide();
void initialiserSIM808();
// ── Mode Configuration AP ──
void verifierBoutonConfig();
void demarrerModeConfigAP();
void handleRoot();
void handleSave();
void handleDelete();

// ============================================================
//                         SETUP
// ============================================================
void setup() {
  Serial.begin(115200);
  delay(1000);

  Serial.println("\n╔══════════════════════════════════════════╗");
  Serial.println("║   SMART PUMP - VEICHI SI23 + Firebase   ║");
  Serial.println("╚══════════════════════════════════════════╝");

  // Vérifier si le bouton BOOT est maintenu → mode Config AP (doit être en premier)
  verifierBoutonConfig();

  // RS485 Modbus
  Serial2.begin(9600, SERIAL_8N1, RS485_RX_PIN, RS485_TX_PIN);
  variateur.begin(1, Serial2);
  delay(500);

  // SIM808
  SerialSIM.begin(9600, SERIAL_8N1, SIM808_RX_PIN, SIM808_TX_PIN);
  delay(1000);
  initialiserSIM808();

  // Connexion réseau
  connecter();

  // NTP disponible uniquement en WiFi (GPRS n'a pas de socket TCP libre pour NTP)
  if (modeActuel == CONNEXION_WIFI) {
    synchroniserHeure();
  }

  // Lire seuils de protection du variateur
  lireSeuilsProtection();

  // Afficher menu
  afficherMenuAide();
}

// ============================================================
//                    BOUCLE PRINCIPALE
// ============================================================
void loop() {
  // Toujours lire les trames GPS
  while (SerialSIM.available()) {
    gps.encode(SerialSIM.read());
  }

  // Commandes série (console)
  if (Serial.available()) {
    String cmd = Serial.readString();
    cmd.trim();
    cmd.toUpperCase();
    traiterCommandeSerial(cmd);
  }

  unsigned long maintenant = millis();

  if (maintenant - dernierVerifConnexion > 60000) {
    verifierConnexion();
    dernierVerifConnexion = maintenant;
  }
  if (maintenant - dernierLectureCmd > 2000) {
    lireCommandes();
    dernierLectureCmd = maintenant;
  }
  if (maintenant - dernierEnvoiMesures > 20000) {
    envoyerMesures();
    dernierEnvoiMesures = maintenant;
  }
  if (maintenant - dernierEnvoiGPS > 30000) {
    envoyerGPS();
    dernierEnvoiGPS = maintenant;
  }
  if (maintenant - dernierCheckDefaut > 200) {
    lireEtatDefaut();
    dernierCheckDefaut = maintenant;
  }

  gererMinuterie();
}

// ============================================================
//                  INITIALISATION SIM808
// ============================================================
void initialiserSIM808() {
  Serial.println("\n[SIM808] Initialisation...");
  modem.restart();
  delay(3000);
  modem.sendAT("+CGNSPWR=1");
  modem.waitResponse(1000);
  modem.sendAT("+CGPSOUT=2");
  modem.waitResponse(500);
  Serial.println("[SIM808] OK");
}

// ============================================================
//                    GESTION CONNEXION
// ============================================================
void connecter() {
  // ── GPRS en priorité (connexion principale au boot) ──────
#if USE_GPRS
  if (connecterGPRS()) { modeActuel = CONNEXION_GPRS; return; }
  Serial.println("[NET] GPRS indisponible, tentative WiFi (fallback)...");
#endif

  // ── WiFi en fallback (optionnel) ─────────────────────────
#if USE_WIFI
  if (connecterWiFi()) { modeActuel = CONNEXION_WIFI; return; }
#endif

  modeActuel = CONNEXION_AUCUNE;
  Serial.println("[NET] Aucune connexion disponible");
}

bool connecterWiFi() {
  // ── 1. Réseaux sauvegardés en NVS (priorité) ─────────────
  wifiPrefs.begin("wifi_cfg", true);
  for (int i = 1; i <= 3; i++) {
    String ssid = wifiPrefs.getString(("ssid" + String(i)).c_str(), "");
    String pass = wifiPrefs.getString(("pass" + String(i)).c_str(), "");
    if (ssid.isEmpty()) continue;

    Serial.print("\n[WiFi] Essai NVS[" + String(i) + "] : " + ssid);
    WiFi.begin(ssid.c_str(), pass.c_str());
    for (int t = 0; t < 20; t++) {
      if (WiFi.status() == WL_CONNECTED) {
        wifiPrefs.end();
        Serial.println("\n[WiFi] OK : " + WiFi.localIP().toString());
        return true;
      }
      delay(500);
      Serial.print(".");
    }
    WiFi.disconnect();
    delay(200);
  }
  wifiPrefs.end();

  // ── 2. Fallback : credentials config.h (dev / premier démarrage) ──
  Serial.print("\n[WiFi] Fallback config.h : " WIFI_SSID);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  for (int i = 0; i < 20; i++) {
    if (WiFi.status() == WL_CONNECTED) {
      Serial.println("\n[WiFi] OK : " + WiFi.localIP().toString());
      return true;
    }
    delay(500);
    Serial.print(".");
  }
  WiFi.disconnect();
  Serial.println("\n[WiFi] Echec");
  return false;
}

bool connecterGPRS() {
  Serial.print("[GPRS] Connexion");
  if (!modem.waitForNetwork(30000)) { Serial.println("\n[GPRS] Reseau GSM indisponible"); return false; }
  if (!modem.gprsConnect(APN, APN_USER, APN_PASS)) { Serial.println("\n[GPRS] Echec"); return false; }
  Serial.println("\n[GPRS] OK");
  return true;
}

void verifierConnexion() {
  bool connecte = false;
  if      (modeActuel == CONNEXION_GPRS) connecte = modem.isGprsConnected();
  else if (modeActuel == CONNEXION_WIFI) connecte = (WiFi.status() == WL_CONNECTED);
  if (!connecte) {
    Serial.println("[NET] Connexion perdue, reconnexion...");
    connecter();
    // NTP seulement si on est passé en fallback WiFi
    if (modeActuel == CONNEXION_WIFI) synchroniserHeure();
  }
}

// ============================================================
//                    HEURE NTP
// ============================================================
void synchroniserHeure() {
  configTime(3600, 0, "pool.ntp.org", "time.nist.gov");
  Serial.print("[NTP] Synchronisation");
  struct tm timeinfo;
  for (int i = 0; i < 20; i++) {
    if (getLocalTime(&timeinfo)) { Serial.println("\n[NTP] OK : " + getTimestamp()); return; }
    delay(500);
    Serial.print(".");
  }
  Serial.println("\n[NTP] Echec, utilisation millis()");
}

String getTimestamp() {
  struct tm timeinfo;
  if (!getLocalTime(&timeinfo)) return String(millis() / 1000);
  char buffer[20];
  strftime(buffer, sizeof(buffer), "%Y-%m-%d %H:%M:%S", &timeinfo);
  return String(buffer);
}

String getDateJour() {
  struct tm timeinfo;
  if (!getLocalTime(&timeinfo)) return "2024-01-01";
  char buffer[11];
  strftime(buffer, sizeof(buffer), "%Y-%m-%d", &timeinfo);
  return String(buffer);
}

String getHeure() {
  struct tm timeinfo;
  if (!getLocalTime(&timeinfo)) return "00";
  char buffer[3];
  strftime(buffer, sizeof(buffer), "%H", &timeinfo);
  return String(buffer);
}

// ============================================================
//              FONCTIONS HTTP FIREBASE
// ============================================================
bool envoyerDonnee(String chemin, String json) {
  String url = FIREBASE_URL + chemin + "?auth=" + FIREBASE_SECRET;
  int codeHTTP = 0;

  if (modeActuel == CONNEXION_WIFI) {
    WiFiClientSecure client;
    client.setCACert(FIREBASE_ROOT_CA);  // Vérifie le certificat TLS Firebase
    HTTPClient http;
    http.begin(client, url);
    http.addHeader("Content-Type", "application/json");
    codeHTTP = http.PUT(json);
    http.end();
  } else if (modeActuel == CONNEXION_GPRS) {
    codeHTTP = envoyerViaGPRS("PUT", chemin, json);
  }

  bool succes = (codeHTTP == 200 || codeHTTP == 204);
  if (!succes) Serial.println("[FB] Erreur " + String(codeHTTP) + " -> " + chemin);
  return succes;
}

String lireDonnee(String chemin) {
  String url = FIREBASE_URL + chemin + "?auth=" + FIREBASE_SECRET;
  if (modeActuel == CONNEXION_WIFI) {
    WiFiClientSecure client;
    client.setCACert(FIREBASE_ROOT_CA);  // Vérifie le certificat TLS Firebase
    HTTPClient http;
    http.begin(client, url);
    int code = http.GET();
    if (code == 200) { String rep = http.getString(); http.end(); return rep; }
    http.end();
  } else if (modeActuel == CONNEXION_GPRS) {
    return lireViaGPRS(chemin);
  }
  return "";
}

int envoyerViaGPRS(String /* methode ignorée */, String chemin, String json) {
  // SIM808 → Relay (Render/Fly.io) → Firebase RTDB
  // Le relay gère TLS côté serveur ; SIM808 envoie HTTP ou HTTPS selon RELAY_PORT
  String path = chemin;
  if (path.endsWith(".json")) path = path.substring(0, path.length() - 5);

  String body = "{\"path\":\"" + path + "\",\"data\":" + json + "}";
  String req  = "POST " + String(RELAY_PATH) + " HTTP/1.1\r\n";
  req += "Host: "           + String(RELAY_HOST)       + "\r\n";
  req += "Content-Type: application/json\r\n";
  req += "Content-Length: " + String(body.length())    + "\r\n";
  req += "Connection: close\r\n\r\n";
  req += body;

  Serial.println("[GPRS] Relay " + String(RELAY_HOST) + ":" + String(RELAY_PORT));
  if (!gsmClient.connect(RELAY_HOST, RELAY_PORT)) {
    Serial.println("[GPRS] Echec connexion relay (TLS ?) – essayer RELAY_PORT 80 si Render échoue");
    return -1;
  }
  gsmClient.print(req);
  unsigned long debut = millis();
  while (!gsmClient.available() && millis() - debut < 8000);
  String rep = "";
  while (gsmClient.available()) rep += (char)gsmClient.read();
  gsmClient.stop();
  if (rep.indexOf("HTTP/1.1 200") != -1) return 200;
  if (rep.indexOf("HTTP/1.1 204") != -1) return 204;
  int idx = rep.indexOf(' ');
  if (idx != -1) Serial.println("[GPRS] Relay réponse: " + rep.substring(idx + 1, idx + 4));
  return -1;
}

String lireViaGPRS(String chemin) {
  // SIM808 → Relay (Render/Fly.io) → Firebase RTDB
  String path = chemin;
  if (path.endsWith(".json")) path = path.substring(0, path.length() - 5);

  String req  = "GET " + String(RELAY_PATH) + "?path=" + path + " HTTP/1.1\r\n";
  req += "Host: " + String(RELAY_HOST) + "\r\n";
  req += "Connection: close\r\n\r\n";

  if (!gsmClient.connect(RELAY_HOST, RELAY_PORT)) {
    Serial.println("[GPRS] Echec connexion relay lecture");
    return "";
  }
  gsmClient.print(req);
  unsigned long debut = millis();
  while (!gsmClient.available() && millis() - debut < 8000);
  String rep = "";
  while (gsmClient.available()) rep += (char)gsmClient.read();
  gsmClient.stop();
  int idx = rep.indexOf("\r\n\r\n");
  if (idx != -1) return rep.substring(idx + 4);
  return "";
}

// ============================================================
//              ENVOYER LES MESURES VERS FIREBASE
// ============================================================
void envoyerMesures() {
  uint8_t result;
  float tensPanneaux = 0, tensBusDC  = 0;
  float freqSortie   = 0, courSortie = 0;
  float tensSortie   = 0, puisSortie = 0;
  float courEntree   = 0, puissEntree = 0;

  result = variateur.readHoldingRegisters(0x2103, 1);
  if (result == variateur.ku8MBSuccess) tensPanneaux = variateur.getResponseBuffer(0) / 10.0;
  delay(60);

  result = variateur.readHoldingRegisters(0x210B, 1);
  if (result == variateur.ku8MBSuccess) tensBusDC = variateur.getResponseBuffer(0) / 10.0;
  delay(60);

  result = variateur.readHoldingRegisters(0x2101, 1);
  if (result == variateur.ku8MBSuccess) freqSortie = variateur.getResponseBuffer(0) / 100.0;
  delay(60);

  result = variateur.readHoldingRegisters(0x2102, 1);
  if (result == variateur.ku8MBSuccess) courSortie = variateur.getResponseBuffer(0) / 10.0;
  delay(60);

  result = variateur.readHoldingRegisters(0x2104, 1);
  if (result == variateur.ku8MBSuccess) tensSortie = variateur.getResponseBuffer(0) / 10.0;

  if (moteurEnMarche && tensSortie > 0 && courSortie > 0) {
    puisSortie  = (tensSortie * courSortie * 1.732 * 0.85) / 1000.0;
    if (tensPanneaux > 0) {
      courEntree  = (puisSortie * 1000.0) / tensPanneaux;
      puissEntree = (tensPanneaux * courEntree) / 1000.0;
    }
  }

  derniereTensPanneaux = tensPanneaux;
  derniereCourSortie   = courSortie;
  dernierePuisSortie   = puisSortie;
  derniereFreqSortie   = freqSortie;
  derniereTensSortie   = tensSortie;

  JsonDocument doc;
  doc["tension_panneaux"] = tensPanneaux;
  doc["tension_bus_dc"]   = tensBusDC;
  doc["sortie_tension"]   = tensSortie;
  doc["sortie_courant"]   = courSortie;
  doc["sortie_frequence"] = freqSortie;
  doc["sortie_puissance"] = puisSortie;
  doc["entree_courant"]   = courEntree;
  doc["entree_puissance"] = puissEntree;
  doc["timestamp"]        = getTimestamp();
  String jsonMesures;
  serializeJson(doc, jsonMesures);
  envoyerDonnee("/pompe/mesures.json", jsonMesures);

  JsonDocument docEtat;
  docEtat["en_marche"] = moteurEnMarche;
  docEtat["frequence"] = consigneFrequence;
  docEtat["timestamp"] = getTimestamp();
  if (minuterie.active) {
    unsigned long reste = minuterie.dureeMs - (millis() - minuterie.debutMs);
    docEtat["timer_actif"]         = true;
    docEtat["timer_reste_minutes"] = reste / 60000;
    docEtat["timer_mode"]          = (minuterie.mode == TIMER_RUN) ? "RUN" : "STOP";
  } else {
    docEtat["timer_actif"] = false;
  }
  String jsonEtat;
  serializeJson(docEtat, jsonEtat);
  envoyerDonnee("/pompe/etat.json", jsonEtat);

  diagnostiquerAvertissements(tensPanneaux, freqSortie, courSortie, puisSortie);
  sauvegarderHistoriqueHoraire(getDateJour(), getHeure(), tensPanneaux, courSortie, puisSortie, freqSortie);

  Serial.printf("[MESURES] Freq=%.1fHz Tens=%.1fV Cour=%.1fA Puis=%.2fkW PanV=%.1fV\n",
    freqSortie, tensSortie, courSortie, puisSortie, tensPanneaux);
}

// ============================================================
//         SAUVEGARDER HISTORIQUE (1 nœud par heure)
// ============================================================
void sauvegarderHistoriqueHoraire(String date, String heure,
                                   float tens, float cour,
                                   float puis, float freq) {
  static String derniereHeure = "";
  if (heure == derniereHeure) return;
  derniereHeure = heure;

  JsonDocument doc;
  doc["tension_panneaux"] = tens;
  doc["courant_sortie"]   = cour;
  doc["puissance_sortie"] = puis;
  doc["frequence"]        = freq;
  doc["en_marche"]        = moteurEnMarche;
  doc["heure"]            = heure;
  String json;
  serializeJson(doc, json);
  envoyerDonnee("/historique/" + date + "/" + heure + ".json", json);
}

// ============================================================
//            LIRE LES COMMANDES DEPUIS FIREBASE
// ============================================================
void lireCommandes() {
  String reponse = lireDonnee("/pompe/commande.json");
  if (reponse == "" || reponse == "null") return;

  JsonDocument doc;
  if (deserializeJson(doc, reponse)) return;

  String statut = doc["statut"] | "IDLE";
  if (statut != "EN_ATTENTE") return;

  envoyerDonnee("/pompe/commande/statut.json", "\"RECU\"");

  String ordre  = doc["ordre"] | "IDLE";
  bool   succes = false;

  if (ordre == "START") {
    if (!moteurEnMarche) { demarrerMoteur(); succes = moteurEnMarche; }
    else succes = true;
  } else if (ordre == "STOP") {
    arreterMinuterie();
    if (moteurEnMarche) { arreterMoteur(); succes = !moteurEnMarche; }
    else succes = true;
  } else if (ordre == "SET_FREQ") {
    setFrequence(doc["frequence"] | consigneFrequence);
    succes = true;
  } else if (ordre == "TIMER_RUN") {
    int h = doc["timer_heures"] | 0, m = doc["timer_minutes"] | 0;
    if ((h + m) > 0) { demarrerMinuterie(h, m, TIMER_RUN); succes = true; }
  } else if (ordre == "TIMER_STOP") {
    int h = doc["timer_heures"] | 0, m = doc["timer_minutes"] | 0;
    if ((h + m) > 0) { demarrerMinuterie(h, m, TIMER_STOP); succes = true; }
  } else if (ordre == "TIMER_OFF") {
    arreterMinuterie(); succes = true;
  } else if (ordre == "SET_PARAM") {
    String param = doc["parametre"] | "";
    int    valeur = doc["valeur"]   | -1;
    if (param != "" && valeur >= 0) succes = ecrireParametreFirebase(param, valeur);
  } else if (ordre == "RESET_VARIATEUR") {
    variateur.writeSingleRegister((0 << 8) | 19, 1);
    succes = true;
    Serial.println("[VAR] Reset variateur envoyé");
  }

  envoyerDonnee("/pompe/commande/statut.json", succes ? "\"EXECUTE\"" : "\"ERREUR\"");
  envoyerDonnee("/pompe/commande/ordre.json",  "\"IDLE\"");
}

// ============================================================
//                     ENVOYER GPS
// ============================================================
void envoyerGPS() {
  JsonDocument doc;

  if (gps.location.isValid()) {
    doc["latitude"]    = gps.location.lat();
    doc["longitude"]   = gps.location.lng();
    doc["valide"]      = true;
    doc["google_maps"] = "https://maps.google.com/?q=" +
                         String(gps.location.lat(), 6) + "," +
                         String(gps.location.lng(), 6);
  } else {
    doc["latitude"] = 0.0; doc["longitude"] = 0.0;
    doc["valide"] = false; doc["google_maps"] = "";
  }

  if (gps.altitude.isValid())  doc["altitude"]   = gps.altitude.meters();
  if (gps.speed.isValid())     doc["vitesse"]     = gps.speed.kmph();
  if (gps.satellites.isValid()) doc["satellites"] = gps.satellites.value();

  String operateur = modem.getOperator();
  if      (operateur.indexOf("Ooredoo") != -1 || operateur.indexOf("605 03") != -1)
    doc["operateur"] = "Ooredoo";
  else if (operateur.indexOf("Orange") != -1 || operateur.indexOf("605 01") != -1)
    doc["operateur"] = "Orange";
  else if (operateur.indexOf("Telecom") != -1 || operateur.indexOf("605 02") != -1)
    doc["operateur"] = "Tunisie Telecom";
  else
    doc["operateur"] = operateur;

  doc["gprs_connecte"] = (modeActuel == CONNEXION_GPRS);
  doc["timestamp"]     = getTimestamp();

  String json;
  serializeJson(doc, json);
  envoyerDonnee("/pompe/gps.json", json);
}

// ============================================================
//                     MINUTERIE
// ============================================================
void demarrerMinuterie(int heures, int minutes, TimerMode mode) {
  if (heures < 0 || heures > 23 || minutes < 0 || minutes > 59) {
    Serial.println("[TIMER] Temps invalide"); return;
  }
  if (minuterie.active) arreterMinuterie();
  minuterie.active  = true;
  minuterie.mode    = mode;
  minuterie.dureeMs = ((unsigned long)heures * 3600000UL) + ((unsigned long)minutes * 60000UL);
  minuterie.debutMs = millis();
  if (mode == TIMER_RUN) demarrerMoteur();
  else                   arreterMoteur();
  Serial.printf("[TIMER] %s : %dh%dmin\n", mode == TIMER_RUN ? "MARCHE" : "ARRET", heures, minutes);

  JsonDocument doc;
  doc["actif"]         = true;
  doc["mode"]          = (mode == TIMER_RUN) ? "RUN" : "STOP";
  doc["duree_minutes"] = (heures * 60) + minutes;
  String json;
  serializeJson(doc, json);
  envoyerDonnee("/pompe/commande/timer.json", json);
}

void arreterMinuterie() {
  if (!minuterie.active) return;
  minuterie.active = false;
  Serial.println("[TIMER] Desactivee");
  JsonDocument doc;
  doc["actif"] = false; doc["mode"] = "NONE";
  String json; serializeJson(doc, json);
  envoyerDonnee("/pompe/commande/timer.json", json);
}

void gererMinuterie() {
  if (!minuterie.active) return;
  if (millis() - minuterie.debutMs < minuterie.dureeMs) return;
  minuterie.active = false;
  Serial.println("[TIMER] FIN");
  if (minuterie.mode == TIMER_RUN) arreterMoteur();
  JsonDocument doc;
  doc["actif"] = false; doc["mode"] = "NONE";
  String json; serializeJson(doc, json);
  envoyerDonnee("/pompe/commande/timer.json", json);
  envoyerDonnee("/pompe/commande/statut.json", "\"EXECUTE\"");
}

// ============================================================
//                   COMMANDES MOTEUR
// ============================================================
void demarrerMoteur() {
  setFrequence(consigneFrequence);
  delay(100);
  uint8_t result = variateur.writeSingleRegister(0x2001, 0x0001);
  if (result == variateur.ku8MBSuccess) { moteurEnMarche = true;  Serial.println("[MOTEUR] Demarre"); }
  else                                  { Serial.println("[MOTEUR] Erreur demarrage"); }
}

void arreterMoteur() {
  uint8_t result = variateur.writeSingleRegister(0x2001, 0x0005);
  if (result == variateur.ku8MBSuccess) { moteurEnMarche = false; Serial.println("[MOTEUR] Arrete"); }
  else                                  { Serial.println("[MOTEUR] Erreur arret"); }
}

void setFrequence(float freq) {
  consigneFrequence = constrain(freq, 0, 300);
  uint16_t valeur   = (uint16_t)(consigneFrequence * 100);
  variateur.writeSingleRegister(0x2000, valeur);
  Serial.printf("[FREQ] %.1f Hz\n", consigneFrequence);
}

// ============================================================
//              LIRE SEUILS DE PROTECTION
// ============================================================
void lireSeuilsProtection() {
  uint8_t result;
  result = variateur.readHoldingRegisters((14 << 8) | 11, 1);
  if (result == variateur.ku8MBSuccess) seuilVeille    = variateur.getResponseBuffer(0);
  result = variateur.readHoldingRegisters((14 << 8) | 12, 1);
  if (result == variateur.ku8MBSuccess) seuilReveil    = variateur.getResponseBuffer(0);
  result = variateur.readHoldingRegisters((14 << 8) | 14, 1);
  if (result == variateur.ku8MBSuccess) seuilBasseFreq = variateur.getResponseBuffer(0) / 100.0;
  result = variateur.readHoldingRegisters((14 << 8) | 17, 1);
  if (result == variateur.ku8MBSuccess) seuilMarcheSec = variateur.getResponseBuffer(0) / 10.0;
  result = variateur.readHoldingRegisters((14 << 8) | 20, 1);
  if (result == variateur.ku8MBSuccess) seuilSurintens = variateur.getResponseBuffer(0) / 10.0;
  result = variateur.readHoldingRegisters((14 << 8) | 23, 1);
  if (result == variateur.ku8MBSuccess) seuilPuissMin  = variateur.getResponseBuffer(0) / 100.0;

  JsonDocument doc;
  doc["veille"]       = seuilVeille;
  doc["reveil"]       = seuilReveil;
  doc["basse_freq"]   = seuilBasseFreq;
  doc["marche_sec"]   = seuilMarcheSec;
  doc["surintensite"] = seuilSurintens;
  doc["puiss_min"]    = seuilPuissMin;
  String json; serializeJson(doc, json);
  envoyerDonnee("/pompe/seuils.json", json);
}

// ============================================================
//              DIAGNOSTIC AVERTISSEMENTS
// ============================================================
void diagnostiquerAvertissements(float tens, float freq, float cour, float puis) {
  String avert = "";
  if      (seuilVeille > 0    && tens < seuilVeille    && tens > 0)  avert = "A.LPn";
  else if (seuilBasseFreq > 0 && moteurEnMarche && freq < seuilBasseFreq && freq > 0) avert = "A.LFr";
  else if (seuilMarcheSec > 0 && moteurEnMarche && cour < seuilMarcheSec && cour > 0) avert = "A.LuT";
  else if (seuilSurintens > 0 && moteurEnMarche && cour > seuilSurintens)              avert = "A.OLd";
  else if (seuilPuissMin > 0  && moteurEnMarche && puis < seuilPuissMin  && puis > 0) avert = "A.LPr";

  if (avert != "" && avert != dernierAvertissement) {
    dernierAvertissement = avert;
    for (int i = 0; i < nbErreurs; i++) {
      if (erreurs[i].code == avert) { envoyerErreurFirebase(erreurs[i]); break; }
    }
  } else if (avert == "" && dernierAvertissement != "") {
    dernierAvertissement = "";
    JsonDocument doc;
    doc["active"] = false; doc["code"] = ""; doc["description"] = "";
    doc["cause"] = ""; doc["solution"] = ""; doc["timestamp"] = getTimestamp();
    String json; serializeJson(doc, json);
    envoyerDonnee("/pompe/alarme.json", json);
  }
}

// ============================================================
//              DÉTECTER DÉFAUTS VARIATEUR
// ============================================================
void lireEtatDefaut() {
  uint8_t result = variateur.readHoldingRegisters(0x2100, 1);
  if (result != variateur.ku8MBSuccess) return;

  uint16_t etat   = variateur.getResponseBuffer(0);
  bool     defaut = (etat & 0x0001);

  if (defaut && dernierEtatDefaut == 0) {
    dernierEtatDefaut = 1;
    uint16_t adresse = ((9 << 8) | 18) | 0x1000;
    result = variateur.readHoldingRegisters(adresse, 1);
    if (result != variateur.ku8MBSuccess)
      result = variateur.readHoldingRegisters((9 << 8) | 18, 1);

    if (result == variateur.ku8MBSuccess) {
      uint16_t code = variateur.getResponseBuffer(0);
      ErreurInfo* err = nullptr;
      if      (code == 1)                      err = &erreurs[0];
      else if (code == 2)                      err = &erreurs[1];
      else if (code >= 10 && code <= 15)       err = &erreurs[2];
      else if (code >= 16 && code <= 20)       err = &erreurs[4];

      if (err != nullptr) {
        envoyerErreurFirebase(*err);
      } else {
        JsonDocument doc;
        doc["active"] = true;
        doc["code"]   = "0x" + String(code, HEX);
        doc["description"] = "Code non repertorie";
        doc["cause"]       = "Voir manuel Veichi SI23";
        doc["solution"]    = "Voir manuel Veichi SI23";
        doc["timestamp"]   = getTimestamp();
        String json; serializeJson(doc, json);
        envoyerDonnee("/pompe/alarme.json", json);
      }
    }
  } else if (!defaut && dernierEtatDefaut == 1) {
    dernierEtatDefaut = 0;
    JsonDocument doc;
    doc["active"] = false; doc["code"] = ""; doc["description"] = ""; doc["timestamp"] = getTimestamp();
    String json; serializeJson(doc, json);
    envoyerDonnee("/pompe/alarme.json", json);
  }
}

// ============================================================
//              ENVOYER ERREUR VERS FIREBASE
// ============================================================
void envoyerErreurFirebase(ErreurInfo err) {
  JsonDocument doc;
  doc["active"]      = true;
  doc["code"]        = err.code;
  doc["description"] = err.description;
  doc["cause"]       = err.cause;
  doc["solution"]    = err.solution;
  doc["timestamp"]   = getTimestamp();
  String json; serializeJson(doc, json);
  envoyerDonnee("/pompe/alarme.json", json);
  envoyerDonnee("/alarmes/" + getDateJour() + "/" + getTimestamp() + ".json", json);
}

// ============================================================
//         ÉCRIRE PARAMÈTRE VARIATEUR (depuis Firebase)
// ============================================================
bool ecrireParametreFirebase(String nomParam, int valeur) {
  if (!nomParam.startsWith("F")) return false;
  int pointIndex = nomParam.indexOf('.');
  if (pointIndex == -1) return false;
  int groupe = nomParam.substring(1, pointIndex).toInt();
  int num    = nomParam.substring(pointIndex + 1).toInt();
  uint16_t adresseRAM    = (groupe << 8) | num;
  uint16_t adresseEEPROM = adresseRAM | 0x1000;
  uint8_t result = variateur.writeSingleRegister(adresseRAM, (uint16_t)valeur);
  if (result == variateur.ku8MBSuccess) {
    delay(100);
    variateur.writeSingleRegister(adresseEEPROM, (uint16_t)valeur);
    Serial.println("[VAR] " + nomParam + " = " + String(valeur));
    return true;
  }
  Serial.println("[VAR] Erreur ecriture " + nomParam);
  return false;
}

// ============================================================
//              COMMANDES SÉRIE (console Arduino)
// ============================================================
void traiterCommandeSerial(String cmd) {
  if      (cmd == "START")  { arreterMinuterie(); demarrerMoteur(); }
  else if (cmd == "STOP")   { arreterMinuterie(); arreterMoteur(); }
  else if (cmd.startsWith("F=")) setFrequence(cmd.substring(2).toFloat());
  else if (cmd == "READ")   envoyerMesures();
  else if (cmd == "GPS")    envoyerGPS();
  else if (cmd == "STATUS") {
    Serial.printf("[STATUS] Moteur:%s Freq:%.1fHz Connexion:%s\n",
      moteurEnMarche ? "MARCHE" : "ARRET",
      consigneFrequence,
      modeActuel == CONNEXION_WIFI ? "WiFi" : modeActuel == CONNEXION_GPRS ? "GPRS" : "Aucune");
  }
  else if (cmd.startsWith("TIMER ")) {
    String args = cmd.substring(6);
    if (args == "OFF") { arreterMinuterie(); }
    else {
      int espIdx = args.indexOf(' ');
      if (espIdx != -1) {
        String temps  = args.substring(0, espIdx);
        String action = args.substring(espIdx + 1);
        int colonIdx  = temps.indexOf(':');
        if (colonIdx != -1) {
          int h = temps.substring(0, colonIdx).toInt();
          int m = temps.substring(colonIdx + 1).toInt();
          if      (action == "START") demarrerMinuterie(h, m, TIMER_RUN);
          else if (action == "STOP")  demarrerMinuterie(h, m, TIMER_STOP);
        }
      }
    }
  }
  else if (cmd.startsWith("R ")) lireParametreConsole(cmd.substring(2));
  else if (cmd.startsWith("W ")) {
    int egalIdx = cmd.indexOf('=');
    if (egalIdx != -1)
      ecrireParametreFirebase(cmd.substring(2, egalIdx), cmd.substring(egalIdx + 1).toInt());
  }
  else if (cmd == "HELP" || cmd == "H") afficherMenuAide();
  else if (cmd.length() > 0) Serial.println("[CMD] Inconnue. Tapez HELP");
}

void lireParametreConsole(String nomParam) {
  if (!nomParam.startsWith("F")) { Serial.println("[VAR] Format: R Fx.yy"); return; }
  int pointIndex = nomParam.indexOf('.');
  if (pointIndex == -1) { Serial.println("[VAR] Format: R Fx.yy"); return; }
  int groupe = nomParam.substring(1, pointIndex).toInt();
  int num    = nomParam.substring(pointIndex + 1).toInt();
  uint16_t adresse = ((groupe << 8) | num) | 0x1000;
  uint8_t  result  = variateur.readHoldingRegisters(adresse, 1);
  if (result == variateur.ku8MBSuccess)
    Serial.println("[VAR] " + nomParam + " = " + String(variateur.getResponseBuffer(0)));
  else
    Serial.println("[VAR] Erreur lecture " + nomParam);
}

// ============================================================
//                     MENU AIDE
// ============================================================
void afficherMenuAide() {
  Serial.println("\n\u2554\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2557");
  Serial.println("\u2551              LISTE DES COMMANDES                 \u2551");
  Serial.println("\u2560\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2563");
  Serial.println("\u2551 START              - Demarrer le moteur          \u2551");
  Serial.println("\u2551 STOP               - Arreter le moteur           \u2551");
  Serial.println("\u2551 F=XX               - Regler frequence (Hz)       \u2551");
  Serial.println("\u2551 TIMER HH:MM START  - Marche puis arret auto      \u2551");
  Serial.println("\u2551 TIMER HH:MM STOP   - Arret sans redemarrage      \u2551");
  Serial.println("\u2551 TIMER OFF          - Annuler minuterie           \u2551");
  Serial.println("\u2551 READ               - Lire et envoyer mesures     \u2551");
  Serial.println("\u2551 GPS                - Envoyer position GPS        \u2551");
  Serial.println("\u2551 STATUS             - Etat du systeme             \u2551");
  Serial.println("\u2551 R Fxx.yy           - Lire parametre variateur    \u2551");
  Serial.println("\u2551 W Fxx.yy=Z         - Ecrire parametre variateur  \u2551");
  Serial.println("\u2551 HELP               - Afficher ce menu            \u2551");
  Serial.println("\u255a\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u255d");
}

void verifierBoutonConfig() {
  pinMode(WIFI_CONFIG_BUTTON_PIN, INPUT_PULLUP);
  if (digitalRead(WIFI_CONFIG_BUTTON_PIN) != LOW) return;

  Serial.print("[CONFIG] Bouton BOOT - maintenir 3s pour mode AP");
  for (int i = 0; i < 30; i++) {
    delay(100);
    if (digitalRead(WIFI_CONFIG_BUTTON_PIN) != LOW) {
      Serial.println("\n[CONFIG] Relache - boot normal");
      return;
    }
    if (i % 5 == 4) Serial.print(".");
  }
  Serial.println("\n[CONFIG] Mode AP active !");
  demarrerModeConfigAP();
  Serial.println("[CONFIG] Timeout 5min - redemarrage");
  ESP.restart();
}

// ── Page principale GET / ─────────────────────────────────────
void handleRoot() {
  int n = WiFi.scanNetworks();

  String pg;
  pg.reserve(3500);

  pg = "<!DOCTYPE html><html lang=fr><head>"
       "<meta charset=UTF-8>"
       "<meta name=viewport content='width=device-width,initial-scale=1'>"
       "<title>Smart Pump Config</title><style>"
       "*{box-sizing:border-box;margin:0;padding:0}"
       "body{background:#0d1117;color:#c9d1d9;font:15px Arial,sans-serif;"
         "padding:16px;max-width:460px;margin:auto}"
       "h1{color:#1d9e75;text-align:center;padding:10px 0 20px;font-size:1.3em}"
       "h2{color:#8b949e;font-size:.78em;text-transform:uppercase;"
         "letter-spacing:.05em;margin:14px 0 8px}"
       ".c{background:#161b22;border:1px solid #30363d;border-radius:10px;"
         "padding:16px;margin-bottom:14px}"
       "label{display:block;margin:10px 0 4px;font-size:.85em;color:#8b949e}"
       "input,select{width:100%;padding:10px;background:#0d1117;color:#c9d1d9;"
         "border:1px solid #30363d;border-radius:6px;font-size:.95em}"
       ".g{display:block;width:100%;padding:12px;background:#1d9e75;color:#fff;"
         "border:none;border-radius:6px;font-size:1em;cursor:pointer;"
         "margin-top:12px;font-weight:700}"
       ".g:hover{background:#17876a}"
       ".r{background:#b91c1c!important;padding:7px 12px;margin-top:0}"
       ".r:hover{background:#991b1b!important}"
       ".row{display:flex;gap:8px;align-items:center;margin-bottom:6px}"
       ".row span{flex:1;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}"
       "footer{color:#8b949e;font-size:.75em;text-align:center;margin-top:8px}"
       "</style></head><body>"
       "<h1>&#9889; Smart Pump &#8212; Config WiFi</h1>";

  // Reseaux sauvegardes
  pg += "<div class=c><h2>R&#233;seaux sauvegard&#233;s</h2>";
  wifiPrefs.begin("wifi_cfg", true);
  bool any = false;
  for (int i = 1; i <= 3; i++) {
    String s = wifiPrefs.getString(("ssid" + String(i)).c_str(), "");
    if (!s.isEmpty()) {
      any = true;
      pg += "<div class=row><span>&#128246; " + s + "</span>"
            "<form action=/delete method=get style=margin:0>"
            "<input type=hidden name=slot value=" + String(i) + ">"
            "<button class='g r'>&#10005;</button></form></div>";
    }
  }
  wifiPrefs.end();
  if (!any)
    pg += "<p style='color:#8b949e;font-size:.85em'>Aucun r&#233;seau sauvegard&#233;</p>";
  pg += "</div>";

  // Ajouter un reseau
  pg += "<div class=c><h2>Ajouter un r&#233;seau</h2>";
  if (n > 0) {
    pg += "<label>R&#233;seaux d&#233;tect&#233;s</label>"
          "<select onchange=\"document.getElementById('sid').value=this.value\">"
          "<option value=''>-- choisir ou saisir --</option>";
    for (int i = 0; i < n; i++) {
      pg += "<option value='" + WiFi.SSID(i) + "'>"
            + WiFi.SSID(i) + " (" + String(WiFi.RSSI(i)) + " dBm)</option>";
    }
    pg += "</select>";
  }
  pg += "<form action=/save method=post>"
        "<label>SSID</label>"
        "<input type=text name=ssid id=sid required placeholder='Nom du r&#233;seau'>"
        "<label>Mot de passe</label>"
        "<input type=password name=pass placeholder='Mot de passe'>"
        "<button type=submit class=g>&#10003; Tester &amp; Sauvegarder</button>"
        "</form></div>"
        "<footer>Timeout 5 min &#8211; red&#233;marrage auto</footer>"
        "</body></html>";

  apServer.send(200, "text/html; charset=utf-8", pg);
  WiFi.scanDelete();
}

// ── POST /save : tester + stocker en NVS ─────────────────────
void handleSave() {
  String ssid = apServer.arg("ssid");
  String pass = apServer.arg("pass");

  if (ssid.isEmpty()) {
    apServer.send(400, "text/plain", "SSID manquant");
    return;
  }

  // Test connexion (AP reste actif en WIFI_AP_STA)
  WiFi.begin(ssid.c_str(), pass.c_str());
  bool ok = false;
  for (int i = 0; i < 20 && !ok; i++) {
    delay(500);
    ok = (WiFi.status() == WL_CONNECTED);
  }
  WiFi.disconnect();   // STA seulement, AP reste vivant

  String pg;
  pg.reserve(900);
  pg = "<!DOCTYPE html><html lang=fr><head>"
       "<meta charset=UTF-8>"
       "<meta name=viewport content='width=device-width,initial-scale=1'>"
       "<title>Smart Pump Config</title><style>"
       "body{background:#0d1117;color:#c9d1d9;font:15px Arial,sans-serif;"
         "padding:20px;max-width:460px;margin:auto;text-align:center}"
       "h1{color:#1d9e75;padding:10px 0 20px;font-size:1.3em}"
       ".c{background:#161b22;border:1px solid #30363d;border-radius:10px;"
         "padding:24px;margin:20px 0}"
       ".ico{font-size:3.5em;margin:10px 0}"
       "p{margin-top:10px}"
       "a{color:#58a6ff;display:block;margin-top:18px;text-decoration:none}"
       "</style></head><body>"
       "<h1>&#9889; Smart Pump &#8212; Config WiFi</h1><div class=c>";

  if (ok) {
    wifiPrefs.begin("wifi_cfg", false);
    int slot = -1;
    for (int i = 1; i <= 3; i++) {
      String ex = wifiPrefs.getString(("ssid" + String(i)).c_str(), "");
      if (ex == ssid)                { slot = i; break; }
      if (slot < 0 && ex.isEmpty()) { slot = i; }
    }
    if (slot < 0) slot = 1;
    wifiPrefs.putString(("ssid" + String(slot)).c_str(), ssid);
    wifiPrefs.putString(("pass" + String(slot)).c_str(), pass);
    wifiPrefs.end();

    Serial.println("[AP] Sauvegarde : " + ssid + " -> slot " + String(slot));
    pg += "<div class=ico>&#9989;</div>"
          "<p style='color:#1d9e75;font-weight:700;font-size:1.1em'>"
          "Connexion r&#233;ussie !</p>"
          "<p>" + ssid + " sauvegard&#233; (slot " + String(slot) + ")</p>";
  } else {
    Serial.println("[AP] Echec : " + ssid);
    pg += "<div class=ico>&#10060;</div>"
          "<p style='color:#b91c1c;font-weight:700;font-size:1.1em'>"
          "Connexion &#233;chou&#233;e</p>"
          "<p>V&#233;rifier SSID et mot de passe</p>";
  }

  pg += "<a href=/>&#8592; Retour</a></div></body></html>";
  apServer.send(200, "text/html; charset=utf-8", pg);
}

// ── GET /delete?slot=N ────────────────────────────────────────
void handleDelete() {
  int slot = apServer.arg("slot").toInt();
  if (slot >= 1 && slot <= 3) {
    wifiPrefs.begin("wifi_cfg", false);
    wifiPrefs.remove(("ssid" + String(slot)).c_str());
    wifiPrefs.remove(("pass" + String(slot)).c_str());
    wifiPrefs.end();
    Serial.println("[AP] Supprime slot " + String(slot));
  }
  apServer.sendHeader("Location", "/");
  apServer.send(302, "text/plain", "Redirect");
}

// ── Boucle AP + WebServer (5 min) ────────────────────────────
void demarrerModeConfigAP() {
  WiFi.mode(WIFI_AP_STA);  // AP + STA simultanes : permet scan et test

  IPAddress apIP;
  apIP.fromString(AP_IP);
  WiFi.softAPConfig(apIP, apIP, IPAddress(255, 255, 255, 0));
  WiFi.softAP(AP_SSID, AP_PASSWORD);

  Serial.println("[AP] Mode Config AP actif");
  Serial.println("[AP] SSID     : " AP_SSID);
  Serial.println("[AP] Password : " AP_PASSWORD);
  Serial.println("[AP] IP       : " AP_IP);
  Serial.println("[AP] Timeout  : 5 minutes");

  apServer.on("/",       HTTP_GET,  handleRoot);
  apServer.on("/save",   HTTP_POST, handleSave);
  apServer.on("/delete", HTTP_GET,  handleDelete);
  apServer.begin();
  Serial.println("[AP] Connectez-vous a " AP_SSID " puis ouvrez http://" AP_IP);

  const unsigned long TIMEOUT_AP = 5UL * 60UL * 1000UL;
  unsigned long t0 = millis();

  while (millis() - t0 < TIMEOUT_AP) {
    apServer.handleClient();
    delay(2);
  }

  apServer.stop();
  WiFi.softAPdisconnect(true);
  Serial.println("[AP] Portail ferme (timeout 5 min)");
}
