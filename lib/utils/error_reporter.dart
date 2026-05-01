import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Reports a non-fatal error to Firebase Crashlytics.
/// Silently ignores failures when Crashlytics is unavailable (e.g., in tests).
Future<void> reportError(Object error, StackTrace stack) async {
  try {
    await FirebaseCrashlytics.instance.recordError(error, stack);
  } catch (_) {}
}

/// Returns true when [e] looks like a transient network failure.
bool isNetworkError(Object e) {
  final msg = e.toString().toLowerCase();
  return msg.contains('socketexception') ||
      msg.contains('failed host lookup') ||
      msg.contains('network is unreachable') ||
      msg.contains('clientexception');
}
