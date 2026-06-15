import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/veichi_reference.dart';
import '../services/pompe_service.dart';

class ParametresScreen extends StatefulWidget {
  const ParametresScreen({super.key});

  @override
  State<ParametresScreen> createState() => _ParametresScreenState();
}

class _ParametresScreenState extends State<ParametresScreen> {
  final _codeCtrl = TextEditingController();
  final _valeurCtrl = TextEditingController();
  final List<_HistoryItem> _history = [];

  Map<String, dynamic> seuils = {};
  bool loading = true;
  bool sending = false;
  String statut = '';

  final List<_ParamDef> parametres = const [
    _ParamDef('F14.11', 'Seuil veille', 0, 1000),
    _ParamDef('F14.12', 'Seuil reveil', 0, 1000),
    _ParamDef('F14.14', 'Frequence min', 0, 300),
    _ParamDef('F14.17', 'Courant marche a sec', 0, 100),
    _ParamDef('F14.20', 'Seuil surintensite', 0, 100),
    _ParamDef('F14.23', 'Puissance min', 0, 100),
    _ParamDef('F00.02', 'Mode commande', 0, 3),
  ];

  @override
  void initState() {
    super.initState();
    _loadSeuils();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _valeurCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSeuils() async {
    final data = await context.read<PompeService>().getSeuils();
    if (!mounted) return;
    setState(() {
      seuils = data;
      loading = false;
    });
  }

  int _valeurActuelle(_ParamDef p) {
    switch (p.code) {
      case 'F14.11':
        return _toInt(seuils['veille']);
      case 'F14.12':
        return _toInt(seuils['reveil']);
      case 'F14.14':
        return _toInt(seuils['basse_freq']);
      case 'F14.17':
        return _toInt(seuils['marche_sec']);
      case 'F14.20':
        return _toInt(seuils['surintensite']);
      case 'F14.23':
        return _toInt(seuils['puiss_min']);
      default:
        return 0;
    }
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Future<void> _envoyerLibre() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    final rawValue = _valeurCtrl.text.trim();

    if (!RegExp(r'^F\d{2}\.\d{2,3}$').hasMatch(code)) {
      setState(() => statut = 'Format invalide. Exemple : F14.16');
      return;
    }

    final value = int.tryParse(rawValue);
    if (value == null) {
      setState(() => statut = 'La valeur doit etre un entier');
      return;
    }

    await _send(
      () => context.read<PompeService>().setParametre(code, value),
      '$code = $value envoye',
      history: _HistoryItem(code, value.toString(), _now()),
    );
    _codeCtrl.clear();
    _valeurCtrl.clear();
  }

  Future<void> _send(
    Future<void> Function() action,
    String success, {
    _HistoryItem? history,
  }) async {
    if (sending) return;
    setState(() {
      sending = true;
      statut = '';
    });

    try {
      await action();
      if (!mounted) return;
      setState(() {
        statut = success;
        if (history != null) {
          _history.insert(0, history);
          if (_history.length > 10) _history.removeLast();
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => statut = 'Erreur : $e');
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  String _now() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Parametres variateur'),
        actions: [
          IconButton(
            tooltip: 'Reference VEICHI',
            onPressed: _showReference,
            icon: const Icon(Icons.table_chart_outlined),
          ),
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _loadSeuils,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionTitle('Seuils principaux'),
          _Card(
            child: Column(
              children: [
                for (int i = 0; i < parametres.length; i++) ...[
                  _ParamTile(
                    param: parametres[i],
                    value: _valeurActuelle(parametres[i]),
                    onTap: () => _editParam(parametres[i]),
                  ),
                  if (i != parametres.length - 1) const Divider(height: 1),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionTitle('Commande libre VEICHI'),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Envoyer un parametre precis au variateur. Exemple : F14.16 = 10.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: TextField(
                        controller: _codeCtrl,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: 'Code',
                          hintText: 'F14.16',
                          prefixIcon: const Icon(Icons.code),
                          suffixIcon: IconButton(
                            tooltip: 'Choisir dans la reference',
                            onPressed: _showReference,
                            icon: const Icon(Icons.list_alt),
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _valeurCtrl,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          labelText: 'Valeur',
                          hintText: '10',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: sending ? null : _envoyerLibre,
                    icon: sending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    label: const Text('Envoyer au variateur'),
                  ),
                ),
                if (statut.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    statut,
                    style: TextStyle(
                      color: statut.startsWith('Erreur') ||
                              statut.startsWith('Format') ||
                              statut.startsWith('La valeur')
                          ? Colors.red
                          : const Color(0xFF1D9E75),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_history.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionTitle('Historique local'),
            _Card(
              child: Column(
                children: [
                  for (final item in _history)
                    ListTile(
                      dense: true,
                      leading: const Icon(
                        Icons.check_circle_outline,
                        color: Color(0xFF1D9E75),
                      ),
                      title: Text('${item.code} = ${item.value}'),
                      trailing: Text(item.time),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          _SectionTitle('Maintenance'),
          _Card(
            child: ListTile(
              leading: const Icon(Icons.restart_alt, color: Colors.orange),
              title: const Text('Reset variateur'),
              subtitle: const Text('Envoyer RESET_VARIATEUR a Firebase'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _confirmReset,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _editParam(_ParamDef param) async {
    final currentValue = _valeurActuelle(param);
    final newValue = await showDialog<int>(
      context: context,
      builder: (ctx) {
        var temp = currentValue.clamp(param.min, param.max).toInt();
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            return AlertDialog(
              title: Text('${param.code} - ${param.label}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$temp ${param.unite}',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Slider(
                    min: param.min.toDouble(),
                    max: param.max.toDouble(),
                    divisions:
                        (param.max - param.min).clamp(1, 1000).toInt(),
                    value: temp.toDouble(),
                    onChanged: (val) =>
                        setDlgState(() => temp = val.toInt()),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, temp),
                  child: const Text('Appliquer'),
                ),
              ],
            );
          },
        );
      },
    );

    if (newValue == null || newValue == currentValue) return;

    await _send(
      () => context.read<PompeService>().setParametre(param.code, newValue),
      '${param.code} = $newValue envoye',
      history: _HistoryItem(param.code, newValue.toString(), _now()),
    );
    await _loadSeuils();
  }

  Future<void> _confirmReset() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer le reset'),
        content: const Text('Envoyer une commande reset au variateur ?'),
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
      await _send(
        () => context.read<PompeService>().resetVariateur(),
        'Reset variateur envoye',
      );
    }
  }

  void _showReference() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640, maxHeight: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: const Color(0xFF1D9E75),
                child: Row(
                  children: [
                    const Icon(Icons.table_chart, color: Colors.white),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Reference parametres VEICHI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: veichiParameters.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final ref = veichiParameters[index];
                    return ListTile(
                      leading: Text(
                        ref.code,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D9E75),
                        ),
                      ),
                      title: Text(ref.label),
                      subtitle: Text('Defaut ${ref.defaultValue} | ${ref.range}'),
                      onTap: () {
                        _codeCtrl.text = ref.code;
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParamTile extends StatelessWidget {
  final _ParamDef param;
  final int value;
  final VoidCallback onTap;

  const _ParamTile({
    required this.param,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('${param.code} - ${param.label}'),
      subtitle: Text('Valeur actuelle : $value ${param.unite}'),
      trailing: const Icon(Icons.edit),
      onTap: onTap,
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

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
        padding: const EdgeInsets.all(8),
        child: child,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _HistoryItem {
  final String code;
  final String value;
  final String time;

  const _HistoryItem(this.code, this.value, this.time);
}

class _ParamDef {
  final String code;
  final String label;
  final int min;
  final int max;

  const _ParamDef(this.code, this.label, this.min, this.max);

  String get unite {
    if (code == 'F14.11' || code == 'F14.12') return 'V';
    if (code == 'F14.14') return 'Hz';
    if (code == 'F14.17' || code == 'F14.20') return 'A';
    if (code == 'F14.23') return 'kW';
    return '';
  }
}
