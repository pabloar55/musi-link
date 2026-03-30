import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Reports a non-fatal error to Firebase Crashlytics.
/// Silently ignores failures when Crashlytics is unavailable (e.g., in tests).
Future<void> reportError(Object error, StackTrace stack) async {
  try {
    await FirebaseCrashlytics.instance.recordError(error, stack);
  } catch (_) {}
}
