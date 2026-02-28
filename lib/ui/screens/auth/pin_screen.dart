import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_routes.dart';
import '../../../services/auth_service.dart';

class PinScreen extends StatefulWidget {
  const PinScreen({super.key});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  String _pin = '';
  bool _erreur = false;
  bool _chargement = false;

  void _ajouterChiffre(String chiffre) {
    if (_pin.length >= 4) return;
    setState(() {
      _pin += chiffre;
      _erreur = false;
    });
    if (_pin.length == 4) _verifier();
  }

  void _supprimer() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _verifier() async {
    setState(() => _chargement = true);
    final auth = context.read<AuthService>();
    final ok = await auth.deverrouillerAvecPin(_pin);
    if (!mounted) return;

    if (ok) {
      context.go(AppRoutes.home);
    } else {
      setState(() {
        _erreur = true;
        _chargement = false;
        _pin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2952),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            // Logo / titre
            Text('💊', style: const TextStyle(fontSize: 52)),
            const SizedBox(height: 16),
            Text('MediRemind',
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('Entrez votre code PIN',
                style: GoogleFonts.inter(
                    color: Colors.white60,
                    fontSize: 14,
                    fontWeight: FontWeight.w400)),

            const SizedBox(height: 40),

            // Points PIN
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final rempli = i < _pin.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _erreur
                        ? const Color(0xFFEF4444)
                        : rempli
                            ? Colors.white
                            : Colors.white24,
                    border: Border.all(
                        color:
                            _erreur ? const Color(0xFFEF4444) : Colors.white38,
                        width: 1.5),
                  ),
                );
              }),
            ),

            if (_erreur) ...[
              const SizedBox(height: 12),
              Text('Code incorrect, réessayez',
                  style: GoogleFonts.inter(
                      color: const Color(0xFFEF4444),
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
            ],

            const SizedBox(height: 48),

            // Clavier numérique
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Column(
                children: [
                  _buildRangee(['1', '2', '3']),
                  const SizedBox(height: 16),
                  _buildRangee(['4', '5', '6']),
                  const SizedBox(height: 16),
                  _buildRangee(['7', '8', '9']),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Bouton se déconnecter
                      _BoutonPin(
                        child: Text('⏏',
                            style: const TextStyle(
                                fontSize: 20, color: Colors.white54)),
                        onTap: () async {
                          await context.read<AuthService>().deconnecter();
                          if (mounted) context.go(AppRoutes.login);
                        },
                      ),
                      _BoutonPin(
                        child: Text('0',
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w500)),
                        onTap: () => _ajouterChiffre('0'),
                      ),
                      _BoutonPin(
                        child: _chargement
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white54, strokeWidth: 2))
                            : const Icon(Icons.backspace_outlined,
                                color: Colors.white54, size: 22),
                        onTap: _supprimer,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildRangee(List<String> chiffres) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: chiffres
          .map((c) => _BoutonPin(
                child: Text(c,
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w500)),
                onTap: () => _ajouterChiffre(c),
              ))
          .toList(),
    );
  }
}

class _BoutonPin extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const _BoutonPin({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.1),
        ),
        child: Center(child: child),
      ),
    );
  }
}
