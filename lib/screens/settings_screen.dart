import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app_shell.dart';
import '../store/store.dart';
import '../sync/sync_service.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';
import '../utils/fr_dates.dart';
import '../widgets/common.dart';
import '../widgets/sheet.dart';

class SettingsScreen extends StatefulWidget {
  final void Function(AppRoute) navigate;
  const SettingsScreen({super.key, required this.navigate});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _resetConfirm = false;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<Store>();
    final t = AppTokens.of(AppThemeIdX.fromKey(store.theme));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 160),
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: HeaderAction(
            t: t,
            icon: Icons.arrow_back,
            label: 'Accueil',
            onPressed: () => widget.navigate(const AppRoute('home')),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Text('Réglages',
              style: t.display(30, weight: FontWeight.w800)),
        ),

        // Account & cloud sync (en haut : important, et toujours accessible)
        SectionLabel(t: t, text: 'Compte & sync cloud'),
        AppCard(
          t: t,
          child: _SyncStatusRow(t: t),
        ),

        // Appearance
        SectionLabel(t: t, text: 'Apparence'),
        AppCard(
          t: t,
          padding: const EdgeInsets.all(6),
          child: Row(
            children: [
              Expanded(
                child: _ThemeCard(
                  t: t,
                  id: AppThemeId.sportDark,
                  label: 'Sport Dark',
                  sub: 'Noir + lime',
                  active: store.theme == 'sport-dark',
                  onTap: () => store.setPref('theme', 'sport-dark'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _ThemeCard(
                  t: t,
                  id: AppThemeId.clean,
                  label: 'Clean',
                  sub: 'Clair, sobre',
                  active: store.theme == 'clean',
                  onTap: () => store.setPref('theme', 'clean'),
                ),
              ),
            ],
          ),
        ),

        // Programme
        SectionLabel(t: t, text: 'Programme'),
        AppCard(
          t: t,
          padding: const EdgeInsets.all(16),
          child: _DateRow(
            t: t,
            label: 'Date de démarrage',
            value: store.startDate,
            onPick: (iso) => store.setStartDate(iso),
          ),
        ),

        // Units
        SectionLabel(t: t, text: 'Unités'),
        AppCard(
          t: t,
          padding: const EdgeInsets.all(6),
          child: Row(
            children: [
              Expanded(
                child: _OptionCard(
                  t: t,
                  label: 'Kilogrammes',
                  sub: 'kg',
                  active: store.unit == 'kg',
                  onTap: () => store.setPref('unit', 'kg'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _OptionCard(
                  t: t,
                  label: 'Livres',
                  sub: 'lbs',
                  active: store.unit == 'lbs',
                  onTap: () => store.setPref('unit', 'lbs'),
                ),
              ),
            ],
          ),
        ),

        // During session
        SectionLabel(t: t, text: 'Pendant la séance'),
        AppCard(
          t: t,
          padding: const EdgeInsets.all(4),
          child: Column(
            children: [
              _ToggleRow(
                t: t,
                label: 'Son de fin de repos',
                value: store.sound,
                onChanged: (v) => store.setPref('sound', v),
              ),
              _ToggleRow(
                t: t,
                label: 'Vibration',
                value: store.vibration,
                onChanged: (v) => store.setPref('vibration', v),
                last: true,
              ),
            ],
          ),
        ),

        // Data
        SectionLabel(t: t, text: 'Données'),
        AppCard(
          t: t,
          padding: const EdgeInsets.all(4),
          child: Column(
            children: [
              _ActionRow(
                t: t,
                icon: Icons.download,
                label: 'Exporter mes données (JSON)',
                onTap: () => _exportData(t, store),
              ),
              _ActionRow(
                t: t,
                icon: Icons.refresh,
                label: _resetConfirm
                    ? 'Confirmer la remise à zéro'
                    : 'Tout réinitialiser',
                danger: _resetConfirm,
                last: true,
                onTap: () {
                  if (_resetConfirm) {
                    store.reset();
                    setState(() => _resetConfirm = false);
                    widget.navigate(const AppRoute('home'));
                  } else {
                    setState(() => _resetConfirm = true);
                    Future.delayed(const Duration(seconds: 4), () {
                      if (mounted) setState(() => _resetConfirm = false);
                    });
                  }
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),
        Center(
          child: Text(
            SyncService.instance.isEnabled
                ? 'Données stockées localement + sauvegardées dans le cloud.'
                : 'Données stockées localement.\nConnecte-toi pour activer la sauvegarde cloud.',
            textAlign: TextAlign.center,
            style: t.body(12, color: t.textFaint, height: 1.5),
          ),
        ),
      ],
    );
  }

  void _exportData(AppTokens t, Store store) {
    final json = store.exportJSON();
    showAppSheet(
      context: context,
      t: t,
      builder: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Exporter mes données',
              style: t.display(22, weight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            'Copie ce JSON pour sauvegarder ta progression.',
            style: t.body(13, color: t.textMuted, height: 1.4),
          ),
          const SizedBox(height: 14),
          Container(
            constraints: const BoxConstraints(maxHeight: 260),
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: t.surface2,
              borderRadius: BorderRadius.circular(t.radiusSm),
              border: Border.all(color: t.border),
            ),
            child: SingleChildScrollView(
              child: SelectableText(json,
                  style: t.mono(11, weight: FontWeight.w400, color: t.text)),
            ),
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            t: t,
            label: 'Copier le JSON',
            icon: Icons.copy,
            full: true,
            onPressed: () {
              final messenger = ScaffoldMessenger.of(context);
              Clipboard.setData(ClipboardData(text: json));
              Navigator.of(ctx).pop();
              messenger.showSnackBar(
                SnackBar(
                  content: Text('Données copiées (${todayISO()})',
                      style: t.body(13, color: t.accentText)),
                  backgroundColor: t.accent,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SyncStatusRow extends StatefulWidget {
  final AppTokens t;
  const _SyncStatusRow({required this.t});

  @override
  State<_SyncStatusRow> createState() => _SyncStatusRowState();
}

class _SyncStatusRowState extends State<_SyncStatusRow> {
  late final SyncService _sync;

  @override
  void initState() {
    super.initState();
    _sync = SyncService.instance;
    _sync.addListener(_onSync);
  }

  @override
  void dispose() {
    _sync.removeListener(_onSync);
    super.dispose();
  }

  void _onSync() {
    if (mounted) setState(() {});
  }

  Future<void> _openAuth() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (ctx) => AuthScreen(onDone: () => Navigator.of(ctx).pop()),
    ));
    if (mounted) setState(() {});
  }

  Future<void> _logout() async {
    await _sync.signOut();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final configured = _sync.isConfigured;
    final signedIn = _sync.isSignedIn;
    final color = signedIn ? t.accent : t.textFaint;

    final String label;
    final String sub;
    if (!configured) {
      label = 'Sync cloud non configurée';
      sub = 'Aucune clé Supabase dans l\'app.';
    } else if (signedIn) {
      label = 'Connecté';
      sub = _sync.userEmail ?? 'Sauvegarde automatique activée.';
    } else {
      label = 'Sauvegarde tes données';
      sub = 'Connecte-toi pour synchroniser sur tous tes appareils.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: signedIn ? 0.18 : 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                signedIn
                    ? Icons.cloud_done_outlined
                    : Icons.cloud_off_outlined,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style:
                          t.body(14, weight: FontWeight.w600, color: t.text)),
                  const SizedBox(height: 2),
                  Text(sub,
                      style: t.body(12, color: t.textMuted, height: 1.3)),
                ],
              ),
            ),
          ],
        ),
        if (configured) ...[
          const SizedBox(height: 14),
          signedIn
              ? GhostButton(
                  t: t,
                  full: true,
                  icon: Icons.logout,
                  label: 'Se déconnecter',
                  onPressed: _logout,
                )
              : PrimaryButton(
                  t: t,
                  full: true,
                  icon: Icons.cloud_sync_outlined,
                  label: 'Se connecter / s\'inscrire',
                  onPressed: _openAuth,
                ),
        ],
      ],
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final AppTokens t;
  final AppThemeId id;
  final String label;
  final String sub;
  final bool active;
  final VoidCallback onTap;
  const _ThemeCard({
    required this.t,
    required this.id,
    required this.label,
    required this.sub,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final swatchBg = id == AppThemeId.sportDark
        ? const Color(0xFF0A0A0B)
        : const Color(0xFFFFFFFF);
    final swatchAccent = id == AppThemeId.sportDark
        ? const Color(0xFFC5FB45)
        : const Color(0xFF0F172A);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: active ? t.surface3 : t.surface2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? t.accent : t.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // swatch
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: swatchBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: t.border),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        bottom: 3,
                        right: 3,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: swatchAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(label,
                      style: t.body(13, weight: FontWeight.w700)),
                ),
                if (active)
                  Icon(Icons.check, size: 14, color: t.accent),
              ],
            ),
            const SizedBox(height: 4),
            Text(sub, style: t.body(11, color: t.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final AppTokens t;
  final String label;
  final String sub;
  final bool active;
  final VoidCallback onTap;
  const _OptionCard({
    required this.t,
    required this.label,
    required this.sub,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: active ? t.surface3 : t.surface2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? t.accent : t.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(label,
                      style: t.body(13, weight: FontWeight.w700)),
                ),
                if (active) Icon(Icons.check, size: 14, color: t.accent),
              ],
            ),
            const SizedBox(height: 4),
            Text(sub, style: t.mono(11, weight: FontWeight.w600, color: t.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final AppTokens t;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool last;
  const _ToggleRow({
    required this.t,
    required this.label,
    required this.value,
    required this.onChanged,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: t.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: t.body(14, weight: FontWeight.w500)),
          GestureDetector(
            onTap: () => onChanged(!value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 28,
              decoration: BoxDecoration(
                color: value ? t.success : t.borderStrong,
                borderRadius: BorderRadius.circular(999),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment:
                    value ? Alignment.centerRight : Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(color: Color(0x33000000), blurRadius: 3, offset: Offset(0, 1)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final AppTokens t;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;
  final bool last;
  const _ActionRow({
    required this.t,
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? t.danger : t.text;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: last ? null : Border(bottom: BorderSide(color: t.border)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 10),
                Text(label, style: t.body(14, weight: FontWeight.w500, color: color)),
              ],
            ),
            Icon(Icons.arrow_forward, size: 14, color: color),
          ],
        ),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  final AppTokens t;
  final String label;
  final String? value;
  final ValueChanged<String> onPick;
  const _DateRow({
    required this.t,
    required this.label,
    required this.value,
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
            final initial =
                value != null ? DateTime.parse(value!) : DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: initial,
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
            if (picked != null) onPick(isoDate(picked));
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: t.surface2,
              borderRadius: BorderRadius.circular(t.radiusSm),
              border: Border.all(color: t.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value ?? 'Non défini',
                    style: t.body(16,
                        color: value != null ? t.text : t.textFaint)),
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
