#!/usr/bin/env bash
# Template de configuration Supabase pour le build.
#
# 1. Copie ce fichier :  cp env.example.sh env.sh
# 2. Remplis tes valeurs (depuis ton dashboard Supabase : Settings > API)
# 3. Source-le avant de builder :  source env.sh
#
# env.sh est ignoré par git (voir .gitignore) — il ne sera jamais commité.

export SUPABASE_URL="https://VOTRE_PROJET.supabase.co"
export SUPABASE_ANON_KEY="sb_publishable_VOTRE_CLE_PUBLISHABLE"

# Exemple de build une fois les variables exportées :
#   flutter run \
#     --dart-define=SUPABASE_URL="$SUPABASE_URL" \
#     --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"
#
#   flutter build apk --release \
#     --dart-define=SUPABASE_URL="$SUPABASE_URL" \
#     --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"
