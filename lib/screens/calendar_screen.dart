import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_shell.dart';
import '../data/program.dart';
import '../store/store.dart';
import '../theme/app_theme.dart';
import '../utils/fr_dates.dart';
import '../widgets/common.dart';

class CalendarScreen extends StatefulWidget {
  final void Function(AppRoute) navigate;
  const CalendarScreen({super.key, required this.navigate});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  int _monthOffset = 0;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<Store>();
    final t = AppTokens.of(AppThemeIdX.fromKey(store.theme));

    final today = DateTime.now();
    final viewDate = DateTime(today.year, today.month + _monthOffset, 1);
    final completed = store.getCompletedDates();

    // 6 weeks grid, Monday-anchored.
    final first = DateTime(viewDate.year, viewDate.month, 1);
    final firstDow = jsDay(first);
    final offset = firstDow == 0 ? 6 : firstDow - 1;
    final startGrid = first.subtract(Duration(days: offset));
    final cells = List.generate(42, (i) => startGrid.add(Duration(days: i)));

    final currentPhase =
        store.startDate != null ? getCurrentPhase(store.startDate, today) : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 130),
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Text('CALENDRIER',
              style: t.label(13, color: t.textMuted, spacing: 1.0)),
        ),

        // Month navigator
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GhostButton(
                t: t,
                icon: Icons.arrow_back,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                onPressed: () => setState(() => _monthOffset--),
              ),
              Text(monthYearFRCapitalized(viewDate),
                  style: t.display(22, weight: FontWeight.w700)),
              GhostButton(
                t: t,
                icon: Icons.arrow_forward,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                onPressed: () => setState(() => _monthOffset++),
              ),
            ],
          ),
        ),

        // Day-of-week header
        Row(
          children: ['L', 'M', 'M', 'J', 'V', 'S', 'D']
              .map((d) => Expanded(
                    child: Center(
                      child: Text(d,
                          style: t.label(10, color: t.textFaint, spacing: 0.6)),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 6),

        // Month grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 1,
          ),
          itemCount: 42,
          itemBuilder: (ctx, i) {
            final d = cells[i];
            final iso = isoDate(d);
            final inMonth = d.month == viewDate.month;
            final isToday = sameDay(d, today);
            final isDone = completed.contains(iso);
            final code = weekdayCode[jsDay(d)];
            final isWorkout = code != 'REST' && code != 'HIIT';
            return _MonthCell(
              t: t,
              day: d.day,
              code: inMonth && isWorkout ? code : null,
              inMonth: inMonth,
              isToday: isToday,
              isDone: isDone,
              isWorkout: isWorkout,
            );
          },
        ),

        const SizedBox(height: 20),
        Text('LES 3 PHASES',
            style: t.label(13, color: t.textMuted, spacing: 0.6)),
        const SizedBox(height: 10),

        // Phase cards
        for (final phase in phases)
          _PhaseCard(
            t: t,
            phase: phase,
            isCurrent: currentPhase?.id == phase.id,
            onSession: (sessionId) => widget.navigate(
              AppRoute('session', phaseId: phase.id, sessionId: sessionId),
            ),
          ),
      ],
    );
  }
}

class _MonthCell extends StatelessWidget {
  final AppTokens t;
  final int day;
  final String? code;
  final bool inMonth;
  final bool isToday;
  final bool isDone;
  final bool isWorkout;
  const _MonthCell({
    required this.t,
    required this.day,
    required this.code,
    required this.inMonth,
    required this.isToday,
    required this.isDone,
    required this.isWorkout,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isToday
        ? t.accentText
        : (isWorkout && inMonth ? t.text : t.textMuted);
    return Opacity(
      opacity: inMonth ? 1 : 0.3,
      child: Container(
        decoration: BoxDecoration(
          color: isToday ? t.accent : t.surface2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isToday ? t.accent : t.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$day',
                style: t.mono(12,
                    weight: isWorkout ? FontWeight.w700 : FontWeight.w400,
                    color: fg)),
            if (code != null)
              Text(code!,
                  style: t.mono(8,
                      weight: FontWeight.w700,
                      color: isToday
                          ? t.accentText.withValues(alpha: 0.65)
                          : t.textMuted.withValues(alpha: 0.6))),
            if (isDone)
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: t.success,
                  boxShadow: [BoxShadow(color: t.success, blurRadius: 4)],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PhaseCard extends StatelessWidget {
  final AppTokens t;
  final dynamic phase; // Phase
  final bool isCurrent;
  final void Function(String sessionId) onSession;
  const _PhaseCard({
    required this.t,
    required this.phase,
    required this.isCurrent,
    required this.onSession,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isCurrent ? 1 : 0.85,
      child: AppCard(
        t: t,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                PhasePill(
                    t: t,
                    number: phase.number,
                    text: 'Phase ${phase.number} · ${phase.months}'),
                if (isCurrent)
                  AppTag(
                    t: t,
                    text: 'EN COURS',
                    bg: t.accent,
                    color: t.accentText,
                    borderColor: t.accent,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${phase.title} — ${phase.subtitle}',
                style: t
                    .display(18, weight: FontWeight.w700)
                    .copyWith(letterSpacing: t.letterTight)),
            const SizedBox(height: 4),
            Text(phase.tagline,
                style: t.body(13, color: t.textMuted, height: 1.45)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final s in phase.sessions)
                  GhostButton(
                    t: t,
                    label: '${s.day} · ${s.code}',
                    fontSize: 11,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    onPressed: () => onSession(s.id),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
