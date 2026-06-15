class AlarmeModel {
  final bool active;
  final String code;
  final String description;
  final String cause;
  final String solution;
  final String timestamp;

  AlarmeModel({
    required this.active,
    required this.code,
    required this.description,
    required this.cause,
    required this.solution,
    required this.timestamp,
  });

  factory AlarmeModel.fromMap(Map<dynamic, dynamic> map) {
    return AlarmeModel(
      active:      map['active']      ?? false,
      code:        map['code']        ?? '',
      description: map['description'] ?? '',
      cause:       map['cause']       ?? '',
      solution:    map['solution']    ?? '',
      timestamp:   map['timestamp']   ?? '',
    );
  }
}
