// === Écran de connexion / inscription ===
// Connexion email + mot de passe via Supabase (vraie sync multi-appareils).
// Accessible depuis Réglages > Compte. Peut être fermé (on garde le local).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../store/store.dart';
import '../sync/sync_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/sheet.dart';

class AuthScreen extends StatefulWidget {
  /// Appelé après connexion/inscription réussie (pour fermer l'écran).
  final VoidCallback onDone;
  const AuthScreen({super.key, required this.onDone});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isSignUp = false;
  bool _loading = false;
  String? _error;
  String? _info;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    setState(() {
      _error = null;
      _info = null;
    });
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Entre une adresse email valide.');
      return;
    }
    if (pass.length < 6) {
      setState(() => _error = 'Mot de passe : 6 caractères minimum.');
      return;
    }
    setState(() => _loading = true);

    final sync = SyncService.instance;
    final res = _isSignUp
        ? await sync.signUp(email, pass)
        : await sync.signIn(email, pass);

    if (!mounted) return;
    setState(() => _loading = false);

    if (!res.ok) {
      setState(() => _error = res.message);
      return;
    }

    // Inscription qui nécessite confirmation email -> on reste sur l'écran.
    if (res.needsEmailConfirm) {
      setState(() {
        _info = res.message;
        _isSignUp = false; // bascule vers connexion pour après confirmation
      });
      return;
    }

    // Connecté : on tire les données cloud puis on ferme.
    if (sync.isSignedIn) {
      await context.read<Store>().onSignedIn();
      if (!mounted) return;
      widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<Store>();
    final t = AppTokens.of(AppThemeIdX.fromKey(store.theme));

    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
              children: [
                // Close
                Align(
                  alignment: Alignment.centerLeft,
                  child: HeaderAction(
                    t: t,
                    icon: Icons.close,
                    label: 'Plus tard',
                    onPressed: widget.onDone,
                  ),
                ),
                const SizedBox(height: 32),

                // Logo mark
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: t.accent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.cloud_sync_outlined,
                      color: t.accentText, size: 28),
                ),
                const SizedBox(height: 20),

                Text(
                  _isSignUp ? 'Créer un compte' : 'Se connecter',
                  style: t.display(28, weight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  _isSignUp
                      ? 'Sauvegarde ta progression dans le cloud et retrouve-la sur tous tes appareils.'
                      : 'Connecte-toi pour synchroniser ta progression.',
                  style: t.body(14, color: t.textMuted, height: 1.5),
                ),
                const SizedBox(height: 28),

                AppField(
                  t: t,
                  controller: _emailCtrl,
                  label: 'Email',
                  hint: 'toi@email.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                AppField(
                  t: t,
                  controller: _passCtrl,
                  label: 'Mot de passe',
                  hint: '••••••••',
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _loading ? null : _submit(),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => setState(() => _obscure = !_obscure),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        _obscure
                            ? 'Afficher le mot de passe'
                            : 'Masquer le mot de passe',
                        style: t.body(12, color: t.textMuted),
                      ),
                    ),
                  ),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 14),
                  _Banner(t: t, text: _error!, danger: true),
                ],
                if (_info != null) ...[
                  const SizedBox(height: 14),
                  _Banner(t: t, text: _info!, danger: false),
                ],

                const SizedBox(height: 24),
                _loading
                    ? Container(
                        height: 54,
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: t.accent,
                          ),
                        ),
                      )
                    : PrimaryButton(
                        t: t,
                        full: true,
                        label: _isSignUp ? 'Créer mon compte' : 'Se connecter',
                        onPressed: _submit,
                      ),

                const SizedBox(height: 18),
                Center(
                  child: GestureDetector(
                    onTap: _loading
                        ? null
                        : () => setState(() {
                              _isSignUp = !_isSignUp;
                              _error = null;
                              _info = null;
                            }),
                    child: RichText(
                      text: TextSpan(
                        style: t.body(13, color: t.textMuted),
                        children: [
                          TextSpan(
                              text: _isSignUp
                                  ? 'Déjà un compte ? '
                                  : 'Pas encore de compte ? '),
                          TextSpan(
                            text: _isSignUp ? 'Se connecter' : 'Créer un compte',
                            style: t.body(13,
                                weight: FontWeight.w700, color: t.accent),
                          ),
                        ],
                      ),
                    ),
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

class _Banner extends StatelessWidget {
  final AppTokens t;
  final String text;
  final bool danger;
  const _Banner({required this.t, required this.text, required this.danger});

  @override
  Widget build(BuildContext context) {
    final c = danger ? t.danger : t.success;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(t.radiusSm),
        border: Border.all(color: c.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(danger ? Icons.error_outline : Icons.check_circle_outline,
              size: 18, color: c),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: t.body(13, color: t.text, height: 1.4)),
          ),
        ],
      ),
    );
  }
}
