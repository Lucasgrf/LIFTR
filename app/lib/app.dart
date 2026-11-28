import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/core/theme/app_theme.dart';
import 'package:personal_fitness_os/core/theme/theme_provider.dart';
import 'package:personal_fitness_os/core/widgets/liftr_brand_mark.dart';
import 'package:personal_fitness_os/routing/app_router.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  bool _showSplash = true;

  @override
  Widget build(BuildContext context) {
    final goRouter = ref.watch(goRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'LIFTR',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: goRouter,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final appMediaQuery = kIsWeb
            ? mediaQuery.copyWith(padding: mediaQuery.padding.copyWith(top: 24))
            : mediaQuery;
        return MediaQuery(
          data: appMediaQuery,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (child != null) child,
              if (_showSplash)
                Positioned.fill(
                  child: _LiftrStartupSplash(
                    onFinished: () {
                      if (mounted) setState(() => _showSplash = false);
                    },
                  ),
                ),
            ],
          ),
        );
      },
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],
    );
  }
}

class _LiftrStartupSplash extends StatefulWidget {
  const _LiftrStartupSplash({required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<_LiftrStartupSplash> createState() => _LiftrStartupSplashState();
}

class _LiftrStartupSplashState extends State<_LiftrStartupSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _dismissTimer;
  bool _didInitializeMotion = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitializeMotion) return;
    _didInitializeMotion = true;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    if (reducedMotion) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
    _dismissTimer = Timer(
      reducedMotion ? Duration.zero : const Duration(milliseconds: 980),
      widget.onFinished,
    );
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF17191E);
    const pen = Color(0xFF1C3FAA);
    return AbsorbPointer(
      child: Semantics(
        label: 'liftr',
        image: true,
        child: ColoredBox(
          color: const Color(0xFFF4F5F0),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) => CustomPaint(
                    size: const Size(120, 120),
                    painter: _RampRevealPainter(
                      progress: _controller.value,
                      ink: ink,
                      pen: pen,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const LiftrWordmarkOnly(height: 55),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RampRevealPainter extends CustomPainter {
  const _RampRevealPainter({
    required this.progress,
    required this.ink,
    required this.pen,
  });

  final double progress;
  final Color ink;
  final Color pen;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 48, size.height / 48);
    final rulePaint = Paint()
      ..color = ink.withValues(alpha: .14)
      ..strokeWidth = .6;
    for (final y in const [16.0, 24.0, 32.0, 40.0]) {
      canvas.drawLine(Offset(0, y), Offset(48, y), rulePaint);
    }
    final ramp = Path()
      ..moveTo(7, 39)
      ..lineTo(18, 34)
      ..lineTo(18, 26)
      ..lineTo(29, 21)
      ..lineTo(29, 13)
      ..lineTo(41, 8);
    final metric = ramp.computeMetrics().first;
    final rampPaint = Paint()
      ..color = pen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(metric.extractPath(0, metric.length * progress), rampPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RampRevealPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.ink != ink ||
      oldDelegate.pen != pen;
}
