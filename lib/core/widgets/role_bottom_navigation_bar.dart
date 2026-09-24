import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class RoleBottomNavigationBar extends StatelessWidget {
  const RoleBottomNavigationBar({super.key, required this.currentIndex, required this.onTap, required this.destinations});
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavigationDestination> destinations;

  @override
  Widget build(BuildContext context) => NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onTap,
        backgroundColor: Colors.white,
        elevation: 0,
        indicatorColor: AppColors.mint,
        height: 72,
        destinations: destinations,
      );
}
