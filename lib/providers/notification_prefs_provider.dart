import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musi_link/providers/shared_preferences_provider.dart';

const _kVibrationKey = 'notification_vibration';

class VibrationNotifier extends Notifier<bool> {
  @override
  bool build() {
    return ref.read(sharedPreferencesProvider).getBool(_kVibrationKey) ?? true;
  }

  void toggle() {
    state = !state;
    ref.read(sharedPreferencesProvider).setBool(_kVibrationKey, state);
  }
}

final vibrationEnabledProvider =
    NotifierProvider<VibrationNotifier, bool>(VibrationNotifier.new);
