import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/pompe_service.dart';

class GraphiquesScreen extends StatefulWidget {
  const GraphiquesScreen({super.key});
  @override
  State<GraphiquesScreen> createState() => _GraphiquesScreenState();
}

class _GraphiquesScreenState extends State<GraphiquesScreen> {
  String _periode = '24 Heures';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Icon(Icons.menu, color: Colors.black87),
        title: const Text('Graphiques', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: DropdownButton<String>(
              value: _periode,
              underline: const SizedBox(),
              items: ['1 Heure', '6 Heures', '24 Heures', '7 Jours']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _periode = v!),
            ),
          ),
        ],
      ),
      body: Consumer<PompeService>(builder: (context, service, _) {
        final courant   = service.mesures?.sortieCourant   ?? 0;
        final tension   = service.mesures?.sortieTension   ?? 0;
        final frequence = service.mesures?.sortieFrequence ?? 0;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            _CarteGraphique(
              titre: 'Courant (A)',
              moyenne: 'Moyenne: ${courant.toStringAsFixed(2)} A',
              couleur: const Color(0xFF26C6DA),
              valeurActuelle: courant,
              min: 0, max: 6,
            ),
            const SizedBox(height: 16),
            _CarteGraphique(
              titre: 'Tension (V)',
              moyenne: 'Moyenne: ${tension.toStringAsFixed(0)} V',
              couleur: const Color(0xFF42A5F5),
              valeurActuelle: tension,
              min: 180, max: 260,
            ),
            const SizedBox(height: 16),
            _CarteGraphique(
              titre: 'Frequence (Hz)',
              moyenne: 'Moyenne: ${frequence.toStringAsFixed(1)} Hz',
              couleur: const Color(0xFF9C27B0),
              valeurActuelle: frequence,
              min: 48, max: 52,
            ),
          ]),
        );
      }),
    );
  }
}

class _CarteGraphique extends StatelessWidget {
  final String titre;
  final String moyenne;
  final Color couleur;
  final double valeurActuelle;
  final double min;
  final double max;

  const _CarteGraphique({
    required this.titre,
    required this.moyenne,
    required this.couleur,
    required this.valeurActuelle,
    required this.min,
    required this.max,
  });

  List<FlSpot> _genererPoints() {
    final List<FlSpot> points = [];
    double v = valeurActuelle == 0 ? (min + max) / 2 : valeurActuelle;
    for (int i = 0; i <= 24; i++) {
      final variation = (i % 3 == 0) ? 0.1 : -0.05;
      v = (v + variation).clamp(min, max);
      points.add(FlSpot(i.toDouble(), v));
    }
    return points;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(titre, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(moyenne, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: LineChart(LineChartData(
            minY: min, maxY: max,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36,
                getTitlesWidget: (v, _) => Text(v.toStringAsFixed(0), style: const TextStyle(fontSize: 10, color: Colors.grey)))),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 6,
                getTitlesWidget: (v, _) => Text('${v.toInt()}:00', style: const TextStyle(fontSize: 10, color: Colors.grey)))),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: _genererPoints(),
                isCurved: true,
                color: couleur,
                barWidth: 2,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: true, color: couleur.withOpacity(0.08)),
              ),
            ],
          )),
        ),
      ]),
    );
  }
}
