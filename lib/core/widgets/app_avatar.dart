import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({super.key, required this.initials, this.size = 48, this.backgroundColor});
  final String initials;
  final double size;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (background, foreground) = switch (backgroundColor) {
      null || AppColors.mint => (colors.primaryContainer, colors.onPrimaryContainer),
      AppColors.sky => (colors.secondaryContainer, colors.onSecondaryContainer),
      AppColors.peach => (colors.tertiaryContainer, colors.onTertiaryContainer),
      final color => (color, AppColors.primaryDark),
    };
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: background,
      child: Text(
        initials,
        style: TextStyle(color: foreground, fontSize: size * .3, fontWeight: FontWeight.w800),
      ),
    );
  }
}