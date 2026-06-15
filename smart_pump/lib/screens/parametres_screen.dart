import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/pompe_service.dart';

class ParametresScreen extends StatefulWidget {
  const ParametresScreen({super.key});
  @override
  State<ParametresScreen> createState() => _ParametresScreenState();
}

class _ParametresScreenState extends State<ParametresScreen> {
  bool   _notifs     = true;
  double _tensionMax = 250;
  double _courantMax = 5.0;
  double _freqMax    = 52.0;

  // ==================== COMMANDE LIBRE ====================
  final _codeCtrl   = TextEditingController();
  final _valeurCtrl = TextEditingController();
  String _statutCmd = '';

  // ==================== PARAMÈTRES RAPIDES (référence) ====================
  static const _paramsRef = [
    {'code': 'F00.02', 'desc': 'Mode fonctionnement',       'defaut': '0',    'plage': '0/1/3'},
    {'code': 'F00.11', 'desc': 'Fréquence maximale',        'defaut': '50',   'plage': '0~50 Hz'},
    {'code': 'F00.14', 'desc': 'Durée d\'accélération',     'defaut': '20',   'plage': '0.01~650 s'},
    {'code': 'F00.15', 'desc': 'Durée de décélération',     'defaut': '20',   'plage': '0.01~650 s'},
    {'code': 'F00.19', 'desc': 'Initialisation paramètres', 'defaut': '0',    'plage': '0/1/2/3'},
    {'code': 'F04.28', 'desc': 'Commande ventilateur',      'defaut': '1',    'plage': '0/1/2'},
    {'code': 'F05.00', 'desc': 'Type de moteur',            'defaut': '0',    'plage': '0/1'},
    {'code': 'F05.02', 'desc': 'Puissance nominale moteur', 'defaut': '18.5', 'plage': '0.1~1000 kW'},
    {'code': 'F05.03', 'desc': 'Fréquence nominale moteur', 'defaut': '-',    'plage': '0.1~fmax Hz'},
    {'code': 'F05.04', 'desc': 'Vitesse nominale moteur',   'defaut': '-',    'plage': '1~65000 tr/min'},
    {'code': 'F05.05', 'desc': 'Tension nominale moteur',   'defaut': '380',  'plage': '1~1500 V'},
    {'code': 'F05.06', 'desc': 'Courant nominal moteur',    'defaut': '37',   'plage': '0.1~3000 A'},
    {'code': 'F14.11', 'desc': 'Tension veille (sommeil)',  'defaut': '0',    'plage': '0~1000 V'},
    {'code': 'F14.12', 'desc': 'Tension réveil',            'defaut': '400',  'plage': '0~1000 V'},
    {'code': 'F14.14', 'desc': 'Fréquence minimale',        'defaut': '10',   'plage': '0~300 Hz'},
    {'code': 'F14.15', 'desc': 'Période détection basse vitesse','defaut':'10','plage': '0~3000 s'},
    {'code': 'F14.16', 'desc': 'Temps attente fréq. min',  'defaut': '10',   'plage': '0~3000 s'},
    {'code': 'F14.17', 'desc': 'Courant marche à sec',      'defaut': '0',    'plage': '0~999.9 A'},
    {'code': 'F14.18', 'desc': 'Durée détection marche sec','defaut': '10',   'plage': '0~3000 s'},
    {'code': 'F14.19', 'desc': 'Temps attente après marche sec','defaut':'10','plage': '0~3000 s'},
    {'code': 'F14.20', 'desc': 'Seuil surintensité',        'defaut': '0',    'plage': '0~999.9 A'},
    {'code': 'F14.23', 'desc': 'Puissance minimale',        'defaut': '0',    'plage': '0~kW'},
  ];

  // Historique des commandes envoyées
  final List<Map<String, String>> _historique = [];

  @override
  void dispose() {
    _codeCtrl.dispose();
    _valeurCtrl.dispose();
    super.dispose();
  }

