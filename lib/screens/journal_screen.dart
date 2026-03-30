import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:mediremind/core/constants/app_colors.dart';
import 'package:mediremind/data/repositories/prise_repository.dart';
import 'package:mediremind/models/prise.dart';
import 'package:mediremind/widgets/main_navigation_scaffold.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<PriseRepository>().chargerMois(_year, _month);
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<PriseRepository>();
    final grouped = _groupByDay(repo.prisesDuMois);
    final monthLabel =
        DateFormat('MMMM yyyy', 'fr_FR').format(DateTime(_year, _month));

    return MainNavigationScaffold(
      currentIndex: 2,
      title: 'Journal de Bord',
      subtitle: '${monthLabel[0].toUpperCase()}${monthLabel.substring(1)}',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (repo.prisesDuMois.isEmpty && repo.observance == 0) ...[
            const SizedBox(height: 32),
          ],
          _ObservanceSummary(
            observance: repo.observance,
            completed: repo.prisesDuMois
                .where((prise) => prise.statut == StatutPrise.prise)
                .length,
            total: repo.prisesDuMois.length,
          ),
          const SizedBox(height: 16),
          ...grouped.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _DayGroup(
                date: entry.key,
                prises: entry.value,
              ),
            ),
          ),
          if (grouped.isEmpty) _EmptyJournal(monthLabel: monthLabel),
        ],
      ),
    );
  }

  Map<DateTime, List<Prise>> _groupByDay(List<Prise> prises) {
    final grouped = <DateTime, List<Prise>>{};
    for (final prise in prises) {
      final day = DateTime(
          prise.datePrevue.year, prise.datePrevue.month, prise.datePrevue.day);
      grouped.putIfAbsent(day, () => []).add(prise);
    }
    final entries = grouped.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    return Map.fromEntries(entries);
  }
}

class _ObservanceSummary extends StatelessWidget {
  const _ObservanceSummary({
    required this.observance,
    required this.completed,
    required this.total,
  });

  final double observance;
  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = (observance / 100).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.blue900, Color(0xFF1E3A5F)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 4,
                    backgroundColor: Colors.white.withValues(alpha: 0.16),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.green),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      observance.toStringAsFixed(0),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    Text(
                      '%',
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(color: Colors.white70),
                    ),
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
                Text(
                  _headline,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$completed prises effectuées sur $total ce mois-ci.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _headline {
    if (observance >= 90) return 'Excellente observance';
    if (observance >= 75) return 'Tres bonne observance';
    if (observance >= 50) return 'Observance à ameliorer';
    return 'Pensez a vos prises';
  }
}

class _DayGroup extends StatelessWidget {
  const _DayGroup({
    required this.date,
    required this.prises,
  });

  final DateTime date;
  final List<Prise> prises;

  @override
  Widget build(BuildContext context) {
    final completed =
        prises.where((prise) => prise.statut == StatutPrise.prise).length;
    final badgeColor = completed == prises.length
        ? AppColors.green
        : completed == 0
            ? AppColors.red
            : AppColors.orange;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _dayLabel(date),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.gray600,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$completed/${prises.length}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: badgeColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        ...prises.map(
          (prise) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _JournalEntry(prise: prise),
          ),
        ),
      ],
    );
  }

  String _dayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final current = DateTime(date.year, date.month, date.day);

    if (current == today) {
      return "AUJOURD'HUI · ${DateFormat('d MMM.', 'fr_FR').format(date).toUpperCase()}";
    }
    if (current == yesterday) {
      return 'HIER · ${DateFormat('d MMM.', 'fr_FR').format(date).toUpperCase()}';
    }
    return '${DateFormat('EEEE', 'fr_FR').format(date).toUpperCase()} · ${DateFormat('d MMM.', 'fr_FR').format(date).toUpperCase()}';
  }
}

class _JournalEntry extends StatelessWidget {
  const _JournalEntry({required this.prise});

  final Prise prise;

  @override
  Widget build(BuildContext context) {
    final config = switch (prise.statut) {
      StatutPrise.prise => (
          Icons.check_rounded,
          AppColors.green,
          'Prise confirmee'
        ),
      StatutPrise.ignoree => (Icons.close_rounded, AppColors.red, 'Ignoree'),
      StatutPrise.snoozee => (
          Icons.alarm_rounded,
          AppColors.orange,
          'Snooze ${prise.snoozeMinutes ?? 0} min'
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: config.$2.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(config.$1, size: 16, color: config.$2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prise.medicamentNom,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontSize: 13),
                ),
                Text(
                  config.$3,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.gray400),
                ),
              ],
            ),
          ),
          Text(
            DateFormat('HH:mm').format(prise.datePrise ?? prise.datePrevue),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.gray600,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _EmptyJournal extends StatelessWidget {
  const _EmptyJournal({required this.monthLabel});

  final String monthLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          const Text('📋', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 12),
          Text(
            'Aucune prise pour $monthLabel',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Les prises confirmées, ignorées ou reportées apparaitront ici.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
