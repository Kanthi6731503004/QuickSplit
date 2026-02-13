import 'package:flutter/material.dart';
import 'package:quicksplit/core/theme/app_theme.dart';

/// Responsive wrapper that constrains content width on tablets
/// and adjusts padding for different screen sizes.
class ResponsiveLayout extends StatelessWidget {
  final Widget child;
  final double? padding;

  const ResponsiveLayout({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final horizontalPadding =
            padding ?? AppTheme.getHorizontalPadding(width);
        final maxWidth = AppTheme.getMaxContentWidth(width);

        Widget content = Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: child,
        );

        if (maxWidth != null) {
          content = Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: child,
            ),
          );
        }

        return content;
      },
    );
  }
}
