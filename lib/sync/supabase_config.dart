// === Configuration Supabase ===
// Sync cloud (sauvegarde + multi-appareils) via Supabase.
//
// Les credentials NE SONT PAS hardcodés ici (repo public).
// Ils sont injectés au moment du build via --dart-define :
//
//   flutter run \
//     --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
//     --dart-define=SUPABASE_ANON_KEY=sb_publishable_xxxxx
//
//   flutter build apk --release \
//     --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
//     --dart-define=SUPABASE_ANON_KEY=sb_publishable_xxxxx
//
// Astuce : mets ces deux lignes dans un fichier local NON commité
// (ex: env.sh) et source-le avant de builder.
//
// La clé attendue est une "publishable key" (sb_publishable_...) :
// conçue pour être embarquée côté client. La sécurité repose sur les
// Row Level Security policies, PAS sur le secret de la clé.
// Ne JAMAIS utiliser ici : mot de passe DB, clé service_role / secret.
//
// --- SQL à exécuter dans Supabase (SQL Editor) ---
//
//   create table if not exists public.user_state (
//     id uuid primary key references auth.users(id) on delete cascade,
//     data jsonb not null default '{}'::jsonb,
//     updated_at timestamptz not null default now()
//   );
//   alter table public.user_state enable row level security;
//   create policy "own_row_select" on public.user_state
//     for select using (auth.uid() = id);
//   create policy "own_row_insert" on public.user_state
//     for insert with check (auth.uid() = id);
//   create policy "own_row_update" on public.user_state
//     for update using (auth.uid() = id);
//
class SupabaseConfig {
  /// URL du projet (injectée via --dart-define=SUPABASE_URL=...).
  static const String url =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');

  /// Clé publishable (injectée via --dart-define=SUPABASE_ANON_KEY=...).
  static const String anonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  /// True si les deux champs sont renseignés.
  /// Si vide, l'app fonctionne en 100% local (sync désactivée).
  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
