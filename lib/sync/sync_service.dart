// === Service de synchronisation cloud (Supabase) ===
// Auth email/mot de passe -> vraie sync multi-appareils.
// Si Supabase n'est pas configuré (voir supabase_config.dart), tout est
// no-op et l'app fonctionne 100% en local.
//
// Stratégie : "last write wins" sur l'état complet (un JSON par user,
// table user_state, clé = auth.uid()).

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

enum SyncStatus { disabled, idle, syncing, error }

/// Résultat d'une opération d'auth, avec message FR prêt à afficher.
class AuthResult {
  final bool ok;
  final String? message; // message à montrer (succès info ou erreur)
  final bool needsEmailConfirm; // true si l'utilisateur doit confirmer son email
  const AuthResult(this.ok, {this.message, this.needsEmailConfirm = false});
}

class SyncService extends ChangeNotifier {
  SyncService._();
  static final SyncService instance = SyncService._();

  bool _initialized = false;
  SyncStatus status = SyncStatus.disabled;
  String? lastError;
  DateTime? lastSyncedAt;

  /// Configuré ET initialisé (Supabase prêt).
  bool get isConfigured => SupabaseConfig.isConfigured && _initialized;

  /// Sync réellement active = configuré + utilisateur connecté.
  bool get isEnabled => isConfigured && isSignedIn;

  bool get isSignedIn => _client?.auth.currentUser != null;
  String? get userEmail => _client?.auth.currentUser?.email;

  SupabaseClient? get _client =>
      _initialized ? Supabase.instance.client : null;

  String? get _userId => _client?.auth.currentUser?.id;

  /// À appeler dans main() avant runApp. No-op si non configuré.
  Future<void> init() async {
    if (!SupabaseConfig.isConfigured) {
      status = SyncStatus.disabled;
      return;
    }
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        // Nouveau format de clé Supabase (sb_publishable_...).
        publishableKey: SupabaseConfig.anonKey,
      );
      _initialized = true;
      status = isSignedIn ? SyncStatus.idle : SyncStatus.idle;
      // Notifie l'UI à chaque changement d'auth (login/logout/refresh).
      _client?.auth.onAuthStateChange.listen((_) => notifyListeners());
    } catch (e) {
      _initialized = false;
      status = SyncStatus.error;
      lastError = e.toString();
      debugPrint('SyncService: init failed ($e)');
    }
  }

  // ---------- Auth ----------

  /// Inscription email/mot de passe.
  Future<AuthResult> signUp(String email, String password) async {
    final client = _client;
    if (client == null) {
      return const AuthResult(false, message: 'Sync non configurée.');
    }
    try {
      final res = await client.auth.signUp(
        email: email.trim(),
        password: password,
      );
      // Si confirmation requise : session null mais user créé.
      if (res.session == null && res.user != null) {
        return const AuthResult(true,
            message:
                'Compte créé. Vérifie ta boîte mail pour confirmer ton adresse, puis connecte-toi.',
            needsEmailConfirm: true);
      }
      notifyListeners();
      return const AuthResult(true, message: 'Compte créé et connecté.');
    } on AuthException catch (e) {
      return AuthResult(false, message: _frError(e.message));
    } catch (e) {
      return AuthResult(false, message: _frError(e.toString()));
    }
  }

  /// Connexion email/mot de passe.
  Future<AuthResult> signIn(String email, String password) async {
    final client = _client;
    if (client == null) {
      return const AuthResult(false, message: 'Sync non configurée.');
    }
    try {
      await client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      notifyListeners();
      return const AuthResult(true, message: 'Connecté.');
    } on AuthException catch (e) {
      return AuthResult(false, message: _frError(e.message));
    } catch (e) {
      return AuthResult(false, message: _frError(e.toString()));
    }
  }

  /// Déconnexion (les données locales restent sur l'appareil).
  Future<void> signOut() async {
    try {
      await _client?.auth.signOut();
    } catch (e) {
      debugPrint('SyncService: signOut failed ($e)');
    }
    notifyListeners();
  }

  /// Renvoie l'email de confirmation.
  Future<AuthResult> resendConfirmation(String email) async {
    final client = _client;
    if (client == null) {
      return const AuthResult(false, message: 'Sync non configurée.');
    }
    try {
      await client.auth.resend(type: OtpType.signup, email: email.trim());
      return const AuthResult(true, message: 'Email de confirmation renvoyé.');
    } catch (e) {
      return AuthResult(false, message: _frError(e.toString()));
    }
  }

  // ---------- Sync ----------

  /// Envoie l'état complet vers le cloud (upsert). No-op si pas connecté.
  Future<void> push(Map<String, dynamic> data) async {
    final client = _client;
    final uid = _userId;
    if (client == null || uid == null) return;
    status = SyncStatus.syncing;
    notifyListeners();
    try {
      await client.from('user_state').upsert({
        'id': uid,
        'data': data,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
      lastSyncedAt = DateTime.now();
      status = SyncStatus.idle;
      lastError = null;
    } catch (e) {
      status = SyncStatus.error;
      lastError = e.toString();
      debugPrint('SyncService: push failed ($e)');
    }
    notifyListeners();
  }

  /// Récupère l'état distant. Renvoie null si rien / pas connecté / erreur.
  Future<Map<String, dynamic>?> pull() async {
    final client = _client;
    final uid = _userId;
    if (client == null || uid == null) return null;
    status = SyncStatus.syncing;
    notifyListeners();
    try {
      final row = await client
          .from('user_state')
          .select('data')
          .eq('id', uid)
          .maybeSingle();
      status = SyncStatus.idle;
      lastError = null;
      notifyListeners();
      if (row == null) return null;
      final data = row['data'];
      if (data is Map) return Map<String, dynamic>.from(data);
      return null;
    } catch (e) {
      status = SyncStatus.error;
      lastError = e.toString();
      debugPrint('SyncService: pull failed ($e)');
      notifyListeners();
      return null;
    }
  }

  // Traduit les erreurs Supabase courantes en français.
  String _frError(String raw) {
    final m = raw.toLowerCase();
    if (m.contains('invalid login') || m.contains('invalid credentials')) {
      return 'Email ou mot de passe incorrect.';
    }
    if (m.contains('email not confirmed')) {
      return 'Email pas encore confirmé. Vérifie ta boîte mail.';
    }
    if (m.contains('already registered') ||
        m.contains('already been registered') ||
        m.contains('user already')) {
      return 'Cet email est déjà utilisé. Connecte-toi.';
    }
    if (m.contains('password') && m.contains('6')) {
      return 'Mot de passe trop court (6 caractères minimum).';
    }
    if (m.contains('invalid') && m.contains('email')) {
      return 'Adresse email invalide.';
    }
    if (m.contains('network') || m.contains('failed host')) {
      return 'Pas de connexion internet.';
    }
    return 'Erreur : $raw';
  }
}
