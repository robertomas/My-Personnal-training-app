// Registre des illustrations de démonstration d'exercices.
// Associe un id d'exercice (de program.dart) à une image dans assets/exercises/.
//
// Toutes les variantes du même mouvement (phases 1/2/3) pointent vers la même
// image. Seuls les exercices "moins évidents" ont une illustration ; les autres
// retombent sur le bouton YouTube (voir utils/demo.dart).

const Map<String, String> _exerciseImageById = {
  // Reverse Fly haltères — même mouvement = même image sur les 3 phases.
  // (face-pull* et reverse-fly* sont tous le "Reverse Fly haltères" après la
  //  réécriture sans câble ; band-pull-apart est devenu "Oiseau haltères".)
  'reverse-fly': 'assets/exercises/reverse_fly.png',
  'reverse-fly-2': 'assets/exercises/reverse_fly.png',
  'reverse-fly-3': 'assets/exercises/reverse_fly.png',
  'face-pull': 'assets/exercises/reverse_fly.png',
  'face-pull-2': 'assets/exercises/reverse_fly.png',
  'face-pull-3': 'assets/exercises/reverse_fly.png',
  // Oiseau assis sur banc -> image dédiée (assis, distincte du reverse fly debout)
  'band-pull-apart': 'assets/exercises/seated_rear_fly.png',

  // Dead Bug (mouvement seul)
  'dead-bug': 'assets/exercises/dead_bug.png',
  'pallof': 'assets/exercises/dead_bug.png',

  // Combos core qui incluent le Russian Twist -> on montre le Russian Twist
  'deadbug-pallof': 'assets/exercises/russian_twist.png',
  'pallof-deadbug': 'assets/exercises/russian_twist.png',

  // Wood Chop medicine ball
  'wood-chop': 'assets/exercises/wood_chop.png',
  'wood-chop-3': 'assets/exercises/wood_chop.png',

  // Bulgarian Split Squat
  'bulgarian': 'assets/exercises/bulgarian_split_squat.png',

  // Hip Thrust haltère
  'hip-thrust': 'assets/exercises/hip_thrust.png',
  'hip-thrust-2': 'assets/exercises/hip_thrust.png',
  'hip-thrust-3': 'assets/exercises/hip_thrust.png',

  // Romanian Deadlift haltères
  'rdl': 'assets/exercises/rdl.png',
  'rdl-2': 'assets/exercises/rdl.png',
  'rdl-3': 'assets/exercises/rdl.png',

  // Pull-over haltère
  'pullover': 'assets/exercises/pullover.png',

  // Bird Dog
  'bird-dog': 'assets/exercises/bird_dog.png',

  // Hollow Hold
  'hollow-hold': 'assets/exercises/hollow_hold.png',
  'hollow-hold-3': 'assets/exercises/hollow_hold.png',

  // Goblet Squat kettlebell
  'goblet-squat': 'assets/exercises/goblet_squat.png',
  'goblet-squat-2': 'assets/exercises/goblet_squat.png',
  'goblet-squat-3': 'assets/exercises/goblet_squat.png',

  // Glute Bridge swiss ball
  'glute-bridge-ball': 'assets/exercises/glute_bridge.png',
  'glute-bridge-3': 'assets/exercises/glute_bridge.png',
};

/// Retourne le chemin de l'illustration pour un id d'exercice, ou null.
String? exerciseImageFor(String exerciseId) => _exerciseImageById[exerciseId];
