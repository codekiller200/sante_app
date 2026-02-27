import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_routes.dart';
import 'services/notification_service.dart';
import 'services/auth_service.dart';
import 'data/repositories/medicament_repository.dart';
import 'data/repositories/prise_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation des timezones (pour les notifications)
  tz.initializeTimeZones();

  // Initialisation des locales françaises
  await initializeDateFormatting('fr_FR', null);

  // Initialisation des notifications
  await NotificationService.instance.init();

  runApp(const MediRemindApp());
}

class MediRemindApp extends StatelessWidget {
  const MediRemindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
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
