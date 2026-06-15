import 'package:flutter/material.dart';

import '../models/etat.dart';

class EtatPompeCard extends StatelessWidget {
  final EtatPompe etat;
  final VoidCallback onMarche;
  final VoidCallback onArret;
  final Function(double) onFrequenceChange;

  static const double _freqMin = 0.0;
  static const double _freqMax = 300.0;

  const EtatPompeCard({
    super.key,
    required this.etat,
    required this.onMarche,
    required this.onArret,
    required this.onFrequenceChange,
  });

  @override
  Widget build(BuildContext context) {
    final double freqSafe = etat.frequence.clamp(_freqMin, _freqMax).toDouble();
    final statusColor =
        etat.enMarche ? const Color(0xFF1D9E75) : Colors.grey.shade700;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                etat.enMarche ? Icons.power_settings_new : Icons.power_off,
                color: statusColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text(
                  'Contrôle pompe',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  etat.enMarche ? 'EN MARCHE' : 'ARRÊT',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ]),
            ),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: onMarche,
                icon: const Icon(Icons.play_arrow),
                label: const Text('MARCHE'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: onArret,
                icon: const Icon(Icons.stop),
                label: const Text('ARRÊT'),
              ),
            ),
          ]),
          const SizedBox(height: 18),
          Row(children: [
            const Icon(Icons.speed, color: Color(0xFF1D9E75), size: 20),
            const SizedBox(width: 8),
            const Text(
              'Fréquence consigne',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            Text(
              '${freqSafe.toStringAsFixed(1)} Hz',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF17231F),
              ),
            ),
          ]),
          Slider(
            min: _freqMin,
            max: _freqMax,
            divisions: 60,
            value: freqSafe,
            label: '${freqSafe.toStringAsFixed(0)} Hz',
            onChanged: onFrequenceChange,
          ),
          if (etat.timerActif)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                const Icon(Icons.timer, color: Colors.orange, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Minuterie ${etat.timerMode} : ${etat.timerResteMinutes} min restantes',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ]),
            ),
        ]),
      ),
    );
  }
}
