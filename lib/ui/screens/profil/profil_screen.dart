import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../data/models/utilisateur.dart';
import '../../../services/auth_service.dart';
import '../../../services/alarm_service.dart';
import '../../widgets/main_scaffold.dart';

// Emojis disponibles pour l'avatar
const _emojisAvatar = [
  '🧑',
  '👨',
  '👩',
  '🧔',
  '👴',
  '👵',
  '👦',
  '👧',
  '🧒',
  '🧑‍⚕️',
  '👨‍⚕️',
  '👩‍⚕️',
];

const _groupesSanguins = [
  'A+',
  'A−',
  'B+',
  'B−',
  'AB+',
  'AB−',
  'O+',
  'O−',
];

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  bool _alarmeAutorisee = false;

  @override
  void initState() {
    super.initState();
    _verifierAlarme();
  }

  Future<void> _verifierAlarme() async {
    final ok = await AlarmService.instance.verifierAutorisation();
    if (mounted) setState(() => _alarmeAutorisee = ok);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.utilisateurConnecte;
    if (user == null) return const SizedBox.shrink();

    return MainScaffold(
      currentIndex: 3,
      child: Column(
        children: [
          _buildHeader(context, auth, user),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: [
                // ── Infos personnelles ──────────────────────────
                _SectionLabel('Informations personnelles'),
                const SizedBox(height: 8),
                _Card(children: [
                  _ProfilRow(
                    emoji: '🧑',
                    label: 'Nom complet',
                    value: user.nomComplet,
                    onTap: () => _editerTexte(
                      context,
                      auth,
                      user,
                      titre: 'Nom complet',
                      valeurActuelle: user.nomComplet,
                      onSave: (v) => user.copyWith(nomComplet: v),
                    ),
                  ),
                  _ProfilRow(
                    emoji: '🎂',
                    label: 'Date de naissance',
                    value: user.dateNaissance != null
                        ? _formatDate(user.dateNaissance!)
                        : 'Non renseignée',
                    valueFaded: user.dateNaissance == null,
                    onTap: () => _editerDateNaissance(context, auth, user),
                  ),
                  _ProfilRow(
                    emoji: '🩺',
                    label: 'Médecin traitant',
                    value: user.medecinTraitant?.isNotEmpty == true
                        ? user.medecinTraitant!
                        : 'Non renseigné',
                    valueFaded: user.medecinTraitant?.isEmpty ?? true,
                    onTap: () => _editerTexte(
                      context,
                      auth,
                      user,
                      titre: 'Médecin traitant',
                      hint: 'Dr. Martin',
                      valeurActuelle: user.medecinTraitant ?? '',
                      onSave: (v) => user.copyWith(medecinTraitant: v),
                    ),
                  ),
                ]),

                const SizedBox(height: 16),

                // ── Infos d'urgence ─────────────────────────────
                _SectionLabel("Informations d'urgence"),
                const SizedBox(height: 8),
                _UrgenceCard(
                  user: user,
                  onTap: () => _editerUrgences(context, auth, user),
                ),

                const SizedBox(height: 16),

                // ── Confidentialité ─────────────────────────────
                _Card(children: [
                  _ProfilRow(
                    emoji: '🔒',
                    label: 'Confidentialité',
                    value: 'Données 100% locales',
                    onTap: null,
                  ),
                ]),

                const SizedBox(height: 16),

                // ── Alarmes ─────────────────────────────────────
                _AlarmeCard(
                  autorisee: _alarmeAutorisee,
                  onDemander: () async {
                    await AlarmService.instance.ouvrirParametresAlarme();
                    await Future.delayed(const Duration(seconds: 1));
                    await _verifierAlarme();
                  },
                ),

                const SizedBox(height: 16),

                // ── Sécurité ────────────────────────────────────
                _SectionLabel('Sécurité'),
                const SizedBox(height: 8),
                _Card(children: [
                  _ProfilRow(
                    emoji: '🔑',
                    label: 'Mot de passe',
                    value: '••••••••',
                    onTap: () => context.go(AppRoutes.forgotPassword),
                  ),
                  _PinRow(auth: context.read<AuthService>()),
                ]),

                const SizedBox(height: 28),

                // ── Déconnexion ─────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmerDeconnexion(context, auth),
                    icon: const Icon(Icons.logout_rounded,
                        color: Color(0xFFEF4444), size: 18),
                    label: Text('Se déconnecter',
                        style: GoogleFonts.inter(
                            color: const Color(0xFFEF4444),
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFECACA)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader(
      BuildContext context, AuthService auth, Utilisateur user) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F2952), Color(0xFF1A4480)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mon Profil',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  )),
              const SizedBox(height: 20),

              // Avatar centré + bouton modifier
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => _choisirAvatar(context, auth, user),
                      child: Stack(
                        children: [
                          // Avatar : photo ou emoji
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.25),
                                  width: 3),
                            ),
                            child: ClipOval(
                              child: user.avatarPath != null
                                  ? Image.file(
                                      File(user.avatarPath!),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _emojiAvatar(user.avatarEmoji),
                                    )
                                  : _emojiAvatar(user.avatarEmoji),
                            ),
                          ),
                          // Badge crayon
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: const Color(0xFF1A4480), width: 2),
                              ),
                              child: const Icon(Icons.edit_rounded,
                                  size: 13, color: Color(0xFF1A4480)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user.nomComplet.isNotEmpty
                          ? user.nomComplet
                          : 'Utilisateur',
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Données stockées localement · RGPD ',
                          style: GoogleFonts.inter(
                              color: const Color(0xFF60A5FA), fontSize: 12),
                        ),
                        Text('✓',
                            style: GoogleFonts.inter(
                                color: const Color(0xFF60A5FA),
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emojiAvatar(String emoji) {
    return Center(child: Text(emoji, style: const TextStyle(fontSize: 40)));
  }

  // ─── Choisir avatar (galerie ou emoji) ───────────────────────────────────

  Future<void> _choisirAvatar(
      BuildContext context, AuthService auth, Utilisateur user) async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _AvatarPicker(
        user: user,
        onPhoto: () async {
          Navigator.pop(ctx);
          final picker = ImagePicker();
          final picked = await picker.pickImage(
              source: ImageSource.gallery, imageQuality: 80);
          if (picked != null) {
            final updated =
                user.copyWith(avatarPath: picked.path, clearAvatarPath: false);
            await auth.mettreAJourProfil(updated);
          }
        },
        onEmoji: (emoji) async {
          Navigator.pop(ctx);
          final updated =
              user.copyWith(avatarEmoji: emoji, clearAvatarPath: true);
          await auth.mettreAJourProfil(updated);
        },
      ),
    );
  }

  // ─── Éditer un champ texte ────────────────────────────────────────────────

  Future<void> _editerTexte(
    BuildContext context,
    AuthService auth,
    Utilisateur user, {
    required String titre,
    required String valeurActuelle,
    required Utilisateur Function(String) onSave,
    String? hint,
  }) async {
    final ctrl = TextEditingController(text: valeurActuelle);
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BottomSheetHandle(),
            const SizedBox(height: 16),
            Text(titre,
                style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              decoration: InputDecoration(hintText: hint ?? titre),
              style: GoogleFonts.inter(fontSize: 15),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
                child: Text('Enregistrer',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );

    if (result != null && result != valeurActuelle) {
      await auth.mettreAJourProfil(onSave(result));
    }
  }

  // ─── Éditer date de naissance ─────────────────────────────────────────────

  Future<void> _editerDateNaissance(
      BuildContext context, AuthService auth, Utilisateur user) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: user.dateNaissance ??
          DateTime.now().subtract(const Duration(days: 365 * 30)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('fr', 'FR'),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF2563EB),
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      await auth.mettreAJourProfil(user.copyWith(dateNaissance: picked));
    }
  }

  // ─── Éditer infos d'urgence ───────────────────────────────────────────────

  Future<void> _editerUrgences(
      BuildContext context, AuthService auth, Utilisateur user) async {
    String? groupeSelectionne = user.groupeSanguin;
    final allergiesCtrl = TextEditingController(text: user.allergies ?? '');
    final antecedentsCtrl = TextEditingController(text: user.antecedents ?? '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BottomSheetHandle(),
                const SizedBox(height: 16),
                Text("Informations d'urgence",
                    style: GoogleFonts.inter(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),

                // Groupe sanguin
                Text('Groupe sanguin',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _groupesSanguins.map((g) {
                    final selected = groupeSelectionne == g;
                    return GestureDetector(
                      onTap: () => setModalState(
                          () => groupeSelectionne = selected ? null : g),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF2563EB)
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(g,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFF374151),
                            )),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // Allergies
                Text('Allergies',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: allergiesCtrl,
                  decoration: const InputDecoration(
                      hintText: 'Ex: pénicilline, aspirine, arachides…'),
                  style: GoogleFonts.inter(fontSize: 14),
                  maxLines: 2,
                ),

                const SizedBox(height: 16),

                // Antécédents
                Text('Antécédents médicaux',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: antecedentsCtrl,
                  decoration: const InputDecoration(
                      hintText: 'Ex: diabète type 2, hypertension…'),
                  style: GoogleFonts.inter(fontSize: 14),
                  maxLines: 2,
                ),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await auth.mettreAJourProfil(user.copyWith(
                        groupeSanguin: groupeSelectionne,
                        allergies: allergiesCtrl.text.trim(),
                        antecedents: antecedentsCtrl.text.trim(),
                      ));
                    },
                    child: Text('Enregistrer',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Déconnexion ──────────────────────────────────────────────────────────

  Future<void> _confirmerDeconnexion(
      BuildContext context, AuthService auth) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Se déconnecter ?',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text('Vos données resteront sauvegardées localement.',
            style: GoogleFonts.inter()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Annuler', style: GoogleFonts.inter())),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Déconnecter',
                style: GoogleFonts.inter(
                    color: const Color(0xFFEF4444),
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      auth.deconnecter();
      if (context.mounted) context.go(AppRoutes.login);
    }
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// ════════════════════════════════════════════════════════════════════════════
// Bottom sheet avatar — galerie + sélection emoji
// ════════════════════════════════════════════════════════════════════════════

class _AvatarPicker extends StatelessWidget {
  final Utilisateur user;
  final VoidCallback onPhoto;
  final void Function(String emoji) onEmoji;

  const _AvatarPicker(
      {required this.user, required this.onPhoto, required this.onEmoji});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BottomSheetHandle(),
          const SizedBox(height: 16),
          Text('Choisir un avatar',
              style:
                  GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),

          // Bouton galerie
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onPhoto,
              icon: const Icon(Icons.photo_library_rounded, size: 18),
              label: Text('Choisir une photo',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Color(0xFF2563EB)),
                foregroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          const SizedBox(height: 16),
          Text('Ou choisir un emoji',
              style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF6B7280),
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),

          // Grille d'emojis
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _emojisAvatar.map((e) {
              final selected = user.avatarEmoji == e && user.avatarPath == null;
              return GestureDetector(
                onTap: () => onEmoji(e),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFFEFF6FF)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(14),
                    border: selected
                        ? Border.all(color: const Color(0xFF2563EB), width: 2)
                        : null,
                  ),
                  child: Center(
                      child: Text(e, style: const TextStyle(fontSize: 26))),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Widgets réutilisables
// ════════════════════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 0),
        child: Text(
          text.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF6B7280),
            letterSpacing: 0.8,
          ),
        ),
      );
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              const Divider(height: 1, indent: 60, color: Color(0xFFF3F4F6)),
          ],
        ],
      ),
    );
  }
}

