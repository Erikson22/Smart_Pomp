class VeichiParameterRef {
  final String code;
  final String label;
  final String defaultValue;
  final String range;

  const VeichiParameterRef({
    required this.code,
    required this.label,
    required this.defaultValue,
    required this.range,
  });
}

class VeichiAlarmRef {
  final String code;
  final String label;
  final String type;
  final String cause;
  final String solution;

  const VeichiAlarmRef({
    required this.code,
    required this.label,
    required this.type,
    required this.cause,
    required this.solution,
  });
}

const veichiParameters = <VeichiParameterRef>[
  VeichiParameterRef(
    code: 'F00.02',
    label: 'Mode commande',
    defaultValue: '0',
    range: '0 / 1 / 3',
  ),
  VeichiParameterRef(
    code: 'F00.11',
    label: 'Frequence maximale',
    defaultValue: '50',
    range: '0 a 50 Hz',
  ),
  VeichiParameterRef(
    code: 'F00.14',
    label: 'Duree acceleration',
    defaultValue: '20',
    range: '0.01 a 650 s',
  ),
  VeichiParameterRef(
    code: 'F00.15',
    label: 'Duree deceleration',
    defaultValue: '20',
    range: '0.01 a 650 s',
  ),
  VeichiParameterRef(
    code: 'F00.19',
    label: 'Initialisation parametres',
    defaultValue: '0',
    range: '0 / 1 / 2 / 3',
  ),
  VeichiParameterRef(
    code: 'F05.02',
    label: 'Puissance nominale moteur',
    defaultValue: '18.5',
    range: '0.1 a 1000 kW',
  ),
  VeichiParameterRef(
    code: 'F05.05',
    label: 'Tension nominale moteur',
    defaultValue: '380',
    range: '1 a 1500 V',
  ),
  VeichiParameterRef(
    code: 'F05.06',
    label: 'Courant nominal moteur',
    defaultValue: '37',
    range: '0.1 a 3000 A',
  ),
  VeichiParameterRef(
    code: 'F14.11',
    label: 'Tension veille',
    defaultValue: '0',
    range: '0 a 1000 V',
  ),
  VeichiParameterRef(
    code: 'F14.12',
    label: 'Tension reveil',
    defaultValue: '400',
    range: '0 a 1000 V',
  ),
  VeichiParameterRef(
    code: 'F14.14',
    label: 'Frequence minimale',
    defaultValue: '10',
    range: '0 a 300 Hz',
  ),
  VeichiParameterRef(
    code: 'F14.17',
    label: 'Courant marche a sec',
    defaultValue: '0',
    range: '0 a 999.9 A',
  ),
  VeichiParameterRef(
    code: 'F14.20',
    label: 'Seuil surintensite',
    defaultValue: '0',
    range: '0 a 999.9 A',
  ),
  VeichiParameterRef(
    code: 'F14.23',
    label: 'Puissance minimale',
    defaultValue: '0',
    range: '0 a puissance moteur',
  ),
];

const veichiAlarms = <VeichiAlarmRef>[
  VeichiAlarmRef(
    code: 'E.LU2',
    label: 'Sous-tension en marche',
    type: 'erreur',
    cause: 'Tension alimentation trop faible ou bus DC insuffisant.',
    solution: 'Verifier la tension DC, les connexions panneaux et F14.11.',
  ),
  VeichiAlarmRef(
    code: 'E.OU1',
    label: 'Surtension a acceleration',
    type: 'erreur',
    cause: 'Fluctuation de tension ou acceleration trop rapide.',
    solution: 'Verifier la tension entree et augmenter F00.14 si besoin.',
  ),
  VeichiAlarmRef(
    code: 'E.OU2',
    label: 'Surtension en deceleration',
    type: 'erreur',
    cause: 'Deceleration trop courte ou charge entrainante.',
    solution: 'Augmenter F00.15 et verifier la charge hydraulique.',
  ),
  VeichiAlarmRef(
    code: 'E.OC1',
    label: 'Surintensite a acceleration',
    type: 'erreur',
    cause: 'Acceleration trop courte, surcharge ou cablage moteur anormal.',
    solution: 'Verifier moteur/cablage et augmenter F00.14.',
  ),
  VeichiAlarmRef(
    code: 'E.OL1',
    label: 'Surcharge moteur',
    type: 'erreur',
    cause: 'Couple ou courant moteur trop eleve.',
    solution: 'Verifier pompe, charge, courant nominal et parametres moteur.',
  ),
  VeichiAlarmRef(
    code: 'E.OH1',
    label: 'Surchauffe variateur',
    type: 'erreur',
    cause: 'Temperature elevee, ventilation ou canal air bloque.',
    solution: 'Nettoyer le variateur, verifier ventilateur et environnement.',
  ),
  VeichiAlarmRef(
    code: 'E.EEP',
    label: 'Defaut memoire',
    type: 'erreur',
    cause: 'EEPROM perturbee ou endommagee.',
    solution: 'Recharger les parametres ou contacter le support.',
  ),
  VeichiAlarmRef(
    code: 'A.LPn',
    label: 'Fonction sommeil',
    type: 'alarme',
    cause: 'Tension panneaux inferieure au seuil F14.11.',
    solution: 'Attendre meilleur ensoleillement ou ajuster F14.11/F14.12.',
  ),
  VeichiAlarmRef(
    code: 'A.LFr',
    label: 'Basse frequence',
    type: 'alarme',
    cause: 'Frequence sortie inferieure au seuil F14.14.',
    solution: 'Verifier ensoleillement, charge et seuil basse frequence.',
  ),
  VeichiAlarmRef(
    code: 'A.LuT',
    label: 'Marche a sec',
    type: 'alarme',
    cause: 'Courant sortie trop faible, pompe possiblement sans eau.',
    solution: 'Verifier niveau eau et ajuster F14.17/F14.19.',
  ),
  VeichiAlarmRef(
    code: 'A.OLd',
    label: 'Surintensite',
    type: 'alarme',
    cause: 'Courant sortie superieur au seuil F14.20.',
    solution: 'Verifier pompe, obstruction hydraulique et seuil F14.20.',
  ),
  VeichiAlarmRef(
    code: 'A.LPr',
    label: 'Puissance minimale',
    type: 'alarme',
    cause: 'Puissance sortie inferieure au seuil F14.23.',
    solution: 'Verifier ensoleillement, debit, pompe et seuil F14.23.',
  ),
];
