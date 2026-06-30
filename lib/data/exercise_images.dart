// Registre des illustrations de démonstration d'exercices.
// Associe un id d'exercice (de program.dart) à une image dans assets/exercises/.
//
// Toutes les variantes du même mouvement (phases 1/2/3) pointent vers la même
// image. Seuls les exercices "moins évidents" ont une illustration ; les autres
// retombent sur le bouton YouTube (voir utils/demo.dart).

const Map<String, String> _exerciseImageById = {
  // Reverse Fly haltères (ex face-pull / reverse-fly toutes phases)
  'reverse-fly': 'assets/exercises/reverse_fly.png',
  'reverse-fly-2': 'assets/exercises/reverse_fly.png',
  'reverse-fly-3': 'assets/exercises/reverse_fly.png',
  'face-pull': 'assets/exercises/reverse_fly.png',
  'face-pull-2': 'assets/exercises/reverse_fly.png',
  'face-pull-3': 'assets/exercises/reverse_fly.png',
  'band-pull-apart': 'assets/exercises/reverse_fly.png',

  // Dead Bug
  'dead-bug': 'assets/exercises/dead_bug.png',
  'pallof': 'assets/exercises/dead_bug.png',
  'deadbug-pallof': 'assets/exercises/dead_bug.png',
  'pallof-deadbug': 'assets/exercises/dead_bug.png',

  // Russian Twist medicine ball — partagé avec les combos core
  // (deadbug-pallof et pallof-deadbug montrent déjà le dead bug ci-dessus ;
  //  on garde wood-chop pour le mouvement de rotation debout)

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
