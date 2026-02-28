import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../ui/screens/auth/login_screen.dart';
import '../../ui/screens/auth/register_screen.dart';
import '../../ui/screens/auth/forgot_password_screen.dart';
import '../../ui/screens/auth/pin_screen.dart';
import '../../ui/screens/home/home_screen.dart';
import '../../ui/screens/medicaments/liste_medicaments_screen.dart';
import '../../ui/screens/medicaments/form_medicament_screen.dart';
import '../../ui/screens/journal/journal_screen.dart';
import '../../ui/screens/profil/profil_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String pin = '/pin';
  static const String home = '/home';
  static const String medicaments = '/medicaments';
  static const String formMedicament = '/medicaments/form';
  static const String journal = '/journal';
  static const String profil = '/profil';

  static final router = GoRouter(
    // Démarre directement sur home — le redirect gère tout
    initialLocation: home,

    redirect: (context, state) async {
      final auth = context.read<AuthService>();

      // Attendre que la session soit chargée (restaurerSession() dans main.dart)
      if (!auth.sessionChargee) return null;

      final isLoggedIn = auth.isLoggedIn;
      final loc = state.matchedLocation;

      final isAuthRoute = loc == login ||
          loc == register ||
          loc == forgotPassword ||
          loc == pin;

      // Pas connecté → login (sauf si déjà sur une page auth)
      if (!isLoggedIn && !isAuthRoute) {
        // Vérifier si une session sauvegardée existe (besoin du PIN)
        final pinEstActif = await auth.pinActif;
        if (pinEstActif) return pin;
        return login;
      }

      // Connecté et sur login/register → home
      if (isLoggedIn && (loc == login || loc == register)) {
        return home;
      }

      return null;
    },

    routes: [
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
