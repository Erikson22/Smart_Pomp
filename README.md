# 🌞 SMART PUMP — Documentation Complète

> Système de supervision d'une pompe solaire VEICHI SI23 via ESP32, GPRS SIM808, Firebase et Flutter.

---

## Table des matières

1. [Vue d'ensemble du projet](#1-vue-densemble-du-projet)
2. [Structure du projet](#2-structure-du-projet)
3. [État actuel (juin 2026)](#3-état-actuel-juin-2026)
4. [Problème principal à résoudre](#4-problème-principal-à-résoudre)
5. [Instructions déploiement relay (priorité #1)](#5-instructions-déploiement-relay--priorité-1)
6. [Configuration requise](#6-configuration-requise)
7. [Comment tester que tout fonctionne](#7-comment-tester-que-tout-fonctionne)
8. [Prochaines étapes après le relay](#8-prochaines-étapes-après-le-relay)
9. [Contacts et ressources](#9-contacts-et-ressources)

---

## 1. Vue d'ensemble du projet

### Description

Smart Pump est un système embarqué de **supervision en temps réel** d'une pompe alimentée par panneaux solaires, pilotée par le variateur de fréquence **VEICHI SI23**. Le firmware tourne sur un **ESP32**, communique avec le variateur via **Modbus RS485**, envoie les données vers **Firebase Realtime Database** via GPRS (module **SIM808**), et une application mobile **Flutter** permet la visualisation et le contrôle à distance.

### Architecture globale

```
┌─────────────────────────────────────────────────────────────────────┐
│                        TERRAIN                                       │
│                                                                      │
│  ┌──────────────┐   RS485/Modbus   ┌──────────────┐                │
│  │ Variateur    │◄────────────────►│   ESP32      │                │
│  │ VEICHI SI23  │                  │  (firmware)  │                │
│  └──────────────┘                  └──────┬───────┘                │
│                                           │ UART                    │
│                                    ┌──────▼───────┐                │
│                                    │   SIM808     │                │
│                                    │ (GPRS/GPS)   │                │
│                                    └──────┬───────┘                │
└───────────────────────────────────────────│─────────────────────────┘
                                            │ GPRS (HTTP)
                                    ┌───────▼────────┐
                                    │   Relay HTTP   │  ← server.js
                                    │ (Render/Fly.io)│    Node.js
                                    └───────┬────────┘
                                            │ HTTPS (TLS 1.2)
                                    ┌───────▼────────┐
                                    │    Firebase    │
                                    │  Realtime DB   │
                                    │ SmartPumpMonitor│
                                    └───────┬────────┘
                                            │ SDK Firebase
                                    ┌───────▼────────┐
                                    │ App Flutter    │
                                    │ (Android)      │
                                    └────────────────┘
```

### Flux de données

| Étape | Source | Destination | Protocole |
|-------|--------|-------------|-----------|
| 1 | Variateur VEICHI SI23 | ESP32 | Modbus RTU / RS485 |
| 2 | ESP32 | SIM808 | UART (Serial2) |
| 3 | SIM808 | Relay HTTP | GPRS + TCP port 80 ou 443 |
| 4 | Relay (Node.js) | Firebase RTDB | HTTPS / REST API |
| 5 | Firebase RTDB | App Flutter | WebSocket / SDK Firebase |

### Composants matériels

| Composant | Rôle | Interface |
|-----------|------|-----------|
| ESP32 DevKit v1 | Microcontrôleur principal | — |
| SIM808 | GPRS + GPS | UART Serial2 (TX:17, RX:16) |
| VEICHI SI23 | Variateur de fréquence pompe | RS485 Modbus RTU |
| SIM Ooredoo TN | Connectivité GPRS | APN : internet.ooredoo.tn |

---

## 2. Structure du projet

```
F:\Smart_Pomp\
│
├── 📁 arduino/smart_pump/       ← Firmware ESP32 (PlatformIO)
│   ├── smart_pump.ino           ← Code principal (1168 lignes)
│   ├── config.h                 ← ⚠️ SECRETS (gitignore) – à remplir
│   ├── config.h.example         ← Modèle de config.h à copier
│   └── platformio.ini           ← Config build PlatformIO
│
├── 📁 app/                      ← Application Flutter (Android)
│   ├── lib/
│   │   ├── main.dart            ← Point d'entrée, initialisation Firebase
│   │   ├── firebase_options.dart← Config Firebase (projet SmartPumpMonitor)
│   │   ├── screens/             ← Écrans (tableau de bord, historique…)
│   │   ├── services/            ← PompeService (listeners Firebase)
│   │   └── providers/           ← State management (Provider)
│   ├── android/
│   │   └── app/google-services.json  ← ⚠️ À télécharger depuis Firebase Console
│   └── pubspec.yaml             ← Dépendances Flutter
│
├── 📁 functions/                ← Relay HTTP → Firebase RTDB
│   ├── server.js                ← ✅ Serveur Node.js standalone (Render/Fly.io)
│   ├── index.js                 ← (ancien, Firebase Functions – ne pas utiliser)
│   ├── package.json             ← Dépendances Node.js (aucune externe)
│   └── .gitignore               ← Exclut node_modules, .env, clés
│
├── render.yaml                  ← Config déploiement Render.com
├── firebase.json                ← Config Firebase CLI (non utilisé sur Spark)
├── .firebaserc                  ← Projet Firebase par défaut
└── README.md                    ← Ce fichier
```

### Fichiers critiques à connaître

#### `arduino/smart_pump/smart_pump.ino`
Le cœur du projet. Contient :
- `setup()` / `loop()` — boot GPRS → WiFi fallback
- `connecterGPRS()` / `connecterWiFi()` — gestion connexion
- `envoyerViaGPRS()` / `lireViaGPRS()` — communication relay
- `envoyerMesures()` — lecture Modbus + push Firebase
- `demarrerModeConfigAP()` — portail WiFi sur 192.168.4.1
- `verifierBoutonConfig()` — maintenir GPIO0 3s au boot pour activer AP

#### `arduino/smart_pump/config.h`
**Ce fichier est dans `.gitignore` — il ne sera jamais commité.** Il contient tous les secrets. Copier `config.h.example` → `config.h` et remplir les valeurs.

#### `functions/server.js`
Serveur Node.js autonome (zéro dépendance npm). Reçoit les requêtes HTTP du SIM808 et les retransmet vers Firebase via HTTPS (REST API + Database Secret).

---

## 3. État actuel (juin 2026)

### ✅ Ce qui fonctionne

| Fonctionnalité | Détail |
|----------------|--------|
| 🔌 Build firmware | `pio run -t upload` → SUCCESS (espressif32@6.9.0) |
| 📡 GPRS SIM808 | Connexion GPRS OK au boot (APN Ooredoo) |
| 🏠 Boot GPRS-first | GPRS essayé en premier, WiFi en fallback |
| 📶 WiFi Manager AP | Portail config sur 192.168.4.1 (bouton boot 3s) |
| 💾 NVS WiFi | Jusqu'à 3 réseaux stockés en mémoire flash NVS |
| 🗄️ Firebase RTDB | Structure de base créée (projet SmartPumpMonitor) |
| 📱 App Flutter | Build Android OK, connectée à Firebase |
| 🌡️ ArduinoJson v7 | Migration `StaticJsonDocument` → `JsonDocument` faite |

### ❌ Ce qui ne fonctionne pas encore

| Problème | Cause | Solution |
|----------|-------|----------|
| 🔒 SIM808 → Firebase bloqué | SIM808 ne supporte pas TLS 1.2 (Firebase exige TLS 1.2+) | Déployer le relay `server.js` (voir §5) |
| 📊 Données Modbus à 0 | Variateur non connecté durant les tests | Brancher le RS485 et tester (voir §8) |
| 🌐 Relay non déployé | `server.js` prêt mais pas encore hébergé | Déployer sur Render.com ou Fly.io |

---

## 4. Problème principal à résoudre

### Pourquoi le SIM808 ne peut pas contacter Firebase directement

Le module SIM808 (basé sur SIM800) implémente TLS via AT+CIPSSL. Son firmware supporte au maximum **TLS 1.0 / TLS 1.1**. Or, depuis 2021, Firebase (Google) **exige TLS 1.2 minimum** et a désactivé les connexions TLS 1.0/1.1.

```
SIM808 ──TLS 1.0──► Firebase ✗  (TLS 1.2 requis → connexion refusée)
```

Log observé sur Serial Monitor :
```
[GPRS] Connexion Firebase REST smartpumpmonitor-default-rtdb...:443
[GPRS] Echec connexion TLS – vérifier firmware SIM808 (TLS 1.2 requis)
[FB] Erreur -1 -> /pompe/seuils.json
```

### La solution : relay intermédiaire

On insère un serveur intermédiaire (relay) entre le SIM808 et Firebase. Le SIM808 envoie ses données en **HTTP simple** (sans TLS) au relay. Le relay, lui, utilise Node.js sur un serveur moderne qui supporte TLS 1.2+ nativement et retransmet vers Firebase.

```
SIM808 ──HTTP (TCP)──► Relay Node.js ──HTTPS/TLS1.2──► Firebase RTDB ✓
```

Le relay existe déjà dans `functions/server.js`. Il faut juste l'héberger.

### Deux options d'hébergement

| | Option A — Render.com | Option B — Fly.io |
|---|---|---|
| **Port SIM808** | 443 (HTTPS) | 80 (HTTP, sans TLS) |
| **Gratuit** | ✅ Free tier | ✅ Free tier |
| **Fiabilité TLS** | ⚠️ TLS 1.2 requis (peut échouer SIM808) | ✅ Port 80 garanti sans TLS |
| **Facilité** | ⭐⭐⭐ Très simple (GitHub connect) | ⭐⭐ Nécessite flyctl CLI |
| **Recommandé** | Essayer en premier | Si Render échoue |

---

## 5. Instructions déploiement relay — Priorité #1

### Option A — Render.com

#### Étape 1 : Créer le repo GitHub

Ouvrir **PowerShell** et exécuter :

```powershell
cd F:\Smart_Pomp\functions

git init
git add server.js package.json .gitignore
git commit -m "feat: relay HTTP SIM808 -> Firebase RTDB"
```

Sur [github.com](https://github.com) → **New repository** :
- Nom : `smart-pump-relay`
- Visibilité : Public ou Private (peu importe)
- **Ne pas** cocher "Add README"

```powershell
git remote add origin https://github.com/TON_USERNAME/smart-pump-relay.git
git branch -M main
git push -u origin main
```

#### Étape 2 : Déployer sur Render.com

1. Aller sur [render.com](https://render.com) → **Sign in with GitHub**
2. **New +** → **Web Service**
3. Connecter le repo `smart-pump-relay`
4. Configurer :

| Paramètre | Valeur |
|-----------|--------|
| **Name** | `smart-pump-relay` |
| **Region** | Frankfurt (EU) |
| **Branch** | `main` |
| **Runtime** | Node |
| **Build Command** | *(laisser vide)* |
| **Start Command** | `node server.js` |
| **Plan** | Free |

5. **Environment Variables** → Add :

| Clé | Valeur |
|-----|--------|
| `FIREBASE_HOST` | `smartpumpmonitor-default-rtdb.europe-west1.firebasedatabase.app` |
| `FIREBASE_SECRET` | *(ton Database Secret — voir §6)* |

6. Cliquer **Create Web Service** → attendre ~2 minutes

L'URL sera : `https://smart-pump-relay.onrender.com`

#### Étape 3 : Tester le relay depuis PowerShell

```powershell
# Test POST (écriture Firebase)
Invoke-WebRequest -Uri "https://smart-pump-relay.onrender.com/relay" `
  -Method POST `
  -ContentType "application/json" `
  -Body '{"path":"/test/ping","data":"hello"}'

# Réponse attendue : StatusCode 200
```

#### Étape 4 : Mettre à jour config.h

Dans `F:\Smart_Pomp\arduino\smart_pump\config.h`, modifier :

```cpp
#define RELAY_HOST  "smart-pump-relay.onrender.com"  // ← URL Render réelle
#define RELAY_PORT  443
#define RELAY_PATH  "/relay"
```

#### Étape 5 : Recompiler et flasher

```powershell
cd F:\Smart_Pomp\arduino\smart_pump
pio run -t upload --upload-port COM23
pio device monitor --port COM23 --baud 115200
```

Log attendu si relay fonctionne :
```
[GPRS] Relay smart-pump-relay.onrender.com:443
[GPRS] Relay réponse: 200
```

---

### Option B — Fly.io (si Render échoue avec TLS)

Fly.io permet l'accès HTTP sur port 80 sans TLS — garanti compatible SIM808.

#### Étape 1 : Installer flyctl

```powershell
# Windows (PowerShell)
iwr https://fly.io/install.ps1 -useb | iex
```

#### Étape 2 : Se connecter

```powershell
fly auth login
```

#### Étape 3 : Créer un Dockerfile

Dans `F:\Smart_Pomp\functions\`, créer le fichier `Dockerfile` :

```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY server.js package.json ./
EXPOSE 8080
CMD ["node", "server.js"]
```

#### Étape 4 : Lancer le déploiement

```powershell
cd F:\Smart_Pomp\functions
fly launch --name smart-pump-relay --region cdg --no-deploy
```

Configurer les secrets :

```powershell
fly secrets set FIREBASE_HOST="smartpumpmonitor-default-rtdb.europe-west1.firebasedatabase.app"
fly secrets set FIREBASE_SECRET="TON_DATABASE_SECRET"
```

Déployer :

```powershell
fly deploy
```

#### Étape 5 : Désactiver le redirect HTTPS dans fly.toml

Éditer `fly.toml` généré et ajouter :

```toml
[[http_service]]
  internal_port = 8080
  force_https   = false    # ← IMPORTANT : permet HTTP port 80 pour SIM808
  auto_stop_machines = true
  auto_start_machines = true
```

```powershell
fly deploy   # redéployer après modification
```

#### Étape 6 : Mettre à jour config.h

```cpp
// Commenter Option A et activer Option B :
// #define RELAY_HOST  "smart-pump-relay.onrender.com"
// #define RELAY_PORT  443
#define RELAY_HOST  "smart-pump-relay.fly.dev"   // ← URL Fly.io réelle
#define RELAY_PORT  80
#define RELAY_PATH  "/relay"
```

Recompiler et flasher :

```powershell
cd F:\Smart_Pomp\arduino\smart_pump
pio run -t upload --upload-port COM23
```

---

## 6. Configuration requise

### Fichiers à remplir avant de commencer

#### `arduino/smart_pump/config.h`

Copier d'abord le modèle :
```powershell
copy F:\Smart_Pomp\arduino\smart_pump\config.h.example `
     F:\Smart_Pomp\arduino\smart_pump\config.h
```

Puis remplir chaque valeur :

```cpp
// ── Relay ────────────────────────────────────────────────────────────
#define RELAY_HOST  "smart-pump-relay.onrender.com"  // URL après déploiement
#define RELAY_PORT  443                               // 443 Render / 80 Fly.io
#define RELAY_PATH  "/relay"

// ── Firebase ─────────────────────────────────────────────────────────
#define FIREBASE_HOST    "smartpumpmonitor-default-rtdb.europe-west1.firebasedatabase.app"
#define FIREBASE_PORT    443
#define FIREBASE_SECRET  "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
//  ↑ Console Firebase → SmartPumpMonitor → ⚙️ Paramètres du projet
//    → Comptes de service → (bas de page) Database secrets → Afficher

// ── GPRS Ooredoo Tunisie ─────────────────────────────────────────────
#define APN       "internet.ooredoo.tn"
#define APN_USER  ""
#define APN_PASS  ""

// ── WiFi fallback ─────────────────────────────────────────────────────
#define WIFI_SSID      "ton_reseau_wifi"
#define WIFI_PASSWORD  "ton_mot_de_passe"

// ── WiFi AP Config Portal ─────────────────────────────────────────────
#define AP_SSID      "SmartPump-Config"
#define AP_PASSWORD  "smartpump123"
```

#### `app/android/app/google-services.json`

1. Aller sur [console.firebase.google.com](https://console.firebase.google.com)
2. Sélectionner le projet **SmartPumpMonitor**
3. ⚙️ **Paramètres du projet** → onglet **Tes applications**
4. Section Android → **Télécharger google-services.json**
5. Placer le fichier dans `F:\Smart_Pomp\app\android\app\`

---

## 7. Comment tester que tout fonctionne

### 7.1 Flasher le firmware ESP32

```powershell
cd F:\Smart_Pomp\arduino\smart_pump

# Compiler + flasher
pio run -t upload --upload-port COM23

# Ouvrir le moniteur série
pio device monitor --port COM23 --baud 115200
```

### 7.2 Interpréter les logs Serial Monitor

```
╔══════════════════════════════════════════╗
║   SMART PUMP - VEICHI SI23 + Firebase   ║
╚══════════════════════════════════════════╝
[SIM808] Initialisation...
[SIM808] OK
[GPRS] Connexion                          ← GPRS en cours
[GPRS] OK                                 ← ✅ GPRS connecté

[GPRS] Relay smart-pump-relay.onrender.com:443
[GPRS] Relay réponse: 200                 ← ✅ Relay OK, données dans Firebase

[MESURES] Freq=50.0Hz Tens=380.0V ...    ← ✅ Modbus OK (variateur branché)
[GPS] Lat=36.8065 Lon=10.1815            ← ✅ GPS fix obtenu
```

### 7.3 Vérifier Firebase Console

1. [console.firebase.google.com](https://console.firebase.google.com) → **SmartPumpMonitor**
2. **Realtime Database** → vérifier les nœuds :

```
smartpumpmonitor-default-rtdb
└── pompe/
    ├── mesures/     ← tension, courant, fréquence, puissance
    ├── etat/        ← moteurEnMarche, modeConnexion
    ├── seuils/      ← freqMin, freqMax, tensMin
    └── gps/         ← latitude, longitude, altitude
```

### 7.4 Tester l'app Flutter

```powershell
cd F:\Smart_Pomp\app
flutter pub get
flutter run
```

Si les données Firebase sont présentes, l'app affiche les valeurs en temps réel.

### 7.5 Tester le portail WiFi AP

1. Mettre l'ESP32 hors tension
2. Maintenir le bouton **BOOT (GPIO0)** enfoncé
3. Remettre sous tension — continuer à maintenir 3 secondes
4. Relâcher → l'ESP32 démarre en mode AP
5. Sur smartphone : se connecter au réseau **SmartPump-Config** (mdp : `smartpump123`)
6. Naviguer vers **http://192.168.4.1**
7. Scanner, choisir un réseau WiFi, entrer le mot de passe, enregistrer

---

## 8. Prochaines étapes après le relay

### 🥇 Priorité 1 — Déployer le relay et valider la chaîne complète

Suivre le §5 (Render.com ou Fly.io). Une fois le relay fonctionnel, la chaîne complète SIM808 → Firebase → Flutter sera opérationnelle.

### 🥈 Priorité 2 — Connecter le variateur Modbus (RS485)

Le firmware lit déjà les bons registres Modbus du VEICHI SI23. Il faut câbler physiquement :

| ESP32 | Convertisseur RS485 | VEICHI SI23 |
|-------|---------------------|-------------|
| GPIO 4 (DE/RE) | DE + RE | — |
| GPIO 17 (TX) | DI | — |
| GPIO 16 (RX) | RO | — |
| — | A+ | Borne RS485 A |
| — | B- | Borne RS485 B |
| GND | GND | GND |

Registres lus (adresses Modbus du SI23) :

| Registre | Valeur | Unité |
|----------|--------|-------|
| 0x2101 | Fréquence sortie | ×0.01 Hz |
| 0x2102 | Courant sortie | ×0.1 A |
| 0x2103 | Tension panneaux | ×0.1 V |
| 0x2104 | Tension sortie | ×0.1 V |
| 0x210B | Tension bus DC | ×0.1 V |

### 🥉 Priorité 3 — Sécuriser Firebase

Actuellement les règles Firebase sont probablement ouvertes (mode développement). Avant la mise en production :

1. Activer Firebase Authentication (email/mot de passe ou Google)
2. Mettre à jour les règles RTDB :
```json
{
  "rules": {
    ".read":  "auth != null",
    ".write": "auth != null"
  }
}
```
3. Adapter l'app Flutter pour s'authentifier avant d'accéder aux données

### Autres améliorations

- [ ] Tester et valider le WiFi Manager AP avec plusieurs réseaux sauvegardés en NVS
- [ ] Ajouter des alertes push (Firebase Cloud Messaging) pour les seuils dépassés
- [ ] Implémenter l'historique journalier (`/historique/YYYY-MM-DD/HH.json`)
- [ ] Mettre à jour le firmware SIM808 vers une version supportant TLS 1.2 (éliminer le besoin du relay)

---

## 9. Contacts et ressources

### Projet Firebase

| Paramètre | Valeur |
|-----------|--------|
| **Nom du projet** | SmartPumpMonitor |
| **RTDB URL** | `https://smartpumpmonitor-default-rtdb.europe-west1.firebasedatabase.app` |
| **Région RTDB** | europe-west1 |
| **Plan** | Spark (gratuit) |

### Matériel ESP32

| Paramètre | Valeur |
|-----------|--------|
| **Board** | ESP32 DevKit v1 (`esp32dev`) |
| **Port série** | COM23 *(peut changer selon le PC)* |
| **Baud rate** | 115200 |
| **Flash mode** | DIO |
| **Partition** | huge_app.csv (3 MB app) |
| **Platform PlatformIO** | espressif32@6.9.0 |

### Ressources utiles

| Ressource | URL |
|-----------|-----|
| 📚 TinyGSM (SIM808) | https://github.com/vshymanskyy/TinyGSM |
| 📚 PlatformIO ESP32 | https://docs.platformio.org/en/latest/boards/espressif32/esp32dev.html |
| 📚 Firebase REST API | https://firebase.google.com/docs/database/rest/retrieve-data |
| 📚 VEICHI SI23 Modbus | Manuel technique VEICHI SI23 (registres 0x2100–0x2110) |
| 📚 ArduinoJson v7 | https://arduinojson.org/v7/doc/ |
| 🌐 Render.com | https://render.com |
| 🌐 Fly.io | https://fly.io |
| 🌐 Console Firebase | https://console.firebase.google.com |

### Arborescence des logs Serial Monitor

```
[SIM808] ...    → Communications avec le module SIM808
[GPRS]   ...    → Connexion GPRS et relay
[WiFi]   ...    → Connexion WiFi
[FB]     ...    → Opérations Firebase (succès / erreur code HTTP)
[MODBUS] ...    → Lectures registres variateur
[GPS]    ...    → Position GPS
[AP]     ...    → Mode Access Point (portail config)
[VAR]    ...    → Lecture/écriture paramètres variateur
[NET]    ...    → Stratégie connexion (GPRS/WiFi/aucune)
[TIMER]  ...    → Minuterie programmée
```

---

*README généré en juin 2026 — À mettre à jour après déploiement du relay et connexion Modbus.*
