import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, this.color});
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final badgeColor = switch (color) {
      null || AppColors.success => colors.tertiary,
      AppColors.warning => Theme.of(context).brightness == Brightness.dark ? AppColors.darkWarning : AppColors.warning,
      AppColors.muted => colors.onSurfaceVariant,
      AppColors.primaryDark => colors.secondary,
      AppColors.error => colors.error,
      _ => color!,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: badgeColor.withValues(alpha: .12), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}