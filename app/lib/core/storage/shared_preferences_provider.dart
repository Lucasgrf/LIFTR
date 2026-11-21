import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Overridden in `main()` with a loaded [SharedPreferences] instance.
/// Remains `null` in isolated widget tests unless explicitly overridden.
final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) => null);
