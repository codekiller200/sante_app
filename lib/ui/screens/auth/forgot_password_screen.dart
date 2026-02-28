import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _etape = 1; // 1, 2, 3, 4 (succès)
  int _tentatives = 3;

  final _usernameController = TextEditingController();
  final _reponseController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmController = TextEditingController();

  String? _errorMessage;
  String? _usernameValide;
  String? _questionSecrete;
  bool _passwordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _reponseController.dispose();
    _newPasswordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // ─── Étape 1 : vérifier username ───────────────────────────────
  Future<void> _verifierUsername() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      setState(
          () => _errorMessage = 'Veuillez entrer votre nom d\'utilisateur.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await context.read<AuthService>().verifierUsername(username);
    final question =
        await context.read<AuthService>().getSecretQuestion(username);

    if (!mounted) return;

    if (result.success) {
      setState(() {
        _usernameValide = username;
        _questionSecrete = question;
        _etape = 2;
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = result.errorMessage;
        _isLoading = false;
      });
    }
  }

  // ─── Étape 2 : vérifier réponse secrète ────────────────────────
  Future<void> _verifierReponse() async {
    final reponse = _reponseController.text.trim();
    if (reponse.isEmpty) {
      setState(() => _errorMessage = 'Veuillez entrer votre réponse.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await context.read<AuthService>().verifierReponseSecrete(
          username: _usernameValide!,
          reponse: reponse,
        );

    if (!mounted) return;

    if (result.success) {
      setState(() {
        _etape = 3;
        _isLoading = false;
      });
    } else {
      _tentatives--;
      setState(() {
        _isLoading = false;
        _errorMessage = _tentatives > 0
            ? 'Réponse incorrecte. Il vous reste $_tentatives tentative(s).'
            : 'Trop de tentatives. Veuillez réessayer plus tard.';
      });
    }
  }

  // ─── Étape 3 : enregistrer nouveau mot de passe ────────────────
  Future<void> _reinitialiser() async {
    final newPwd = _newPasswordController.text;
    final confirm = _confirmController.text;

    if (newPwd.length < 6) {
      setState(() => _errorMessage = 'Minimum 6 caractères.');
      return;
    }
    if (newPwd != confirm) {
      setState(() => _errorMessage = 'Les mots de passe ne correspondent pas.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await context.read<AuthService>().reinitialiserMotDePasse(
          username: _usernameValide!,
          nouveauPassword: newPwd,
        );

    if (!mounted) return;

    if (result.success) {
      setState(() {
        _etape = 4;
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = result.errorMessage;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Contenu selon l'étape
            _etape == 4 ? _buildSucces() : _buildForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final titles = [
      '',
      'Mot de passe\noublié ?',
      'Question\nsecrète',
      'Nouveau\nmot de passe',
      ''
    ];
    final subs = [
      '',
      'Récupération 100% locale, aucune connexion nécessaire.',
      'Compte trouvé : ${_usernameValide ?? ""}',
      'Choisissez un mot de passe sécurisé.',
      ''
    ];

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.blue900, Color(0xFF0D3460)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_etape < 4)
                GestureDetector(
                  onTap: () {
                    if (_etape == 1) {
                      context.go(AppRoutes.login);
                    } else {
                      setState(() {
                        _etape--;
                        _errorMessage = null;
                      });
                    }
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 18),
                  ),
                ),
              if (_etape < 4) const SizedBox(height: 14),
              if (_etape < 4)
                Text(
                  titles[_etape],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                ),
              if (_etape < 4) const SizedBox(height: 4),
              if (_etape < 4)
                Text(
                  subs[_etape],
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stepper
          _buildStepper(),
          const SizedBox(height: 20),

          // Message erreur
          if (_errorMessage != null) ...[
            _ErrorBox(message: _errorMessage!),
            const SizedBox(height: 16),
          ],

          // Contenu par étape
          if (_etape == 1) _buildEtape1(),
          if (_etape == 2) _buildEtape2(),
          if (_etape == 3) _buildEtape3(),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    return Column(
      children: [
        Row(
          children: [
            _StepDot(numero: 1, etapeActuelle: _etape),
            _StepLine(actif: _etape > 1),
            _StepDot(numero: 2, etapeActuelle: _etape),
            _StepLine(actif: _etape > 2),
            _StepDot(numero: 3, etapeActuelle: _etape),
          ],
        ),
        const SizedBox(height: 6),
        const Row(
          children: [
            Expanded(
                child: Text('Username',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 10,
                        color: AppColors.gray400,
                        fontWeight: FontWeight.w600))),
            Expanded(
                child: Text('Question',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 10,
                        color: AppColors.gray400,
                        fontWeight: FontWeight.w600))),
            Expanded(
                child: Text('Nouveau MDP',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 10,
                        color: AppColors.gray400,
                        fontWeight: FontWeight.w600))),
          ],
        ),
      ],
    );
  }

  Widget _buildEtape1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _InfoBox(
            text:
                'Entrez votre nom d\'utilisateur pour retrouver votre compte. Vos données restent sur votre téléphone.'),
        const SizedBox(height: 16),
        const Text('Nom d\'utilisateur',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.gray600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: _usernameController,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _verifierUsername(),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.person_outline),
            hintText: 'ex: marie.dupont',
          ),
        ),
        const SizedBox(height: 24),
        _PrimaryButton(
            label: 'Vérifier →',
            isLoading: _isLoading,
            onTap: _verifierUsername),
        const SizedBox(height: 16),
        _SwitchLink(
            text: 'Vous vous souvenez ? ',
            linkText: 'Se connecter',
            onTap: () => context.go(AppRoutes.login)),
      ],
    );
  }

  Widget _buildEtape2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _InfoBox(
            text:
                'Répondez à votre question secrète choisie lors de l\'inscription.'),
        const SizedBox(height: 16),
        const Text('Votre question secrète',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.gray600)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.gray100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.gray200),
          ),
          child: Text(
            _questionSecrete ?? '',
            style: const TextStyle(fontSize: 13, color: AppColors.gray600),
          ),
        ),
        const SizedBox(height: 14),
        const Text('Votre réponse',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.gray600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: _reponseController,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _verifierReponse(),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.edit_outlined),
            hintText: 'Votre réponse',
          ),
        ),
        const SizedBox(height: 24),
        _PrimaryButton(
            label: 'Vérifier la réponse →',
            isLoading: _isLoading,
            onTap: _tentatives > 0 ? _verifierReponse : null),
        const SizedBox(height: 16),
        _SwitchLink(
            text: 'Vous vous souvenez ? ',
            linkText: 'Se connecter',
            onTap: () => context.go(AppRoutes.login)),
      ],
    );
  }

  Widget _buildEtape3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Nouveau mot de passe',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.gray600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: _newPasswordController,
          obscureText: !_passwordVisible,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock_outline),
            hintText: '••••••••',
            suffixIcon: IconButton(
              icon: Icon(_passwordVisible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined),
              onPressed: () =>
                  setState(() => _passwordVisible = !_passwordVisible),
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text('Confirmer le mot de passe',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.gray600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: _confirmController,
          obscureText: true,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _reinitialiser(),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.lock_outline),
            hintText: '••••••••',
          ),
        ),
        const SizedBox(height: 24),
        _PrimaryButton(
            label: '✓ Enregistrer le mot de passe',
            isLoading: _isLoading,
            onTap: _reinitialiser,
            color: AppColors.green),
        const SizedBox(height: 16),
        _SwitchLink(
            text: 'Vous vous souvenez ? ',
            linkText: 'Se connecter',
            onTap: () => context.go(AppRoutes.login)),
      ],
    );
  }

  Widget _buildSucces() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF059669), AppColors.green]),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.green.withOpacity(0.3),
                      blurRadius: 24,
                      spreadRadius: 4)
                ],
              ),
              child: const Center(
                  child: Text('✅', style: TextStyle(fontSize: 42))),
            ),
            const SizedBox(height: 24),
            const Text('Mot de passe\nréinitialisé !',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.gray900,
                    letterSpacing: -0.5,
                    height: 1.2)),
            const SizedBox(height: 12),
            const Text(
                'Votre nouveau mot de passe a été enregistré localement. Vous pouvez maintenant vous reconnecter.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, color: AppColors.gray400, height: 1.6)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => context.go(AppRoutes.login),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue700,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('→ Se connecter',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets réutilisables ─────────────────────────────────────────

class _StepDot extends StatelessWidget {
  final int numero;
  final int etapeActuelle;
  const _StepDot({required this.numero, required this.etapeActuelle});

  @override
  Widget build(BuildContext context) {
    final done = etapeActuelle > numero;
    final current = etapeActuelle == numero;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: done
            ? AppColors.green
            : current
                ? AppColors.blue700
                : AppColors.gray200,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: done
            ? const Icon(Icons.check, size: 14, color: Colors.white)
            : Text('$numero',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: current ? Colors.white : AppColors.gray400)),
      ),
    );
  }
}

class _StepLine extends StatelessWidget {
  final bool actif;
  const _StepLine({required this.actif});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
          height: 2, color: actif ? AppColors.green : AppColors.gray200),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String text;
  const _InfoBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.blue50,
        border: Border.all(color: AppColors.blue100),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ℹ️', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.blue700,
                      fontWeight: FontWeight.w500,
                      height: 1.5))),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        border: Border.all(color: const Color(0xFFFECACA)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(message,
                  style: const TextStyle(
                      color: AppColors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onTap;
  final Color color;
  const _PrimaryButton(
      {required this.label,
      required this.isLoading,
      this.onTap,
      this.color = AppColors.blue700});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : Text(label,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
      ),
    );
  }
}

class _SwitchLink extends StatelessWidget {
  final String text;
  final String linkText;
  final VoidCallback onTap;
  const _SwitchLink(
      {required this.text, required this.linkText, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 13, color: AppColors.gray400),
            children: [
              TextSpan(text: text),
              TextSpan(
                  text: linkText,
                  style: const TextStyle(
                      color: AppColors.blue700, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
