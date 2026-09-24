import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_avatar.dart';
import 'app_card.dart';

class ClinicCard extends StatelessWidget {
  const ClinicCard({super.key, required this.name, required this.location});
  final String name;
  final String location;

  @override
  Widget build(BuildContext context) => AppCard(
        child: Row(children: [
          const AppAvatar(initials: 'ع', size: 48, backgroundColor: AppColors.sky),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: Theme.of(context).textTheme.titleMedium),
            Text(location, style: Theme.of(context).textTheme.bodyMedium),
          ])),
          const Icon(Icons.chevron_left, color: AppColors.muted),
        ]),
      );
}
