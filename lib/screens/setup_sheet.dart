import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../store/store.dart';
import '../theme/app_theme.dart';
import '../utils/fr_dates.dart';
import '../widgets/common.dart';
import '../widgets/sheet.dart';

Future<void> showSetupSheet(BuildContext context, AppTokens t) {
  return showAppSheet(
    context: context,
    t: t,
    builder: (ctx) => const _SetupSheetBody(),
  );
}

class _SetupSheetBody extends StatefulWidget {
  const _SetupSheetBody();
  @override
  State<_SetupSheetBody> createState() => _SetupSheetBodyState();
}

class _SetupSheetBodyState extends State<_SetupSheetBody> {
  late DateTime _date = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final store = context.read<Store>();
    final t = AppTokens.of(AppThemeIdX.fromKey(store.theme));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('On démarre.',
            style: t.display(26, weight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(
          'Choisis le jour J. Tout le programme (phases, séances du jour, semaines) se calera dessus.',
          style: t.body(14, color: t.textMuted, height: 1.5),
        ),
        const SizedBox(height: 20),
        _DatePickerField(
          t: t,
          label: 'Date de démarrage',
          date: _date,
          onPick: (d) => setState(() => _date = d),
        ),
        const SizedBox(height: 12),
        GhostButton(
          t: t,
          label: "Aujourd'hui",
          full: true,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          onPressed: () => setState(() => _date = DateTime.now()),
        ),
        const SizedBox(height: 8),
        GhostButton(
          t: t,
          label: 'Demain (Lundi)',
          full: true,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          onPressed: () => setState(
              () => _date = DateTime.now().add(const Duration(days: 1))),
        ),
        const SizedBox(height: 18),
        PrimaryButton(
          t: t,
          label: 'Lancer le programme',
          icon: Icons.play_arrow_rounded,
          full: true,
          onPressed: () {
            store.setStartDate(isoDate(_date));
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

/// Date field that opens the native date picker (replaces <input type=date>).
class _DatePickerField extends StatelessWidget {
  final AppTokens t;
  final String label;
  final DateTime date;
  final ValueChanged<DateTime> onPick;
  const _DatePickerField({
    required this.t,
    required this.label,
    required this.date,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: t.label(11, color: t.textMuted, spacing: 0.6)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime(2024),
              lastDate: DateTime(2030),
              builder: (ctx, child) => Theme(
                data: Theme.of(ctx).copyWith(
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: t.accent,
                    brightness: t.id == AppThemeId.sportDark
                        ? Brightness.dark
                        : Brightness.light,
                  ),
                ),
                child: child!,
              ),
            );
            if (picked != null) onPick(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: t.surface2,
              borderRadius: BorderRadius.circular(t.radiusSm),
              border: Border.all(color: t.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isoDate(date), style: t.body(16, color: t.text)),
                Icon(Icons.calendar_today_outlined,
                    size: 16, color: t.textMuted),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
