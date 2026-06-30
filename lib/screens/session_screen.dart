import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../utils/machine_photos.dart';

import '../app_shell.dart';
import '../data/exercise_images.dart';
import '../data/program.dart';
import '../data/warmup.dart';
import '../models/program_models.dart';
import '../store/store.dart';
import '../store/user_state.dart';
import '../theme/app_theme.dart';
import '../utils/demo.dart';
import '../utils/feedback.dart';
import '../utils/fr_dates.dart';
import '../utils/units.dart';
import '../widgets/common.dart';
import '../widgets/sheet.dart';

class SessionScreen extends StatefulWidget {
  final String phaseId;
  final String sessionId;
  final void Function(AppRoute) navigate;
  const SessionScreen({
    super.key,
    required this.phaseId,
    required this.sessionId,
    required this.navigate,
  });

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  Timer? _timer;
  bool _restActive = false;
  int _restSeconds = 0;
  DateTime _restEndAt = DateTime.now();

  late final DateTime _date;
  Phase? _phase;
  Session? _session;

  @override
  void initState() {
    super.initState();
    _date = DateTime.now();
    _phase = phaseById(widget.phaseId);
    _session = _phase?.sessions.firstWhere(
      (s) => s.id == widget.sessionId,
      orElse: () => _phase!.sessions.first,
    );
    if (_phase != null && _session != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<Store>().getOrInitLog(
            widget.sessionId, _date, _session!.exercises);
      });
    }
  }

  void _enableWakelock() {
    WakelockPlus.enable().catchError((_) {});
  }

  void _disableWakelock() {
    WakelockPlus.disable().catchError((_) {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    _disableWakelock();
    super.dispose();
  }

  void _startRest(int seconds) {
    if (seconds <= 0) return;
    _timer?.cancel();
    _enableWakelock();
    _restEndAt = DateTime.now().add(Duration(seconds: seconds));
    setState(() {
      _restActive = true;
      _restSeconds = seconds;
    });
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      final left = ((_restEndAt.difference(DateTime.now()).inMilliseconds) / 1000)
          .round();
      final clamped = left < 0 ? 0 : left;
      if (clamped <= 0) {
        _timer?.cancel();
        _disableWakelock();
        setState(() {
          _restActive = false;
          _restSeconds = 0;
        });
        final store = context.read<Store>();
        playBeep(store);
        vibrate(store);
      } else {
        setState(() => _restSeconds = clamped);
      }
    });
  }

  void _adjustRest(int delta) {
    setState(() {
      _restSeconds = (_restSeconds + delta).clamp(0, 9999);
      _restEndAt = DateTime.now().add(Duration(seconds: _restSeconds));
    });
  }

  void _stopRest() {
    _timer?.cancel();
    _disableWakelock();
    setState(() {
      _restActive = false;
      _restSeconds = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<Store>();
    final t = AppTokens.of(AppThemeIdX.fromKey(store.theme));
    final phase = _phase;
    final session = _session;

    if (phase == null || session == null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Séance introuvable.', style: t.body(15)),
            const SizedBox(height: 12),
            GhostButton(
              t: t,
              label: 'Retour',
              onPressed: () => widget.navigate(const AppRoute('home')),
            ),
          ],
        ),
      );
    }

    final log = store.getLog(widget.sessionId, _date);
    if (log == null) {
      return Center(child: Text('Initialisation…', style: t.body(15)));
    }

    final totalSets = log.sets.length;
    final doneSets = log.sets.where((s) => s.done).length;
    final pct = totalSets == 0 ? 0.0 : doneSets / totalSets;

    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.fromLTRB(20, 16, 20, _restActive ? 180 : 100),
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                HeaderAction(
                  t: t,
                  icon: Icons.arrow_back,
                  label: 'Accueil',
                  onPressed: () => widget.navigate(const AppRoute('home')),
                ),
                HeaderAction(
                  t: t,
                  icon: Icons.edit_note,
                  label: 'Notes',
                  onPressed: () => _openNotes(t, store, log),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Title block
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                PhasePill(
                    t: t, number: phase.number, text: 'Phase ${phase.number}'),
                Text(fullDayLabelFR(DateTime.now()).toUpperCase(),
                    style: t.label(11, color: t.textMuted, spacing: 1.0)),
              ],
            ),
            const SizedBox(height: 6),
            Text(session.title,
                style: t.display(26, weight: FontWeight.w700, height: 1.1)),
            const SizedBox(height: 18),

            // Progress bar
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      height: 6,
                      color: t.border,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: pct,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          color: t.accent,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text('$doneSets/$totalSets',
                    style: t.mono(13, weight: FontWeight.w700, color: t.textMuted)),
              ],
            ),
            const SizedBox(height: 22),

            // Warm-up (spécifique haut / bas du corps)
            _WarmupCard(
              t: t,
              routine: warmupForCode(session.code),
              done: log.warmupDone,
              onToggle: (v) =>
                  store.setWarmupDone(widget.sessionId, _date, v),
            ),
            const SizedBox(height: 22),

            // Exercises
            for (final ex in session.exercises)
              _ExerciseCard(
                t: t,
                exercise: ex,
                unit: store.unit,
                sets: log.sets.where((s) => s.exerciseId == ex.id).toList(),
                substitution: log.substitutions[ex.id],
                lastWeight: store.getLastWeight(ex.id),
                photoFilename: store.machinePhoto(ex.id),
                onPhoto: () => _openMachinePhoto(t, store, ex),
                onToggleDone: (setIdx, newDone) {
                  store.updateSet(widget.sessionId, _date, ex.id, setIdx,
                      done: newDone);
                  if (newDone && ex.rest > 0) _startRest(ex.rest);
                },
                onWeight: (setIdx, val) {
                  if (val == null) {
                    store.updateSet(widget.sessionId, _date, ex.id, setIdx,
                        clearWeight: true);
                  } else {
                    // val est dans l'unité d'affichage -> convertir en kg.
                    store.updateSet(widget.sessionId, _date, ex.id, setIdx,
                        weight: toKg(val, store.unit));
                  }
                },
                onReps: (setIdx, val) {
                  if (val == null) {
                    store.updateSet(widget.sessionId, _date, ex.id, setIdx,
                        clearReps: true);
                  } else {
                    store.updateSet(widget.sessionId, _date, ex.id, setIdx,
                        reps: val);
                  }
                },
                onSubstitute: () => _openSubstitution(t, store, ex, log),
              ),

            const SizedBox(height: 12),
            PrimaryButton(
              t: t,
              label: 'Terminer la séance',
              icon: Icons.check,
              full: true,
              onPressed: () =>
                  _openEnd(t, store, doneSets, totalSets, phase),
            ),
          ],
        ),

        // Rest overlay
        if (_restActive)
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: _RestOverlay(
              t: t,
              seconds: _restSeconds,
              onPlus: () => _adjustRest(15),
              onMinus: () => _adjustRest(-15),
              onSkip: _stopRest,
            ),
          ),
      ],
    );
  }

  // ===== Sheets =====
  void _openNotes(AppTokens t, Store store, SessionLog log) {
    final controller = TextEditingController(text: log.notes);
    showAppSheet(
      context: context,
      t: t,
      builder: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Notes de séance',
              style: t.display(22, weight: FontWeight.w800)),
          const SizedBox(height: 14),
          AppField(
            t: t,
            controller: controller,
            maxLines: 5,
            hint: 'Comment tu te sens ? Quoi améliorer ? Sensations ?',
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            t: t,
            label: 'Enregistrer',
            full: true,
            onPressed: () {
              store.setNotes(widget.sessionId, _date, controller.text);
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  void _openSubstitution(
      AppTokens t, Store store, Exercise ex, SessionLog log) {
    final controller =
        TextEditingController(text: log.substitutions[ex.id] ?? '');
    showAppSheet(
      context: context,
      t: t,
      builder: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Substituer', style: t.display(22, weight: FontWeight.w800)),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              style: t.body(13, color: t.textMuted, height: 1.4),
              children: [
                const TextSpan(text: 'Remplace '),
                TextSpan(
                    text: ex.name,
                    style: t.body(13,
                        color: t.text, weight: FontWeight.w700)),
                const TextSpan(
                    text:
                        ' par un exercice équivalent (machine prise, douleur, etc.)'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppField(
            t: t,
            controller: controller,
            label: 'Exercice de remplacement',
            hint: 'Ex. Développé couché barre',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GhostButton(
                  t: t,
                  label: 'Annuler substitution',
                  full: true,
                  onPressed: () {
                    store.setSubstitution(widget.sessionId, _date, ex.id, '');
                    Navigator.of(ctx).pop();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PrimaryButton(
                  t: t,
                  label: 'Confirmer',
                  full: true,
                  onPressed: () {
                    store.setSubstitution(
                        widget.sessionId, _date, ex.id, controller.text);
                    Navigator.of(ctx).pop();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openMachinePhoto(AppTokens t, Store store, Exercise ex) {
    final existing = store.machinePhoto(ex.id);
    showAppSheet(
      context: context,
      t: t,
      builder: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Photo de la machine',
              style: t.display(22, weight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(ex.name,
              style: t.body(13, color: t.textMuted, height: 1.4)),
          const SizedBox(height: 16),

          // Aperçu si une photo existe
          if (existing != null && existing.isNotEmpty) ...[
            FutureBuilder<String?>(
              future: MachinePhotos.instance.pathFor(existing),
              builder: (c, snap) {
                if (snap.data == null) {
                  return const SizedBox.shrink();
                }
                return ClipRRect(
                  borderRadius: BorderRadius.circular(t.radiusSm),
                  child: Image.file(File(snap.data!),
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover),
                );
              },
            ),
            const SizedBox(height: 16),
          ],

          // Boutons caméra / galerie
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  t: t,
                  full: true,
                  icon: Icons.photo_camera,
                  label: 'Caméra',
                  onPressed: () =>
                      _pickPhoto(ctx, store, ex, fromCamera: true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GhostButton(
                  t: t,
                  full: true,
                  icon: Icons.photo_library_outlined,
                  label: 'Galerie',
                  onPressed: () =>
                      _pickPhoto(ctx, store, ex, fromCamera: false),
                ),
              ),
            ],
          ),
          if (existing != null && existing.isNotEmpty) ...[
            const SizedBox(height: 10),
            GhostButton(
              t: t,
              full: true,
              icon: Icons.delete_outline,
              label: 'Supprimer la photo',
              onPressed: () async {
                await MachinePhotos.instance.delete(existing);
                store.setMachinePhoto(ex.id, null);
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'La photo reste sur ton téléphone (pas dans le cloud). '
            'Idéal pour retrouver la bonne machine dans ton gym.',
            style: t.body(11.5, color: t.textFaint, height: 1.4),
          ),
        ],
      ),
    );
  }

  Future<void> _pickPhoto(BuildContext sheetCtx, Store store, Exercise ex,
      {required bool fromCamera}) async {
    final filename = await MachinePhotos.instance
        .capture(ex.id, fromCamera: fromCamera);
    if (filename != null) {
      // Supprime l'ancienne photo si remplacement.
      final old = store.machinePhoto(ex.id);
      if (old != null && old.isNotEmpty && old != filename) {
        await MachinePhotos.instance.delete(old);
      }
      store.setMachinePhoto(ex.id, filename);
    }
    if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
  }

  void _openEnd(AppTokens t, Store store, int doneSets, int totalSets,
      Phase phase) {
    final pct = totalSets == 0 ? 0 : ((doneSets / totalSets) * 100).round();
    final emoji = pct == 100 ? '🔥' : (pct >= 70 ? '💪' : '✓');
    final msg = pct == 100
        ? "Séance pleine. C'est exactement comme ça qu'on transforme un corps."
        : pct >= 70
            ? 'Solide. La régularité bat l\'intensité ponctuelle, et tu viens de cocher une case.'
            : pct >= 40
                ? "Demi-séance, mais demi-séance c'est mille fois mieux que zéro."
                : 'Tu es venu. C\'est déjà 90% du job à 49 ans. Demain on remet ça.';

    showAppSheet(
      context: context,
      t: t,
      builder: (ctx) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 12, 0, 4),
            child: Column(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text('$pct% complété',
                    style: t.display(28, weight: FontWeight.w800)),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(msg,
                      textAlign: TextAlign.center,
                      style: t.body(15, color: t.textMuted, height: 1.5)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: GhostButton(
                  t: t,
                  label: 'Continuer',
                  full: true,
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: PrimaryButton(
                  t: t,
                  label: 'Valider la séance',
                  full: true,
                  onPressed: () {
                    store.completeSession(widget.sessionId, _date);
                    Navigator.of(ctx).pop();
                    widget.navigate(const AppRoute('home'));
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ===== Exercise card =====
class _ExerciseCard extends StatelessWidget {
  final AppTokens t;
  final Exercise exercise;
  final String unit;
  final List<SetLog> sets;
  final String? substitution;
  final double? lastWeight;
  final String? photoFilename;
  final VoidCallback onPhoto;
  final void Function(int setIdx, bool newDone) onToggleDone;
  final void Function(int setIdx, double? val) onWeight;
  final void Function(int setIdx, int? val) onReps;
  final VoidCallback onSubstitute;

  const _ExerciseCard({
    required this.t,
    required this.exercise,
    required this.unit,
    required this.sets,
    required this.substitution,
    required this.lastWeight,
    required this.photoFilename,
    required this.onPhoto,
    required this.onToggleDone,
    required this.onWeight,
    required this.onReps,
    required this.onSubstitute,
  });

  @override
  Widget build(BuildContext context) {
    final ex = exercise;
    final done = sets.isNotEmpty && sets.every((s) => s.done);
    final isBodyweight = ex.isBodyweight;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: done ? 0.6 : 1.0,
      child: AppCard(
        t: t,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Head
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // marker row
                      if (ex.superset != null ||
                          ex.circuit != null ||
                          ex.star ||
                          ex.isCardio)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (ex.superset != null)
                                GroupMarker(t: t, text: ex.superset!),
                              if (ex.circuit != null)
                                GroupMarker(
                                    t: t,
                                    text: 'Circuit ${ex.circuit}',
                                    circuit: true),
                              if (ex.star)
                                Text('⭐',
                                    style: TextStyle(
                                        fontSize: 12, color: t.accent)),
                              if (ex.isCardio) AppTag(t: t, text: 'Cardio'),
                            ],
                          ),
                        ),
                      // name (with optional substitution)
                      if (substitution != null && substitution!.isNotEmpty) ...[
                        Text(ex.name,
                            style: t
                                .display(14.5, weight: FontWeight.w700)
                                .copyWith(
                                  decoration: TextDecoration.lineThrough,
                                  color: t.text.withValues(alpha: 0.5),
                                )),
                        const SizedBox(height: 2),
                        Text(substitution!,
                            style: t.display(17, weight: FontWeight.w700, height: 1.25)),
                      ] else
                        Text(ex.name,
                            style: t.display(17,
                                weight: FontWeight.w700, height: 1.25)),
                      const SizedBox(height: 6),
                      // meta row
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          AppTag(t: t, text: '${ex.sets}×${ex.reps}'),
                          if (ex.rest > 0)
                            AppTag(t: t, text: 'Repos ${ex.rest}s'),
                          if (lastWeight != null && !isBodyweight)
                            AppTag(
                              t: t,
                              text:
                                  'Dernier · ${fmtWeightFromKg(lastWeight!, unit)}',
                              color: t.textFaint,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    IconBtn(
                      t: t,
                      icon: Icons.play_circle_outline,
                      onPressed: () => openExerciseDemo(
                        (substitution != null && substitution!.isNotEmpty)
                            ? substitution!
                            : ex.name,
                      ),
                    ),
                    const SizedBox(height: 8),
                    IconBtn(
                        t: t, icon: Icons.swap_vert, onPressed: onSubstitute),
                    const SizedBox(height: 8),
                    IconBtn(
                      t: t,
                      icon: (photoFilename != null && photoFilename!.isNotEmpty)
                          ? Icons.photo_camera
                          : Icons.photo_camera_outlined,
                      onPressed: onPhoto,
                    ),
                  ],
                ),
              ],
            ),

            // note
            if (ex.notes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Text(ex.notes,
                    style: t.body(12.5, color: t.textMuted, height: 1.5)),
              ),

            // illustration de démonstration (exos moins évidents)
            if (exerciseImageFor(ex.id) != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _DemoImage(
                  t: t,
                  asset: exerciseImageFor(ex.id)!,
                  label: ex.name,
                ),
              ),

            // machine photo thumbnail
            if (photoFilename != null && photoFilename!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _MachineThumb(
                  t: t,
                  filename: photoFilename!,
                  onTap: onPhoto,
                ),
              ),

            const SizedBox(height: 8),

            // sets
            if (isBodyweight)
              ...sets.asMap().entries.map((e) => _BodyweightRow(
                    t: t,
                    label: ex.reps,
                    done: e.value.done,
                    onToggle: () => onToggleDone(e.key, !e.value.done),
                  ))
            else ...[
              _SetHeaderRow(t: t, unit: unit),
              ...sets.asMap().entries.map((e) {
                final i = e.key;
                final s = e.value;
                return _SetRow(
                  t: t,
                  index: i + 1,
                  set: s,
                  unit: unit,
                  weightHint: lastWeight != null
                      ? fmtWeight(toDisplay(lastWeight!, unit), unit)
                      : '—',
                  repsHint: _repsHint(ex.reps),
                  onWeight: (v) => onWeight(i, v),
                  onReps: (v) => onReps(i, v),
                  onToggle: () => onToggleDone(i, !s.done),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  static String _repsHint(String reps) {
    final digits = reps.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '—';
    return digits.length > 2 ? digits.substring(0, 2) : digits;
  }
}

// ===== Warm-up card (collapsible) =====
class _WarmupCard extends StatefulWidget {
  final AppTokens t;
  final WarmupRoutine routine;
  final bool done;
  final ValueChanged<bool> onToggle;
  const _WarmupCard({
    required this.t,
    required this.routine,
    required this.done,
    required this.onToggle,
  });

  @override
  State<_WarmupCard> createState() => _WarmupCardState();
}

class _WarmupCardState extends State<_WarmupCard> {
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    // Déplié par défaut si pas encore fait, replié si déjà fait.
    _expanded = !widget.done;
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final r = widget.routine;
    final done = widget.done;

    return AppCard(
      t: t,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (tappable to expand)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: (done ? t.accent : t.textFaint)
                        .withValues(alpha: done ? 0.18 : 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    done
                        ? Icons.check_circle_outline
                        : Icons.local_fire_department_outlined,
                    color: done ? t.accent : t.textMuted,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Échauffement',
                          style: t.display(15.5, weight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(
                        done
                            ? 'Fait · ${r.subtitle}'
                            : '${r.subtitle} · ~${r.estMinutes} min',
                        style: t.body(12, color: t.textMuted),
                      ),
                    ],
                  ),
                ),
                Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                    color: t.textFaint, size: 22),
              ],
            ),
          ),

          if (_expanded) ...[
            const SizedBox(height: 14),
            // Coach note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: t.surface2,
                borderRadius: BorderRadius.circular(t.radiusSm),
                border: Border(
                  left: BorderSide(color: t.accent, width: 3),
                ),
              ),
              child: Text(r.coachNote,
                  style: t.body(12.5, color: t.textMuted, height: 1.5)),
            ),
            const SizedBox(height: 14),
            // Moves
            for (var i = 0; i < r.moves.length; i++)
              Padding(
                padding: EdgeInsets.only(
                    bottom: i == r.moves.length - 1 ? 0 : 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 22,
                      child: Text('${i + 1}',
                          style: t.mono(13,
                              weight: FontWeight.w700, color: t.accent)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(r.moves[i].name,
                                    style: t.body(13.5,
                                        weight: FontWeight.w700, color: t.text)),
                              ),
                              const SizedBox(width: 8),
                              Text(r.moves[i].detail,
                                  style: t.mono(11.5,
                                      weight: FontWeight.w600,
                                      color: t.textMuted)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(r.moves[i].why,
                              style: t.body(11.5,
                                  color: t.textFaint, height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            done
                ? GhostButton(
                    t: t,
                    full: true,
                    icon: Icons.undo,
                    label: 'Marquer non fait',
                    onPressed: () => widget.onToggle(false),
                  )
                : PrimaryButton(
                    t: t,
                    full: true,
                    icon: Icons.check,
                    label: 'Échauffement terminé',
                    onPressed: () {
                      widget.onToggle(true);
                      setState(() => _expanded = false);
                    },
                  ),
          ],
        ],
      ),
    );
  }
}

class _SetHeaderRow extends StatelessWidget {
  final AppTokens t;
  final String unit;
  const _SetHeaderRow({required this.t, required this.unit});
  @override
  Widget build(BuildContext context) {
    Widget lbl(String s) => Text(s.toUpperCase(),
        textAlign: TextAlign.center,
        style: t.mono(9, weight: FontWeight.w700, color: t.textFaint)
            .copyWith(letterSpacing: 1.0));
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(width: 32, child: lbl('Set')),
          const SizedBox(width: 8),
          Expanded(child: lbl('Poids ($unit)')),
          const SizedBox(width: 8),
          Expanded(child: lbl('Reps')),
          const SizedBox(width: 8),
          const SizedBox(width: 42),
        ],
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  final AppTokens t;
  final int index;
  final SetLog set;
  final String unit;
  final String weightHint;
  final String repsHint;
  final void Function(double?) onWeight;
  final void Function(int?) onReps;
  final VoidCallback onToggle;

  const _SetRow({
    required this.t,
    required this.index,
    required this.set,
    required this.unit,
    required this.weightHint,
    required this.repsHint,
    required this.onWeight,
    required this.onReps,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: t.border)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text('$index',
                textAlign: TextAlign.center,
                style: t.mono(12, weight: FontWeight.w700, color: t.textFaint)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _NumInput(
              t: t,
              value: set.weight == null
                  ? ''
                  : fmtWeight(toDisplay(set.weight!, unit), unit),
              hint: weightHint,
              unit: unit,
              decimal: true,
              onChanged: (s) => onWeight(
                  s.isEmpty ? null : double.tryParse(s.replaceAll(',', '.'))),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _NumInput(
              t: t,
              value: set.reps?.toString() ?? '',
              hint: repsHint,
              decimal: false,
              onChanged: (s) => onReps(s.isEmpty ? null : int.tryParse(s)),
            ),
          ),
          const SizedBox(width: 8),
          _CheckButton(t: t, done: set.done, onTap: onToggle),
        ],
      ),
    );
  }
}

class _NumInput extends StatefulWidget {
  final AppTokens t;
  final String value;
  final String hint;
  final String? unit;
  final bool decimal;
  final ValueChanged<String> onChanged;
  const _NumInput({
    required this.t,
    required this.value,
    required this.hint,
    required this.onChanged,
    this.unit,
    this.decimal = false,
  });

  @override
  State<_NumInput> createState() => _NumInputState();
}

class _NumInputState extends State<_NumInput> {
  late final TextEditingController _c =
      TextEditingController(text: widget.value);
  final _focus = FocusNode();

  @override
  void didUpdateWidget(_NumInput old) {
    super.didUpdateWidget(old);
    if (!_focus.hasFocus && widget.value != _c.text) {
      _c.text = widget.value;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    return Stack(
      alignment: Alignment.centerRight,
      children: [
        TextField(
          controller: _c,
          focusNode: _focus,
          onChanged: widget.onChanged,
          textAlign: TextAlign.center,
          cursorColor: t.accent,
          keyboardType: TextInputType.numberWithOptions(decimal: widget.decimal),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
                widget.decimal ? RegExp(r'[0-9.,]') : RegExp(r'[0-9]')),
          ],
          style: t.mono(16, weight: FontWeight.w700, color: t.text),
          decoration: InputDecoration(
            isDense: true,
            hintText: widget.hint,
            hintStyle: t.mono(16, weight: FontWeight.w500, color: t.textFaint),
            filled: true,
            fillColor: t.surface2,
            contentPadding: EdgeInsets.fromLTRB(
                10, 10, widget.unit != null ? 22 : 10, 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(t.radiusSm),
              borderSide: BorderSide(color: t.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(t.radiusSm),
              borderSide: BorderSide(color: t.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(t.radiusSm),
              borderSide: BorderSide(color: t.accent, width: 2),
            ),
          ),
        ),
        if (widget.unit != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IgnorePointer(
              child: Text(widget.unit!,
                  style: t.mono(10,
                      weight: FontWeight.w600, color: t.textFaint)),
            ),
          ),
      ],
    );
  }
}

class _CheckButton extends StatelessWidget {
  final AppTokens t;
  final bool done;
  final VoidCallback onTap;
  const _CheckButton(
      {required this.t, required this.done, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: done ? t.accent : t.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: done ? t.accent : t.border),
        ),
        child: Icon(Icons.check,
            size: 18,
            weight: done ? 700 : 400,
            color: done ? t.accentText : t.textFaint),
      ),
    );
  }
}

class _BodyweightRow extends StatelessWidget {
  final AppTokens t;
  final String label;
  final bool done;
  final VoidCallback onToggle;
  const _BodyweightRow({
    required this.t,
    required this.label,
    required this.done,
    required this.onToggle,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: t.border)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text('●',
                textAlign: TextAlign.center,
                style: t.body(12, color: t.textFaint)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: t.body(14, weight: FontWeight.w600, color: t.textMuted)),
          ),
          const SizedBox(width: 8),
          _CheckButton(t: t, done: done, onTap: onToggle),
        ],
      ),
    );
  }
}

// ===== Machine photo thumbnail =====
class _MachineThumb extends StatelessWidget {
  final AppTokens t;
  final String filename;
  final VoidCallback onTap;
  const _MachineThumb({
    required this.t,
    required this.filename,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: FutureBuilder<String?>(
        future: MachinePhotos.instance.pathFor(filename),
        builder: (c, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const SizedBox.shrink();
          }
          if (snap.data == null) {
            // Fichier introuvable (ex: réinstallation) -> invite à reprendre.
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: t.surface2,
                borderRadius: BorderRadius.circular(t.radiusSm),
                border: Border.all(color: t.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.add_a_photo_outlined,
                      size: 16, color: t.textMuted),
                  const SizedBox(width: 8),
                  Text('Ajouter une photo de la machine',
                      style: t.body(12, color: t.textMuted)),
                ],
              ),
            );
          }
          return ClipRRect(
            borderRadius: BorderRadius.circular(t.radiusSm),
            child: Stack(
              children: [
                Image.file(File(snap.data!),
                    width: double.infinity, height: 140, fit: BoxFit.cover),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.zoom_in, size: 13, color: Colors.white),
                        SizedBox(width: 4),
                        Text('Voir',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ===== Demo illustration (asset) =====
class _DemoImage extends StatelessWidget {
  final AppTokens t;
  final String asset;
  final String label;
  const _DemoImage({
    required this.t,
    required this.asset,
    required this.label,
  });

  void _openFull(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () => Navigator.of(ctx).pop(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(t.radiusSm),
                child: Image.asset(asset, fit: BoxFit.contain),
              ),
              const SizedBox(height: 12),
              Text(label,
                  textAlign: TextAlign.center,
                  style: t.body(14,
                      color: Colors.white, weight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('Touche pour fermer · ▶ ouvre une vidéo',
                  style: t.body(11.5, color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openFull(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(t.radiusSm),
        child: Stack(
          children: [
            Container(
              color: const Color(0xFF1A1A1A),
              width: double.infinity,
              child: Image.asset(
                asset,
                width: double.infinity,
                height: 150,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              left: 8,
              top: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: t.accent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('DÉMO',
                    style: t.label(9, color: t.accentText, spacing: 0.8)),
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.zoom_in, size: 13, color: Colors.white),
                    SizedBox(width: 4),
                    Text('Agrandir',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== Rest overlay =====
class _RestOverlay extends StatelessWidget {
  final AppTokens t;
  final int seconds;
  final VoidCallback onPlus;
  final VoidCallback onMinus;
  final VoidCallback onSkip;
  const _RestOverlay({
    required this.t,
    required this.seconds,
    required this.onPlus,
    required this.onMinus,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    Widget actionBtn(String label, VoidCallback onTap, {double? width}) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          height: 38,
          width: width,
          constraints: const BoxConstraints(minWidth: 38),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: t.restActionBg,
            borderRadius: BorderRadius.circular(width != null ? 999 : 10),
          ),
          child: Text(label,
              style: t.body(12, weight: FontWeight.w700, color: t.restText)),
        ),
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: const Cubic(0.34, 1.56, 0.64, 1),
      builder: (ctx, v, child) => Transform.translate(
        offset: Offset(0, (1 - v) * 40),
        child: Opacity(opacity: v.clamp(0, 1), child: child),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: t.restBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            const BoxShadow(color: Color(0x4D000000), blurRadius: 50, offset: Offset(0, 20)),
            if (t.id == AppThemeId.sportDark)
              BoxShadow(color: t.accent.withValues(alpha: 0.3), blurRadius: 60),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('REPOS',
                    style: t.label(10,
                        color: t.restText.withValues(alpha: 0.7),
                        spacing: 1.2)),
                const SizedBox(height: 2),
                Text(fmtTime(seconds),
                    style: t.mono(30, weight: FontWeight.w700, color: t.restText)),
              ],
            ),
            Row(
              children: [
                actionBtn('+15', onPlus),
                const SizedBox(width: 6),
                actionBtn('−15', onMinus),
                const SizedBox(width: 6),
                actionBtn('Skip', onSkip, width: 80),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
