import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../services/auth_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/alarm_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  double _progress = 0.0;
  bool _alarmDialogShown = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
    _startLoading();
  }

  Future<void> _startLoading() async {
    // Simulation du chargement progressif
    for (int i = 1; i <= 5; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) setState(() => _progress = i / 10);
    }

    // Demander les permissions de notification
    await _requestPermissions();

    // Reprendre le chargement
    for (int i = 6; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) setState(() => _progress = i / 10);
    }

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    // Redirection selon l'état de connexion
    final authService = context.read<AuthService>();
    if (authService.isLoggedIn) {
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.login);
    }
  }

  Future<void> _requestPermissions() async {
    final notificationService = NotificationService.instance;
    final granted = await notificationService.requestPermissions();

    if (!mounted) return;

    if (!granted) {
      _showNotificationPermissionDialog();
    } else {
      // Permissions accordées - vérifier si les alarmes exactes sont activées
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted && !_alarmDialogShown) {
        _showAlarmPermissionDialog();
      }
    }
  }

  void _showNotificationPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: true, // Permet à l'utilisateur de fermer
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('🔔', style: TextStyle(fontSize: 24)),
            SizedBox(width: 10),
            Text('Notifications'),
          ],
        ),
        content: const Text(
          'Pour recevoir vos rappels de médicaments à l\'heure, '
          'veuillex autoriser les notifications.\n\n'
          'Allez dans:\n'
          'Paramètres > Notifications > MediRemind > Autoriser',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showAlarmPermissionDialog();
            },
            child: const Text('Plus tard'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await NotificationService.instance.requestPermissions();
              if (mounted) {
                _showAlarmPermissionDialog();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Autoriser'),
          ),
        ],
      ),
    );
  }

  void _showAlarmPermissionDialog() {
    _alarmDialogShown = true;

    showDialog(
      context: context,
      barrierDismissible: true, // Permet à l'utilisateur de fermer lui-même
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('⏰', style: TextStyle(fontSize: 24)),
            SizedBox(width: 10),
            Text('Alarmes exactes'),
          ],
        ),
        content: const Text(
          'Pour que les rappels sonnent à l\'HEURE EXACTE, '
          'vous devez activer les alarmes exactes.\n\n'
          '📱 étapes à suivre:\n\n'
          '1. Ouvrez Paramètres Android\n'
          '2. Cherchez "Apps" ou "Applications"\n'
          '3. Trouvez MediRemind\n'
          '4. Appuyez sur "Permissions"\n'
          '5. Cherchez "Alarmes et minuteurs"\n'
          '6. Activez l\'autorisation\n\n'
          '⚠️ Cette autorisation est DIFFERENTE de la permission de notification!',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Envoyer notification test
              NotificationService.instance.afficherImmediatement(
                titre: '✅ Notifications prêtes',
                corps: 'Vous recevrez vos rappels de médicaments',
              );
            },
            child: const Text('Plus tard'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              // Copier les paramètres dans le presse-papier
              await Clipboard.setData(const ClipboardData(
                text:
                    'Paramètres > Apps > MediRemind > Permissions > Alarmes et minuteurs',
              ));

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('📋 Chemin copié! Collez-le dans les paramètres.'),
                    backgroundColor: AppColors.blue700,
                  ),
                );
              }

              // Envoyer notification test
              NotificationService.instance.afficherImmediatement(
                titre: '⏰ Prêt pour les rappels',
                corps: 'Vos alarmes fonctionneront une fois autorisées',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Copier le chemin'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.blue900, Color(0xFF0D3460), Color(0xFF1A1A4E)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Logo animé
                FadeTransition(
                  opacity: _fadeAnim,
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: Column(
                      children: [
                        // Icône
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.blue500, AppColors.teal],
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.blue500.withOpacity(0.4),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text('💊', style: TextStyle(fontSize: 48)),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Nom de l'app
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                            ),
                            children: [
                              TextSpan(
                                text: 'Medi',
                                style: TextStyle(color: Colors.white),
                              ),
                              TextSpan(
                                text: 'Remind',
                                style: TextStyle(color: AppColors.blue300),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Tagline
                        const Text(
                          'Votre traitement, toujours à l\'heure.',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // Barre de progression
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _progress < 0.5 ? 'Chargement…' : 'Configuration…',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                              fontFamily: 'DM Mono',
                            ),
                          ),
                          Text(
                            '${(_progress * 100).toInt()}%',
                            style: const TextStyle(
                              color: AppColors.blue300,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'DM Mono',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: _progress,
                          minHeight: 4,
                          backgroundColor: Colors.white12,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.teal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
