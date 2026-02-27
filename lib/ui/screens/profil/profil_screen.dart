import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../services/auth_service.dart';
import '../../widgets/main_scaffold.dart';

class ProfilScreen extends StatelessWidget {
  const ProfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.utilisateurConnecte;
    final prenom = user?.nomComplet.split(' ').first ?? '';

    return MainScaffold(
      currentIndex: 3,
      child: Column(
        children: [
          // Header avec avatar
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.blue900, Color(0xFF0D3460)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: Column(
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Mon Profil', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: 68, height: 68,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.blue500, AppColors.teal]),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 3),
                      ),
                      child: Center(
                        child: Text(
                          prenom.isNotEmpty ? prenom[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(user?.nomComplet ?? '',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                    Text('@${user?.username ?? ''}',
                        style: const TextStyle(color: AppColors.blue300, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),

          // Contenu
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Badge RGPD
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.blue50,
                    border: Border.all(color: AppColors.blue100),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Text('🔒', style: TextStyle(fontSize: 16)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Données 100% locales · RGPD conforme · Aucun serveur',
                          style: TextStyle(fontSize: 12, color: AppColors.blue700, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Section Compte
                const _SectionTitle('Compte'),
                const SizedBox(height: 8),
                _InfoCard(children: [
                  _InfoRow(icon: Icons.badge_outlined, iconBg: AppColors.blue50, label: 'Nom complet', value: user?.nomComplet ?? ''),
                  _InfoRow(icon: Icons.person_outline, iconBg: AppColors.blue50, label: 'Nom d\'utilisateur', value: '@${user?.username ?? ''}'),
                  _InfoRow(icon: Icons.calendar_today_outlined, iconBg: AppColors.blue50, label: 'Membre depuis',
                      value: user != null ? '${user.dateCreation.day}/${user.dateCreation.month}/${user.dateCreation.year}' : ''),
                ]),
                const SizedBox(height: 16),

                // Section Sécurité
                const _SectionTitle('Sécurité'),
                const SizedBox(height: 8),
                _InfoCard(children: [
                  _InfoRow(icon: Icons.lock_outline, iconBg: AppColors.blue50, label: 'Question secrète', value: user?.secretQuestion ?? '', onTap: () {}),
                  _InfoRow(icon: Icons.key_outlined, iconBg: AppColors.blue50, label: 'Mot de passe', value: '••••••••', onTap: () => context.go(AppRoutes.forgotPassword)),
                ]),
                const SizedBox(height: 16),

                // Section App
                const _SectionTitle('Application'),
                const SizedBox(height: 8),
                const _InfoCard(children: [
                  _InfoRow(icon: Icons.info_outline, iconBg: AppColors.blue50, label: 'Version', value: '1.0.0'),
                  _InfoRow(icon: Icons.storage_outlined, iconBg: AppColors.blue50, label: 'Stockage', value: 'Local uniquement'),
                ]),
                const SizedBox(height: 24),

                // Bouton déconnexion
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmerDeconnexion(context, auth),
                    icon: const Icon(Icons.logout, color: AppColors.red),
                    label: const Text('Se déconnecter', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w700, fontSize: 15)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFECACA)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmerDeconnexion(BuildContext context, AuthService auth) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Se déconnecter ?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Vos données resteront sauvegardées localement.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Déconnecter', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      auth.deconnecter();
      if (context.mounted) context.go(AppRoutes.login);
    }
  }
}

// ─── Widgets locaux ───────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) => Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.blue700, letterSpacing: 1),
      );
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _InfoRow({required this.icon, required this.iconBg, required this.label, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(9)),
              child: Icon(icon, size: 17, color: AppColors.blue700),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11, color: AppColors.gray400, fontWeight: FontWeight.w500)),
                  Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.gray900)),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right, color: AppColors.gray200, size: 20),
          ],
        ),
      ),
    );
  }
}
