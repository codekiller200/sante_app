import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:mediremind/core/constants/app_colors.dart';
import 'package:mediremind/core/constants/app_routes.dart';
import 'package:mediremind/services/app_launch_service.dart';
import 'package:mediremind/widgets/app_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runStartup());
  }

  Future<void> _runStartup() async {
    await Future<void>.delayed(const Duration(seconds: 2));

    final isFirstLaunch = await AppLaunchService.isFirstLaunch();
    if (isFirstLaunch && mounted) {
      context.go(AppRoutes.alarmSetup, extra: true);
      return;
    }

    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                  ),
                  alignment: Alignment.center,
                  child: const AppLogo(
                    size: 72,
                    borderRadius: 22,
                    backgroundColor: Colors.transparent,
                    padding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'MediRemind',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontSize: 30,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Suivi des traitements et rappels de prise',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 28),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
