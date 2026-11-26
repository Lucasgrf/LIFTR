import 'package:flutter/material.dart';

/// Responsive container enforcing mobile padding (16dp on <= 375dp, 20dp
/// above 375dp) and centering content at 560dp maxWidth on tablets (>= 600dp).
class ResponsiveContainer extends StatelessWidget {
  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = 560,
    this.padding,
    this.heightFactor,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final double? heightFactor;

  static double horizontalPaddingForWidth(double width) {
    if (width <= 375) return 16;
    return 20;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = horizontalPaddingForWidth(width);

    return Align(
      alignment: Alignment.topCenter,
      heightFactor: heightFactor,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ?? EdgeInsets.symmetric(horizontal: horizontal),
          child: child,
        ),
      ),
    );
  }
}
