import 'package:go_router/go_router.dart';

import 'package:mediremind/screens/auth/forgot_password_screen.dart';
import 'package:mediremind/screens/auth/login_screen.dart';
import 'package:mediremind/screens/auth/pin_screen.dart';
import 'package:mediremind/screens/auth/register_screen.dart';
import 'package:mediremind/screens/alarm_setup_screen.dart';
import 'package:mediremind/screens/home_screen.dart';
import 'package:mediremind/screens/journal_screen.dart';
import 'package:mediremind/screens/medicament_form_screen.dart';
import 'package:mediremind/screens/medicament_list_screen.dart';
import 'package:mediremind/screens/profile_screen.dart';
import 'package:mediremind/screens/splash_screen.dart';
import 'package:mediremind/services/auth_service.dart';

class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const pin = '/pin';
  static const alarmSetup = '/alarm-setup';
  static const home = '/home';
  static const medicaments = '/medicaments';
  static const formMedicament = '/medicaments/form';
  static const journal = '/journal';
  static const profil = '/profil';

  static GoRouter createRouter(AuthService auth) {
    return GoRouter(
      initialLocation: splash,
      refreshListenable: auth,
      redirect: (context, state) async {
        if (!auth.sessionChargee) {
          return null;
        }

        final location = state.matchedLocation;
        if (location == splash) {
          return null;
        }
        final isAuthRoute = {
          login,
          register,
          forgotPassword,
          pin,
        }.contains(location);

        if (!auth.isLoggedIn) {
          final pinActif = await auth.pinActif;
          if (!isAuthRoute) {
            return pinActif ? pin : login;
          }
          if (location == pin && !pinActif) {
            return login;
          }
        }

        if (auth.isLoggedIn && isAuthRoute && location != forgotPassword) {
          return home;
        }

        return null;
      },
      routes: [
        GoRoute(
          path: splash,
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: register,
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: forgotPassword,
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: pin,
          builder: (context, state) => const PinScreen(),
        ),
        GoRoute(
          path: alarmSetup,
          builder: (context, state) => AlarmSetupScreen(
            isFirstLaunch: state.extra as bool? ?? false,
          ),
        ),
        GoRoute(
          path: home,
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: medicaments,
          builder: (context, state) => const MedicamentListScreen(),
        ),
        GoRoute(
          path: formMedicament,
          builder: (context, state) => MedicamentFormScreen(
            medicamentId: state.extra as int?,
          ),
        ),
        GoRoute(
          path: journal,
          builder: (context, state) => const JournalScreen(),
        ),
        GoRoute(
          path: profil,
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    );
  }
}
