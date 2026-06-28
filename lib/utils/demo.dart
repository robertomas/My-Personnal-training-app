// Ouvre une recherche vidéo de démonstration pour un exercice.
// Pas d'assets embarqués : on pointe vers YouTube (vraies vidéos de technique).

import 'package:url_launcher/url_launcher.dart';

/// Nettoie le nom d'exercice pour une bonne requête (retire les parenthèses
/// type "(machine)", "(câble)" et garde l'essentiel).
String _cleanName(String name) {
  var n = name.replaceAll(RegExp(r'\([^)]*\)'), ' ');
  n = n.replaceAll(RegExp(r'\s+'), ' ').trim();
  return n;
}

Uri demoSearchUri(String exerciseName) {
  final q = Uri.encodeQueryComponent(
      '${_cleanName(exerciseName)} technique exercice musculation');
  return Uri.parse('https://www.youtube.com/results?search_query=$q');
}

Future<bool> openExerciseDemo(String exerciseName) async {
  final uri = demoSearchUri(exerciseName);
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
