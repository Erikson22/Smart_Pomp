import 'package:flutter/material.dart';

class EtatPompeBanner extends StatelessWidget {
  final bool enMarche;
  final String? alarmeCode;
  final String? alarmeDescription;

  const EtatPompeBanner({super.key, required this.enMarche, this.alarmeCode, this.alarmeDescription});

  @override
  Widget build(BuildContext context) {
    final bool alarme = alarmeCode != null;
    final Color couleur = alarme ? const Color(0xFFE53935) : enMarche ? const Color(0xFF1D9E75) : const Color(0xFF757575);
    final IconData icone = alarme ? Icons.warning_rounded : enMarche ? Icons.check_circle : Icons.stop_circle_outlined;
    final String titre = alarme ? alarmeCode! : enMarche ? 'NORMAL' : 'ARRET';
    final String sousTitre = alarme ? (alarmeDescription ?? 'Alarme detectee') : enMarche ? 'Fonctionnement normal de la pompe' : 'La pompe est a l arret';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: couleur, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Etat de la Pompe', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
          const SizedBox(height: 4),
          Text(titre, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(sousTitre, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
        ])),
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
          child: Icon(icone, color: Colors.white, size: 30),
        ),
      ]),
    );
  }
}
