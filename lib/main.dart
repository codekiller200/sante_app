import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/theme/app_theme.dart';
import 'core/constants/app_routes.dart';
import 'services/notification_service.dart';
import 'services/auth_service.dart';
import 'data/repositories/medicament_repository.dart';
import 'data/repositories/prise_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('fr_FR', null);
  await NotificationService.instance.init();

  // Restaurer la session AVANT runApp pour éviter le flash de login
  final authService = AuthService();
  await authService.restaurerSession();

  runApp(MediRemindApp(authService: authService));
}

class MediRemindApp extends StatefulWidget {
  final AuthService authService;
  const MediRemindApp({super.key, required this.authService});

  @override
  State<MediRemindApp> createState() => _MediRemindAppState();
}

class _MediRemindAppState extends State<MediRemindApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      NotificationService.instance.refreshPermissions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.authService),
        ChangeNotifierProvider(create: (_) => MedicamentRepository()),
        ChangeNotifierProvider(create: (_) => PriseRepository()),
      ],
      child: MaterialApp.router(
        title: 'MediRemind',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: AppRoutes.router,
      ),
    );
  }
}
