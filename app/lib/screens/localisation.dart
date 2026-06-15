import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/gps_data.dart';
import '../services/pompe_service.dart';

class LocalisationScreen extends StatelessWidget {
  const LocalisationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Localisation de la pompe')),
      body: StreamBuilder<GPSData>(
        stream: context.read<PompeService>().gpsStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final gps = snapshot.data!;
          if (!gps.valide) {
            return const Center(child: Text('Position GPS non disponible'));
          }
          return Column(
            children: [
              // Carte occupe 3/4 de l'écran
              Expanded(
                flex: 3,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(gps.latitude, gps.longitude),
                    initialZoom: 15,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.smartpumpmonitor',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(gps.latitude, gps.longitude),
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.location_pin,
                              color: Colors.red, size: 40),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Panneau info : flex:1 ≈ 130–180 px selon l'appareil.
              // SingleChildScrollView évite tout overflow si l'espace est
              // plus petit que prévu (petit écran ou barre système haute).
              Expanded(
                flex: 1,
                child: Card(
                  margin: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow(Icons.sim_card, 'Opérateur', gps.operateur),
                        _infoRow(Icons.satellite, 'Satellites',
                            '${gps.satellites ?? 0}'),
                        _infoRow(
                          Icons.location_on,
                          'Coordonnées',
                          '${gps.latitude.toStringAsFixed(5)}°,'
                              ' ${gps.longitude.toStringAsFixed(5)}°',
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                                visualDensity: VisualDensity.compact),
                            onPressed: () async {
                              final uri = Uri.parse(gps.googleMaps);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri,
                                    mode: LaunchMode.externalApplication);
                              } else if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Impossible d\'ouvrir Google Maps')),
                                );
                              }
                            },
                            icon: const Icon(Icons.map, size: 16),
                            label: const Text('Ouvrir dans Google Maps'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Ligne d'info compacte (≈ 24 px de hauteur) pour remplacer ListTile (≈ 56 px).
  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text('$label : ',
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
