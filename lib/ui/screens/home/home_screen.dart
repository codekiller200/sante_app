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
          _buildHeader(auth, now),
          Expanded(
            child: medRepo.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () async {
                      await medRepo.charger();
                      await priseRepo.chargerAujourdhui();
                    },
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (prochaine != null) ...[
                          _NextDoseCard(
                            medicament: prochaine,
                            heure: _getProchainHeure(prochaine, now),
                            onPris: () => _confirmerPrise(prochaine, priseRepo),
                            onSnooze: () => _snoozerPrise(prochaine, priseRepo),
                          ),
                          const SizedBox(height: 16),
                        ],
                        _ObservanceCard(
                          observance: priseRepo.observance,
                          prisesEffectuees: priseRepo.prisesDuMois
                              .where((p) => p.statut == StatutPrise.prise)
                              .length,
                          totalPrises: priseRepo.prisesDuMois.length,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Aujourd'hui",
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.gray900,
                              letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 10),
                        if (medRepo.medicaments.isEmpty)
                          _EmptyState()
                        else
                          ...medRepo.medicaments.map((m) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _MedTodayCard(medicament: m, now: now),
                              )),
                        ..._buildStockAlertes(medRepo.medicaments),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

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

  Future<int?> _showSnoozeDialog() async {
    return showModalBottomSheet<int>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStockAlertes(List<Medicament> meds) {
    final bas = meds.where((m) => m.stockBas).toList();
    if (bas.isEmpty) return [];

    return [
      const SizedBox(height: 16),
      const Text('⚠️ Stock bas',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.orange)),
      const SizedBox(height: 8),
      ...bas.map((m) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _StockAlerteTile(medicament: m),
          )),
    ];
  }

  Widget _buildHeader(AuthService auth, DateTime now) {
    final prenom = auth.utilisateurConnecte?.nomComplet.split(' ').first ?? '';
    final dateStr = DateFormat('EEEE d MMMM', 'fr_FR').format(now);

    return Container(
      width: double.infinity,
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bonjour, ${prenom.isNotEmpty ? prenom : 'à tous'} 👋',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _capitalizeFirst(dateStr),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
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

class _NextDoseCard extends StatelessWidget {
  final Medicament medicament;
  final String heure;
  final VoidCallback onPris;
  final VoidCallback onSnooze;

  const _NextDoseCard(
      {required this.medicament,
      required this.heure,
      required this.onPris,
      required this.onSnooze});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.blue700, AppColors.teal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: AppColors.blue700.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('⏰ PROCHAINE PRISE',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2)),
          const SizedBox(height: 6),
          Text(heure,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  height: 1)),
          const SizedBox(height: 4),
          Text('${medicament.icone} ${medicament.nom} · ${medicament.dosage}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onPris,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.blue700,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  child: const Text('✓ Pris',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: onSnooze,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white54),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
                child: const Text('⏱ Snooze',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ObservanceCard extends StatelessWidget {
  final double observance;
  final int prisesEffectuees;
  final int totalPrises;

  const _ObservanceCard(
      {required this.observance,
      required this.prisesEffectuees,
      required this.totalPrises});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Observance ce mois',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray900)),
              Text(
                '${observance.toStringAsFixed(0)}%',
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.green),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: observance / 100,
              minHeight: 8,
              backgroundColor: AppColors.gray100,
              valueColor: const AlwaysStoppedAnimation(AppColors.green),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '$prisesEffectuees prises sur $totalPrises effectuées',
              style: const TextStyle(fontSize: 11, color: AppColors.gray400),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedTodayCard extends StatelessWidget {
  final Medicament medicament;
  final DateTime now;

  const _MedTodayCard({required this.medicament, required this.now});

  @override
  Widget build(BuildContext context) {
    final prochainHoraire = medicament.horaires.firstWhere(
      (h) {
        final parts = h.split(':');
        final heure = DateTime(now.year, now.month, now.day,
            int.parse(parts[0]), int.parse(parts[1]));
        return heure.isAfter(now);
      },
      orElse: () => medicament.horaires.last,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                color: AppColors.blue50,
                borderRadius: BorderRadius.circular(12)),
            child: Center(
                child: Text(medicament.icone,
                    style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(medicament.nom,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray900)),
                Text(
                    '${medicament.dosage} · ${medicament.frequenceParJour}x/jour',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.gray400)),
              ],
            ),
          ),
          Text(prochainHoraire,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blue700,
                  fontFamily: 'DM Mono')),
        ],
      ),
    );
  }
}

class _StockAlerteTile extends StatelessWidget {
  final Medicament medicament;
  const _StockAlerteTile({required this.medicament});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        border: Border.all(color: const Color(0xFFFDE68A)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(medicament.icone, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(medicament.nom,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray900)),
                Text('${medicament.joursRestants} jours restants',
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.orange,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          StockIndicator(medicament: medicament),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Text('💊', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text('Aucun médicament ajouté',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray600)),
            SizedBox(height: 4),
            Text('Allez dans "Médicaments" pour commencer',
                style: TextStyle(fontSize: 13, color: AppColors.gray400)),
          ],
        ),
      ),
    );
  }
}
