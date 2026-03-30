import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:mediremind/core/constants/app_colors.dart';
import 'package:mediremind/core/constants/app_routes.dart';
import 'package:mediremind/data/repositories/medicament_repository.dart';
import 'package:mediremind/models/medicament.dart';
import 'package:mediremind/widgets/main_navigation_scaffold.dart';

class MedicamentListScreen extends StatefulWidget {
  const MedicamentListScreen({super.key});

  @override
  State<MedicamentListScreen> createState() => _MedicamentListScreenState();
}

class _MedicamentListScreenState extends State<MedicamentListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MedicamentRepository>().charger();
    });
  }

  Future<void> _delete(Medicament medicament) async {
    if (medicament.id == null) return;
    await context.read<MedicamentRepository>().supprimer(medicament.id!);
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<MedicamentRepository>();

    return MainNavigationScaffold(
      currentIndex: 1,
      title: 'Mes Médicaments',
      subtitle: '${repo.medicaments.length} traitement(s) actif(s)',
      actions: [
        IconButton(
          onPressed: () => context.go(AppRoutes.formMedicament),
          icon: const Icon(Icons.add, color: Colors.white),
        ),
      ],
      child: Stack(
        children: [
          ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 92),
            itemBuilder: (context, index) {
              final medicament = repo.medicaments[index];
              return _MedicationCard(
                medicament: medicament,
                onEdit: () => context.go(AppRoutes.formMedicament, extra: medicament.id),
                onDelete: () => _delete(medicament),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemCount: repo.medicaments.length,
          ),
          if (repo.isLoading)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(),
            ),
          Positioned(
            right: 16,
            bottom: 18,
            child: InkWell(
              onTap: () => context.go(AppRoutes.formMedicament),
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.blue700, AppColors.teal],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.blue700.withValues(alpha: 0.30),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicationCard extends StatelessWidget {
  const _MedicationCard({
    required this.medicament,
    required this.onEdit,
    required this.onDelete,
  });

  final Medicament medicament;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _iconBackground(medicament).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(medicament.icone, style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicament.nom,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${medicament.dosage} · Comprimé',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.gray400,
                          ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Modifier')),
                  PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                ],
                icon: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.more_horiz, size: 18, color: AppColors.gray400),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _TagChip('${medicament.frequenceParJour}x / jour'),
              _TagChip(medicament.horaires.join(' · ')),
              const _TagChip('Actif', success: true),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Stock',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.gray400),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: (medicament.joursRestants / 45).clamp(0, 1).toDouble(),
                    backgroundColor: AppColors.gray100,
                    valueColor: AlwaysStoppedAnimation<Color>(_stockColor(medicament)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${medicament.joursRestants}j',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: _stockColor(medicament),
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _iconBackground(Medicament medicament) {
    if (medicament.joursRestants <= 7) return AppColors.orange;
    if (medicament.frequenceParJour >= 3) return AppColors.blue700;
    return AppColors.green;
  }

  Color _stockColor(Medicament medicament) {
    if (medicament.joursRestants <= 7) return AppColors.orange;
    if (medicament.joursRestants <= 3) return AppColors.red;
    return medicament.joursRestants >= 30 ? AppColors.blue500 : AppColors.green;
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip(this.label, {this.success = false});

  final String label;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final background = success ? AppColors.green.withValues(alpha: 0.10) : AppColors.blue50;
    final foreground = success ? AppColors.green : AppColors.blue700;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