class _ProfilRow extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final bool valueFaded;
  final VoidCallback? onTap;

  const _ProfilRow({
    required this.emoji,
    required this.label,
    required this.value,
    this.valueFaded = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10)),
              child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 1),
                  Text(value,
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: valueFaded
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF111827))),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right,
                  color: Color(0xFFD1D5DB), size: 20),
          ],
        ),
      ),
    );
  }
}

class _UrgenceCard extends StatelessWidget {
  final Utilisateur user;
  final VoidCallback onTap;

  const _UrgenceCard({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasData = user.hasUrgences;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1F2),
          border: Border.all(color: const Color(0xFFFECACA)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(10)),
              child: const Center(
                  child: Text('🚨', style: TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Informations d'urgence",
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFEF4444))),
                  const SizedBox(height: 4),
                  Text(
                    hasData
                        ? user.resumeUrgences
                        : 'Appuyez pour renseigner votre groupe sanguin, allergies et antécédents.',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                        height: 1.5),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFEF4444), size: 18),
          ],
        ),
      ),
    );
  }
}

class _AlarmeCard extends StatelessWidget {
  final bool autorisee;
  final VoidCallback onDemander;

  const _AlarmeCard({required this.autorisee, required this.onDemander});

  @override
  Widget build(BuildContext context) {
    if (autorisee) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          border: Border.all(color: const Color(0xFFBBF7D0)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Text('✅', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Alarmes exactes autorisées — les rappels sonneront à l\'heure.',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF16A34A),
                    fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        border: Border.all(color: const Color(0xFFFDE68A)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⏰', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Alarmes exactes non autorisées',
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF92400E))),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Sans cette permission, vos rappels ne sonneront pas à l\'heure exacte.',
            style: GoogleFonts.inter(
                fontSize: 12, color: const Color(0xFF78350F), height: 1.5),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onDemander,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Autoriser les alarmes exactes',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomSheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      );
}

