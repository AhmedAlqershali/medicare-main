import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({super.key, required this.initials, this.size = 48, this.backgroundColor = AppColors.mint});
  final String initials;
  final double size;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) => CircleAvatar(
        radius: size / 2,
        backgroundColor: backgroundColor,
        child: Text(initials, style: TextStyle(color: AppColors.primaryDark, fontSize: size * .3, fontWeight: FontWeight.w800)),
      );
}