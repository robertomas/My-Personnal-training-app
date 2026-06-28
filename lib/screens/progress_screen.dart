import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_shell.dart';
import '../data/program.dart';
import '../store/store.dart';
import '../store/user_state.dart';
import '../theme/app_theme.dart';
import '../utils/fr_dates.dart';
import '../utils/units.dart';
import '../widgets/common.dart';
import '../widgets/sheet.dart';

class ProgressScreen extends StatefulWidget {
  final void Function(AppRoute) navigate;
  const ProgressScreen({super.key, required this.navigate});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  String? _selectedExercise;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<Store>();
    final t = AppTokens.of(AppThemeIdX.fromKey(store.theme));
    final stats = store.getStats();

    final loggedIds = store.loggedExerciseIds();
    // Sélection par défaut = premier exercice loggé.
    final sel = _selectedExercise != null && loggedIds.contains(_selectedExercise)
        ? _selectedExercise
        : (loggedIds.isNotEmpty ? loggedIds.first : null);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 130),
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Text('Progrès', style: t.display(30, weight: FontWeight.w800)),
        ),
        Text(
          'Ta transformation, semaine après semaine.',
          style: t.body(14, color: t.textMuted),
        ),
        const SizedBox(height: 20),

        // Stat row
        Row(
          children: [
            _Stat(t: t, value: '${stats.sessionsCompleted}', label: 'Séances'),
            const SizedBox(width: 10),
            _Stat(t: t, value: '${stats.streak}', label: 'Streak'),
            const SizedBox(width: 10),
            _Stat(t: t, value: '${stats.totalSets}', label: 'Séries'),
          ],
        ),

        const SizedBox(height: 24),

        // Body weight
        SectionLabel(t: t, text: 'Poids de corps'),
        _BodyWeightCard(t: t, store: store, unit: store.unit),

        const SizedBox(height: 12),

        // Volume per week
        SectionLabel(t: t, text: 'Volume hebdomadaire'),
        _VolumeCard(t: t, store: store, unit: store.unit),

        const SizedBox(height: 12),

        // Exercise progress
        SectionLabel(t: t, text: 'Progression par exercice'),
        if (sel == null)
          AppCard(
            t: t,
            padding: const EdgeInsets.all(20),
            child: Text(
              'Termine quelques séances avec des charges pour voir tes courbes ici.',
              style: t.body(13, color: t.textMuted, height: 1.5),
            ),
          )
        else
          _ExerciseProgressCard(
            t: t,
            store: store,
            unit: store.unit,
            loggedIds: loggedIds,
            selected: sel,
            onSelect: (id) => setState(() => _selectedExercise = id),
          ),
      ],
    );
  }
}

// ===== Stat chip =====
class _Stat extends StatelessWidget {
  final AppTokens t;
  final String value;
  final String label;
  const _Stat({required this.t, required this.value, required this.label});
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

// ===== Body weight card =====
class _BodyWeightCard extends StatelessWidget {
  final AppTokens t;
  final Store store;
  final String unit;
  const _BodyWeightCard(
      {required this.t, required this.store, required this.unit});

