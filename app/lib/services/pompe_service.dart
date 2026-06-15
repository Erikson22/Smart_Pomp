import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../models/alarme.dart';
import '../models/etat.dart';
import '../models/gps_data.dart';
import '../models/mesure.dart';
import '../utils/notifications.dart';

class PompeService extends ChangeNotifier {
  final DatabaseReference _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://solarpumpsupervision-b0c86-default-rtdb.europe-west1.firebasedatabase.app',
  ).ref();

  // --- État brut pour le dashboard (Provider) ---
  Map<String, dynamic> mesures = {};
  Map<String, dynamic> etat    = {};
  Map<String, dynamic> alarme  = {};
  Map<String, dynamic> gps     = {};

  bool   get enMarche  => etat['en_marche'] ?? false;
  double get frequence => _safeDouble(etat['frequence']);

  bool _alarmeWasActive = false;

  // --- Gestion des abonnements ---
  bool _listening = false;
  StreamSubscription<DatabaseEvent>? _subMesures;
  StreamSubscription<DatabaseEvent>? _subEtat;
  StreamSubscription<DatabaseEvent>? _subAlarme;
  StreamSubscription<DatabaseEvent>? _subGps;

  /// Démarre les 4 listeners Firebase une seule fois (idempotent).
  void ecouterTout() {
    if (_listening) return;
    _listening = true;

    _subMesures = _db.child('pompe/mesures').onValue.listen((e) {
      mesures = _toMap(e.snapshot.value);
      notifyListeners();
    });
    _subEtat = _db.child('pompe/etat').onValue.listen((e) {
      etat = _toMap(e.snapshot.value);
      notifyListeners();
    });
    _subAlarme = _db.child('pompe/alarme').onValue.listen((e) {
      alarme = _toMap(e.snapshot.value);
      _verifierAlarme();
      notifyListeners();
    });
    _subGps = _db.child('pompe/gps').onValue.listen((e) {
      gps = _toMap(e.snapshot.value);
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subMesures?.cancel();
    _subEtat?.cancel();
    _subAlarme?.cancel();
    _subGps?.cancel();
    super.dispose();
  }

  void _verifierAlarme() {
    final active = alarme['active'] == true;
    if (active && !_alarmeWasActive) {
      final code = alarme['code'] ?? 'Alarme';
      final desc = alarme['description'] ?? 'Défaut détecté sur la pompe';
      showAlarmNotification(code, desc);
    }
    _alarmeWasActive = active;
  }

  // --- Helpers de parsing sûrs ---

  /// Convertit une valeur Firebase en Map<String, dynamic> sans exception.
  static Map<String, dynamic> _toMap(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : {};

  /// Convertit int / double / String en double, retourne [fallback] si impossible.
  static double _safeDouble(dynamic v, [double fallback = 0.0]) {
    if (v == null)    return fallback;
    if (v is double)  return v;
    if (v is int)     return v.toDouble();
    if (v is String)  return double.tryParse(v) ?? fallback;
    return fallback;
  }

  // --- Streams typés pour les autres écrans ---
  Stream<Alarme> get alarmeStream => _db.child('pompe/alarme').onValue.map(
        (e) => Alarme.fromJson(_toMap(e.snapshot.value)),
      );

  Stream<GPSData> get gpsStream => _db.child('pompe/gps').onValue.map(
        (e) => GPSData.fromJson(_toMap(e.snapshot.value)),
      );

  Stream<Mesure> get mesuresStream => _db.child('pompe/mesures').onValue.map(
        (e) => Mesure.fromJson(_toMap(e.snapshot.value)),
      );

  Stream<EtatPompe> get etatStream => _db.child('pompe/etat').onValue.map(
        (e) => EtatPompe.fromJson(_toMap(e.snapshot.value)),
      );

  // --- Commandes ---
  Future<void> _envoyerCommande(Map<String, dynamic> commande) async {
    await _db.child('pompe/commande').set({
      ...commande,
      'statut': 'EN_ATTENTE',
      'timestamp': ServerValue.timestamp,
    });
  }

  Future<void> demarrer()             => _envoyerCommande({'ordre': 'START'});
  Future<void> arreter()              => _envoyerCommande({'ordre': 'STOP'});
  Future<void> setFrequence(double f) => _envoyerCommande({'ordre': 'SET_FREQ', 'frequence': f});
  Future<void> resetVariateur()       => _envoyerCommande({'ordre': 'RESET_VARIATEUR'});

  Future<void> startTimerRun(int heures, int minutes) => _envoyerCommande({
        'ordre': 'TIMER_RUN',
        'timer_heures': heures,
        'timer_minutes': minutes,
      });

  Future<void> startTimerStop(int heures, int minutes) => _envoyerCommande({
        'ordre': 'TIMER_STOP',
        'timer_heures': heures,
        'timer_minutes': minutes,
      });

  Future<void> annulerTimer() => _envoyerCommande({'ordre': 'TIMER_OFF'});

  Future<void> setParametre(String param, int valeur) => _envoyerCommande({
        'ordre': 'SET_PARAM',
        'parametre': param,
        'valeur': valeur,
      });

  // --- Lectures ponctuelles ---
  Future<Map<String, dynamic>> getSeuils() async {
    final snapshot = await _db.child('pompe/seuils').get();
    return snapshot.exists ? _toMap(snapshot.value) : {};
  }

  Future<Map<String, dynamic>> getHistoriqueJour(String date) async {
    final snapshot = await _db.child('historique/$date').get();
    return snapshot.exists ? _toMap(snapshot.value) : {};
  }
}
