// Échauffements spécifiques par type de séance (Upper / Lower).
// Pensés pour un athlète de 49 ans : mobilité articulaire + activation
// progressive, ~5-7 min, sans matériel (ou poids très légers).

class WarmupMove {
  final String name;
  final String detail; // durée / reps / consigne
  final String why; // pourquoi ce mouvement (coach)

  const WarmupMove({
    required this.name,
    required this.detail,
    required this.why,
  });
}

class WarmupRoutine {
  final String title;
  final String subtitle;
  final String coachNote;
  final int estMinutes;
  final List<WarmupMove> moves;

  const WarmupRoutine({
    required this.title,
    required this.subtitle,
    required this.coachNote,
    required this.estMinutes,
    required this.moves,
  });
}

// ===== UPPER (UA / UB) : épaules, dos, coudes, poignets =====
const WarmupRoutine _upperWarmup = WarmupRoutine(
  title: 'Échauffement Haut du corps',
  subtitle: 'Épaules · dos · coudes',
  estMinutes: 6,
  coachNote:
      "À 49 ans, l'épaule c'est l'articulation la plus fragile en haut. "
      "Ces 6 minutes valent mieux que 6 mois de tendinite. Va doucement, "
      "amplitude complète, sans forcer.",
  moves: [
    WarmupMove(
      name: 'Cardio léger (rameur ou marche)',
      detail: '2 min · allure tranquille',
      why: 'Monte la température du corps et le rythme cardiaque.',
    ),
    WarmupMove(
      name: 'Cercles de bras',
      detail: '10 avant + 10 arrière',
      why: 'Réveille les épaules en douceur, lubrifie l\'articulation.',
    ),
    WarmupMove(
      name: 'Rotations des épaules',
      detail: '10 vers l\'arrière',
      why: 'Active les trapèzes et décolle les épaules des oreilles.',
    ),
    WarmupMove(
      name: 'Band pull-apart (ou bras tendus)',
      detail: '2 × 15',
      why: 'Active l\'arrière d\'épaule et le haut du dos — clé pour la posture.',
    ),
    WarmupMove(
      name: 'Rotation externe épaule (élastique léger)',
      detail: '2 × 12 par bras',
      why: 'Prépare la coiffe des rotateurs, prévient la blessure au développé.',
    ),
    WarmupMove(
      name: 'Cercles de poignets + extension coudes',
      detail: '30 s',
      why: 'Poignets et coudes encaissent les charges : on les réveille.',
    ),
    WarmupMove(
      name: 'Série d\'approche (1er exercice à vide/léger)',
      detail: '1 × 12 très léger',
      why: 'Répète le 1er mouvement de la séance à charge minime.',
    ),
  ],
);

// ===== LOWER (LA / LB) : hanches, genoux, chevilles, lombaires =====
const WarmupRoutine _lowerWarmup = WarmupRoutine(
  title: 'Échauffement Bas du corps',
  subtitle: 'Hanches · genoux · chevilles',
  estMinutes: 7,
  coachNote:
      "Le bas du corps porte des charges lourdes. Genoux et bas du dos "
      "doivent être chauds AVANT la première série. Ne saute jamais ça : "
      "c'est ton assurance anti-blessure.",
  moves: [
    WarmupMove(
      name: 'Cardio léger (vélo ou marche)',
      detail: '2-3 min · allure tranquille',
      why: 'Augmente le flux sanguin dans les jambes.',
    ),
    WarmupMove(
      name: 'Balancements de jambe (avant/arrière)',
      detail: '10 par jambe',
      why: 'Ouvre les hanches dynamiquement.',
    ),
    WarmupMove(
      name: 'Balancements de jambe (latéraux)',
      detail: '10 par jambe',
      why: 'Mobilise les adducteurs et les hanches sur le côté.',
    ),
    WarmupMove(
      name: 'Squats au poids de corps',
      detail: '2 × 12 · amplitude complète',
      why: 'Réveille quadris/fessiers et chauffe les genoux progressivement.',
    ),
    WarmupMove(
      name: 'Fentes dynamiques',
      detail: '8 par jambe',
      why: 'Active les fessiers et étire les fléchisseurs de hanche.',
    ),
    WarmupMove(
      name: 'Mobilité cheville (genou au mur)',
      detail: '10 par cheville',
      why: 'Une cheville raide = un squat dangereux. On la débloque.',
    ),
    WarmupMove(
      name: 'Série d\'approche (1er exercice léger)',
      detail: '1 × 12 charge minime',
      why: 'Répète le 1er mouvement de la séance avant de charger.',
    ),
  ],
);

/// Retourne l'échauffement adapté au code de séance (UA/UB = haut, LA/LB = bas).
WarmupRoutine warmupForCode(String code) {
  final c = code.toUpperCase();
  if (c.startsWith('U')) return _upperWarmup;
  if (c.startsWith('L')) return _lowerWarmup;
  return _upperWarmup; // fallback
}
