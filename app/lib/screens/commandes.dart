import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/pompe_service.dart';

class CommandesScreen extends StatefulWidget {
  const CommandesScreen({super.key});

  @override
  State<CommandesScreen> createState() => _CommandesScreenState();
}

class _CommandesScreenState extends State<CommandesScreen> {
  static const double _freqMin = 0;
  static const double _freqMax = 300;

  double _frequence = 20;
  int _heures = 0;
  int _minutes = 30;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final pompe = context.read<PompeService>();
    pompe.ecouterTout();
    _frequence = pompe.frequence.clamp(_freqMin, _freqMax).toDouble();
  }

  Future<void> _run(
    Future<void> Function(PompeService pompe) action,
    String message,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action(context.read<PompeService>());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur commande : $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pompe = context.watch<PompeService>();
    final freqEtat = pompe.frequence.clamp(_freqMin, _freqMax).toDouble();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Commandes'),
        actions: [
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatusCard(
            enMarche: pompe.enMarche,
            frequence: freqEtat,
            timerActif: pompe.etat['timer_actif'] == true,
            timerMode: pompe.etat['timer_mode']?.toString() ?? 'NONE',
            timerReste: _intValue(pompe.etat['timer_reste_minutes']),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Commande manuelle',
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _run(
                              (p) => p.demarrer(),
                              'Commande MARCHE envoyee',
                            ),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Marche'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _busy
                        ? null
                        : () => _run(
                              (p) => p.arreter(),
                              'Commande ARRET envoyee',
                            ),
                    icon: const Icon(Icons.stop),
                    label: const Text('Arret'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Consigne frequence',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.speed, color: Color(0xFF1D9E75)),
                    const SizedBox(width: 8),
                    Text(
                      '${_frequence.toStringAsFixed(0)} Hz',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Actuel ${freqEtat.toStringAsFixed(1)} Hz',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
                Slider(
                  min: _freqMin,
                  max: _freqMax,
                  divisions: 60,
                  value: _frequence.clamp(_freqMin, _freqMax).toDouble(),
                  label: '${_frequence.toStringAsFixed(0)} Hz',
                  onChanged: _busy
                      ? null
                      : (value) => setState(() => _frequence = value),
                ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _run(
                              (p) => p.setFrequence(_frequence),
                              'Frequence envoyee',
                            ),
                    icon: const Icon(Icons.send),
                    label: const Text('Appliquer la frequence'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Minuterie',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _NumberPicker(
                        label: 'Heures',
                        value: _heures,
                        min: 0,
                        max: 23,
                        onChanged: (value) => setState(() => _heures = value),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _NumberPicker(
                        label: 'Minutes',
                        value: _minutes,
                        min: 0,
                        max: 59,
                        onChanged: (value) => setState(() => _minutes = value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _busy || (_heures + _minutes == 0)
                        ? null
                        : () => _run(
                              (p) => p.startTimerRun(_heures, _minutes),
                              'Minuterie marche envoyee',
                            ),
                    icon: const Icon(Icons.timer),
                    label: const Text('Marche puis arret'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _busy || (_heures + _minutes == 0)
                        ? null
                        : () => _run(
                              (p) => p.startTimerStop(_heures, _minutes),
                              'Minuterie arret envoyee',
                            ),
                    icon: const Icon(Icons.timer_off),
                    label: const Text('Arret temporaire'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _run(
                              (p) => p.annulerTimer(),
                              'Minuterie annulee',
                            ),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Annuler la minuterie'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Maintenance',
            child: FilledButton.tonalIcon(
              onPressed: _busy
                  ? null
                  : () => _confirmReset(context),
              icon: const Icon(Icons.restart_alt),
              label: const Text('Reset variateur'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset variateur'),
        content: const Text(
          'Envoyer une commande de reset au variateur ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _run((p) => p.resetVariateur(), 'Reset variateur envoye');
    }
  }

  int _intValue(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class _StatusCard extends StatelessWidget {
  final bool enMarche;
  final double frequence;
  final bool timerActif;
  final String timerMode;
  final int timerReste;

  const _StatusCard({
    required this.enMarche,
    required this.frequence,
    required this.timerActif,
    required this.timerMode,
    required this.timerReste,
  });

  @override
  Widget build(BuildContext context) {
    final color = enMarche ? const Color(0xFF1D9E75) : Colors.grey.shade700;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            enMarche ? Icons.check_circle : Icons.stop_circle_outlined,
            color: Colors.white,
            size: 38,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  enMarche ? 'Pompe en marche' : 'Pompe arretee',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timerActif
                      ? 'Timer $timerMode : $timerReste min restantes'
                      : 'Frequence ${frequence.toStringAsFixed(1)} Hz',
                  style: TextStyle(color: Colors.white.withOpacity(0.85)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _NumberPicker extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _NumberPicker({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: value <= min ? null : () => onChanged(value - 1),
            icon: const Icon(Icons.remove),
          ),
          Expanded(
            child: Text(
              value.toString().padLeft(2, '0'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            onPressed: value >= max ? null : () => onChanged(value + 1),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
