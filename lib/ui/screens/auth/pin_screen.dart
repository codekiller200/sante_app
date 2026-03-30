import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:sante_app/core/constants/app_colors.dart';
import 'package:sante_app/core/constants/app_routes.dart';
import 'package:sante_app/services/auth_service.dart';

class PinScreen extends StatefulWidget {
  const PinScreen({super.key});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  String _pin = '';
  bool _error = false;
  bool _loading = false;

  Future<void> _validate() async {
    setState(() => _loading = true);
    final ok = await context.read<AuthService>().deverrouillerAvecPin(_pin);
    if (!mounted) return;
    if (ok) {
      context.go(AppRoutes.home);
      return;
    }
    setState(() {
      _pin = '';
      _error = true;
      _loading = false;
    });
  }

  void _tap(String value) {
    if (_pin.length >= 4 || _loading) return;
    setState(() {
      _pin += value;
      _error = false;
    });
    if (_pin.length == 4) {
      _validate();
    }
  }

  void _delete() {
    if (_pin.isEmpty || _loading) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _error = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.blue900, Color(0xFF0D3460)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(colors: [AppColors.blue500, AppColors.teal]),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.blue500.withValues(alpha: 0.28),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text('🔐', style: TextStyle(fontSize: 36)),
                ),
                const SizedBox(height: 20),
                Text(
                  'Entrez votre code PIN',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Acces rapide et securisé a vos traitements',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    4,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _error
                            ? AppColors.red
                            : index < _pin.length
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.18),
                        border: Border.all(
                          color: _error ? AppColors.red : Colors.white38,
                          width: 1.4,
                        ),
                      ),
                    ),
                  ),
                ),
                if (_error) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Code incorrect',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFFFCA5A5),
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
                const SizedBox(height: 36),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    for (final value in ['1', '2', '3', '4', '5', '6', '7', '8', '9'])
                      _PinKey(label: value, onTap: () => _tap(value)),
                    _PinKey(
                      label: '⏏',
                      onTap: () async {
                        final auth = context.read<AuthService>();
                        await auth.deconnecter();
                        if (!context.mounted) return;
                        context.go(AppRoutes.login);
                      },
                    ),
                    _PinKey(label: '0', onTap: () => _tap('0')),
                    _PinKey(
                      labelWidget: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                            )
                          : const Icon(Icons.backspace_outlined, color: Colors.white70),
                      onTap: _delete,
                    ),
                  ],
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PinKey extends StatelessWidget {
  const _PinKey({
    this.label,
    this.labelWidget,
    required this.onTap,
  });

  final String? label;
  final Widget? labelWidget;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Ink(
        width: 74,
        height: 74,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.08),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Center(
          child: labelWidget ??
              Text(
                label ?? '',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 24,
                    ),
              ),
        ),
      ),
    );
  }
}

