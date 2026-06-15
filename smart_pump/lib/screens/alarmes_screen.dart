import 'package:flutter/material.dart';

class AlarmesScreen extends StatefulWidget {
  const AlarmesScreen({super.key});
  @override
  State<AlarmesScreen> createState() => _AlarmesScreenState();
}

class _AlarmesScreenState extends State<AlarmesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ==================== ALARMES ACTIVES ====================
  static const _alarmesActives = [
    {
      'code'  : 'E.OV',
      'desc'  : 'Surtension',
      'detail': '245 V detectes',
      'ts'    : '02/06/2024 10:30:15',
      'type'  : 'erreur',
    },
    {
      'code'  : 'E.OC',
      'desc'  : 'Surintensité',
      'detail': '5.2 A detectes',
      'ts'    : '02/06/2024 09:15:42',
      'type'  : 'erreur',
    },
    {
      'code'  : 'A.HF',
      'desc'  : 'Frequence elevee',
      'detail': '52.5 Hz detectes',
      'ts'    : '02/06/2024 08:22:10',
      'type'  : 'alarme',
    },
    {
      'code'  : 'I.RS',
      'desc'  : 'Pompe redeMarree',
      'detail': 'Redemarrage manuel',
      'ts'    : '02/06/2024 07:45:33',
      'type'  : 'info',
    },
    {
      'code'  : 'I.PM',
      'desc'  : 'Parametres modifies',
      'detail': 'Frequence reglee 45 Hz',
      'ts'    : '02/06/2024 07:30:00',
      'type'  : 'info',
    },
  ];

  // ==================== CODES VEICHI COMPLETS ====================
  static const _codesVeichi = [
    // ---- ERREURS ----
    {
      'code'    : 'E.LU2',
      'desc'    : 'Sous-tension en marche',
      'type'    : 'erreur',
      'cause'   : 'Tension d\'alimentation trop faible. Le contacteur principal DC ne se ferme pas.',
      'solution': 'Vérifier la tension d\'entrée et les connexions des panneaux solaires.',
    },
    {
      'code'    : 'E.oU1',
      'desc'    : 'Surtension à l\'accélération',
      'type'    : 'erreur',
      'cause'   : 'Fluctuation de la tension d\'alimentation au-delà de la limite.',
      'solution': 'Vérifier le réseau électrique. Augmenter F00.14.',
    },
    {
      'code'    : 'E.oU2',
      'desc'    : 'Surtension pendant la décélération',
      'type'    : 'erreur',
      'cause'   : 'Temps de décélération trop court. Charge trop lourde.',
      'solution': 'Prolonger le temps de décélération F00.15. Réduire la charge.',
    },
    {
      'code'    : 'E.oU3',
      'desc'    : 'Surtension à vitesse constante',
      'type'    : 'erreur',
      'cause'   : 'Tension d\'entrée trop élevée. Force externe entraîne le moteur.',
      'solution': 'Ajuster la tension à la plage normale. Installer une résistance de freinage.',
    },
    {
      'code'    : 'E.oC1',
      'desc'    : 'Surintensité à l\'accélération',
      'type'    : 'erreur',
      'cause'   : 'Temps d\'accélération trop court. Réglage V/F incorrect.',
      'solution': 'Prolonger le temps d\'accélération F00.14. Vérifier le câblage.',
    },
    {
      'code'    : 'E.oC2',
      'desc'    : 'Surintensité pendant la décélération',
      'type'    : 'erreur',
      'cause'   : 'Court-circuit de sortie. Temps d\'accélération trop court.',
      'solution': 'Éliminer les défauts externes. Effectuer le réglage automatique du moteur.',
    },
    {
      'code'    : 'E.oC3',
      'desc'    : 'Surintensité à vitesse constante',
      'type'    : 'erreur',
      'cause'   : 'Court-circuit de sortie. Charge soudaine ajoutée.',
      'solution': 'Éliminer les défauts externes. Retirer la charge supplémentaire.',
    },
    {
      'code'    : 'E.oL1',
      'desc'    : 'Surcharge moteur',
      'type'    : 'erreur',
      'cause'   : 'Couple trop élevé. Temps ACC/DEC trop courts.',
      'solution': 'Réduire le couple. Augmenter le temps ACC/DEC. Réinitialiser les paramètres moteur.',
    },
    {
      'code'    : 'E.oL2',
      'desc'    : 'Surcharge du variateur',
      'type'    : 'erreur',
      'cause'   : 'Charge trop importante. Tension réseau trop basse.',
      'solution': 'Vérifier la charge. Remplacer par un variateur de puissance supérieure.',
    },
    {
      'code'    : 'E.SC',
      'desc'    : 'Système anormal',
      'type'    : 'erreur',
      'cause'   : 'Décélération trop courte. Court-circuit de sortie. Dommages carte commande.',
      'solution': 'Prolonger le temps d\'accélération. Vérifier le câblage et la mise à la terre.',
    },
    {
      'code'    : 'E.oH1',
      'desc'    : 'Surchauffe du variateur',
      'type'    : 'erreur',
      'cause'   : 'Température trop élevée. Canal aérien bloqué. Ventilateur endommagé.',
      'solution': 'Nettoyer le canal d\'air. Vérifier et remplacer le ventilateur.',
    },
    {
      'code'    : 'E.oH2',
      'desc'    : 'Surchauffe du redresseur',
      'type'    : 'erreur',
      'cause'   : 'Température trop élevée. Canal d\'air bloqué.',
      'solution': 'Nettoyer le canal d\'air. Changer le ventilateur. Contacter l\'usine.',
    },
    {
      'code'    : 'E.EEP',
      'desc'    : 'Défaut de mémoire',
      'type'    : 'erreur',
      'cause'   : 'Perturbation électromagnétique en mémoire. EEPROM endommagé.',
      'solution': 'Reprendre le chargement et sauvegarder. Contacter l\'usine.',
    },
    {
      'code'    : 'E.ILF',
      'desc'    : 'Perte de phase d\'entrée',
      'type'    : 'erreur',
      'cause'   : 'Une des phases d\'entrée est ouverte.',
      'solution': 'Vérifier le câblage d\'alimentation triphasé.',
    },
    {
      'code'    : 'E.oLF',
      'desc'    : 'Perte de phase de sortie',
      'type'    : 'erreur',
      'cause'   : 'Une des phases de sortie est ouverte.',
      'solution': 'Vérifier la tension et le courant de sortie triphasés.',
    },
    {
      'code'    : 'E.HAL',
      'desc'    : 'Détection de courant de défaut',
      'type'    : 'erreur',
      'cause'   : 'Défaut de circuit. Déséquilibre de phase.',
      'solution': 'Solliciter l\'aide de l\'usine. Vérifier le moteur et le câblage.',
    },
    // ---- ALARMES ----
    {
      'code'    : 'A.LPn',
      'desc'    : 'Fonction Sommeil',
      'type'    : 'alarme',
      'cause'   : 'Tension panneaux inférieure au seuil F14.11.',
      'solution': 'Attendre meilleur ensoleillement. Le variateur reprend automatiquement quand tension remonte à F14.12.',
    },
    {
      'code'    : 'A.LFr',
      'desc'    : 'Basse fréquence',
      'type'    : 'alarme',
      'cause'   : 'Fréquence de sortie inférieure à F14.14.',
      'solution': 'Le variateur reprend automatiquement quand fréquence remonte à F14.16.',
    },
    {
      'code'    : 'A.LuT',
      'desc'    : 'Marche à sec',
      'type'    : 'alarme',
      'cause'   : 'Courant de sortie inférieur à F14.17. Pompe sans eau.',
      'solution': 'Vérifier le niveau d\'eau. Ajuster F14.17. Reprise automatique après délai F14.19.',
    },
    {
      'code'    : 'A.old',
      'desc'    : 'Surintensité',
      'type'    : 'alarme',
      'cause'   : 'Courant de sortie supérieur à F14.20.',
      'solution': 'Vérifier la pompe. Ajuster F14.20. Reprise automatique après délai F14.22.',
    },
    {
      'code'    : 'A.LPr',
      'desc'    : 'Puissance minimale',
      'type'    : 'alarme',
      'cause'   : 'Puissance de sortie inférieure à F14.23.',
      'solution': 'Vérifier l\'ensoleillement. Reprise automatique après délai F14.25.',
    },
  ];

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

  Color _couleur(String type) {
    if (type == 'erreur') return const Color(0xFFE53935);
    if (type == 'alarme') return const Color(0xFFFFA726);
    return const Color(0xFF42A5F5);
  }

  IconData _icone(String type) {
    if (type == 'erreur') return Icons.error_outline;
    if (type == 'alarme') return Icons.warning_amber_outlined;
    return Icons.info_outline;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Icon(Icons.menu, color: Colors.black87),
        title: const Text(
          'Alarmes',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF1D9E75),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF1D9E75),
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Codes VEICHI'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ongletActives(),
          _ongletCodesVeichi(),
        ],
      ),
    );
  }

  // ==================== ONGLET ACTIVES ====================
  Widget _ongletActives() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _alarmesActives.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final a = _alarmesActives[i];
        final c = _couleur(a['type']!);
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
              ),
            ],
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: c,
              child: Icon(_icone(a['type']!), color: Colors.white, size: 18),
            ),
            title: Text(
              a['desc']!,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a['detail']!,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Text(
                  a['ts']!,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          ),
        );
      },
    );
  }

  // ==================== ONGLET CODES VEICHI ====================
  Widget _ongletCodesVeichi() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _codesVeichi.length,
      itemBuilder: (context, i) {
        final code = _codesVeichi[i];
        return _CarteCodeVeichi(
          code    : code['code']!,
          desc    : code['desc']!,
          cause   : code['cause']!,
          solution: code['solution']!,
          couleur : _couleur(code['type']!),
          icone   : _icone(code['type']!),
        );
      },
    );
  }
}

