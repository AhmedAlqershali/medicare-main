import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, color: AppColors.primary, size: 19),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text('$label: ', style: Theme.of(context).textTheme.bodyMedium),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w700))),
        ],
      );
}
