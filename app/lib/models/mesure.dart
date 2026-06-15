class Mesure {
  final double tensionPanneaux;
  final double tensionBusDc;
  final double sortieTension;
  final double sortieCourant;
  final double sortieFrequence;
  final double sortiePuissance;
  final double entreeCourant;
  final double entreePuissance;
  final String timestamp;

  Mesure({
    required this.tensionPanneaux,
    required this.tensionBusDc,
    required this.sortieTension,
    required this.sortieCourant,
    required this.sortieFrequence,
    required this.sortiePuissance,
    required this.entreeCourant,
    required this.entreePuissance,
    required this.timestamp,
  });

  factory Mesure.fromJson(Map<String, dynamic> json) {
    return Mesure(
      tensionPanneaux:  _d(json['tension_panneaux']),
      tensionBusDc:     _d(json['tension_bus_dc']),
      sortieTension:    _d(json['sortie_tension']),
      sortieCourant:    _d(json['sortie_courant']),
      sortieFrequence:  _d(json['sortie_frequence']),
      sortiePuissance:  _d(json['sortie_puissance']),
      entreeCourant:    _d(json['entree_courant']),
      entreePuissance:  _d(json['entree_puissance']),
      timestamp: json['timestamp']?.toString() ?? '',
    );
  }

  /// Convertit int / double / String en double sans exception.
  static double _d(dynamic v, [double fallback = 0.0]) {
    if (v == null)   return fallback;
    if (v is double) return v;
    if (v is int)    return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }
}
