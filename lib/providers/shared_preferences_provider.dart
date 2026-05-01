import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences inyectado como provider para poder accederlo desde notifiers.
/// Se sobreescribe en main() antes de runApp con el valor real.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Must be overridden in main'),
);
