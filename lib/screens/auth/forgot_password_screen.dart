import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:mediremind/core/constants/app_colors.dart';
import 'package:mediremind/core/constants/app_routes.dart';
import 'package:mediremind/services/auth_service.dart';
import 'package:mediremind/widgets/auth_shell.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _usernameController = TextEditingController();
  final _answerController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  String? _question;
  String? _error;
  bool _verified = false;
  bool _loading = false;

  int get _step => _verified ? 3 : (_question != null ? 2 : 1);

  @override
  void dispose() {
    _usernameController.dispose();
    _answerController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestion() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = context.read<AuthService>();
    final result = await auth.verifierUsername(_usernameController.text);
    if (!mounted) return;
    if (!result.success) {
      setState(() {
        _loading = false;
        _error = result.errorMessage;
      });
      return;
    }
    final question = await auth.getSecretQuestion(_usernameController.text);
    setState(() {
      _question = question;
      _loading = false;
      _error = null;
    });
  }

  Future<void> _verifyAnswer() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await context.read<AuthService>().verifierReponseSecrete(
          username: _usernameController.text,
          reponse: _answerController.text,
        );
    if (!mounted) return;
    setState(() {
      _verified = result.success;
      _loading = false;
      _error = result.success ? null : result.errorMessage;
    });
  }

  Future<void> _resetPassword() async {
    if (_passwordController.text != _confirmController.text) {
      setState(() => _error = 'Les mots de passe ne correspondent pas.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await context.read<AuthService>().reinitialiserMotDePasse(
          username: _usernameController.text,
          nouveauPassword: _passwordController.text,
        );
    if (!mounted) return;
    if (result.success) {
      context.go(AppRoutes.login);
      return;
    }
    setState(() {
      _loading = false;
      _error = result.errorMessage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: _headerTitle,
      subtitle: _headerSubtitle,
      showLogo: false,
      headerPadding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                if (_step == 1) {
                  context.go(AppRoutes.login);
                } else if (_step == 2) {
                  setState(() {
                    _question = null;
                    _error = null;
                  });
                } else {
                  setState(() {
                    _verified = false;
                    _error = null;
                  });
                }
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.blue900.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.arrow_back, size: 18, color: AppColors.blue900),
              ),
            ),
            const SizedBox(height: 16),
            _Stepper(step: _step),
            const SizedBox(height: 18),
            if (_step == 1)
              const InlineBanner.info(
                'Entrez votre nom d\'utilisateur pour retrouver votre compte. Vos donnees restent sur votre telephone.',
              ),
            if (_step == 2)
              const InlineBanner.info(
                'Repondez a votre question secrete choisie lors de l\'inscription.',
              ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              InlineBanner.error(_error!),
            ],
            const SizedBox(height: 16),
            if (_step == 1) _UsernameStep(controller: _usernameController),
            if (_step == 2) _QuestionStep(question: _question ?? '', controller: _answerController),
            if (_step == 3)
              _PasswordStep(
                passwordController: _passwordController,
                confirmController: _confirmController,
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading
                    ? null
                    : () {
                        if (_step == 1) _loadQuestion();
                        if (_step == 2) _verifyAnswer();
                        if (_step == 3) _resetPassword();
                      },
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_buttonLabel),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: () => context.go(AppRoutes.login),
                child: Text(
                  'Vous vous souvenez ? Se connecter',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.gray400,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _headerTitle {
    switch (_step) {
      case 1:
        return 'Mot de passe\noublie ?';
      case 2:
        return 'Question\nsecrete';
      default:
        return 'Nouveau\nmot de passe';
    }
  }

  String get _headerSubtitle {
    switch (_step) {
      case 1:
        return 'Recuperation 100% locale, aucune connexion necessaire.';
      case 2:
        return 'Compte trouve : ${_usernameController.text.trim()}';
      default:
        return 'Choisissez un mot de passe securise.';
    }
  }

  String get _buttonLabel {
    switch (_step) {
      case 1:
        return 'Verifier →';
      case 2:
        return 'Verifier la reponse →';
      default:
        return '✓ Enregistrer le mot de passe';
    }
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _StepDot(index: 1, currentStep: step),
            _StepLine(active: step > 1),
            _StepDot(index: 2, currentStep: step),
            _StepLine(active: step > 2),
            _StepDot(index: 3, currentStep: step),
          ],
        ),
        const SizedBox(height: 6),
        const Row(
          children: [
            Expanded(child: Text('Username', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: AppColors.gray400, fontWeight: FontWeight.w700))),
            Expanded(child: Text('Question', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: AppColors.gray400, fontWeight: FontWeight.w700))),
            Expanded(child: Text('Nouveau MDP', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: AppColors.gray400, fontWeight: FontWeight.w700))),
          ],
        ),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.index, required this.currentStep});

  final int index;
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final isDone = currentStep > index;
    final isCurrent = currentStep == index;

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDone
            ? AppColors.green
            : isCurrent
                ? AppColors.blue700
                : AppColors.gray200,
      ),
      alignment: Alignment.center,
      child: isDone
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : Text(
              '$index',
              style: TextStyle(
                color: isCurrent ? Colors.white : AppColors.gray400,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        color: active ? AppColors.green : AppColors.gray200,
      ),
    );
  }
}

class _UsernameStep extends StatelessWidget {
  const _UsernameStep({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return AuthInput(
      label: 'Nom d\'utilisateur',
      child: TextField(
        controller: controller,
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.person_outline),
          hintText: 'ali.toure',
        ),
      ),
    );
  }
}

class _QuestionStep extends StatelessWidget {
  const _QuestionStep({required this.question, required this.controller});

  final String question;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AuthInput(
          label: 'Votre question secrete',
          child: TextField(
            enabled: false,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.help_outline),
              hintText: question,
            ),
          ),
        ),
        const SizedBox(height: 14),
        AuthInput(
          label: 'Votre reponse',
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.edit_outlined),
              hintText: 'Votre reponse',
            ),
          ),
        ),
      ],
    );
  }
}

class _PasswordStep extends StatefulWidget {
  const _PasswordStep({
    required this.passwordController,
    required this.confirmController,
  });

  final TextEditingController passwordController;
  final TextEditingController confirmController;

  @override
  State<_PasswordStep> createState() => _PasswordStepState();
}

class _PasswordStepState extends State<_PasswordStep> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final password = widget.passwordController.text;
    final strength = password.length >= 10 ? 0.8 : password.length >= 6 ? 0.55 : 0.25;
    final color = strength >= 0.8 ? AppColors.green : strength >= 0.55 ? AppColors.orange : AppColors.red;
    final label = strength >= 0.8 ? 'Fort' : strength >= 0.55 ? 'Moyen' : 'Faible';

    return Column(
      children: [
        AuthInput(
          label: 'Nouveau mot de passe',
          child: Column(
            children: [
              TextField(
                controller: widget.passwordController,
                obscureText: _obscure,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline),
                  hintText: '••••••••',
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: strength,
                  minHeight: 4,
                  backgroundColor: AppColors.gray200,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Force : $label',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AuthInput(
          label: 'Confirmer le mot de passe',
          child: TextField(
            controller: widget.confirmController,
            obscureText: true,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.lock_outline),
              hintText: '••••••••',
            ),
          ),
        ),
      ],
    );
  }
}
