// Conversion poids — le stockage est TOUJOURS en kg.
// L'affichage et la saisie se font dans l'unité choisie (kg | lbs).

const double _kgPerLb = 0.45359237;

/// kg stocké -> valeur affichée dans l'unité courante.
double toDisplay(double kg, String unit) =>
    unit == 'lbs' ? kg / _kgPerLb : kg;

/// valeur saisie dans l'unité courante -> kg pour le stockage.
double toKg(double value, String unit) =>
    unit == 'lbs' ? value * _kgPerLb : value;

/// Formatte un poids déjà exprimé dans l'unité d'affichage (sans suffixe).
String fmtWeight(double value, String unit) {
  // lbs : pas de décimale (les plaques sont en incréments). kg : 1 décimale si besoin.
  if (unit == 'lbs') return value.round().toString();
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
}

/// kg stocké -> chaîne affichée avec suffixe, ex "60kg" ou "132lbs".
String fmtWeightFromKg(double kg, String unit) =>
    '${fmtWeight(toDisplay(kg, unit), unit)}$unit';
