import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../ui/screens/splash/splash_screen.dart';
import '../../ui/screens/auth/login_screen.dart';
import '../../ui/screens/auth/register_screen.dart';
import '../../ui/screens/auth/forgot_password_screen.dart';
import '../../ui/screens/home/home_screen.dart';
import '../../ui/screens/medicaments/liste_medicaments_screen.dart';
import '../../ui/screens/medicaments/form_medicament_screen.dart';
import '../../ui/screens/journal/journal_screen.dart';
import '../../ui/screens/profil/profil_screen.dart';

class AppRoutes {
  AppRoutes._();

  // Noms des routes
  static const String splash        = '/';
  static const String login         = '/login';
  static const String register      = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home          = '/home';
  static const String medicaments   = '/medicaments';
  static const String formMedicament = '/medicaments/form';
  static const String journal       = '/journal';
  static const String profil        = '/profil';

  static final router = GoRouter(
    initialLocation: splash,
    redirect: (context, state) {
      final authService = context.read<AuthService>();
      final isLoggedIn = authService.isLoggedIn;
      final isAuthRoute = state.matchedLocation == login
          || state.matchedLocation == register
          || state.matchedLocation == forgotPassword
          || state.matchedLocation == splash;

      // Si pas connecté et pas sur une page auth → login
      if (!isLoggedIn && !isAuthRoute) return login;

      // Si connecté et sur login/register → home
      if (isLoggedIn && (state.matchedLocation == login || state.matchedLocation == register)) {
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
        path: home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: medicaments,
        builder: (context, state) => const ListeMedicamentsScreen(),
      ),
      GoRoute(
        path: formMedicament,
        builder: (context, state) => FormMedicamentScreen(
          medicamentId: state.extra as int?,
        ),
      ),
      GoRoute(
        path: journal,
        builder: (context, state) => const JournalScreen(),
      ),
      GoRoute(
        path: profil,
        builder: (context, state) => const ProfilScreen(),
      ),
    ],
  );
}