  // ==================== ENVOYER COMMANDE LIBRE ====================
  void _envoyerCommande() {
    final code   = _codeCtrl.text.trim().toUpperCase();
    final valeur = _valeurCtrl.text.trim();

    // Validation
    if (code.isEmpty) {
      setState(() => _statutCmd = '❌ Entrez un code paramètre (ex: F14.16)');
      return;
    }
    if (valeur.isEmpty) {
      setState(() => _statutCmd = '❌ Entrez une valeur');
      return;
    }
    if (!RegExp(r'^F\d{2}\.\d{2,3}$').hasMatch(code)) {
      setState(() => _statutCmd = '❌ Format invalide. Exemple : F14.16');
      return;
    }
    final valInt = int.tryParse(valeur);
    if (valInt == null) {
      setState(() => _statutCmd = '❌ La valeur doit être un entier');
      return;
    }

    try {
      context.read<PompeService>().ecrireParametre(code, valInt);
      setState(() {
        _statutCmd = '✅ $code = $valeur envoyé';
        _historique.insert(0, {
          'code'  : code,
          'valeur': valeur,
          'heure' : _heureActuelle(),
        });
        // Garder max 10 dans l'historique
        if (_historique.length > 10) _historique.removeLast();
      });
      _codeCtrl.clear();
      _valeurCtrl.clear();
    } catch (e) {
      setState(() => _statutCmd = '❌ Erreur : $e');
    }
  }

