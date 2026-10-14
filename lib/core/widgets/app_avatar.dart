import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({super.key, required this.initials, this.name, this.size = 48, this.backgroundColor});
  final String initials;
  final String? name;
  final double size;
  final Color? backgroundColor;

  static String initialsForName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '').trim();
    final parts = cleaned.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    const titles = {'د', 'دكتور', 'الدكتور', 'دكتورة', 'الدكتورة', 'أستاذ', 'الأستاذ', 'Dr', 'Doctor'};
    while (parts.isNotEmpty && titles.contains(parts.first.replaceAll(RegExp(r'[.,،]'), ''))) {
      parts.removeAt(0);
    }
    if (parts.isEmpty) return '';
    String firstRune(String value) => String.fromCharCodes(value.runes.take(1));
    final first = firstRune(parts.first);
    return parts.length == 1 ? first : '$first ${firstRune(parts.last)}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (background, foreground) = switch (backgroundColor) {
      null || AppColors.mint => (colors.primaryContainer, colors.onPrimaryContainer),
      AppColors.sky => (colors.secondaryContainer, colors.onSecondaryContainer),
      AppColors.peach => (colors.tertiaryContainer, colors.onTertiaryContainer),
      final color => (color, AppColors.primaryDark),
    };
    final avatarInitials = name == null || name!.trim().isEmpty
      ? initialsForName(initials)
      : initialsForName(name!);
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: background,
      child: Text(
        avatarInitials,
        style: TextStyle(color: foreground, fontSize: size * .3, fontWeight: FontWeight.w800),
      ),
    );
  }
}