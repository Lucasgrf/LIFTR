import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Active theme mode preference for LIFTR (Dark-first by default).
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);

/// Allows toggling a discrete offline preview banner in Settings without
/// affecting real connectivity detection.
final simulatedOfflineProvider = StateProvider<bool>((ref) => false);
