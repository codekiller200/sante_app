import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:mediremind/constants/secret_questions.dart';
import 'package:mediremind/core/constants/app_colors.dart';
import 'package:mediremind/core/constants/app_routes.dart';
import 'package:mediremind/services/auth_service.dart';
import 'package:mediremind/widgets/auth_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _answerController = TextEditingController();

  bool _isLoading = false;
  bool _acceptTerms = true;
  bool _passwordObscure = true;
  String? _error;
  String _selectedQuestion = SecretQuestions.items.first;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  int get _strength {
    final value = _passwordController.text;
    var score = 0;
    if (value.length >= 6) score++;
    if (value.length >= 10) score++;
    if (RegExp(r'[A-Z]').hasMatch(value)) score++;
    if (RegExp(r'[0-9]').hasMatch(value)) score++;
    return score;
  }

  Color get _strengthColor {
    if (_strength <= 1) return AppColors.red;
    if (_strength <= 3) return AppColors.orange;
    return AppColors.green;
  }

  String get _strengthLabel {
    if (_strength <= 1) return 'Faible';
    if (_strength <= 3) return 'Moyen';
    return 'Fort';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      setState(
          () => _error = 'Vous devez accepter les conditions d\'utilisation.');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await context.read<AuthService>().inscrire(
          username: _usernameController.text,
          password: _passwordController.text,
          nomComplet: _nameController.text,
          secretQuestion: _selectedQuestion,
          secretAnswer: _answerController.text,
        );

    if (!mounted) return;
    if (result.success) {
      context.go(AppRoutes.login);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Compte cree. Vous pouvez maintenant vous connecter.')),
      );
      return;
    }

    setState(() {
      _isLoading = false;
      _error = result.errorMessage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: 'Creer un compte 🎉',
      subtitle: 'Rejoignez MediRemind et prenez soin de vous',
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AuthTabs(
                selectedIndex: 1,
                onLoginTap: () => context.go(AppRoutes.login),
                onRegisterTap: () {},
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                InlineBanner.error(_error!),
              ],
              const SizedBox(height: 16),
              AuthInput(
                label: 'Nom complet',
                child: TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.person_outline),
                    hintText: 'Ali Touré',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Champ requis'
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              AuthInput(
                label: 'Nom d\'utilisateur',
                child: TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.badge_outlined),
                    hintText: 'ali.toure',
                  ),
                  validator: (value) => value == null || value.trim().length < 3
                      ? 'Minimum 3 caracteres'
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              AuthInput(
                label: 'Mot de passe',
                child: Column(
                  children: [
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _passwordObscure,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline),
                        hintText: '••••••••',
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                              () => _passwordObscure = !_passwordObscure),
                          icon: Icon(_passwordObscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                        ),
                      ),
                      validator: (value) => value == null || value.length < 6
                          ? 'Minimum 6 caracteres'
                          : null,
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: (_strength / 4).clamp(0, 1).toDouble(),
                        minHeight: 4,
                        backgroundColor: AppColors.gray200,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(_strengthColor),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Force : $_strengthLabel',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: _strengthColor,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AuthInput(
                label: 'Confirmer le mot de passe',
                child: TextFormField(
                  controller: _confirmController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.lock_outline),
                    hintText: '••••••••',
                  ),
                  validator: (value) => value != _passwordController.text
                      ? 'Les mots de passe ne correspondent pas'
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              AuthInput(
                label: 'Question secrète',
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedQuestion,
                  isExpanded: true,
                  menuMaxHeight: 320,
                  items: SecretQuestions.items
                      .map(
                        (question) => DropdownMenuItem(
                          value: question,
                          child: Text(
                            question,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  selectedItemBuilder: (context) => SecretQuestions.items
                      .map(
                        (question) => Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            question,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() =>
                      _selectedQuestion = value ?? SecretQuestions.items.first),
                ),
              ),
              const SizedBox(height: 12),
              AuthInput(
                label: 'Votre réponse',
                child: TextFormField(
                  controller: _answerController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.edit_outlined),
                    hintText: 'Votre reponse secrète',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Champ requis'
                      : null,
                ),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => setState(() => _acceptTerms = !_acceptTerms),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        color: _acceptTerms
                            ? AppColors.blue50
                            : Colors.transparent,
                        border: Border.all(color: AppColors.blue500, width: 2),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      alignment: Alignment.center,
                      child: _acceptTerms
                          ? const Icon(Icons.check,
                              size: 12, color: AppColors.blue700)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "J'accepte les conditions d'utilisation et la politique de confidentialité",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('→ Creer mon compte'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
