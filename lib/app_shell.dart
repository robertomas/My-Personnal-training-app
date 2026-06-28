// Root shell: max-width 480 column, bottom nav (hidden on Session), routing.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'store/store.dart';
import 'theme/app_theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/session_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/progress_screen.dart';

/// Simple internal route descriptor.
class AppRoute {
  final String view; // home | calendar | settings | session
  final String? phaseId;
  final String? sessionId;
  const AppRoute(this.view, {this.phaseId, this.sessionId});
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppRoute _route = const AppRoute('home');
  final _scrollController = ScrollController();

  void navigate(AppRoute to) {
    setState(() => _route = to);
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<Store>();
    final t = AppTokens.of(AppThemeIdX.fromKey(store.theme));
    final view = _route.view;

    Widget screen;
    switch (view) {
      case 'session':
        screen = SessionScreen(
          key: ValueKey('session-${_route.phaseId}-${_route.sessionId}'),
          phaseId: _route.phaseId!,
          sessionId: _route.sessionId!,
          navigate: navigate,
        );
        break;
      case 'calendar':
        screen = CalendarScreen(navigate: navigate);
        break;
      case 'progress':
        screen = ProgressScreen(navigate: navigate);
        break;
      case 'settings':
        screen = SettingsScreen(navigate: navigate);
        break;
      default:
        screen = DashboardScreen(navigate: navigate);
    }

    final showNav = view == 'home' ||
        view == 'progress' ||
        view == 'calendar' ||
        view == 'settings';

    return Scaffold(
      backgroundColor: t.bg,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: DecoratedBox(
            decoration: BoxDecoration(color: t.bg),
            child: Stack(
              children: [
                Positioned.fill(child: SafeArea(bottom: false, child: screen)),
                if (showNav)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _BottomNav(
                      t: t,
                      active: view,
                      onTap: (v) => navigate(AppRoute(v)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final AppTokens t;
  final String active;
  final ValueChanged<String> onTap;
  const _BottomNav(
      {required this.t, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('home', 'Accueil', Icons.home_outlined),
      ('progress', 'Progrès', Icons.show_chart),
      ('calendar', 'Calendrier', Icons.calendar_today_outlined),
      ('settings', 'Réglages', Icons.settings_outlined),
    ];
    return ClipRect(
      child: Container(
        decoration: BoxDecoration(
          color: t.navBg,
          border: Border(top: BorderSide(color: t.border)),
        ),
        padding: EdgeInsets.only(
          top: 10,
          bottom: 10 + MediaQuery.of(context).padding.bottom,
        ),
        child: Row(
          children: items.map((it) {
            final isActive = active == it.$1;
            final color = isActive ? t.accent : t.textFaint;
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(it.$1),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(it.$3, size: 20, color: color),
                    const SizedBox(height: 4),
                    Text(
                      it.$2.toUpperCase(),
                      style: t.label(10, color: color, spacing: 0.6),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
