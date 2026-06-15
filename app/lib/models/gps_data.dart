class GPSData {
  final double latitude;
  final double longitude;
  final bool valide;
  final String operateur;
  final String googleMaps;
  final double? altitude;
  final double? vitesse;
  final int? satellites;
  final String timestamp;

  GPSData({
    required this.latitude,
    required this.longitude,
    required this.valide,
    required this.operateur,
    required this.googleMaps,
    this.altitude,
    this.vitesse,
    this.satellites,
    required this.timestamp,
  });

  factory GPSData.fromJson(Map<String, dynamic> json) {
    return GPSData(
      latitude:   _d(json['latitude']),
      longitude:  _d(json['longitude']),
      valide:     json['valide'] == true,
      operateur:  json['operateur']?.toString() ?? 'Inconnu',
      googleMaps: json['google_maps']?.toString() ?? '',
      altitude:   json['altitude'] != null ? _d(json['altitude']) : null,
      vitesse:    json['vitesse']  != null ? _d(json['vitesse'])  : null,
      satellites: json['satellites'] is int ? json['satellites'] as int : null,
      timestamp:  json['timestamp']?.toString() ?? '',
    );
  }

  static double _d(dynamic v, [double fallback = 0.0]) {
    if (v == null)   return fallback;
    if (v is double) return v;
    if (v is int)    return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }
}
