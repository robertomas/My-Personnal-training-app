import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_shell.dart';
import '../data/program.dart';
import '../models/program_models.dart';
import '../store/store.dart';
import '../theme/app_theme.dart';
import '../utils/fr_dates.dart';
import '../utils/units.dart';
import '../widgets/common.dart';
import 'setup_sheet.dart';

class DashboardScreen extends StatelessWidget {
  final void Function(AppRoute) navigate;
  const DashboardScreen({super.key, required this.navigate});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<Store>();
    final t = AppTokens.of(AppThemeIdX.fromKey(store.theme));
    final stats = store.getStats();

    final today = DateTime.now();
    final dayCode = weekdayCode[jsDay(today)];
    final phase = getCurrentPhase(store.startDate, today);

    // Monday-anchored week.
    final dow = jsDay(today);
    final monday =
        today.subtract(Duration(days: dow == 0 ? 6 : dow - 1));
    final weekDays =
        List.generate(7, (i) => monday.add(Duration(days: i)));

    // Séance proposée = prochaine séance NON faite et NON sautée cette semaine,
    // dans l'ordre UA -> LA -> UB -> LB. Indépendant du jour de la semaine :
    // tu peux donc démarrer le programme n'importe quel jour, et "décaler/sauter".
    final ordered = orderedSessions(phase);
    Session? session;
    for (final s in ordered) {
      if (store.isCompletedThisWeek(s.id, monday)) continue;
      if (store.isSkipped(s.id, monday)) continue;
      session = s;
      break;
    }
    final allDoneThisWeek = session == null && ordered.isNotEmpty;

    final completedDates = store.getCompletedDates();

    int progressWeek = 0;
    if (store.startDate != null) {
      final start = DateTime.parse(store.startDate!);
      final days = today.difference(start).inDays;
      progressWeek = (days < 0 ? 0 : days) ~/ 7;
    }

    final volume = store.unit == 'lbs'
        ? toDisplay(stats.totalVolume.toDouble(), 'lbs').round()
        : stats.totalVolume;
    final volumeLabel = volume > 1000
        ? '${(volume / 1000).toStringAsFixed(1)}k'
        : '$volume';

