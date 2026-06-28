# Programme 6 Mois — Lift Tracker

Application Flutter de suivi d'entraînement en salle pour un programme de 6 mois.
Compagnon mobile-first, en français, avec sync cloud optionnelle.

## Fonctionnalités

- **Programme structuré** : 3 phases × 4 séances (~96 exercices), enchaînement Upper A → Lower A → Upper B → Lower B
- **Suivi des séances** : log des séries (poids × reps), timer de repos avec wakelock (l'écran reste allumé)
- **Progression** : courbes de poids par exercice, volume hebdomadaire, suivi du poids de corps
- **Calendrier** des séances effectuées
- **2 thèmes** : Sport Dark (noir + lime, défaut) et Clean (clair)
- **Sync cloud (optionnelle)** : auth email/mot de passe via Supabase, sauvegarde et synchro multi-appareils
- **100% fonctionnel hors-ligne** : sans config Supabase, tout reste en local (`shared_preferences`)

## Stack

- Flutter 3.35.4 / Dart 3.9.2
- `provider` (state management)
- `shared_preferences` (persistance locale)
- `supabase_flutter` (sync cloud optionnelle)
- `fl_chart` (graphiques), `wakelock_plus`, `google_fonts`, `url_launcher`

## Configuration Supabase (optionnelle)

Les credentials ne sont **pas** dans le code. Ils sont injectés au build via `--dart-define`.

1. Crée un projet Supabase et exécute le SQL de création de table
   (voir `lib/sync/supabase_config.dart`).
2. Active l'auth Email dans le dashboard.
3. Configure tes variables :
   ```bash
   cp env.example.sh env.sh   # puis édite env.sh avec tes valeurs
   source env.sh
   ```

## Build

```bash
flutter pub get

# Lancer en local (avec sync cloud)
flutter run \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"

# APK release signé
flutter build apk --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"
```

> Sans les `--dart-define`, l'app compile et tourne très bien — la sync cloud
> est simplement désactivée et tout reste local.

## Signature Android

Le keystore (`android/release-key.jks`) et `android/key.properties` sont **exclus
du repo** (`.gitignore`). Génère les tiens pour produire un APK signé.

## Licence

Projet personnel.
