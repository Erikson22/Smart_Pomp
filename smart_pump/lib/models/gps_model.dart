class GpsModel {
  final double latitude;
  final double longitude;
  final bool valide;
  final String googleMaps;
  final String operateur;
  final bool gprsConnecte;
  final String timestamp;

  GpsModel({
    required this.latitude,
    required this.longitude,
    required this.valide,
    required this.googleMaps,
    required this.operateur,
    required this.gprsConnecte,
    required this.timestamp,
  });

  factory GpsModel.fromMap(Map<dynamic, dynamic> map) {
    return GpsModel(
      latitude:     (map['latitude']     ?? 0.0).toDouble(),
      longitude:    (map['longitude']    ?? 0.0).toDouble(),
      valide:        map['valide']        ?? false,
      googleMaps:    map['google_maps']   ?? '',
      operateur:     map['operateur']     ?? 'Inconnu',
      gprsConnecte:  map['gprs_connecte'] ?? false,
      timestamp:     map['timestamp']     ?? '',
    );
  }
}
