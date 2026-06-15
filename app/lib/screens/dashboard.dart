import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/etat.dart';
import '../services/pompe_service.dart';
import '../widgets/etat_pompe_card.dart';
import 'timer_dialog.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Rafraîchit l'indicateur vert/rouge toutes les 5 s sans attendre Firebase.
  Timer? _freshnessTimer;

  @override
  void initState() {
    super.initState();
    context.read<PompeService>().ecouterTout();
    _freshnessTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _freshnessTimer?.cancel();
    super.dispose();
  }

  /// Données fraîches si reçues il y a moins de 15 secondes.
  bool _estFraiche(DateTime? lastUpdate) {
    if (lastUpdate == null) return false;
    return DateTime.now().difference(lastUpdate).inSeconds < 15;
  }

  @override
  Widget build(BuildContext context) {
    final pompe         = context.watch<PompeService>();
    final mesures       = pompe.mesures;
    final alarme        = pompe.alarme;
    final gps           = pompe.gps;
    final bool enMarche     = pompe.enMarche;
    final bool alarmeActive = alarme['active'] ?? false;
    final bool fraiche      = _estFraiche(pompe.lastUpdate);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F7F4),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            tooltip: 'Paramètres',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF17231F),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => context.go('/parametres'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ),
        title: const Text('Tableau de Bord',
            style: TextStyle(color: Color(0xFF17231F), fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Stack(children: [
              IconButton(
                tooltip: 'Alarmes',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF17231F),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => context.go('/alarmes'),
              ),
              if (alarmeActive)
                Positioned(
                  right: 8, top: 8,
                  child: Container(
                    width: 12, height: 12,
                    decoration: const BoxDecoration(color: Color(0xFFE53935), shape: BoxShape.circle),
                    child: const Center(child: Text('!', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold))),
                  ),
                ),
            ]),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => context.read<PompeService>().ecouterTout(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // --- Bannière état pompe ---
            _banniereEtat(enMarche, alarmeActive, alarme),
            const SizedBox(height: 16),

            // --- Contrôles pompe ---
            EtatPompeCard(
              etat: EtatPompe(
                enMarche:          enMarche,
                frequence:         pompe.frequence,
                timerActif:        pompe.etat['timer_actif'] ?? false,
                timerResteMinutes: pompe.timerResteMinutes,         // getter sûr (num→int)
                timerMode:         pompe.etat['timer_mode']?.toString() ?? 'NONE',
                timestamp:         pompe.etat['timestamp']?.toString() ?? '',
              ),
              onMarche:          () => pompe.demarrer(),
              onArret:           () => pompe.arreter(),
              onFrequenceChange: (val) => pompe.setFrequence(val),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => showTimerDialog(context),
                icon: const Icon(Icons.timer_outlined),
                label: const Text('Minuterie'),
              ),
            ),
            const SizedBox(height: 8),

            // --- Titre + badge fraîcheur ---
            Row(children: [
              _titreSection('Sorties Variateur'),
              const Spacer(),
              _badgeFraicheur(fraiche, pompe.lastUpdate),
            ]),
            const SizedBox(height: 8),

            // --- 4 cartes mesures sortie ---
            GridView.count(
              crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12,
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.35,
              children: [
                _carteMesure('Tension',   _fmt(mesures['sortie_tension']),   'V',  Icons.bolt,       const Color(0xFFFFA726), fraiche),
                _carteMesure('Courant',   _fmt(mesures['sortie_courant']),   'A',  Icons.show_chart, const Color(0xFF26C6DA), fraiche),
                _carteMesure('Fréquence', _fmt(mesures['sortie_frequence']), 'Hz', Icons.waves,      const Color(0xFF42A5F5), fraiche),
                _carteMesure('Puissance', _fmt(mesures['sortie_puissance']), 'kW', Icons.speed,      const Color(0xFFEF5350), fraiche),
              ],
            ),
            const SizedBox(height: 16),

            // --- Entrée panneaux ---
            _titreSection('Entrée Panneaux Solaires'),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _carteMesure('Tension DC', _fmt(mesures['tension_panneaux']), 'V',  Icons.solar_power, const Color(0xFFFFA726), fraiche)),
              const SizedBox(width: 12),
              Expanded(child: _carteMesure('Puissance',  _fmt(mesures['entree_puissance']), 'kW', Icons.power,       const Color(0xFF66BB6A), fraiche)),
            ]),
            const SizedBox(height: 16),

            // --- GPS ---
            _titreSection('Localisation GPS'),
            const SizedBox(height: 8),
            _carteGPS(gps),
            const SizedBox(height: 12),

            // --- Opérateur SIM ---
            _carteOperateur(gps),
            const SizedBox(height: 8),

            // --- Timestamp ESP32 ---
            Center(
              child: Text(
                mesures['timestamp'] != null
                    ? 'ESP32 : ${mesures["timestamp"]}'
                    : pompe.lastUpdate == null
                        ? 'En attente de données Firebase…'
                        : 'Aucune donnée ESP32',
                style: TextStyle(
                    fontSize: 11,
                    color: fraiche ? const Color(0xFF1D9E75) : Colors.grey),
              ),
            ),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  String _fmt(dynamic val) {
    if (val == null) return '--';
    if (val is double) return val.toStringAsFixed(1);
    if (val is int)    return val.toDouble().toStringAsFixed(1);
    return val.toString();
  }

  Widget _titreSection(String texte) => Padding(
    padding: const EdgeInsets.only(left: 2),
    child: Text(texte,
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF17231F))),
  );

  /// Pastille verte (< 15 s) ou rouge (stale / hors ligne).
  Widget _badgeFraicheur(bool fraiche, DateTime? lastUpdate) {
    final couleur = fraiche ? const Color(0xFF1D9E75) : Colors.red.shade400;
    final label   = fraiche ? 'En direct' : lastUpdate == null ? 'Hors ligne' : 'Données stales';
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8,
          decoration: BoxDecoration(color: couleur, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text(label,
          style: TextStyle(fontSize: 11, color: couleur, fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _banniereEtat(bool enMarche, bool alarmeActive, Map alarme) {
    final couleur = alarmeActive ? const Color(0xFFE53935)
        : enMarche ? const Color(0xFF1D9E75) : const Color(0xFF647067);
    final couleurSec = alarmeActive ? const Color(0xFFFF7043)
        : enMarche ? const Color(0xFF0B6B52) : const Color(0xFF3D4741);
    final icone = alarmeActive ? Icons.warning_rounded
        : enMarche ? Icons.check_circle : Icons.stop_circle_outlined;
    final titre = alarmeActive ? (alarme['code'] ?? 'ALARME')
        : enMarche ? 'NORMAL' : 'ARRÊT';
    final sous = alarmeActive ? (alarme['description'] ?? 'Défaut détecté')
        : enMarche ? 'Fonctionnement normal de la pompe' : 'La pompe est à l\'arrêt';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [couleur, couleurSec],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: couleur.withOpacity(0.22), blurRadius: 18, offset: const Offset(0, 10))],
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('État de la Pompe',
              style: TextStyle(color: Colors.white.withOpacity(0.86), fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(titre, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(sous, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
        ])),
        Container(
          width: 58, height: 58,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), shape: BoxShape.circle),
          child: Icon(icone, color: Colors.white, size: 32),
        ),
      ]),
    );
  }

  Widget _carteMesure(
      String titre, String valeur, String unite, IconData icone, Color couleur, bool fraiche) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5ECE8)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: couleur.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icone, color: couleur, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(titre, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w700)),
          ),
          // Point de fraîcheur : gris si '--', vert si récent, rouge si stale
          Container(
            width: 7, height: 7,
            decoration: BoxDecoration(
              color: valeur == '--'
                  ? Colors.grey.shade300
                  : fraiche ? const Color(0xFF1D9E75) : Colors.red.shade400,
              shape: BoxShape.circle,
            ),
          ),
        ]),
        const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Flexible(
            child: Text(valeur, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: Color(0xFF17231F))),
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(unite,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          ),
        ]),
      ]),
    );
  }

  Widget _carteGPS(Map gps) {
    final lat    = (gps['latitude']  ?? 0.0).toDouble();
    final lng    = (gps['longitude'] ?? 0.0).toDouble();
    final valide = gps['valide'] ?? false;
    final lien   = gps['google_maps'] ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5ECE8)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(valide ? 'Latitude :  ${lat.toStringAsFixed(4)}° N' : 'GPS non disponible',
                style: const TextStyle(fontSize: 13, color: Color(0xFF17231F), fontWeight: FontWeight.w600)),
            if (valide) ...[
              const SizedBox(height: 4),
              Text('Longitude : ${lng.toStringAsFixed(4)}° E',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF17231F), fontWeight: FontWeight.w600)),
            ],
          ])),
          if (valide && lien.isNotEmpty)
            TextButton(
              onPressed: () => launchUrl(Uri.parse(lien), mode: LaunchMode.externalApplication),
              child: const Text('Voir sur la carte',
                  style: TextStyle(color: Color(0xFF1D9E75), fontWeight: FontWeight.w600)),
            ),
        ]),
        if (valide) ...[
          const SizedBox(height: 12),
          Container(
            height: 100, width: double.infinity,
            decoration: BoxDecoration(color: const Color(0xFFF0F5F2), borderRadius: BorderRadius.circular(12)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.location_on, color: Colors.red, size: 32),
              Text('${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _carteOperateur(Map gps) {
    final op   = gps['operateur']     ?? 'Inconnu';
    final gprs = gps['gprs_connecte'] ?? false;
    Color couleur = Colors.grey;
    if (op.contains('Ooredoo'))  couleur = const Color(0xFFE30613);
    else if (op.contains('Orange'))  couleur = const Color(0xFFFF6600);
    else if (op.contains('Telecom')) couleur = const Color(0xFF003DA5);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5ECE8)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Row(children: [
        Container(width: 40, height: 40,
            decoration: BoxDecoration(color: couleur.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.sim_card, color: couleur, size: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(op, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          Text(gprs ? 'GPRS connecté' : 'WiFi',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: gprs ? Colors.green.shade50 : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(20)),
          child: Text(gprs ? 'GPRS' : 'WiFi',
              style: TextStyle(fontSize: 11,
                  color: gprs ? Colors.green.shade700 : Colors.blue.shade700,
                  fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}
