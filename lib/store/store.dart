// === Store de l'app ===
// Architecture conçue pour migration vers Supabase plus tard.
// Surface publique identique au prototype JS — seule la couche
// read/write (SharedPreferences) change. ChangeNotifier pour Provider.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/program_models.dart';
import '../sync/sync_service.dart';
import 'user_state.dart';

class Store extends ChangeNotifier {
  static const _storageKey = 'roberto_training_v1';

  late SharedPreferences _prefs;

  // ---- Profile ----
  String? startDate; // ISO date "YYYY-MM-DD"
  double? bodyWeight;

  // ---- Prefs ----
  String theme = 'sport-dark'; // 'sport-dark' | 'clean'
  bool sound = true;
  bool vibration = true;
  String unit = 'kg'; // 'kg' | 'lbs' (display only — storage toujours en kg)

  // ---- Logs ----  key = `${sessionId}_${YYYY-MM-DD}`
  final Map<String, SessionLog> logs = {};

  // ---- Séances sautées (clé = sessionId_YYYY-MM-DD de la semaine courante) ----
  // Permet de "décaler / sauter" une journée sans la compléter.
  final Set<String> skipped = {};

  // ---- Mesures corporelles (poids/taille dans le temps) ----
  // Indexé par date ISO -> une mesure par jour (la dernière écrase).
  final Map<String, BodyMeasure> measures = {};

