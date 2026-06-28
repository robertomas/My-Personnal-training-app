// Rest-timer completion feedback: two-tone beep + vibration, gated by prefs.
import 'package:flutter/services.dart';
import '../store/store.dart';

void playBeep(Store store) {
  if (!store.sound) return;
  // Web Audio isn't directly available; use the platform alert sound twice
  // to approximate the two-tone beep from the prototype.
  SystemSound.play(SystemSoundType.alert);
  Future.delayed(const Duration(milliseconds: 250), () {
    SystemSound.play(SystemSoundType.alert);
  });
}

void vibrate(Store store) {
  if (!store.vibration) return;
  // navigator.vibrate([200,80,200]) equivalent — heavy double pulse.
  HapticFeedback.heavyImpact();
  Future.delayed(const Duration(milliseconds: 280), () {
    HapticFeedback.heavyImpact();
  });
}
