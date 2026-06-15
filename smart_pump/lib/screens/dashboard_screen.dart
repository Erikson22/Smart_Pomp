import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/pompe_service.dart';
import '../widgets/mesure_card.dart';
import '../widgets/etat_pompe_banner.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    final s = context.read<PompeService>();
    s.ecouterMesures();
    s.ecouterEtat();
    s.ecouterAlarmes();
    s.ecouterGPS();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Tableau de Bord', style: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.w600)),
        leading: const Icon(Icons.menu, color: Colors.black87),
        actions: [
          Consumer<PompeService>(builder: (context, service, _) {
            return Stack(children: [
              const Icon(Icons.notifications_outlined, color: Colors.black87, size: 28),
              if (service.alarmeCode != null)
                Positioned(right: 0, top: 0,
                  child: Container(width: 14, height: 14,
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: const Center(child: Text('!', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
                  ),
                ),
            ]);
          }),
          const SizedBox(width: 16),
        ],
      ),
      body: Consumer<PompeService>(builder: (context, service, _) {
        return RefreshIndicator(
          onRefresh: () async => service.ecouterMesures(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              EtatPompeBanner(enMarche: service.enMarche, alarmeCode: service.alarmeCode, alarmeDescription: service.alarmeDescription),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12,
                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), childAspectRatio: 1.4,
                children: [
                  MesureCard(titre: 'Tension',   valeur: service.mesures?.sortieTension.toStringAsFixed(0)   ?? '--', unite: 'V',  icone: Icons.bolt,     couleur: const Color(0xFFFFA726)),
                  MesureCard(titre: 'Courant',   valeur: service.mesures?.sortieCourant.toStringAsFixed(2)   ?? '--', unite: 'A',  icone: Icons.show_chart,couleur: const Color(0xFF26C6DA)),
                  MesureCard(titre: 'Frequence', valeur: service.mesures?.sortieFrequence.toStringAsFixed(1)  ?? '--', unite: 'Hz', icone: Icons.waves,    couleur: const Color(0xFF42A5F5)),
                  MesureCard(titre: 'Puissance', valeur: service.mesures != null ? (service.mesures!.sortiePuissance * 1000).toStringAsFixed(0) : '--', unite: 'W', icone: Icons.speed, couleur: const Color(0xFFEF5350)),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Entree Panneaux Solaires', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: MesureCard(titre: 'Tension DC', valeur: service.mesures?.tensionPanneaux.toStringAsFixed(0) ?? '--', unite: 'V', icone: Icons.solar_power, couleur: const Color(0xFFFFA726))),
                const SizedBox(width: 12),
                Expanded(child: MesureCard(titre: 'Puissance',  valeur: service.mesures != null ? (service.mesures!.entreePuissance * 1000).toStringAsFixed(0) : '--', unite: 'W', icone: Icons.power, couleur: const Color(0xFF66BB6A))),
              ]),
              const SizedBox(height: 16),
              const Text('Localisation GPS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
              const SizedBox(height: 8),
              _CarteGPS(service: service),
              const SizedBox(height: 12),
              _CarteOperateur(service: service),
              const SizedBox(height: 8),
              if (service.mesures?.timestamp != null)
                Center(child: Text('Mise a jour : ${service.mesures!.timestamp}', style: const TextStyle(fontSize: 11, color: Colors.grey))),
              const SizedBox(height: 20),
            ]),
          ),
        );
      }),
    );
  }
}

class _CarteGPS extends StatelessWidget {
  final PompeService service;
  const _CarteGPS({required this.service});
  @override
  Widget build(BuildContext context) {
    final lat    = service.gps?.latitude  ?? 0.0;
    final lng    = service.gps?.longitude ?? 0.0;
    final valide = service.gps?.valide    ?? false;
    final lien   = service.gps?.googleMaps ?? '';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(valide ? 'Latitude :  ${lat.toStringAsFixed(4)} N' : 'GPS non disponible',
              style: const TextStyle(fontSize: 13, color: Colors.black87)),
            if (valide) ...[
              const SizedBox(height: 4),
              Text('Longitude : ${lng.toStringAsFixed(4)} E', style: const TextStyle(fontSize: 13, color: Colors.black87)),
            ],
          ]),
          if (valide) TextButton(
            onPressed: () async {
              final uri = Uri.parse(lien);
              if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            child: const Text('Voir sur la carte', style: TextStyle(color: Color(0xFF1D9E75), fontWeight: FontWeight.w600)),
          ),
        ]),
        if (valide) ...[
          const SizedBox(height: 12),
          Container(
            height: 120, width: double.infinity,
            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.location_on, color: Colors.red, size: 32),
              const SizedBox(height: 4),
              Text('${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ]),
          ),
        ],
      ]),
    );
  }
}

class _CarteOperateur extends StatelessWidget {
  final PompeService service;
  const _CarteOperateur({required this.service});
  Color _couleur(String? op) {
    if (op == null) return Colors.grey;
    if (op.contains('Ooredoo')) return const Color(0xFFE30613);
    if (op.contains('Orange'))  return const Color(0xFFFF6600);
    if (op.contains('Telecom')) return const Color(0xFF003DA5);
    return Colors.grey;
  }
  @override
  Widget build(BuildContext context) {
    final op   = service.gps?.operateur    ?? 'Inconnu';
    final gprs = service.gps?.gprsConnecte ?? false;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
      child: Row(children: [
        Container(width: 40, height: 40,
          decoration: BoxDecoration(color: _couleur(op).withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(Icons.sim_card, color: _couleur(op), size: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(op,   style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          Text(gprs ? 'GPRS connecte' : 'WiFi', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: gprs ? Colors.green.shade50 : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(gprs ? 'GPRS' : 'WiFi',
            style: TextStyle(fontSize: 11, color: gprs ? Colors.green.shade700 : Colors.blue.shade700, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}
