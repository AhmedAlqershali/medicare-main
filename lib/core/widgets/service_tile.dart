import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ServiceTile extends StatelessWidget {
  const ServiceTile({super.key, required this.label, required this.icon, required this.color, required this.onTap});
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tileColor = color == AppColors.mint
        ? colors.primaryContainer
        : color == AppColors.sky
            ? colors.secondaryContainer
            : color == AppColors.peach
                ? colors.tertiaryContainer
                : color;
    return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: double.infinity,
          child: Column(children: [
            Container(height: 56, width: 56, decoration: BoxDecoration(color: tileColor, borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: colors.primary, size: 25)),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.onSurface, fontWeight: FontWeight.w600)),
          ]),
        ),
      );
  }
}
