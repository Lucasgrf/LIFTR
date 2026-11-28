import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum LiftrIconName {
  back,
  chevron,
  settings,
  plus,
  check,
  close,
  play,
  reorder,
  share,
  message,
  copy,
  skip,
  more,
  today,
  todayFilled,
  training,
  trainingFilled,
  progress,
  progressFilled,
}

/// Uses the exact line drawings from `liftr-identidade-v3.html`.
class LiftrIcon extends StatelessWidget {
  const LiftrIcon(this.name, {super.key, this.size = 24, this.color});

  final LiftrIconName name;
  final double size;
  final Color? color;

  static const _paths = <LiftrIconName, String>{
    LiftrIconName.back: '<path d="M15 5l-7 7 7 7"/>',
    LiftrIconName.chevron: '<path d="M9 6l6 6-6 6"/>',
    LiftrIconName.settings:
        '<circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 00.3 1.8l.1.1a2 2 0 11-2.8 2.8l-.1-.1a1.7 1.7 0 00-1.8-.3 1.7 1.7 0 00-1 1.5V21a2 2 0 11-4 0v-.1a1.7 1.7 0 00-1.1-1.5 1.7 1.7 0 00-1.8.3l-.1.1a2 2 0 11-2.8-2.8l.1-.1a1.7 1.7 0 00.3-1.8 1.7 1.7 0 00-1.5-1H3a2 2 0 110-4h.1a1.7 1.7 0 001.5-1.1 1.7 1.7 0 00-.3-1.8l-.1-.1a2 2 0 112.8-2.8l.1.1a1.7 1.7 0 001.8.3H9a1.7 1.7 0 001-1.5V3a2 2 0 114 0v.1a1.7 1.7 0 001 1.5 1.7 1.7 0 001.8-.3l.1-.1a2 2 0 112.8 2.8l-.1.1a1.7 1.7 0 00.3 1.8V9a1.7 1.7 0 001.5 1H21a2 2 0 110 4h-.1a1.7 1.7 0 00-1.5 1z"/>',
    LiftrIconName.plus: '<path d="M12 5v14M5 12h14"/>',
    LiftrIconName.check: '<path d="M5 12.5l4.5 4.5L19 7.5"/>',
    LiftrIconName.close: '<path d="M6 6l12 12M18 6L6 18"/>',
    LiftrIconName.play:
        '<path d="M7.5 5.2v13.6a.6.6 0 00.9.5l10.6-6.8a.6.6 0 000-1L8.4 4.7a.6.6 0 00-.9.5z" fill="currentColor" stroke="none"/>',
    LiftrIconName.reorder: '<path d="M5 9h14M5 15h14"/>',
    LiftrIconName.share:
        '<circle cx="18" cy="5.5" r="2.5"/><circle cx="6" cy="12" r="2.5"/><circle cx="18" cy="18.5" r="2.5"/><path d="M8.2 10.8l7.6-4.1M8.2 13.2l7.6 4.1"/>',
    LiftrIconName.message:
        '<path d="M4 19.5l1.3-3.9A8 8 0 1112 20a8 8 0 01-3.9-1z"/>',
    LiftrIconName.copy:
        '<rect x="8.5" y="8.5" width="11" height="11" rx="2.5"/><path d="M15.5 8.5V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7.5a2 2 0 002 2h2.5"/>',
    LiftrIconName.skip: '<path d="M6 6l8 6-8 6zM18 6v12"/>',
    LiftrIconName.more:
        '<circle cx="12" cy="5.5" r="1.2" fill="currentColor"/><circle cx="12" cy="12" r="1.2" fill="currentColor"/><circle cx="12" cy="18.5" r="1.2" fill="currentColor"/>',
    LiftrIconName.today:
        '<rect x="4.5" y="3.5" width="15" height="17" rx="1.5"/><path d="M8 8.5h8M8 12h8M8 15.5h5"/>',
    LiftrIconName.todayFilled:
        '<path fill="currentColor" stroke="none" fill-rule="evenodd" d="M5.5 3h13A1.5 1.5 0 0120 4.5v15a1.5 1.5 0 01-1.5 1.5h-13A1.5 1.5 0 014 19.5v-15A1.5 1.5 0 015.5 3zM8 7.75a.75.75 0 000 1.5h8a.75.75 0 000-1.5zm0 3.5a.75.75 0 000 1.5h8a.75.75 0 000-1.5zm0 3.5a.75.75 0 000 1.5h5a.75.75 0 000-1.5z"/>',
    LiftrIconName.training:
        '<rect x="3.5" y="7.5" width="17" height="13" rx="1.5"/><path d="M5.5 5h13M7.5 2.75h9"/>',
    LiftrIconName.trainingFilled:
        '<rect x="3" y="7" width="18" height="14" rx="1.6" fill="currentColor" stroke="none"/><path d="M5.5 4.75h13M7.5 2.5h9" stroke="currentColor" stroke-width="1.8" fill="none"/>',
    LiftrIconName.progress: '<path d="M3.5 19.5l5-2.3v-4l5-2.3v-4l7-3.2"/>',
    LiftrIconName.progressFilled:
        '<path d="M3.5 19.5l5-2.3v-4l5-2.3v-4l7-3.2" stroke-width="2.6"/>',
  };

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? IconTheme.of(context).color ?? Colors.black;
    final svg =
        '<svg xmlns="http://www.w3.org/2000/svg" '
        'width="$size" height="$size" viewBox="0 0 24 24" '
        'fill="none" stroke="currentColor" stroke-width="1.5" '
        'stroke-linecap="round" stroke-linejoin="round">'
        '${_paths[name]}</svg>';
    return SvgPicture.string(
      svg,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
      semanticsLabel: null,
    );
  }
}
