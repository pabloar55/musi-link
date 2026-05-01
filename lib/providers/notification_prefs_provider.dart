import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:musi_link/providers/shared_preferences_provider.dart';

const _kVibrationKey = 'notification_vibration';
const kAnalyticsEnabledKey = 'analytics_enabled';

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

final vibrationEnabledProvider = NotifierProvider<VibrationNotifier, bool>(
  VibrationNotifier.new,
);

class AnalyticsEnabledNotifier extends Notifier<bool> {
  @override
  bool build() {
    return ref.read(sharedPreferencesProvider).getBool(kAnalyticsEnabledKey) ??
        false;
  }

  Future<void> toggle() async {
    state = !state;
    await ref
        .read(sharedPreferencesProvider)
        .setBool(kAnalyticsEnabledKey, state);
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(state);
  }
}

final analyticsEnabledProvider =
    NotifierProvider<AnalyticsEnabledNotifier, bool>(
      AnalyticsEnabledNotifier.new,
    );
