import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/mesures_model.dart';
import '../models/gps_model.dart';
import '../models/alarme_model.dart';

class PompeService extends ChangeNotifier {

  DatabaseReference? _dbRef;

  DatabaseReference get _db {
    _dbRef ??= FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://solarpumpsupervision-b0c86-default-rtdb.europe-west1.firebasedatabase.app',
    ).ref();
    return _dbRef!;
  }

  MesuresModel? mesures;
  GpsModel?     gps;
  AlarmeModel?  alarme;
  bool   enMarche  = false;
  double frequence = 20.0;

  String? get alarmeCode        => alarme?.active == true ? alarme?.code : null;
  String? get alarmeDescription => alarme?.active == true ? alarme?.description : null;

  void ecouterMesures() {
    _db.child('pompe/mesures').onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) { mesures = MesuresModel.fromMap(data); notifyListeners(); }
    });
  }

  void ecouterEtat() {
    _db.child('pompe/etat').onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        enMarche  = data['en_marche'] ?? false;
        frequence = (data['frequence'] ?? 20.0).toDouble();
        notifyListeners();
      }
    });
  }

  void ecouterAlarmes() {
    _db.child('pompe/alarme').onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) { alarme = AlarmeModel.fromMap(data); notifyListeners(); }
    });
  }

  void ecouterGPS() {
    _db.child('pompe/gps').onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) { gps = GpsModel.fromMap(data); notifyListeners(); }
    });
  }

  Future<void> envoyerCommande(String ordre, {Map<String, dynamic>? extras}) async {
    final commande = {
      'ordre':     ordre,
      'statut':    'EN_ATTENTE',
      'timestamp': DateTime.now().toIso8601String(),
      ...?extras,
    };
    await _db.child('pompe/commande').set(commande);
  }

  Future<void> demarrer()             => envoyerCommande('START');
  Future<void> arreter()              => envoyerCommande('STOP');
  Future<void> setFrequence(double f) => envoyerCommande('SET_FREQ', extras: {'frequence': f});
  Future<void> resetVariateur()       => envoyerCommande('RESET_VARIATEUR');

  Future<void> setTimer(int heures, int minutes, String mode) =>
      envoyerCommande('TIMER_$mode', extras: {
        'timer_heures':  heures,
        'timer_minutes': minutes,
      });

  Future<void> ecrireParametre(String param, int valeur) =>
      envoyerCommande('SET_PARAM', extras: {
        'parametre': param,
        'valeur':    valeur,
      });
}