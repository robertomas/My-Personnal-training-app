// French date helpers (no intl dependency needed).

const _dayShort = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];
const _dayFull = [
  'Dimanche',
  'Lundi',
  'Mardi',
  'Mercredi',
  'Jeudi',
  'Vendredi',
  'Samedi'
];
const _monthFull = [
  'janvier',
  'février',
  'mars',
  'avril',
  'mai',
  'juin',
  'juillet',
  'août',
  'septembre',
  'octobre',
  'novembre',
  'décembre'
];

// Dart weekday: Mon=1..Sun=7. JS getDay: Sun=0..Sat=6.
int jsDay(DateTime d) => d.weekday % 7;

String dayLabelFR(DateTime d) => _dayShort[jsDay(d)];
String fullDayLabelFR(DateTime d) => _dayFull[jsDay(d)];

String monthYearFR(DateTime d) => '${_monthFull[d.month - 1]} ${d.year}';

String _cap(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
String monthYearFRCapitalized(DateTime d) => _cap(monthYearFR(d));

String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String todayISO() => isoDate(DateTime.now());

String fmtTime(int s) {
  final m = s ~/ 60;
  final sec = s % 60;
  return '$m:${sec.toString().padLeft(2, '0')}';
}

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

const _monthShort = [
  'jan', 'fév', 'mar', 'avr', 'mai', 'jun',
  'jui', 'aoû', 'sep', 'oct', 'nov', 'déc'
];

// "12 jan" — étiquette compacte pour les axes de graphique.
String shortDateFR(DateTime d) => '${d.day} ${_monthShort[d.month - 1]}';
