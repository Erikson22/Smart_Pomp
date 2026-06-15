import 'package:flutter/material.dart';
import '../models/etat.dart';

class EtatPompeCard extends StatelessWidget {
  final EtatPompe etat;
  final VoidCallback onMarche;
  final VoidCallback onArret;
  final Function(double) onFrequenceChange;

  // Plage alignée sur le firmware ESP32 (VEICHI SI23 : 0–300 Hz).
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
    // Protège contre une valeur Firebase hors bornes qui ferait planter le Slider.
    final double freqSafe = etat.frequence.clamp(_freqMin, _freqMax);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            ElevatedButton.icon(
              onPressed: onMarche,
              icon: const Icon(Icons.play_arrow),
              label: const Text('MARCHE'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
            ElevatedButton.icon(
              onPressed: onArret,
              icon: const Icon(Icons.stop),
              label: const Text('ARRET'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            const Text('Fréquence consigne : '),
            Expanded(
              child: Slider(
                min: _freqMin,
                max: _freqMax,
                divisions: 60, // pas de 5 Hz
                value: freqSafe,
                label: '${freqSafe.toStringAsFixed(0)} Hz',
                onChanged: onFrequenceChange,
              ),
            ),
            Text('${freqSafe.toStringAsFixed(1)} Hz'),
          ]),
          if (etat.timerActif)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.timer, color: Colors.orange),
                const SizedBox(width: 8),
                Text('Minuterie ${etat.timerMode} : ${etat.timerResteMinutes} min restantes'),
              ]),
            ),
          const SizedBox(height: 8),
          Text(
            'État : ${etat.enMarche ? "EN MARCHE" : "ARRÊT"}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ]),
      ),
    );
  }
}
