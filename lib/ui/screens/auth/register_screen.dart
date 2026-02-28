import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../services/auth_service.dart';
import '../../widgets/auth_header.dart';
import '../../widgets/auth_tabs.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _reponseController = TextEditingController();

  bool _passwordVisible = false;
  bool _confirmVisible = false;
  bool _isLoading = false;
  bool _accepteCGU = false;
  String? _errorMessage;
  String _questionChoisie = 'Nom de votre médecin traitant ?';

  final List<String> _questions = [
    'Nom de votre médecin traitant ?',
    'Prénom de votre mère ?',
    'Ville de naissance ?',
    'Nom de votre animal ?',
    'Surnom d\'enfance ?',
  ];

  int get _passwordStrength {
    final p = _passwordController.text;
    int score = 0;
    if (p.length >= 6) score++;
    if (p.length >= 10) score++;
    if (p.contains(RegExp(r'[A-Z]'))) score++;
    if (p.contains(RegExp(r'[0-9]'))) score++;
    if (p.contains(RegExp(r'[!@#\$&*~]'))) score++;
    return score;
  }

  String get _strengthLabel {
    switch (_passwordStrength) {
      case 0:
      case 1:
        return 'Très faible';
      case 2:
        return 'Faible';
      case 3:
        return 'Moyen';
      case 4:
        return 'Fort';
      default:
        return 'Très fort';
    }
  }

  Color get _strengthColor {
    switch (_passwordStrength) {
      case 0:
      case 1:
        return AppColors.red;
      case 2:
        return AppColors.orange;
      case 3:
        return AppColors.orange;
      case 4:
        return AppColors.green;
      default:
        return AppColors.green;
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _reponseController.dispose();
    super.dispose();
  }

  Future<void> _sInscrire() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_accepteCGU) {
      setState(() =>
          _errorMessage = 'Veuillez accepter les conditions d\'utilisation.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await context.read<AuthService>().inscrire(
          username: _usernameController.text,
          password: _passwordController.text,
          nomComplet: _nomController.text,
          secretQuestion: _questionChoisie,
          secretAnswer: _reponseController.text,
        );

    if (!mounted) return;

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Compte créé avec succès ! Connectez-vous.'),
          backgroundColor: AppColors.green,
        ),
      );
      context.go(AppRoutes.login);
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = result.errorMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const AuthHeader(
              title: 'Créer un compte 🎉',
              subtitle: 'Rejoignez MediRemind et prenez soin de vous',
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AuthTabs(
                      selectedIndex: 1,
                      onTap: (i) {
                        if (i == 0) context.go(AppRoutes.login);
                      },
                    ),
                    const SizedBox(height: 20),
                    if (_errorMessage != null) ...[
                      _ErrorBox(message: _errorMessage!),
                      const SizedBox(height: 16),
                    ],
                    _label('Nom complet'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nomController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.badge_outlined),
                        hintText: 'ex: Marie Dupont',
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 14),
                    _label('Nom d\'utilisateur'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _usernameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.person_outline),
                        hintText: 'ex: marie.dupont',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Champ requis';
                        if (v.trim().length < 3) return 'Minimum 3 caractères';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _label('Mot de passe'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_passwordVisible,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline),
                        hintText: '••••••••',
                        suffixIcon: IconButton(
                          icon: Icon(_passwordVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined),
                          onPressed: () => setState(
                              () => _passwordVisible = !_passwordVisible),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Champ requis';
                        if (v.length < 6) return 'Minimum 6 caractères';
                        return null;
                      },
                    ),
                    if (_passwordController.text.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: _passwordStrength / 5,
                          minHeight: 4,
                          backgroundColor: AppColors.gray200,
                          valueColor: AlwaysStoppedAnimation(_strengthColor),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Force : $_strengthLabel',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _strengthColor,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    _label('Confirmer le mot de passe'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _confirmController,
                      obscureText: !_confirmVisible,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline),
                        hintText: '••••••••',
                        suffixIcon: IconButton(
                          icon: Icon(_confirmVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined),
                          onPressed: () => setState(
                              () => _confirmVisible = !_confirmVisible),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Champ requis';
                        if (v != _passwordController.text) {
                          return 'Les mots de passe ne correspondent pas';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _label('Question secrète'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _questionChoisie,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.help_outline),
                      ),
                      items: _questions
                          .map((q) => DropdownMenuItem(
                                value: q,
                                child: Text(q,
                                    style: const TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _questionChoisie = v ?? _questions[0]),
                    ),
                    const SizedBox(height: 14),
                    _label('Votre réponse'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _reponseController,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.edit_outlined),
                        hintText: 'Votre réponse secrète',
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () =>
                              setState(() => _accepteCGU = !_accepteCGU),
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: _accepteCGU
                                  ? AppColors.blue700
                                  : AppColors.gray100,
                              border: Border.all(
                                color: _accepteCGU
                                    ? AppColors.blue700
                                    : AppColors.gray200,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: _accepteCGU
                                ? const Icon(Icons.check,
                                    size: 14, color: Colors.white)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'J\'accepte les conditions d\'utilisation et la politique de confidentialité',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.gray400,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _sInscrire,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.blue700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                '→ Créer mon compte',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: GestureDetector(
                        onTap: () => context.go(AppRoutes.login),
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(
                                fontSize: 13, color: AppColors.gray400),
                            children: [
                              TextSpan(text: 'Déjà un compte ? '),
                              TextSpan(
                                text: 'Se connecter',
                                style: TextStyle(
                                    color: AppColors.blue700,
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.gray600,
        ),
      );
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
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