// ==================== CARTE CODE VEICHI DÉPLIABLE ====================
class _CarteCodeVeichi extends StatefulWidget {
  final String   code;
  final String   desc;
  final String   cause;
  final String   solution;
  final Color    couleur;
  final IconData icone;

  const _CarteCodeVeichi({
    required this.code,
    required this.desc,
    required this.cause,
    required this.solution,
    required this.couleur,
    required this.icone,
  });

  @override
  State<_CarteCodeVeichi> createState() => _CarteCodeVeichiState();
}

class _CarteCodeVeichiState extends State<_CarteCodeVeichi> {
  bool _ouvert = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        children: [
          // ---- En-tête cliquable ----
          InkWell(
            onTap: () => setState(() => _ouvert = !_ouvert),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width : 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color : widget.couleur.withOpacity(0.12),
                      shape : BoxShape.circle,
                    ),
                    child: Icon(widget.icone, color: widget.couleur, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.code,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize  : 15,
                            color     : widget.couleur,
                          ),
                        ),
                        Text(
                          widget.desc,
                          style: const TextStyle(
                            fontSize: 13,
                            color   : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _ouvert
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),

          // ---- Détails dépliables ----
          if (_ouvert)
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF9F9F9),
                borderRadius: BorderRadius.only(
                  bottomLeft : Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Column(
                children: [
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  // Cause
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.search,
                          color: Color(0xFFFFA726),
                          size : 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Cause',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color     : Color(0xFFFFA726),
                                  fontSize  : 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.cause,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color   : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Solution
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.build,
                          color: Color(0xFF1D9E75),
                          size : 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Solution',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color     : Color(0xFF1D9E75),
                                  fontSize  : 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.solution,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color   : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}