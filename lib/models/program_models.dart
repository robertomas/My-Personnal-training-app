// Domain models for the 6-month training program.
// Static content — never stored in user state.

class Exercise {
  final String id;
  final String name;
  final int sets;
  final String reps;
  final int rest; // seconds; 0 = no rest (chained)
  final String notes;
  final bool star;
  final String? superset; // "SS1" | "SS2" | "SS3"
  final String? circuit; // "A" | "B" | "C" | "D"
  final bool isCardio;
  final bool isTime;

  const Exercise({
    required this.id,
    required this.name,
    required this.sets,
    required this.reps,
    required this.rest,
    required this.notes,
    this.star = false,
    this.superset,
    this.circuit,
    this.isCardio = false,
    this.isTime = false,
  });

  bool get isBodyweight => isCardio || isTime;
}

class Session {
  final String id; // e.g. "p2-UA"
  final String day; // "Lun" | "Mar" | "Jeu" | "Ven"
  final String code; // "UA" | "LA" | "UB" | "LB"
  final String title;
  final List<Exercise> exercises;

  const Session({
    required this.id,
    required this.day,
    required this.code,
    required this.title,
    required this.exercises,
  });
}

class Phase {
  final String id; // "p1" | "p2" | "p3"
  final int number; // 1 | 2 | 3
  final String months; // "M1-M2"
  final String title;
  final String subtitle;
  final String tagline;
  final String objective;
  final String intensity;
  final String cardio;
  final String coachNote;
  final String color; // "emerald" | "orange" | "violet"
  final List<Session> sessions;

  const Phase({
    required this.id,
    required this.number,
    required this.months,
    required this.title,
    required this.subtitle,
    required this.tagline,
    required this.objective,
    required this.intensity,
    required this.cardio,
    required this.coachNote,
    required this.color,
    required this.sessions,
  });

  Session? sessionForCode(String dayCode) {
    for (final s in sessions) {
      if (s.code == dayCode) return s;
    }
    return null;
  }
}
