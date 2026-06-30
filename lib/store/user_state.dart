// User-produced state models (logs/prefs/profile). JSON-serializable.

class SetLog {
  final String exerciseId;
  final int setIndex;
  double? weight;
  int? reps;
  bool done;

  SetLog({
    required this.exerciseId,
    required this.setIndex,
    this.weight,
    this.reps,
    this.done = false,
  });

  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'setIndex': setIndex,
        'weight': weight,
        'reps': reps,
        'done': done,
      };

  factory SetLog.fromJson(Map<String, dynamic> j) => SetLog(
        exerciseId: j['exerciseId'] as String,
        setIndex: (j['setIndex'] as num).toInt(),
        weight: (j['weight'] as num?)?.toDouble(),
        reps: (j['reps'] as num?)?.toInt(),
        done: j['done'] as bool? ?? false,
      );
}

class SessionLog {
  final String sessionId;
  final String date; // ISO datetime
  final List<SetLog> sets;
  String notes;
  final Map<String, String> substitutions; // exerciseId -> replacement
  String? completedAt; // null = in progress
  bool warmupDone; // échauffement effectué

  SessionLog({
    required this.sessionId,
    required this.date,
    required this.sets,
    this.notes = '',
    Map<String, String>? substitutions,
    this.completedAt,
    this.warmupDone = false,
  }) : substitutions = substitutions ?? {};

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'date': date,
        'sets': sets.map((s) => s.toJson()).toList(),
        'notes': notes,
        'substitutions': substitutions,
        'completedAt': completedAt,
        'warmupDone': warmupDone,
      };

  factory SessionLog.fromJson(Map<String, dynamic> j) => SessionLog(
        sessionId: j['sessionId'] as String,
        date: j['date'] as String,
        sets: ((j['sets'] as List?) ?? [])
            .map((e) => SetLog.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        notes: j['notes'] as String? ?? '',
        substitutions: ((j['substitutions'] as Map?) ?? {})
            .map((k, v) => MapEntry(k.toString(), v.toString())),
        completedAt: j['completedAt'] as String?,
        warmupDone: j['warmupDone'] as bool? ?? false,
      );
}

// Mesure corporelle horodatée (poids de corps en kg, tour de taille en cm).
class BodyMeasure {
  final String date; // ISO date "YYYY-MM-DD"
  final double weightKg;
  final double? waistCm;

  BodyMeasure({
    required this.date,
    required this.weightKg,
    this.waistCm,
  });

  Map<String, dynamic> toJson() => {
        'date': date,
        'weightKg': weightKg,
        'waistCm': waistCm,
      };

  factory BodyMeasure.fromJson(Map<String, dynamic> j) => BodyMeasure(
        date: j['date'] as String,
        weightKg: (j['weightKg'] as num).toDouble(),
        waistCm: (j['waistCm'] as num?)?.toDouble(),
      );
}

class Stats {
  final int sessionsCompleted;
  final int totalSets;
  final int totalVolume;
  final int streak;
  const Stats({
    required this.sessionsCompleted,
    required this.totalSets,
    required this.totalVolume,
    required this.streak,
  });
}
