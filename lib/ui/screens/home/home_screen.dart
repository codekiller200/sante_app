import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/medicament.dart';
import '../../../data/models/prise.dart';
import '../../../data/repositories/medicament_repository.dart';
import '../../../data/repositories/prise_repository.dart';
import '../../../services/auth_service.dart';
import '../../widgets/main_scaffold.dart';
import '../../widgets/stock_indicator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MedicamentRepository>().charger();
      context.read<PriseRepository>().chargerAujourdhui();
      final now = DateTime.now();
      context.read<PriseRepository>().chargerMois(now.year, now.month);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final medRepo = context.watch<MedicamentRepository>();
    final priseRepo = context.watch<PriseRepository>();
    final now = DateTime.now();

    final prochaine = medRepo.medicaments.isNotEmpty
        ? _getProchainePrise(medRepo.medicaments, now)
        : null;

    return MainScaffold(
      currentIndex: 0,
      child: Column(
        children: [
          _buildHeader(auth, now, priseRepo, medRepo.medicaments),
          Expanded(
            child: medRepo.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () async {
                      await medRepo.charger();
                      await priseRepo.chargerAujourdhui();
                    },
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                      children: [
                        // ── Bouton prochaine prise ──────────────────────────
                        if (prochaine != null) ...[
                          _ProchainePriseBanner(
                            medicament: prochaine,
                            heure: _getProchainHeure(prochaine, now),
                            onPris: () => _confirmerPrise(prochaine, priseRepo),
                            onSnooze: () => _snoozerPrise(prochaine, priseRepo),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // ── Liste médicaments du jour ───────────────────────
                        const Text(
                          'AUJOURD\'HUI',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF9CA3AF),
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 10),

                        if (medRepo.medicaments.isEmpty)
                          _EmptyState()
                        else
                          ...medRepo.medicaments.map((m) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _MedTodayCard(
                                  medicament: m,
                                  now: now,
                                  prises: priseRepo.prisesAujourdhui,
                                ),
                              )),

                        // ── Observance ──────────────────────────────────────
                        if (medRepo.medicaments.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _ObservanceCard(
                            observance: priseRepo.observance,
                            prisesEffectuees: priseRepo.prisesDuMois
                                .where((p) => p.statut == StatutPrise.prise)
                                .length,
                            totalPrises: priseRepo.prisesDuMois.length,
                          ),
                        ],

                        // ── Alertes stock bas ───────────────────────────────
                        ..._buildStockAlertes(medRepo.medicaments),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  Medicament? _getProchainePrise(List<Medicament> meds, DateTime now) {
    for (final med in meds) {
      for (final horaire in med.horaires) {
        final parts = horaire.split(':');
        final heure = DateTime(now.year, now.month, now.day,
            int.parse(parts[0]), int.parse(parts[1]));
        if (heure.isAfter(now)) return med;
      }
    }
    return null;
  }

  String _getProchainHeure(Medicament med, DateTime now) {
    for (final horaire in med.horaires) {
      final parts = horaire.split(':');
      final heure = DateTime(now.year, now.month, now.day, int.parse(parts[0]),
          int.parse(parts[1]));
      if (heure.isAfter(now)) return horaire;
    }
    return med.horaires.first;
  }

  Future<void> _confirmerPrise(Medicament med, PriseRepository repo) async {
    final prise = Prise(
      medicamentId: med.id!,
      medicamentNom: med.nom,
      medicamentIcone: med.icone,
      statut: StatutPrise.prise,
      datePrevue: DateTime.now(),
      datePrise: DateTime.now(),
    );
    await repo.enregistrer(prise);
    await context.read<MedicamentRepository>().decrementerStock(med.id!);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${med.nom} marqué comme pris ✓'),
          backgroundColor: AppColors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _snoozerPrise(Medicament med, PriseRepository repo) async {
    final minutes = await _showSnoozeDialog();
    if (minutes == null) return;

    final prise = Prise(
      medicamentId: med.id!,
      medicamentNom: med.nom,
      medicamentIcone: med.icone,
      statut: StatutPrise.snoozee,
      datePrevue: DateTime.now(),
      snoozeMinutes: minutes,
    );
    await repo.enregistrer(prise);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rappel dans $minutes minutes'),
          backgroundColor: AppColors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<int?> _showSnoozeDialog() {
    return showModalBottomSheet<int>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Reporter de…',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Row(
              children: [10, 30, 60]
                  .map((min) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx, min),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.blue100),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text('$min min',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.blue700)),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStockAlertes(List<Medicament> meds) {
    final bas = meds.where((m) => m.stockBas).toList();
    if (bas.isEmpty) return [];

    return [
      const SizedBox(height: 20),
      const Text('⚠️ Stock bas',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.orange,
              letterSpacing: 1.2)),
      const SizedBox(height: 8),
      ...bas.map((m) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _StockAlerteTile(medicament: m),
          )),
    ];
  }

  // ─── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader(
    AuthService auth,
    DateTime now,
    PriseRepository priseRepo,
    List<Medicament> meds,
  ) {
    final prenom = auth.utilisateurConnecte?.nomComplet.split(' ').first ?? '';
    final dateStr = DateFormat('EEEE d MMM.', 'fr_FR').format(now);

    // Compter les prises prévues aujourd'hui
    final totalHoraires =
        meds.fold<int>(0, (sum, m) => sum + m.horaires.length);

    return Container(
      width: double.infinity,
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
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bonjour + prénom
              Row(
                children: [
                  Text(
                    'Bonjour, ${prenom.isNotEmpty ? prenom : 'vous'} ',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Text('👋', style: TextStyle(fontSize: 15)),
                ],
              ),
              const SizedBox(height: 2),
              // Date
              Text(
                _capitalizeFirst(dateStr),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              // Nombre de prises
              if (totalHoraires > 0)
                Text(
                  '$totalHoraires prise${totalHoraires > 1 ? 's' : ''} prévue${totalHoraires > 1 ? 's' : ''} aujourd\'hui',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Bannière "Prochaine Prise" — bouton gradient pleine largeur
// ════════════════════════════════════════════════════════════════════════════

class _ProchainePriseBanner extends StatelessWidget {
  final Medicament medicament;
  final String heure;
  final VoidCallback onPris;
  final VoidCallback onSnooze;

  const _ProchainePriseBanner({
    required this.medicament,
    required this.heure,
    required this.onPris,
    required this.onSnooze,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPris,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF38BDF8)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            const Text('⏰', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            const Text(
              'PROCHAINE PRISE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
            const Spacer(),
            // Petit bouton snooze discret
            GestureDetector(
              onTap: onSnooze,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '⏱ Snooze',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Carte médicament du jour — style maquette
// ════════════════════════════════════════════════════════════════════════════

class _MedTodayCard extends StatelessWidget {
  final Medicament medicament;
  final DateTime now;
  final List<Prise> prises;

  const _MedTodayCard({
    required this.medicament,
    required this.now,
    required this.prises,
  });

  bool get _estPrisAujourdhui {
    return prises.any((p) =>
        p.medicamentId == medicament.id && p.statut == StatutPrise.prise);
  }

  String get _prochainHoraire {
    return medicament.horaires.firstWhere(
      (h) {
        final parts = h.split(':');
        final heure = DateTime(now.year, now.month, now.day,
            int.parse(parts[0]), int.parse(parts[1]));
        return heure.isAfter(now);
      },
      orElse: () => medicament.horaires.last,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pris = _estPrisAujourdhui;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icone médicament
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                medicament.icone,
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Nom + dosage + fréquence
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicament.nom,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${medicament.dosage} · ${medicament.frequenceParJour}x par jour',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // Heure + coche si pris
          Row(
            children: [
              Text(
                _prochainHoraire,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color:
                      pris ? const Color(0xFF9CA3AF) : const Color(0xFF2563EB),
                  decoration: pris ? TextDecoration.lineThrough : null,
                ),
              ),
              if (pris) ...[
                const SizedBox(width: 4),
                const Text(
                  '✓',
                  style: TextStyle(
                    color: Color(0xFF22C55E),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Carte observance
// ════════════════════════════════════════════════════════════════════════════

class _ObservanceCard extends StatelessWidget {
  final double observance;
  final int prisesEffectuees;
  final int totalPrises;

  const _ObservanceCard({
    required this.observance,
    required this.prisesEffectuees,
    required this.totalPrises,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Observance ce mois',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              Text(
                '${observance.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF22C55E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: totalPrises == 0 ? 0 : observance / 100,
              minHeight: 8,
              backgroundColor: const Color(0xFFF3F4F6),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF22C55E)),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '$prisesEffectuees prises sur $totalPrises effectuées',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Alerte stock bas
// ════════════════════════════════════════════════════════════════════════════

class _StockAlerteTile extends StatelessWidget {
  final Medicament medicament;
  const _StockAlerteTile({required this.medicament});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        border: Border.all(color: const Color(0xFFFDE68A)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(medicament.icone, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicament.nom,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  '${medicament.joursRestants} jours restants',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          StockIndicator(medicament: medicament),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// État vide
// ════════════════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text('💊', style: TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucun médicament ajouté',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Allez dans "Médicaments" pour commencer',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
