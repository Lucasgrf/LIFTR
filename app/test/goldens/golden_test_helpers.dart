import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personal_fitness_os/core/providers/clock_provider.dart';
import 'package:personal_fitness_os/core/storage/shared_preferences_provider.dart';
import 'package:personal_fitness_os/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

final kFixedGoldenNow = DateTime(2026, 11, 20, 18, 42, 15);

bool _fontsLoaded = false;

Future<ByteData> _loadFileBytes(String relativePath) async {
  final direct = File(relativePath);
  final file = direct.existsSync() ? direct : File('app/$relativePath');
  final bytes = await file.readAsBytes();
  return ByteData.sublistView(bytes);
}

Future<void> _loadMaterialIconsIfAvailable() async {
  final exe = File(Platform.resolvedExecutable);
  // Traverse up from .../bin/cache/dart-sdk/bin/dart to find bin/cache/artifacts/material_fonts/
  var dir = exe.parent;
  for (var i = 0; i < 6; i++) {
    final candidate = File(
      '${dir.path}/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    );
    if (candidate.existsSync()) {
      final loader = FontLoader('MaterialIcons');
      final bytes = await candidate.readAsBytes();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
      await loader.load();
      return;
    }
    final directCandidate = File(
      '${dir.path}/artifacts/material_fonts/MaterialIcons-Regular.otf',
    );
    if (directCandidate.existsSync()) {
      final loader = FontLoader('MaterialIcons');
      final bytes = await directCandidate.readAsBytes();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
      await loader.load();
      return;
    }
    dir = dir.parent;
  }
}

Future<SharedPreferences> initializeGoldenTest() async {
  if (!_fontsLoaded) {
    final geistLoader = FontLoader('Geist')
      ..addFont(_loadFileBytes('assets/fonts/Geist-Regular.ttf'))
      ..addFont(_loadFileBytes('assets/fonts/Geist-Medium.ttf'))
      ..addFont(_loadFileBytes('assets/fonts/Geist-SemiBold.ttf'))
      ..addFont(_loadFileBytes('assets/fonts/Geist-Bold.ttf'));
    await geistLoader.load();
    await _loadMaterialIconsIfAvailable();
    _fontsLoaded = true;
  }
  await initializeDateFormatting('pt_BR', null);
  SharedPreferences.setMockInitialValues({});
  return SharedPreferences.getInstance();
}

Future<void> pumpGoldenWidget(
  WidgetTester tester, {
  required Widget child,
  required ThemeMode themeMode,
  required SharedPreferences prefs,
  double width = 375,
  double height = 812,
  List<Override> overrides = const [],
  bool settle = true,
}) async {
  const dpr = 2.0;
  tester.view.physicalSize = Size(width * dpr, height * dpr);
  tester.view.devicePixelRatio = dpr;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appClockProvider.overrideWithValue(() => kFixedGoldenNow),
        ...overrides,
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        builder: (ctx, c) => MediaQuery(
          data: MediaQuery.of(ctx).copyWith(disableAnimations: true),
          child: c!,
        ),
        home: child,
      ),
    ),
  );

  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }
}