  String _heureActuelle() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}:${now.second.toString().padLeft(2,'0')}';
  }

  // ==================== RÉINITIALISATION USINE ====================
  void _confirmerReset() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape  : RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title  : const Text('Confirmer la réinitialisation'),
        content: const Text(
          'Cela va restaurer les paramètres d\'usine du variateur (F00.19=1). Continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child    : const Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style    : ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              try {
                context.read<PompeService>().resetVariateur();
                setState(() => _statutCmd = '✅ Réinitialisation envoyée');
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content        : Text('Réinitialisation envoyée'),
                  backgroundColor: Colors.red,
                ));
              } catch (e) {
                setState(() => _statutCmd = '❌ Erreur : $e');
              }
            },
            child: const Text('Confirmer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ==================== DIALOG MODIFIER SEUIL ====================
  void _dialogSeuil(
      String label, double valeurActuelle, String unite,
      double min, double max, ValueChanged<double> onChange,
      ) {
    double temp = valeurActuelle;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape  : RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title  : Text(label),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(
              '${temp % 1 == 0 ? temp.toInt() : temp.toStringAsFixed(1)} $unite',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            Slider(
              value      : temp,
              min        : min,
              max        : max,
              divisions  : ((max - min) * 2).toInt(),
              activeColor: const Color(0xFF1D9E75),
              onChanged  : (v) => setD(() => temp = v),
            ),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child    : const Text('Annuler'),
            ),
            ElevatedButton(
              style    : ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1D9E75)),
              onPressed: () { onChange(temp); Navigator.pop(context); },
              child    : const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== DIALOG TABLEAU DE RÉFÉRENCE ====================
  void _afficherTableauReference() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color       : Color(0xFF1D9E75),
                borderRadius: BorderRadius.only(
                  topLeft : Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.table_chart, color: Colors.white),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Référence Paramètres VEICHI',
                      style: TextStyle(
                        color     : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize  : 15,
                      ),
                    ),
                  ),
                  IconButton(
                    icon    : const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // En-tête tableau
            Container(
              color  : const Color(0xFFF0F0F0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child  : const Row(children: [
                SizedBox(
                  width: 70,
                  child: Text('Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                Expanded(
                  child: Text('Fonction', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                SizedBox(
                  width: 50,
                  child: Text('Défaut', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center),
                ),
              ]),
            ),
            // Liste des paramètres
            SizedBox(
              height: 400,
              child : ListView.separated(
                itemCount      : _paramsRef.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder    : (context, i) {
                  final p = _paramsRef[i];
                  return InkWell(
                    onTap: () {
                      _codeCtrl.text = p['code']!;
                      Navigator.pop(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child  : Row(children: [
                        SizedBox(
                          width: 70,
                          child: Text(
                            p['code']!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize  : 12,
                              color     : Color(0xFF1D9E75),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p['desc']!,  style: const TextStyle(fontSize: 12)),
                              Text(p['plage']!, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 50,
                          child: Text(
                            p['defaut']!,
                            style   : const TextStyle(fontSize: 12, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ]),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child  : Text(
                'Appuyez sur un code pour le sélectionner',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation      : 0,
        leading        : const Icon(Icons.menu, color: Colors.black87),
        title          : const Text(
          'Parametres',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child  : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children          : [

            // ==================== PARAMÈTRES GÉNÉRAUX ====================
            _TitreSec('Parametres Generaux'),
            _Carte(children: [
              _LigneInfo(icone: Icons.memory,   couleur: Colors.blue, titre: 'Modèle variateur', valeur: 'VEICHI SI23-D5-018G'),
              _Divider(),
              _LigneInfo(icone: Icons.wifi,     couleur: Colors.teal, titre: 'Connexion',         valeur: 'Firebase RTDB'),
              _Divider(),
              _LigneInfo(icone: Icons.sim_card, couleur: Colors.grey, titre: 'Opérateur SIM',     valeur: 'TUNSIANA'),
            ]),
            const SizedBox(height: 16),

            // ==================== NOTIFICATIONS ====================
            _TitreSec('Notifications'),
            _Carte(children: [
              _LigneSwitch(
                icone    : Icons.notifications_outlined,
                couleur  : const Color(0xFF1D9E75),
                titre    : 'Notifications alarmes',
                valeur   : _notifs,
                onChanged: (v) => setState(() => _notifs = v),
              ),
            ]),
            const SizedBox(height: 16),

            // ==================== SEUILS D'ALARMES ====================
            _TitreSec('Seuils d\'Alarmes'),
            _Carte(children: [
              _LigneSeuil(
                icone  : Icons.bolt,       couleur: Colors.orange,
                titre  : 'Tension maximale',
                valeur : '${_tensionMax.toStringAsFixed(0)} V',
                onTap  : () => _dialogSeuil('Tension maximale', _tensionMax, 'V', 100, 300, (v) => setState(() => _tensionMax = v)),
              ),
              _Divider(),
              _LigneSeuil(
                icone  : Icons.show_chart, couleur: Colors.cyan,
                titre  : 'Courant maximal',
                valeur : '${_courantMax.toStringAsFixed(1)} A',
                onTap  : () => _dialogSeuil('Courant maximal', _courantMax, 'A', 1, 20, (v) => setState(() => _courantMax = v)),
              ),
              _Divider(),
              _LigneSeuil(
                icone  : Icons.waves,      couleur: Colors.blue,
                titre  : 'Fréquence maximale',
                valeur : '${_freqMax.toStringAsFixed(1)} Hz',
                onTap  : () => _dialogSeuil('Fréquence maximale', _freqMax, 'Hz', 40, 70, (v) => setState(() => _freqMax = v)),
              ),
            ]),
            const SizedBox(height: 16),

            // ==================== COMMANDE VARIATEUR ====================
            _TitreSec('Commande Variateur VEICHI'),
            Container(
              decoration: BoxDecoration(
                color       : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow   : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
              ),
              padding: const EdgeInsets.all(16),
              child  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children          : [

                  // ---- Description ----
                  Container(
                    padding    : const EdgeInsets.all(12),
                    decoration : BoxDecoration(
                      color       : const Color(0xFF1D9E75).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border      : Border.all(color: const Color(0xFF1D9E75).withOpacity(0.2)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.info_outline, color: Color(0xFF1D9E75), size: 16),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Entrez le code du paramètre et sa valeur.\nEx : F14.16 = 10',
                          style: TextStyle(fontSize: 12, color: Color(0xFF1D9E75)),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // ---- Champs de saisie ----
                  Row(children: [
                    // Champ Code
                    Expanded(
                      flex : 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children          : [
                          const Text(
                            'Code paramètre',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black54),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller   : _codeCtrl,
                            textCapitalization: TextCapitalization.characters,
                            style        : const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            decoration   : InputDecoration(
                              hintText     : 'F14.16',
                              hintStyle    : TextStyle(color: Colors.grey.shade400),
                              border       : OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide  : BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide  : const BorderSide(color: Color(0xFF1D9E75), width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              prefixIcon   : const Icon(Icons.code, color: Color(0xFF1D9E75), size: 18),
                              // Bouton tableau de référence
                              suffixIcon   : IconButton(
                                icon    : const Icon(Icons.list_alt, color: Color(0xFF1D9E75), size: 18),
                                tooltip : 'Voir tous les paramètres',
                                onPressed: _afficherTableauReference,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Champ Valeur
                    Expanded(
                      flex : 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children          : [
                          const Text(
                            'Valeur',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black54),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller  : _valeurCtrl,
                            keyboardType: TextInputType.number,
                            textAlign   : TextAlign.center,
                            style       : const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            decoration  : InputDecoration(
                              hintText     : '10',
                              hintStyle    : TextStyle(color: Colors.grey.shade400),
                              border       : OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide  : BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide  : const BorderSide(color: Color(0xFF1D9E75), width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),

                  // ---- Bouton Envoyer ----
                  SizedBox(
                    width : double.infinity,
                    height: 48,
                    child : ElevatedButton.icon(
                      style    : ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D9E75),
                        shape          : RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon     : const Icon(Icons.send, color: Colors.white, size: 18),
                      label    : const Text(
                        'Envoyer au variateur',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      onPressed: _envoyerCommande,
                    ),
                  ),

                  // ---- Statut ----
                  if (_statutCmd.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding   : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color       : _statutCmd.startsWith('✅')
                            ? const Color(0xFF1D9E75).withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _statutCmd,
                        style: TextStyle(
                          fontSize : 13,
                          color    : _statutCmd.startsWith('✅') ? const Color(0xFF1D9E75) : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],

                  // ---- Historique des commandes ----
                  if (_historique.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Historique',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    ..._historique.map((h) => Container(
                      margin    : const EdgeInsets.only(bottom: 6),
                      padding   : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color       : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(8),
                        border      : Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(children: [
                        const Icon(Icons.check_circle_outline, color: Color(0xFF1D9E75), size: 14),
                        const SizedBox(width: 8),
                        Text(
                          '${h['code']} = ${h['valeur']}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Text(
                          h['heure']!,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ]),
                    )),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ==================== AUTRES ====================
            _TitreSec('Autres'),
            _Carte(children: [
              ListTile(
                leading : CircleAvatar(
                  radius         : 16,
                  backgroundColor: Colors.orange.withOpacity(0.12),
                  child          : const Icon(Icons.restart_alt, color: Colors.orange, size: 18),
                ),
                title   : const Text('Réinitialiser le variateur', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                subtitle: const Text('Restaurer paramètres usine (F00.19=1)', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                onTap   : _confirmerReset,
              ),
              _Divider(),
              ListTile(
                leading : CircleAvatar(
                  radius         : 16,
                  backgroundColor: Colors.blue.withOpacity(0.12),
                  child          : const Icon(Icons.info_outline, color: Colors.blue, size: 18),
                ),
                title   : const Text('À propos', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                subtitle: const Text('Smart Pump Monitor v1.0', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                onTap   : () => showAboutDialog(
                  context            : context,
                  applicationName    : 'Smart Pump Monitor',
                  applicationVersion : 'v1.0',
                  applicationLegalese: 'Projet de fin d\'études',
                ),
              ),
            ]),
            const SizedBox(height: 16),

            // ==================== DÉCONNEXION ====================
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon : const Icon(Icons.logout, color: Colors.red),
                label: const Text('Se deconnecter', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  side   : const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape  : RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) context.go('/login');
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ==================== WIDGETS RÉUTILISABLES ====================

class _TitreSec extends StatelessWidget {
  final String t;
  const _TitreSec(this.t);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child  : Text(t, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
  );
}

class _Carte extends StatelessWidget {
  final List<Widget> children;
  const _Carte({required this.children});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color       : Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow   : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
    ),
    child: Column(children: children),
  );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Divider(height: 1, indent: 52);
}

class _LigneInfo extends StatelessWidget {
  final IconData icone;
  final Color    couleur;
  final String   titre;
  final String   valeur;
  const _LigneInfo({required this.icone, required this.couleur, required this.titre, required this.valeur});
  @override
  Widget build(BuildContext context) => ListTile(
    leading : CircleAvatar(radius: 16, backgroundColor: couleur.withOpacity(0.12), child: Icon(icone, color: couleur, size: 18)),
    title   : Text(titre, style: const TextStyle(fontSize: 14)),
    trailing: Text(valeur, style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w600)),
  );
}

class _LigneSeuil extends StatelessWidget {
  final IconData     icone;
  final Color        couleur;
  final String       titre;
  final String       valeur;
  final VoidCallback onTap;
  const _LigneSeuil({required this.icone, required this.couleur, required this.titre, required this.valeur, required this.onTap});
  @override
  Widget build(BuildContext context) => ListTile(
    leading : CircleAvatar(radius: 16, backgroundColor: couleur.withOpacity(0.12), child: Icon(icone, color: couleur, size: 18)),
    title   : Text(titre, style: const TextStyle(fontSize: 14)),
    trailing: Text(valeur, style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
    onTap   : onTap,
  );
}

class _LigneSwitch extends StatelessWidget {
  final IconData           icone;
  final Color              couleur;
  final String             titre;
  final bool               valeur;
  final ValueChanged<bool> onChanged;
  const _LigneSwitch({required this.icone, required this.couleur, required this.titre, required this.valeur, required this.onChanged});
  @override
  Widget build(BuildContext context) => ListTile(
    leading : CircleAvatar(radius: 16, backgroundColor: couleur.withOpacity(0.12), child: Icon(icone, color: couleur, size: 18)),
    title   : Text(titre, style: const TextStyle(fontSize: 14)),
    trailing: Switch(value: valeur, onChanged: onChanged, activeColor: const Color(0xFF1D9E75)),
  );
}