import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;
  final int currentIndex;

  const MainScaffold({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.gray200)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                _NavItem(icon: Icons.home_outlined,      activeIcon: Icons.home,           label: 'Accueil',      index: 0, current: currentIndex, route: AppRoutes.home),
                _NavItem(icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view,      label: 'Médicaments',  index: 1, current: currentIndex, route: AppRoutes.medicaments),
                _NavItem(icon: Icons.article_outlined,   activeIcon: Icons.article,        label: 'Journal',      index: 2, current: currentIndex, route: AppRoutes.journal),
                _NavItem(icon: Icons.person_outline,     activeIcon: Icons.person,         label: 'Profil',       index: 3, current: currentIndex, route: AppRoutes.profil),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int current;
  final String route;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.current,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => context.go(route),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppColors.blue700 : AppColors.gray400,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppColors.blue700 : AppColors.gray400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
