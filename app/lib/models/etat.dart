class EtatPompe {
  final bool enMarche;
  final double frequence;
  final bool timerActif;
  final int timerResteMinutes;
  final String timerMode;
  final String timestamp;

  EtatPompe({
    required this.enMarche,
    required this.frequence,
    required this.timerActif,
    required this.timerResteMinutes,
    required this.timerMode,
    required this.timestamp,
  });

  factory EtatPompe.fromJson(Map<String, dynamic> json) {
    return EtatPompe(
      enMarche:           json['en_marche'] == true,
      frequence:          _d(json['frequence']),
      timerActif:         json['timer_actif'] == true,
      timerResteMinutes:  _i(json['timer_reste_minutes']),
      timerMode:          json['timer_mode']?.toString() ?? 'NONE',
      timestamp:          json['timestamp']?.toString() ?? '',
    );
  }

  static double _d(dynamic v, [double fallback = 0.0]) {
    if (v == null)   return fallback;
    if (v is double) return v;
    if (v is int)    return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }

  static int _i(dynamic v, [int fallback = 0]) {
    if (v == null)   return fallback;
    if (v is int)    return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }
}
