import 'dart:async';

import 'package:flutter/material.dart';

/// Leaf widget that renders and ticks elapsed workout duration (`mm:ss`)
/// independently so the parent [WorkoutSessionScreen] never rebuilds every
/// second.
class SessionElapsedText extends StatefulWidget {
  const SessionElapsedText({
    super.key,
    required this.startedAt,
    this.nowProvider,
    this.style,
  });

  final DateTime startedAt;
  final DateTime Function()? nowProvider;
  final TextStyle? style;

  /// Returns non-negative elapsed seconds from [startedAt] until [now].
  static int computeElapsedSeconds(DateTime startedAt, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final diff = reference.difference(startedAt).inSeconds;
    return diff < 0 ? 0 : diff;
  }

  /// Formats [totalSeconds] as `mm:ss`.
  static String formatElapsed(int totalSeconds) {
    final safe = totalSeconds < 0 ? 0 : totalSeconds;
    final m = safe ~/ 60;
    final s = safe % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  State<SessionElapsedText> createState() => _SessionElapsedTextState();
}

class _SessionElapsedTextState extends State<SessionElapsedText> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = SessionElapsedText.computeElapsedSeconds(
      widget.startedAt,
      now: widget.nowProvider?.call(),
    );
    return Text(
      SessionElapsedText.formatElapsed(elapsed),
      maxLines: 1,
      softWrap: false,
      style: widget.style,
    );
  }
}
