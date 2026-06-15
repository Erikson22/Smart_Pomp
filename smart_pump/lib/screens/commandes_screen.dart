import 'package:flutter/material.dart';

class CommandesScreen extends StatefulWidget {
  const CommandesScreen({super.key});

  @override
  State<CommandesScreen> createState() => _CommandesScreenState();
}

class _CommandesScreenState extends State<CommandesScreen> {
  bool timerEnabled = false;
  bool variatorRunning = false;

  TimeOfDay startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay stopTime = const TimeOfDay(hour: 17, minute: 0);

  Future<void> selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: startTime,
    );

    if (picked != null) {
      setState(() {
        startTime = picked;
      });
    }
  }

  Future<void> selectStopTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: stopTime,
    );

    if (picked != null) {
      setState(() {
        stopTime = picked;
      });
    }
  }

  String formatTime(TimeOfDay time) {
    return "${time.hour.toString().padLeft(2, '0')}:"
        "${time.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Commande Variateur"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "État du variateur",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              variatorRunning ? "🟢 Marche" : "🔴 Arrêt",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            const Text(
              "Commande manuelle",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        variatorRunning = true;
                      });
                    },
                    child: const Text("Marche"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        variatorRunning = false;
                      });
                    },
                    child: const Text("Arrêt"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Text(
              "Programmation Horaire",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            ListTile(
              title: const Text("Heure de démarrage"),
              subtitle: Text(formatTime(startTime)),
              trailing: const Icon(Icons.access_time),
              onTap: selectStartTime,
            ),
            ListTile(
              title: const Text("Heure d'arrêt"),
              subtitle: Text(formatTime(stopTime)),
              trailing: const Icon(Icons.access_time),
              onTap: selectStopTime,
            ),
            SwitchListTile(
              title: const Text("Activer la minuterie"),
              value: timerEnabled,
              onChanged: (value) {
                setState(() {
                  timerEnabled = value;
                });
              },
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Horaires enregistrés"),
                    ),
                  );
                },
                child: const Text("Enregistrer"),
              ),
            ),
            const SizedBox(height: 30),
            const Divider(),
            const Text(
              "Informations",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "État de la minuterie : ${timerEnabled ? "Activée" : "Désactivée"}",
            ),
            Text(
              "Prochain démarrage : ${formatTime(startTime)}",
            ),
            Text(
              "Prochain arrêt : ${formatTime(stopTime)}",
            ),
          ],
        ),
      ),
    );
  }
}