  // ---- Photos de machines (locales) ----
  // exerciseId -> nom de fichier (dans le dossier de l'app). Seul le nom est
  // stocké/synchronisé ; l'image reste sur l'appareil (même gym, photo 1×).
  final Map<String, String> machinePhotos = {};

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _read();
    _purgeStaleSkips();
    // Sync cloud (no-op si Supabase non configuré).
    await _hydrateFromCloud();
  }

  // ---------- Sync cloud ----------
  Timer? _pushDebounce;

  /// Appelé juste après une connexion réussie : fusionne avec le cloud.
  /// Si le cloud a des données (autre appareil), on les adopte ; sinon
  /// on pousse l'état local existant (première connexion).
  Future<void> onSignedIn() => _hydrateFromCloud();

  /// Tire l'état distant. Si présent et plus "riche" (plus de logs),
  /// on l'adopte. Sinon on pousse l'état local.
  Future<void> _hydrateFromCloud() async {
    if (!SyncService.instance.isEnabled) return;
    try {
      final remote = await SyncService.instance.pull();
      if (remote != null) {
        final remoteLogs = (remote['logs'] as Map?)?.length ?? 0;
        // Adopte le distant s'il contient au moins autant de logs que le local.
        if (remoteLogs >= logs.length) {
          _hydrate(remote);
          _prefs.setString(_storageKey, jsonEncode(_toJson()));
          notifyListeners();
          return;
        }
      }
      // Le local est plus à jour (ou cloud vide) -> on pousse.
      _schedulePush(immediate: true);
    } catch (e) {
      debugPrint('Store: cloud hydrate failed ($e)');
    }
  }

  /// Remplace l'état en mémoire à partir d'un JSON (cloud).
  void _hydrate(Map<String, dynamic> parsed) {
    final profile = (parsed['profile'] as Map?) ?? {};
    startDate = profile['startDate'] as String?;
    bodyWeight = (profile['bodyWeight'] as num?)?.toDouble();
    final p = (parsed['prefs'] as Map?) ?? {};
    theme = p['theme'] as String? ?? theme;
    sound = p['sound'] as bool? ?? sound;
    vibration = p['vibration'] as bool? ?? vibration;
    unit = p['unit'] as String? ?? unit;
    final l = (parsed['logs'] as Map?) ?? {};
    logs.clear();
    l.forEach((k, v) {
      logs[k.toString()] =
          SessionLog.fromJson(Map<String, dynamic>.from(v as Map));
    });
    skipped
      ..clear()
      ..addAll(((parsed['skipped'] as List?) ?? const [])
          .map((e) => e.toString()));
    measures.clear();
    for (final e in ((parsed['measures'] as List?) ?? const [])) {
      final m = BodyMeasure.fromJson(Map<String, dynamic>.from(e as Map));
      measures[m.date] = m;
    }
    machinePhotos
      ..clear()
      ..addAll(((parsed['machinePhotos'] as Map?) ?? {})
          .map((k, v) => MapEntry(k.toString(), v.toString())));
  }

  /// Pousse vers le cloud avec un petit debounce (évite le spam d'écritures).
  void _schedulePush({bool immediate = false}) {
    if (!SyncService.instance.isEnabled) return;
    _pushDebounce?.cancel();
    final data = _toJson();
    if (immediate) {
      SyncService.instance.push(data);
      return;
    }
    _pushDebounce = Timer(const Duration(seconds: 2), () {
      SyncService.instance.push(data);
    });
  }

  // Lundi de la semaine courante (ancrage du programme séquentiel).
  DateTime _currentMonday([DateTime? today]) {
    today ??= DateTime.now();
    final dow = today.weekday % 7; // dim=0..sam=6
    final m = today.subtract(Duration(days: dow == 0 ? 6 : dow - 1));
    return DateTime(m.year, m.month, m.day);
  }

  // Retire les clés `skipped` qui ne concernent pas la semaine courante.
  // Empêche l'accumulation silencieuse sur 6 mois.
  void _purgeStaleSkips() {
    final mondayIso = _isoDate(_currentMonday());
    final stale =
        skipped.where((k) => !k.endsWith('_$mondayIso')).toList();
    if (stale.isNotEmpty) {
      skipped.removeAll(stale);
      _write();
    }
  }

  // ---------- Persistence ----------
  void _read() {
    final raw = _prefs.getString(_storageKey);
    if (raw == null) return;
    try {
      final parsed = jsonDecode(raw) as Map<String, dynamic>;
      final profile = (parsed['profile'] as Map?) ?? {};
      startDate = profile['startDate'] as String?;
      bodyWeight = (profile['bodyWeight'] as num?)?.toDouble();
      final prefs = (parsed['prefs'] as Map?) ?? {};
      theme = prefs['theme'] as String? ?? 'sport-dark';
      sound = prefs['sound'] as bool? ?? true;
      vibration = prefs['vibration'] as bool? ?? true;
      unit = prefs['unit'] as String? ?? 'kg';
      final l = (parsed['logs'] as Map?) ?? {};
      logs.clear();
      l.forEach((k, v) {
        logs[k.toString()] =
            SessionLog.fromJson(Map<String, dynamic>.from(v as Map));
      });
      skipped
        ..clear()
        ..addAll(((parsed['skipped'] as List?) ?? const [])
            .map((e) => e.toString()));
      measures.clear();
      for (final e in ((parsed['measures'] as List?) ?? const [])) {
        final m = BodyMeasure.fromJson(Map<String, dynamic>.from(e as Map));
        measures[m.date] = m;
      }
      machinePhotos
        ..clear()
        ..addAll(((parsed['machinePhotos'] as Map?) ?? {})
            .map((k, v) => MapEntry(k.toString(), v.toString())));
    } catch (e) {
      debugPrint('Store: read failed, using default ($e)');
    }
  }

  Map<String, dynamic> _toJson() => {
        'profile': {
          'startDate': startDate,
          'bodyWeight': bodyWeight,
          'lastSeenSkin': 'clean',
        },
        'prefs': {
          'theme': theme,
          'sound': sound,
          'vibration': vibration,
          'unit': unit,
        },
        'logs': logs.map((k, v) => MapEntry(k, v.toJson())),
        'skipped': skipped.toList(),
        'measures': measures.values.map((m) => m.toJson()).toList(),
        'machinePhotos': machinePhotos,
      };

  void _write() {
    _prefs.setString(_storageKey, jsonEncode(_toJson()));
    _schedulePush();
    notifyListeners();
  }

  // ---------- Helpers ----------
  String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String logKey(String sessionId, DateTime date) =>
      '${sessionId}_${_isoDate(date)}';

  // ---------- Profile ----------
  void setStartDate(String? iso) {
    startDate = iso;
    _write();
  }

  void setBodyWeight(double? kg) {
    bodyWeight = kg;
    _write();
  }

  // ---------- Prefs ----------
  void setPref(String key, dynamic value) {
    switch (key) {
      case 'theme':
        theme = value as String;
        break;
      case 'sound':
        sound = value as bool;
        break;
      case 'vibration':
        vibration = value as bool;
        break;
      case 'unit':
        unit = value as String;
        break;
    }
    _write();
  }

  // ---------- Logs ----------
  SessionLog? getLog(String sessionId, DateTime date) =>
      logs[logKey(sessionId, date)];

  SessionLog getOrInitLog(
      String sessionId, DateTime date, List<Exercise> template) {
    final key = logKey(sessionId, date);
    final existing = logs[key];
    if (existing != null) return existing;
    final newLog = SessionLog(
      sessionId: sessionId,
      date: date.toUtc().toIso8601String(),
      sets: [
        for (final ex in template)
          for (var i = 0; i < ex.sets; i++)
            SetLog(exerciseId: ex.id, setIndex: i),
      ],
    );
    logs[key] = newLog;
    _write();
    return newLog;
  }

  void updateSet(String sessionId, DateTime date, String exerciseId,
      int setIndex, {double? weight, int? reps, bool? done, bool clearWeight = false, bool clearReps = false}) {
    final log = logs[logKey(sessionId, date)];
    if (log == null) return;
    for (final s in log.sets) {
      if (s.exerciseId == exerciseId && s.setIndex == setIndex) {
        if (clearWeight) {
          s.weight = null;
        } else if (weight != null) {
          s.weight = weight;
        }
        if (clearReps) {
          s.reps = null;
        } else if (reps != null) {
          s.reps = reps;
        }
        if (done != null) s.done = done;
        break;
      }
    }
    _write();
  }

  void setNotes(String sessionId, DateTime date, String notes) {
    final log = logs[logKey(sessionId, date)];
    if (log != null) {
      log.notes = notes;
      _write();
    }
  }

  void setSubstitution(
      String sessionId, DateTime date, String exerciseId, String replacement) {
    final log = logs[logKey(sessionId, date)];
    if (log != null) {
      if (replacement.trim().isEmpty) {
        log.substitutions.remove(exerciseId);
      } else {
        log.substitutions[exerciseId] = replacement;
      }
      _write();
    }
  }

  void setWarmupDone(String sessionId, DateTime date, bool done) {
    final log = logs[logKey(sessionId, date)];
    if (log != null && log.warmupDone != done) {
      log.warmupDone = done;
      _write();
    }
  }

  // ---------- Photos de machines ----------
  String? machinePhoto(String exerciseId) => machinePhotos[exerciseId];

  void setMachinePhoto(String exerciseId, String? filename) {
    if (filename == null || filename.isEmpty) {
      machinePhotos.remove(exerciseId);
    } else {
      machinePhotos[exerciseId] = filename;
    }
    _write();
  }

  // ---------- Programme séquentiel (décaler / sauter) ----------
  // Clé d'une séance pour une semaine donnée (ancrée sur le lundi).
  String _weekKey(String sessionId, DateTime weekMonday) =>
      '${sessionId}_${_isoDate(weekMonday)}';

  bool isSkipped(String sessionId, DateTime weekMonday) =>
      skipped.contains(_weekKey(sessionId, weekMonday));

  void skipSession(String sessionId, DateTime weekMonday) {
    skipped.add(_weekKey(sessionId, weekMonday));
    _write();
  }

  void unskipSession(String sessionId, DateTime weekMonday) {
    skipped.remove(_weekKey(sessionId, weekMonday));
    _write();
  }

  // Une séance est "faite" cette semaine si un log complété existe entre
  // lundi et dimanche.
  bool isCompletedThisWeek(String sessionId, DateTime weekMonday) {
    for (var i = 0; i < 7; i++) {
      final d = weekMonday.add(Duration(days: i));
      final log = logs[logKey(sessionId, d)];
      if (log?.completedAt != null) return true;
    }
    return false;
  }

  // ---------- Mesures corporelles ----------
  void addMeasure({required double weightKg, double? waistCm, DateTime? date}) {
    final d = date ?? DateTime.now();
    final iso = _isoDate(d);
    measures[iso] = BodyMeasure(date: iso, weightKg: weightKg, waistCm: waistCm);
    bodyWeight = weightKg; // garde le "dernier connu" à jour
    _write();
  }

  void deleteMeasure(String dateIso) {
    if (measures.remove(dateIso) != null) _write();
  }

  // Mesures triées de la plus ancienne à la plus récente.
  List<BodyMeasure> measuresSorted() {
    final list = measures.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  BodyMeasure? get latestMeasure {
    final s = measuresSorted();
    return s.isEmpty ? null : s.last;
  }

  void completeSession(String sessionId, DateTime date) {
    final log = logs[logKey(sessionId, date)];
    if (log != null) {
      log.completedAt = DateTime.now().toUtc().toIso8601String();
      _write();
    }
  }

  // Dernier poids utilisé pour un exercice (suggestion auto).
  double? getLastWeight(String exerciseId) {
    final allLogs = logs.values.toList()
      ..sort((a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));
    for (final log in allLogs) {
      final sets =
          log.sets.where((s) => s.exerciseId == exerciseId && s.weight != null);
      if (sets.isNotEmpty) return sets.last.weight;
    }
    return null;
  }

  // Stats globales.
  Stats getStats() {
    final all = logs.values.toList();
    final completed = all.where((l) => l.completedAt != null).toList();
    final totalSets =
        completed.fold<int>(0, (acc, l) => acc + l.sets.where((s) => s.done).length);
    final totalVolume = completed.fold<double>(0, (acc, l) {
      return acc +
          l.sets
              .where((s) => s.done && s.weight != null && s.reps != null)
              .fold<double>(0, (s2, set) => s2 + set.weight! * set.reps!);
    });

    // Streak (jours calendaires consécutifs).
    final dates = completed
        .map((l) => l.completedAt!.substring(0, 10))
        .toSet()
        .toList()
      ..sort();
    int streak = 0;
    if (dates.isNotEmpty) {
      final todayStr = _isoDate(DateTime.now());
      var cur = DateTime.parse(todayStr);
      while (true) {
        final iso = _isoDate(cur);
        if (dates.contains(iso)) {
          streak++;
          cur = cur.subtract(const Duration(days: 1));
        } else if (iso == todayStr) {
          cur = cur.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }
    }

    return Stats(
      sessionsCompleted: completed.length,
      totalSets: totalSets,
      totalVolume: totalVolume.round(),
      streak: streak,
    );
  }

  // Dates des séances complétées (calendrier / dashboard).
  Set<String> getCompletedDates() => logs.values
      .where((l) => l.completedAt != null)
      .map((l) => l.date.substring(0, 10))
      .toSet();

  // ---------- Analytics progression ----------
  // Volume total (kg) par semaine, ancré sur le lundi. Trié chronologiquement.
  List<({DateTime weekStart, double volume})> volumeByWeek() {
    final map = <String, ({DateTime weekStart, double volume})>{};
    for (final log in logs.values.where((l) => l.completedAt != null)) {
      final d = DateTime.parse(log.date);
      final monday = _currentMonday(d);
      final key = _isoDate(monday);
      final vol = log.sets
          .where((s) => s.done && s.weight != null && s.reps != null)
          .fold<double>(0, (a, s) => a + s.weight! * s.reps!);
      final existing = map[key];
      map[key] = (
        weekStart: monday,
        volume: (existing?.volume ?? 0) + vol,
      );
    }
    final list = map.values.toList()
      ..sort((a, b) => a.weekStart.compareTo(b.weekStart));
    return list;
  }

  // Meilleur poids (kg) enregistré par séance pour un exercice donné, dans le
  // temps. Sert à tracer "Chest Press : 40 -> 55 kg".
  List<({DateTime date, double weight})> weightProgress(String exerciseId) {
    final pts = <({DateTime date, double weight})>[];
    final completed = logs.values.where((l) => l.completedAt != null).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    for (final log in completed) {
      final weights = log.sets
          .where((s) =>
              s.exerciseId == exerciseId && s.done && s.weight != null)
          .map((s) => s.weight!);
      if (weights.isEmpty) continue;
      final best = weights.reduce((a, b) => a > b ? a : b);
      pts.add((date: DateTime.parse(log.date), weight: best));
    }
    return pts;
  }

  // Liste des exercices effectivement loggés (avec poids), pour le sélecteur.
  List<String> loggedExerciseIds() {
    final ids = <String>{};
    for (final log in logs.values.where((l) => l.completedAt != null)) {
      for (final s in log.sets) {
        if (s.weight != null && s.done) ids.add(s.exerciseId);
      }
    }
    return ids.toList();
  }

  void reset() {
    startDate = null;
    bodyWeight = null;
    theme = 'sport-dark';
    sound = true;
    vibration = true;
    unit = 'kg';
    logs.clear();
    skipped.clear();
    measures.clear();
    _write();
  }

  String exportJSON() =>
      const JsonEncoder.withIndent('  ').convert(_toJson());

  bool importJSON(String json) {
    try {
      final parsed = jsonDecode(json) as Map<String, dynamic>;
      _prefs.setString(_storageKey, jsonEncode(parsed));
      _read();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Import failed: $e');
      return false;
    }
  }
}
