import 'package:flutter/material.dart';
import '../models/alarme_model.dart';

class AlarmeTile extends StatelessWidget {
  final AlarmeModel alarme;
  const AlarmeTile({super.key, required this.alarme});

  Color get _couleur {
    if (alarme.code.startsWith('E.')) return Colors.red;
    if (alarme.code.startsWith('A.')) return Colors.orange;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: _couleur, child: const Icon(Icons.warning, color: Colors.white, size: 20)),
        title: Text(alarme.description, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(alarme.code, style: TextStyle(color: _couleur, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(alarme.code),
            content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Description : ${alarme.description}'),
              const SizedBox(height: 8),
              Text('Cause : ${alarme.cause}'),
              const SizedBox(height: 8),
              Text('Solution : ${alarme.solution}'),
            ]),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer'))],
          ),
        ),
      ),
    );
  }
}