// ════════════════════════════════════════════════════════════════════════════
// Ligne PIN — affiche l'état actuel et permet d'activer/désactiver
// ════════════════════════════════════════════════════════════════════════════

class _PinRow extends StatefulWidget {
  final AuthService auth;
  const _PinRow({required this.auth});

  @override
  State<_PinRow> createState() => _PinRowState();
}

class _PinRowState extends State<_PinRow> {
  bool _pinActif = false;

  @override
  void initState() {
    super.initState();
    widget.auth.pinActif.then((v) {
      if (mounted) setState(() => _pinActif = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _pinActif ? _desactiver() : _activer(),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                  child: Text('🔢', style: TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Code PIN',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w500)),
                  Text(_pinActif ? 'Activé' : 'Désactivé',
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _pinActif
                              ? const Color(0xFF16A34A)
                              : const Color(0xFF111827))),
                ],
              ),
            ),
            Switch(
              value: _pinActif,
              activeColor: const Color(0xFF2563EB),
              onChanged: (_) => _pinActif ? _desactiver() : _activer(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _activer() async {
    final pin = await _saisirPin(context, 'Choisir un code PIN');
    if (pin == null) return;
    final confirm = await _saisirPin(context, 'Confirmer le code PIN');
    if (confirm == null) return;
    if (pin != confirm) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Les codes ne correspondent pas'),
            backgroundColor: Color(0xFFEF4444)));
      }
      return;
    }
    await widget.auth.activerPin(pin);
    if (mounted) setState(() => _pinActif = true);
  }

  Future<void> _desactiver() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Désactiver le PIN ?',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text('L\'app s\'ouvrira directement sans code.',
            style: GoogleFonts.inter()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Annuler', style: GoogleFonts.inter())),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Désactiver',
                  style: GoogleFonts.inter(
                      color: const Color(0xFFEF4444),
                      fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirm == true) {
      await widget.auth.desactiverPin();
      if (mounted) setState(() => _pinActif = false);
    }
  }

  Future<String?> _saisirPin(BuildContext context, String titre) async {
    String pin = '';
    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(titre,
              style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                    4,
                    (i) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i < pin.length
                                ? const Color(0xFF2563EB)
                                : const Color(0xFFE5E7EB),
                          ),
                        )),
              ),
              const SizedBox(height: 20),
              // Mini clavier
              ...[
                [1, 2, 3],
                [4, 5, 6],
                [7, 8, 9],
                [null, 0, null]
              ].map(
                (rangee) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: rangee.map((n) {
                      if (n == null)
                        return const SizedBox(width: 60, height: 44);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: SizedBox(
                          width: 60,
                          height: 44,
                          child: OutlinedButton(
                            onPressed: () {
                              if (pin.length < 4) {
                                set(() => pin += n.toString());
                                if (pin.length == 4) Navigator.pop(ctx, pin);
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text('$n',
                                style: GoogleFonts.inter(
                                    fontSize: 18, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: Text('Annuler', style: GoogleFonts.inter())),
          ],
        ),
      ),
    );
  }
}
