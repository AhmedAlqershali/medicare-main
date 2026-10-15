import 'package:flutter/material.dart';

class RoleBottomNavigationBar extends StatelessWidget {
  const RoleBottomNavigationBar({super.key, required this.currentIndex, required this.onTap, required this.destinations});
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavigationDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      backgroundColor: colors.surface,
      elevation: 0,
      indicatorColor: colors.primaryContainer,
      height: 72,
      destinations: destinations,
    );
  }
}
