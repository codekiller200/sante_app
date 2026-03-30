import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:mediremind/core/constants/app_colors.dart';
import 'package:mediremind/core/constants/app_routes.dart';
import 'package:mediremind/services/alarm_guard_service.dart';
import 'package:mediremind/services/alarm_service.dart';
import 'package:mediremind/services/app_launch_service.dart';
import 'package:mediremind/widgets/app_logo.dart';

class AlarmSetupScreen extends StatefulWidget {
  const AlarmSetupScreen({
    super.key,
    this.isFirstLaunch = false,
  });

  final bool isFirstLaunch;

  @override
  State<AlarmSetupScreen> createState() => _AlarmSetupScreenState();
}

class _AlarmSetupScreenState extends State<AlarmSetupScreen>
    with WidgetsBindingObserver {
  AlarmGuardStatus? _status;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshStatus();
    }
  }

  Future<void> _refreshStatus() async {
    final status = await AlarmGuardService.loadStatus();
    if (!mounted) return;
    setState(() => _status = status);
  }

  Future<void> _runAction(Future<bool> Function() action) async {
    setState(() => _busy = true);
    final opened = await action();
    if (!mounted) return;

    setState(() => _busy = false);
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d ouvrir ce reglage sur cet appareil.'),
        ),
      );
    }
  }

  Future<void> _activateRecommendedSettings() async {
    setState(() => _busy = true);
    await AlarmGuardService.requestRecommendedPermissions();
    await _refreshStatus();
    if (!mounted) return;
    setState(() => _busy = false);
  }

  Future<void> _finishSetup() async {
    if (widget.isFirstLaunch) {
      await AppLaunchService.markFirstLaunchHandled();
    }
    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            children: [
              Center(
                child: Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  alignment: Alignment.center,
                  child: const AppLogo(
                    size: 60,
                    borderRadius: 18,
                    backgroundColor: Colors.transparent,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Pour que vos alarmes sonnent vraiment',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Sur certains telephones Android, les rappels peuvent etre bloques si l application est optimisee par la batterie ou consideree comme inactive.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.white70, height: 1.45),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatusTile(
                      icon: Icons.notifications_active_outlined,
                      title: 'Notifications',
                      subtitle: 'Necessaires pour les rappels et alertes',
                      enabled: status?.notificationsGranted ?? false,
                    ),
                    const Divider(height: 20),
                    _StatusTile(
                      icon: Icons.alarm_on_outlined,
                      title: 'Alarmes exactes',
                      subtitle: 'Permet de declencher a l heure prevue',
                      enabled: status?.exactAlarmGranted ?? false,
                    ),
                    const Divider(height: 20),
                    _StatusTile(
                      icon: Icons.battery_charging_full_outlined,
                      title: 'Optimisation batterie',
                      subtitle: 'Aide Android a laisser l alarme se lancer',
                      enabled: status?.ignoringBatteryOptimizations ?? false,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _busy ? null : _activateRecommendedSettings,
                        icon: const Icon(Icons.shield_outlined),
                        label: const Text('Activer les autorisations recommandees'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _busy
                            ? null
                            : () => _runAction(
                                  AlarmService.instance.demanderIgnorerOptimisationsBatterie,
                                ),
                        icon: const Icon(Icons.battery_saver_outlined),
                        label: const Text('Ignorer les optimisations de batterie'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _busy
                            ? null
                            : () => _runAction(
                                  AlarmService.instance.ouvrirParametresAlarme,
                                ),
                        icon: const Icon(Icons.alarm_outlined),
                        label: const Text('Autoriser les alarmes exactes'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _busy
                            ? null
                            : () => _runAction(
                                  AlarmService.instance.ouvrirParametresArrierePlan,
                                ),
                        icon: const Icon(Icons.open_in_new_outlined),
                        label: const Text('Autoriser fonctionnement en arriere-plan'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: _busy
                            ? null
                            : () => _runAction(
                                  AlarmService.instance.ouvrirParametresBatterie,
                                ),
                        child: const Text('Ouvrir les reglages batterie et optimisation'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                ),
                child: Text(
                  'Conseil: si votre telephone propose aussi "Applications inutilisees", "Lancer en arriere-plan" ou "Demarrage automatique", autorisez MediRemind.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white, height: 1.45),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _busy ? null : _finishSetup,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.blue900,
                  ),
                  child: Text(
                    widget.isFirstLaunch
                        ? 'Continuer vers l application'
                        : 'Retour a l accueil',
                  ),
                ),
              ),
              if (_busy) ...[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator(color: Colors.white)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? AppColors.green : AppColors.orange;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Icon(
          enabled ? Icons.check_circle : Icons.error_outline,
          color: color,
        ),
      ],
    );
  }
}