    return ListView(
      controller: ScrollController(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 130),
      children: [
        // Header strip
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('PROGRAMME · 6 MOIS',
                  style: t.label(13, color: t.textMuted, spacing: 1.0)),
              HeaderAction(
                t: t,
                icon: Icons.settings_outlined,
                onPressed: () => navigate(const AppRoute('settings')),
              ),
            ],
          ),
        ),

        // Greeting
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text('Bonjour Roberto.',
              style: t.display(30, weight: FontWeight.w800, height: 1.05)),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Text(
            store.startDate != null
                ? 'Semaine ${progressWeek + 1} / 24 · ${fullDayLabelFR(today)} ${today.day}'
                : '${fullDayLabelFR(today)} ${today.day} · Configure ton point de départ pour commencer',
            style: t.body(14, color: t.textMuted),
          ),
        ),

        // First-run card
        if (store.startDate == null) ...[
          AppCard(
            t: t,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            margin: const EdgeInsets.only(bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Première utilisation ?',
                    style: t.body(14, weight: FontWeight.w600)),
                const SizedBox(height: 12),
                Text(
                  'Choisis le jour où tu commences le programme. Tout le reste se cale dessus.',
                  style: t.body(13, color: t.textMuted, height: 1.4),
                ),
                const SizedBox(height: 14),
                PrimaryButton(
                  t: t,
                  label: 'Démarrer le programme',
                  icon: Icons.play_arrow_rounded,
                  full: true,
                  onPressed: () => showSetupSheet(context, t),
                ),
              ],
            ),
          ),
        ],

        // Hero card
        _HeroCard(
          t: t,
          phase: phase,
          session: session,
          dayCode: dayCode,
          today: today,
          allDoneThisWeek: allDoneThisWeek,
          onStart: session == null
              ? null
              : () => navigate(AppRoute('session',
                  phaseId: phase.id, sessionId: session!.id)),
          onSkip: session == null
              ? null
              : () => store.skipSession(session!.id, monday),
        ),

        const SizedBox(height: 16),

        // Phase strip (24 weeks)
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 18),
          child: SizedBox(
            height: 5,
            child: Row(
              children: List.generate(24, (i) {
                final p = i < 8 ? 1 : (i < 16 ? 2 : 3);
                final reached = i <= progressWeek && store.startDate != null;
                return Expanded(
                  child: Container(
                    margin:
                        EdgeInsets.only(right: i == 23 ? 0 : 3),
                    decoration: BoxDecoration(
                      color: reached ? t.phaseColor(p) : t.surface2,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),

        // Stats
        Row(
          children: [
            _StatCard(t: t, value: '${stats.sessionsCompleted}', label: 'Séances'),
            const SizedBox(width: 10),
            _StatCard(t: t, value: '${stats.streak}', label: 'Streak'),
            const SizedBox(width: 10),
            _StatCard(t: t, value: volumeLabel, label: 'Volume ${store.unit}'),
          ],
        ),

        const SizedBox(height: 24),

        // This week header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('CETTE SEMAINE',
                style: t.label(13, color: t.textMuted, spacing: 0.6)),
            GhostButton(
              t: t,
              label: 'Calendrier →',
              fontSize: 12,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              onPressed: () => navigate(const AppRoute('calendar')),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Week strip
        Row(
          children: List.generate(7, (i) {
            final d = weekDays[i];
            final code = weekdayCode[jsDay(d)];
            final iso = isoDate(d);
            final isToday = sameDay(d, today);
            final isDone = completedDates.contains(iso);
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i == 6 ? 0 : 3),
                child: _WeekDay(
                  t: t,
                  name: dayLabelFR(d),
                  num: d.day,
                  code: code == 'REST' ? '·' : code,
                  isToday: isToday,
                  isDone: isDone,
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 20),

        // Coach card
        AppCard(
          t: t,
          clip: true,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(gradient: t.coachTint),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('🔥 ', style: t.body(12)),
                      Text('COACH',
                          style: t.label(10, color: t.accent, spacing: 1.2)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(phase.coachNote,
                      style: t
                          .display(17, weight: FontWeight.w500, height: 1.4)
                          .copyWith(letterSpacing: t.letterTight)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  final AppTokens t;
  final dynamic phase; // Phase
  final dynamic session; // Session?
  final String dayCode;
  final DateTime today;
  final bool allDoneThisWeek;
  final VoidCallback? onStart;
  final VoidCallback? onSkip;
  const _HeroCard({
    required this.t,
    required this.phase,
    required this.session,
    required this.dayCode,
    required this.today,
    required this.allDoneThisWeek,
    required this.onStart,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final hasSession = session != null;
    final intensityShort =
        (phase.intensity as String).split('—').first.trim();

    return AppCard(
      t: t,
      clip: true,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      margin: const EdgeInsets.only(top: 8),
      child: Stack(
        children: [
          // radial glow top-right
          Positioned(
            top: -80,
            right: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (t.id == AppThemeId.sportDark ? t.accent : t.text)
                        .withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  PhasePill(
                      t: t,
                      number: phase.number,
                      text: 'Phase ${phase.number} · ${phase.title}'),
                  Text(
                      hasSession
                          ? '· PROCHAINE SÉANCE'
                          : '· ${fullDayLabelFR(today)}',
                      style: t.label(10, color: t.textMuted, spacing: 1.0)),
                ],
              ),
              const SizedBox(height: 12),
              if (hasSession) ...[
                Text(session.title,
                    style: t.display(24, weight: FontWeight.w700, height: 1.15)),
                const SizedBox(height: 4),
                _MetaLine(
                    t: t,
                    parts: [
                      ('${session.exercises.length} exercices', true),
                      (' · ~50 min · $intensityShort', false),
                    ]),
                const SizedBox(height: 18),
                PrimaryButton(
                  t: t,
                  label: 'Démarrer la séance',
                  icon: Icons.play_arrow_rounded,
                  full: true,
                  onPressed: onStart,
                ),
                const SizedBox(height: 8),
                GhostButton(
                  t: t,
                  label: 'Sauter / décaler cette séance',
                  fontSize: 13,
                  full: true,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  onPressed: onSkip,
                ),
              ] else if (allDoneThisWeek) ...[
                Text('Semaine bouclée 🔥',
                    style:
                        t.display(24, weight: FontWeight.w700, height: 1.15)),
                const SizedBox(height: 4),
                Text(
                  'Tes 4 séances sont faites. Repos mérité — on remet ça lundi prochain.',
                  style: t.body(13, color: t.textMuted, height: 1.4),
                ),
              ] else ...[
                Text(
                  dayCode == 'HIIT'
                      ? 'Repos (ou HIIT optionnel)'
                      : 'Repos complet',
                  style: t.display(24, weight: FontWeight.w700, height: 1.15),
                ),
                const SizedBox(height: 4),
                Text(
                  dayCode == 'HIIT'
                      ? 'Cardio long optionnel : rameur Zone 2 ou HIIT. Si tu en as besoin, vas-y.'
                      : 'Famille, soleil, déconnexion. Le repos fait partie du programme.',
                  style: t.body(13, color: t.textMuted, height: 1.4),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  final AppTokens t;
  final List<(String, bool)> parts; // text, isStrong
  const _MetaLine({required this.t, required this.parts});
  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: parts
            .map((p) => TextSpan(
                  text: p.$1,
                  style: t.body(13,
                      color: p.$2 ? t.text : t.textMuted,
                      weight: p.$2 ? FontWeight.w600 : FontWeight.w400),
                ))
            .toList(),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final AppTokens t;
  final String value;
  final String label;
  const _StatCard(
      {required this.t, required this.value, required this.label});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: t.surface2,
          borderRadius: BorderRadius.circular(t.radiusSm),
          border: Border.all(color: t.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: t.display(24, weight: FontWeight.w700, height: 1.0)),
            const SizedBox(height: 6),
            Text(label.toUpperCase(),
                style: t.label(9, color: t.textMuted, spacing: 0.8)),
          ],
        ),
      ),
    );
  }
}

class _WeekDay extends StatelessWidget {
  final AppTokens t;
  final String name;
  final int num;
  final String code;
  final bool isToday;
  final bool isDone;
  const _WeekDay({
    required this.t,
    required this.name,
    required this.num,
    required this.code,
    required this.isToday,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isToday ? t.accentText : null;
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isToday ? t.accent : t.surface2,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isToday ? t.accent : t.border),
          ),
          child: Column(
            children: [
              Text(name.toUpperCase(),
                  style: t.label(8.5,
                      color: isToday
                          ? t.accentText.withValues(alpha: 0.65)
                          : t.textFaint,
                      spacing: 0.2)),
              const SizedBox(height: 3),
              Text('$num',
                  style: t.display(16,
                      weight: FontWeight.w700,
                      color: fg ?? t.text,
                      height: 1.0)),
              const SizedBox(height: 3),
              Text(code,
                  style: t
                      .mono(8,
                          weight: FontWeight.w700,
                          color: isToday
                              ? t.accentText.withValues(alpha: 0.65)
                              : t.textMuted)
                      .copyWith(letterSpacing: 0.5)),
            ],
          ),
        ),
        if (isDone)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: t.success,
                boxShadow: [
                  BoxShadow(color: t.success, blurRadius: 8),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
