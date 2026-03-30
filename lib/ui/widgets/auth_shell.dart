import 'package:flutter/material.dart';

import 'package:sante_app/core/constants/app_colors.dart';
import 'package:sante_app/ui/widgets/app_logo.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.showLogo = true,
    this.headerPadding = const EdgeInsets.fromLTRB(24, 28, 24, 36),
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool showLogo;
  final EdgeInsets headerPadding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: headerPadding,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.blue900, Color(0xFF0D3460)],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showLogo) ...[
                    Row(
                      children: [
                        const AppLogo(
                          size: 40,
                          borderRadius: 12,
                          backgroundColor: Colors.transparent,
                          padding: EdgeInsets.zero,
                        ),
                        const SizedBox(width: 10),
                        RichText(
                          text: TextSpan(
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                            children: const [
                              TextSpan(text: 'Medi'),
                              TextSpan(
                                text: 'Remind',
                                style: TextStyle(color: AppColors.blue300),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              child: SafeArea(
                top: false,
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthTabs extends StatelessWidget {
  const AuthTabs({
    super.key,
    required this.selectedIndex,
    required this.onLoginTap,
    required this.onRegisterTap,
  });

  final int selectedIndex;
  final VoidCallback onLoginTap;
  final VoidCallback onRegisterTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _TabButton(
            label: 'Connexion',
            selected: selectedIndex == 0,
            onTap: onLoginTap,
          ),
          _TabButton(
            label: 'Inscription',
            selected: selectedIndex == 1,
            onTap: onRegisterTap,
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: selected ? AppColors.blue700 : AppColors.gray400,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    );
  }
}

class AuthInput extends StatelessWidget {
  const AuthInput({
    super.key,
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.gray600,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class InlineBanner extends StatelessWidget {
  const InlineBanner.error(this.text, {super.key})
      : background = const Color(0xFFFEF2F2),
        border = const Color(0xFFFECACA),
        foreground = AppColors.red,
        icon = '!';

  const InlineBanner.info(this.text, {super.key})
      : background = AppColors.blue50,
        border = AppColors.blue100,
        foreground = AppColors.blue700,
        icon = 'i';

  final String text;
  final Color background;
  final Color border;
  final Color foreground;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            icon,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

