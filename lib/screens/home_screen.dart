import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:mediremind/core/constants/app_colors.dart';
import 'package:mediremind/data/repositories/medicament_repository.dart';
import 'package:mediremind/data/repositories/prise_repository.dart';
import 'package:mediremind/models/medicament.dart';
import 'package:mediremind/models/prise.dart';
import 'package:mediremind/services/alarm_service.dart';
import 'package:mediremind/services/auth_service.dart';
import 'package:mediremind/widgets/main_navigation_scaffold.dart';
import 'package:mediremind/widgets/section_card.dart';
import 'package:mediremind/widgets/stock_indicator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int? _markingMedicationId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final medicamentRepository = context.read<MedicamentRepository>();
      final priseRepository = context.read<PriseRepository>();
      await Future.wait([
        medicamentRepository.charger(),
        priseRepository.chargerAujourdhui(),
      ]);
      if (!mounted) return;
      final now = DateTime.now();
      await priseRepository.chargerMois(now.year, now.month);
    });
  }

  Future<void> _markTaken(_ScheduledMedication scheduledMedication) async {
    final medicament = scheduledMedication.medicament;
    if (medicament.id == null) return;

    setState(() => _markingMedicationId = medicament.id);

    final priseRepository = context.read<PriseRepository>();
    final medicamentRepository = context.read<MedicamentRepository>();

    await AlarmService.instance.stopActiveAlarm();

    final prise = Prise(
      medicamentId: medicament.id!,
      medicamentNom: medicament.nom,
      medicamentIcone: medicament.icone,
      statut: StatutPrise.prise,
      datePrevue: scheduledMedication.scheduledAt,
      datePrise: DateTime.now(),
    );

    await priseRepository.enregistrer(prise);
    if (!mounted) return;
    await medicamentRepository.decrementerStock(medicament.id!);
    if (!mounted) return;

    setState(() => _markingMedicationId = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${medicament.nom} marqué comme pris. Le bouton reviendra à la prochaine prise.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final medicamentRepository = context.watch<MedicamentRepository>();
    final meds = medicamentRepository.medicaments;
    final prises = context.watch<PriseRepository>();
    final firstName = auth.user?.nomComplet.split(' ').first ?? 'vous';
    final nextMedication = _findNextScheduledMedication(
      medications: meds,
      todayPrises: prises.prisesAujourdhui,
      now: DateTime.now(),
    );

    return MainNavigationScaffold(
      currentIndex: 0,
      title: 'Bonjour, $firstName',
      subtitle: DateFormat('EEEE d MMMM', 'fr_FR').format(DateTime.now()),
      child: RefreshIndicator(
        onRefresh: () async {
          final priseRepository = context.read<PriseRepository>();
          await Future.wait([
            context.read<MedicamentRepository>().charger(),
            priseRepository.chargerAujourdhui(),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (medicamentRepository.isLoading) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 16),
            ],
            if (nextMedication != null) ...[
              _NextDoseCard(
                scheduledMedication: nextMedication,
                isProcessing: _markingMedicationId == nextMedication.medicament.id,
                onTaken: () => _markTaken(nextMedication),
              ),
              const SizedBox(height: 16),
            ],
            SectionCard(
              title: 'Synthese du jour',
              child: Row(
                children: [
                  _Metric(label: 'Medicaments', value: meds.length.toString()),
                  _Metric(label: 'Prises', value: prises.prisesAujourdhui.length.toString()),
                  _Metric(label: 'Observance', value: prises.observanceFormatee),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Traitements actifs',
              child: meds.isEmpty
                  ? const Text('Ajoutez votre premier traitement depuis l\'onglet Medicaments.')
                  : Column(
                      children: meds
                          .map(
                            (medicament) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Text(medicament.icone, style: const TextStyle(fontSize: 24)),
                              title: Text(medicament.nom),
                              subtitle: Text(
                                '${medicament.dosage} · ${medicament.horaires.join(', ')}'
                                '${medicament.intervalleJours > 1 ? ' · tous les ${medicament.intervalleJours} jours' : ''}',
                              ),
                              trailing: StockIndicator(medicament: medicament),
                            ),
                          )
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

_ScheduledMedication? _findNextScheduledMedication({
  required List<Medicament> medications,
  required List<Prise> todayPrises,
  required DateTime now,
}) {
  final candidates = <_ScheduledMedication>[];

  for (final medicament in medications.where((item) => item.estActif && item.id != null)) {
    if (!_isMedicationDueToday(medicament, now)) {
      continue;
    }

    for (final schedule in medicament.horaires) {
      final scheduledAt = _scheduledDateTime(now, schedule);
      if (scheduledAt == null || scheduledAt.isAfter(now)) {
        continue;
      }

      final alreadyTaken = todayPrises.any(
        (prise) =>
            prise.medicamentId == medicament.id &&
            prise.statut == StatutPrise.prise &&
            _isSameScheduledSlot(prise.datePrevue, scheduledAt),
      );

      if (!alreadyTaken) {
        candidates.add(
          _ScheduledMedication(
            medicament: medicament,
            scheduledAt: scheduledAt,
            label: schedule,
          ),
        );
      }
    }
  }

  if (candidates.isEmpty) return null;

  candidates.sort((left, right) => right.scheduledAt.compareTo(left.scheduledAt));
  return candidates.first;
}

bool _isMedicationDueToday(Medicament medicament, DateTime now) {
  if (medicament.intervalleJours <= 1) return true;
  final creationDay = DateTime(
    medicament.dateCreation.year,
    medicament.dateCreation.month,
    medicament.dateCreation.day,
  );
  final currentDay = DateTime(now.year, now.month, now.day);
  final difference = currentDay.difference(creationDay).inDays;
  return difference >= 0 && difference % medicament.intervalleJours == 0;
}

DateTime? _scheduledDateTime(DateTime reference, String value) {
  final parts = value.split(':');
  if (parts.length != 2) return null;

  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;

  return DateTime(reference.year, reference.month, reference.day, hour, minute);
}

bool _isSameScheduledSlot(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day &&
      left.hour == right.hour &&
      left.minute == right.minute;
}

class _ScheduledMedication {
  const _ScheduledMedication({
    required this.medicament,
    required this.scheduledAt,
    required this.label,
  });

  final Medicament medicament;
  final DateTime scheduledAt;
  final String label;
}

class _NextDoseCard extends StatelessWidget {
  const _NextDoseCard({
    required this.scheduledMedication,
    required this.onTaken,
    required this.isProcessing,
  });

  final _ScheduledMedication scheduledMedication;
  final VoidCallback onTaken;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    final medicament = scheduledMedication.medicament;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.blue700, AppColors.teal],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Prochaine prise',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white70,
                  letterSpacing: 1.1,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            scheduledMedication.label,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontSize: 34,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            '${medicament.icone} ${medicament.nom} · ${medicament.dosage}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white),
          ),
          if (medicament.intervalleJours > 1) ...[
            const SizedBox(height: 4),
            Text(
              'Tous les ${medicament.intervalleJours} jours',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isProcessing ? null : onTaken,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.blue700,
              ),
              child: isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Pris'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