  @override
  Widget build(BuildContext context) {
    final measures = store.measuresSorted();
    final latest = store.latestMeasure;

    return AppCard(
      t: t,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DERNIER POIDS',
                        style: t.label(10, color: t.textMuted, spacing: 0.8)),
                    const SizedBox(height: 6),
                    if (latest != null)
                      Text(
                        fmtWeightFromKg(latest.weightKg, unit),
                        style: t.display(30, weight: FontWeight.w800, height: 1.0),
                      )
                    else
                      Text('—',
                          style:
                              t.display(30, weight: FontWeight.w800, height: 1.0)),
                    if (latest != null) ...[
                      const SizedBox(height: 4),
                      Text(_trendLabel(measures, unit),
                          style: t.body(12, color: t.textMuted)),
                    ],
                  ],
                ),
              ),
              GhostButton(
                t: t,
                label: 'Ajouter',
                icon: Icons.add,
                fontSize: 12,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                onPressed: () => _openAddMeasure(context, t, store, unit),
              ),
            ],
          ),
          if (measures.length >= 2) ...[
            const SizedBox(height: 18),
            SizedBox(
              height: 140,
              child: _LineChart(
                t: t,
                points: [
                  for (var i = 0; i < measures.length; i++)
                    FlSpot(i.toDouble(),
                        toDisplay(measures[i].weightKg, unit)),
                ],
                xLabels: [
                  for (final m in measures) shortDateFR(DateTime.parse(m.date)),
                ],
                color: t.accent,
              ),
            ),
          ] else if (measures.length == 1) ...[
            const SizedBox(height: 14),
            Text('Ajoute une 2e mesure pour voir la courbe.',
                style: t.body(12, color: t.textFaint)),
          ],
        ],
      ),
    );
  }

  String _trendLabel(List<BodyMeasure> m, String unit) {
    if (m.length < 2) return 'Première mesure';
    final deltaKg = m.last.weightKg - m.first.weightKg;
    final d = toDisplay(deltaKg.abs(), unit);
    final sign = deltaKg < 0 ? '−' : '+';
    return '$sign${fmtWeight(d, unit)}$unit depuis le début';
  }

  void _openAddMeasure(
      BuildContext context, AppTokens t, Store store, String unit) {
    final weightCtrl = TextEditingController(
      text: store.latestMeasure != null
          ? fmtWeight(toDisplay(store.latestMeasure!.weightKg, unit), unit)
          : '',
    );
    final waistCtrl = TextEditingController(
      text: store.latestMeasure?.waistCm != null
          ? store.latestMeasure!.waistCm!
              .toStringAsFixed(0)
          : '',
    );
    showAppSheet(
      context: context,
      t: t,
      builder: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nouvelle mesure',
              style: t.display(22, weight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('Aujourd\'hui · ${shortDateFR(DateTime.now())}',
              style: t.body(13, color: t.textMuted)),
          const SizedBox(height: 16),
          AppField(
            t: t,
            controller: weightCtrl,
            label: 'Poids de corps ($unit)',
            hint: unit == 'lbs' ? 'Ex. 165' : 'Ex. 75',
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
          AppField(
            t: t,
            controller: waistCtrl,
            label: 'Tour de taille (cm) — optionnel',
            hint: 'Ex. 84',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            t: t,
            label: 'Enregistrer',
            full: true,
            onPressed: () {
              final raw = weightCtrl.text.replaceAll(',', '.').trim();
              final val = double.tryParse(raw);
              if (val == null || val <= 0) {
                Navigator.of(ctx).pop();
                return;
              }
              final kg = toKg(val, unit);
              final waist =
                  double.tryParse(waistCtrl.text.replaceAll(',', '.').trim());
              store.addMeasure(weightKg: kg, waistCm: waist);
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }
}

// ===== Volume card =====
class _VolumeCard extends StatelessWidget {
  final AppTokens t;
  final Store store;
  final String unit;
  const _VolumeCard(
      {required this.t, required this.store, required this.unit});

  @override
  Widget build(BuildContext context) {
    final weeks = store.volumeByWeek();
    if (weeks.length < 2) {
      return AppCard(
        t: t,
        padding: const EdgeInsets.all(20),
        child: Text(
          'Boucle au moins 2 semaines pour voir l\'évolution de ton volume.',
          style: t.body(13, color: t.textMuted, height: 1.5),
        ),
      );
    }
    return AppCard(
      t: t,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Volume total soulevé / semaine ($unit)',
              style: t.body(13, weight: FontWeight.w600)),
          const SizedBox(height: 18),
          SizedBox(
            height: 150,
            child: _BarChart(
              t: t,
              values: [
                for (final w in weeks) toDisplay(w.volume, unit),
              ],
              xLabels: [
                for (final w in weeks) shortDateFR(w.weekStart),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===== Exercise progress card =====
class _ExerciseProgressCard extends StatelessWidget {
  final AppTokens t;
  final Store store;
  final String unit;
  final List<String> loggedIds;
  final String selected;
  final ValueChanged<String> onSelect;
  const _ExerciseProgressCard({
    required this.t,
    required this.store,
    required this.unit,
    required this.loggedIds,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final progress = store.weightProgress(selected);

    return AppCard(
      t: t,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selector
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: loggedIds.map((id) {
              final active = id == selected;
              return GestureDetector(
                onTap: () => onSelect(id),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: active ? t.accent : t.surface2,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: active ? t.accent : t.border),
                  ),
                  child: Text(
                    exerciseName(id),
                    style: t.label(10,
                        color: active ? t.accentText : t.textMuted,
                        spacing: 0.4),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          if (progress.length < 2)
            Text('Pas encore assez de données pour cet exercice.',
                style: t.body(12, color: t.textFaint))
          else ...[
            Builder(builder: (_) {
              final first = progress.first.weight;
              final last = progress.last.weight;
              final delta = last - first;
              final sign = delta >= 0 ? '+' : '−';
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(fmtWeightFromKg(last, unit),
                      style: t.display(26, weight: FontWeight.w800, height: 1.0)),
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      '$sign${fmtWeight(toDisplay(delta.abs(), unit), unit)}$unit',
                      style: t.body(13,
                          weight: FontWeight.w700,
                          color: delta >= 0 ? t.success : t.danger),
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 16),
            SizedBox(
              height: 140,
              child: _LineChart(
                t: t,
                points: [
                  for (var i = 0; i < progress.length; i++)
                    FlSpot(i.toDouble(), toDisplay(progress[i].weight, unit)),
                ],
                xLabels: [
                  for (final p in progress) shortDateFR(p.date),
                ],
                color: t.accent,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ===== Charts =====
class _LineChart extends StatelessWidget {
  final AppTokens t;
  final List<FlSpot> points;
  final List<String> xLabels;
  final Color color;
  const _LineChart({
    required this.t,
    required this.points,
    required this.xLabels,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ys = points.map((p) => p.y).toList();
    final minY = ys.reduce((a, b) => a < b ? a : b);
    final maxY = ys.reduce((a, b) => a > b ? a : b);
    final pad = ((maxY - minY) * 0.15).clamp(1.0, double.infinity);

    return LineChart(
      LineChartData(
        minY: (minY - pad),
        maxY: (maxY + pad),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: ((maxY - minY) <= 0) ? 1 : (maxY - minY) / 2,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: t.border, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              getTitlesWidget: (v, _) => Text(
                v.round().toString(),
                style: t.mono(9, color: t.textFaint),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 1,
              getTitlesWidget: (v, _) {
                final i = v.round();
                if (i < 0 || i >= xLabels.length) return const SizedBox();
                // Évite la surcharge : 1 label sur N si beaucoup de points.
                final step = (xLabels.length / 4).ceil().clamp(1, 999);
                if (i % step != 0 && i != xLabels.length - 1) {
                  return const SizedBox();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(xLabels[i],
                      style: t.mono(8, color: t.textFaint)),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: points,
            isCurved: true,
            curveSmoothness: 0.25,
            color: color,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (s, _, __, ___) => FlDotCirclePainter(
                radius: 3,
                color: color,
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  final AppTokens t;
  final List<double> values;
  final List<String> xLabels;
  const _BarChart(
      {required this.t, required this.values, required this.xLabels});

  @override
  Widget build(BuildContext context) {
    final maxV = values.reduce((a, b) => a > b ? a : b);
    return BarChart(
      BarChartData(
        maxY: maxV * 1.2,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: t.border, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (v, _) {
                final lbl = v >= 1000
                    ? '${(v / 1000).toStringAsFixed(0)}k'
                    : v.round().toString();
                return Text(lbl, style: t.mono(9, color: t.textFaint));
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (v, _) {
                final i = v.round();
                if (i < 0 || i >= xLabels.length) return const SizedBox();
                final step = (xLabels.length / 4).ceil().clamp(1, 999);
                if (i % step != 0 && i != xLabels.length - 1) {
                  return const SizedBox();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(xLabels[i], style: t.mono(8, color: t.textFaint)),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          for (var i = 0; i < values.length; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: values[i],
                color: t.accent,
                width: 12,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4)),
              ),
            ]),
        ],
      ),
    );
  }
}
