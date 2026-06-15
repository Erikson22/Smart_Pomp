class MesuresModel {
  final double tensionPanneaux;
  final double tensionBusDC;
  final double sortieTension;
  final double sortieCourant;
  final double sortieFrequence;
  final double sortiePuissance;
  final double entreeCourant;
  final double entreePuissance;
  final String timestamp;

  MesuresModel({
    required this.tensionPanneaux,
    required this.tensionBusDC,
    required this.sortieTension,
    required this.sortieCourant,
    required this.sortieFrequence,
    required this.sortiePuissance,
    required this.entreeCourant,
    required this.entreePuissance,
    required this.timestamp,
  });

  factory MesuresModel.fromMap(Map<dynamic, dynamic> map) {
    return MesuresModel(
      tensionPanneaux: (map['tension_panneaux'] ?? 0).toDouble(),
      tensionBusDC:    (map['tension_bus_dc']   ?? 0).toDouble(),
      sortieTension:   (map['sortie_tension']   ?? 0).toDouble(),
      sortieCourant:   (map['sortie_courant']   ?? 0).toDouble(),
      sortieFrequence: (map['sortie_frequence'] ?? 0).toDouble(),
      sortiePuissance: (map['sortie_puissance'] ?? 0).toDouble(),
      entreeCourant:   (map['entree_courant']   ?? 0).toDouble(),
      entreePuissance: (map['entree_puissance'] ?? 0).toDouble(),
      timestamp:        map['timestamp'] ?? '',
    );
  }
}
