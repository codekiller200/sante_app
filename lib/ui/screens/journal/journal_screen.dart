import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/prise.dart';
import '../../../data/repositories/prise_repository.dart';
import '../../widgets/main_scaffold.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  late int _annee;
  late int _mois;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _annee = now.year;
    _mois  = now.month;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PriseRepository>().chargerMois(_annee, _mois);
    });
  }

  void _changerMois(int delta) {
    setState(() {
      _mois += delta;
      if (_mois > 12) { _mois = 1; _annee++; }
      if (_mois < 1)  { _mois = 12; _annee--; }
    });
    context.read<PriseRepository>().chargerMois(_annee, _mois);
  }

  // Grouper les prises par jour
  Map<String, List<Prise>> _grouperParJour(List<Prise> prises) {
    final Map<String, List<Prise>> grouped = {};
    for (final p in prises) {
      final key = DateFormat('yyyy-MM-dd').format(p.datePrevue);
      grouped.putIfAbsent(key, () => []).add(p);
    }
    return Map.fromEntries(
      grouped.entries.toList()..sort((a, b) => b.key.compareTo(a.key)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<PriseRepository>();
    final grouped = _grouperParJour(repo.prisesDuMois);
    final moisLabel = DateFormat('MMMM yyyy', 'fr_FR').format(DateTime(_annee, _mois));

    return MainScaffold(
      currentIndex: 2,
      child: Column(
        children: [
          // Header
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Journal de Bord',
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    // Navigation mois
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _changerMois(-1),
                          child: const Icon(Icons.chevron_left, color: AppColors.blue300),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          moisLabel[0].toUpperCase() + moisLabel.substring(1),
                          style: const TextStyle(color: AppColors.blue300, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _changerMois(1),
                          child: const Icon(Icons.chevron_right, color: AppColors.blue300),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: repo.prisesDuMois.isEmpty
                ? _EmptyJournal()
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Carte observance
                      _ObservanceSummary(
                        observance: repo.observance,
                        prises: repo.prisesDuMois,
                      ),
                      const SizedBox(height: 16),

                      // Groupes par jour
                      ...grouped.entries.map((entry) {
                        final date = DateTime.parse(entry.key);
                        final prises = entry.value;
                        final prisesOk = prises.where((p) => p.statut == StatutPrise.prise).length;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _DayHeader(date: date, prisesOk: prisesOk, total: prises.length),
                              const SizedBox(height: 8),
                              ...prises.map((p) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: _PriseTile(prise: p),
                                  )),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets ──────────────────────────────────────────────────────

class _ObservanceSummary extends StatelessWidget {
  final double observance;
  final List<Prise> prises;
  const _ObservanceSummary({required this.observance, required this.prises});

  String get _message {
    if (observance >= 90) return 'Excellente observance 🎯';
    if (observance >= 75) return 'Très bonne observance 👍';
    if (observance >= 50) return 'Observance à améliorer';
    return 'Pensez à prendre vos médicaments';
  }

  @override
  Widget build(BuildContext context) {
    final ok = prises.where((p) => p.statut == StatutPrise.prise).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.blue900, Color(0xFF1E3A5F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          // Cercle
          SizedBox(
            width: 64, height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: observance / 100,
                  strokeWidth: 5,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation(AppColors.green),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(observance.toStringAsFixed(0), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                    const Text('%', style: TextStyle(color: Colors.white54, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_message, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('$ok prises sur ${prises.length} effectuées ce mois-ci.',
                    style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  final DateTime date;
  final int prisesOk;
  final int total;
  const _DayHeader({required this.date, required this.prisesOk, required this.total});

  @override
  Widget build(BuildContext context) {
    final isToday = DateFormat('yyyy-MM-dd').format(date) == DateFormat('yyyy-MM-dd').format(DateTime.now());
    final label = isToday ? "Aujourd'hui" : DateFormat('EEEE d MMM', 'fr_FR').format(date);

    Color badgeColor;
    String badgeText;
    if (prisesOk == total) {
      badgeColor = AppColors.green;
      badgeText = '$prisesOk/$total ✓';
    } else if (prisesOk == 0) {
      badgeColor = AppColors.red;
      badgeText = '$prisesOk/$total';
    } else {
      badgeColor = AppColors.orange;
      badgeText = '$prisesOk/$total';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label[0].toUpperCase() + label.substring(1),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.gray900)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(badgeText,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: badgeColor, fontFamily: 'DM Mono')),
        ),
      ],
    );
  }
}

class _PriseTile extends StatelessWidget {
  final Prise prise;
  const _PriseTile({required this.prise});

  @override
  Widget build(BuildContext context) {
    Widget statusIcon;
    String statusText;

    switch (prise.statut) {
      case StatutPrise.prise:
        statusIcon = Container(
          width: 30, height: 30,
          decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(8)),
          child: const Center(child: Text('✅', style: TextStyle(fontSize: 14))),
        );
        statusText = 'Pris';
        break;
      case StatutPrise.ignoree:
        statusIcon = Container(
          width: 30, height: 30,
          decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8)),
          child: const Center(child: Text('❌', style: TextStyle(fontSize: 14))),
        );
        statusText = 'Ignoré';
        break;
      case StatutPrise.snoozee:
        statusIcon = Container(
          width: 30, height: 30,
          decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(8)),
          child: const Center(child: Text('⏱', style: TextStyle(fontSize: 14))),
        );
        statusText = 'Snoozé${prise.snoozeMinutes != null ? " +${prise.snoozeMinutes}min" : ""}';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4)],
      ),
      child: Row(
        children: [
          statusIcon,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(prise.medicamentNom,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray900)),
                Text(statusText, style: const TextStyle(fontSize: 11, color: AppColors.gray400)),
              ],
            ),
          ),
          Text(
            DateFormat('HH:mm').format(prise.datePrise ?? prise.datePrevue),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.gray600, fontFamily: 'DM Mono'),
          ),
        ],
      ),
    );
  }
}

class _EmptyJournal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('📋', style: TextStyle(fontSize: 48)),
          SizedBox(height: 12),
          Text('Aucune prise ce mois-ci', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.gray600)),
          SizedBox(height: 4),
          Text('Les prises confirmées apparaîtront ici', style: TextStyle(fontSize: 13, color: AppColors.gray400)),
        ],
      ),
    );
  }
}
