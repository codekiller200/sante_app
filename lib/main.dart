import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'package:sante_app/core/constants/app_routes.dart';
import 'package:sante_app/core/theme/app_theme.dart';
import 'package:sante_app/data/repositories/medicament_repository.dart';
import 'package:sante_app/data/repositories/prise_repository.dart';
import 'package:sante_app/services/alarm_preferences_service.dart';
import 'package:sante_app/services/auth_service.dart';
import 'package:sante_app/services/emergency_contacts_service.dart';
import 'package:sante_app/services/notification_center_service.dart';
import 'package:sante_app/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('fr_FR');
  await NotificationService.instance.init();

  final authService = AuthService();
  await authService.restaurerSession();

  runApp(MediRemindApp(authService: authService));
}

class MediRemindApp extends StatelessWidget {
  const MediRemindApp({super.key, required this.authService});

  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: authService),
        ChangeNotifierProvider(create: (_) => MedicamentRepository()),
        ChangeNotifierProvider(create: (_) => PriseRepository()),
        ChangeNotifierProvider(create: (_) => AlarmPreferencesService()),
        ChangeNotifierProvider(create: (_) => NotificationCenterService()),
        ChangeNotifierProvider(create: (_) => EmergencyContactsService()..load()),
      ],
      child: Builder(
        builder: (context) {
          final auth = context.watch<AuthService>();
          return MaterialApp.router(
            title: 'MediRemind',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('fr', 'FR'),
              Locale('en', 'US'),
            ],
            routerConfig: AppRoutes.createRouter(auth),
          );
        },
      ),
    );
  }
}

