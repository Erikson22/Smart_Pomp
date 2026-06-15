import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/veichi_reference.dart';
import '../models/alarme.dart';
import '../services/pompe_service.dart';

class AlarmesScreen extends StatefulWidget {
  const AlarmesScreen({super.key});

  @override
  State<AlarmesScreen> createState() => _AlarmesScreenState();
}

class _AlarmesScreenState extends State<AlarmesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Alarmes'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Codes VEICHI'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ActiveAlarmTab(),
          _VeichiAlarmReferenceTab(),
        ],
      ),
    );
  }
}

class _ActiveAlarmTab extends StatelessWidget {
  const _ActiveAlarmTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Alarme>(
      stream: context.read<PompeService>().alarmeStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Erreur : ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final alarme = snapshot.data!;
        if (!alarme.active) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Color(0xFF1D9E75), size: 64),
                SizedBox(height: 16),
                Text('Aucune alarme active', style: TextStyle(fontSize: 18)),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _AlarmCard(
              code: alarme.code,
              label: alarme.description,
              cause: alarme.cause,
              solution: alarme.solution,
              timestamp: alarme.timestamp,
              color: const Color(0xFFE53935),
              icon: Icons.warning_rounded,
              initiallyOpen: true,
            ),
          ],
        );
      },
    );
  }
}

class _VeichiAlarmReferenceTab extends StatelessWidget {
  const _VeichiAlarmReferenceTab();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: veichiAlarms.length,
      itemBuilder: (context, index) {
        final ref = veichiAlarms[index];
        final isError = ref.type == 'erreur';
        return _AlarmCard(
          code: ref.code,
          label: ref.label,
          cause: ref.cause,
          solution: ref.solution,
          color: isError ? const Color(0xFFE53935) : const Color(0xFFFFA726),
          icon: isError ? Icons.error_outline : Icons.warning_amber_outlined,
        );
      },
    );
  }
}

class _AlarmCard extends StatefulWidget {
  final String code;
  final String label;
  final String cause;
  final String solution;
  final String? timestamp;
  final Color color;
  final IconData icon;
  final bool initiallyOpen;

  const _AlarmCard({
    required this.code,
    required this.label,
    required this.cause,
    required this.solution,
    required this.color,
    required this.icon,
    this.timestamp,
    this.initiallyOpen = false,
  });

  @override
  State<_AlarmCard> createState() => _AlarmCardState();
}

class _AlarmCardState extends State<_AlarmCard> {
  late bool _open = widget.initiallyOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: widget.color.withOpacity(0.12),
                    child: Icon(widget.icon, color: widget.color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.code.isEmpty ? 'ALARME' : widget.code,
                          style: TextStyle(
                            color: widget.color,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.label.isEmpty ? 'Defaut detecte' : widget.label,
                          style: const TextStyle(fontSize: 13),
                        ),
                        if (widget.timestamp?.isNotEmpty == true) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.timestamp!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    _open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          if (_open) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  _DetailRow(
                    icon: Icons.search,
                    title: 'Cause',
                    text: widget.cause.isEmpty
                        ? 'Cause non renseignee'
                        : widget.cause,
                    color: const Color(0xFFFFA726),
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.build,
                    title: 'Solution',
                    text: widget.solution.isEmpty
                        ? 'Verifier le variateur et les seuils configures'
                        : widget.solution,
                    color: const Color(0xFF1D9E75),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final Color color;

  const _DetailRow({
    required this.icon,
    required this.title,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(text, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}
