import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../data/models/medicament.dart';
import '../../../data/repositories/medicament_repository.dart';
import '../../widgets/main_scaffold.dart';
import '../../widgets/stock_indicator.dart';

class ListeMedicamentsScreen extends StatefulWidget {
  const ListeMedicamentsScreen({super.key});

  @override
  State<ListeMedicamentsScreen> createState() => _ListeMedicamentsScreenState();
}

class _ListeMedicamentsScreenState extends State<ListeMedicamentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MedicamentRepository>().charger();
    });
  }

  Future<void> _confirmerSuppression(Medicament med) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer ?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Voulez-vous supprimer ${med.nom} ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Supprimer', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<MedicamentRepository>().supprimer(med.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<MedicamentRepository>();

    return MainScaffold(
      currentIndex: 1,
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Mes Médicaments',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800)),
                        Text(
                            '${repo.medicaments.length} traitement(s) actif(s)',
                            style: const TextStyle(
                                color: AppColors.blue300, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Liste
          Expanded(
            child: Stack(
              children: [
                repo.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : repo.medicaments.isEmpty
                        ? _EmptyState()
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                            itemCount: repo.medicaments.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (ctx, i) => _MedCard(
                              medicament: repo.medicaments[i],
                              onEdit: () => context.go(AppRoutes.formMedicament,
                                  extra: repo.medicaments[i].id),
                              onDelete: () =>
                                  _confirmerSuppression(repo.medicaments[i]),
                            ),
                          ),
                // Bouton flottant pour ajouter un médicament
                Positioned(
                  right: 0,
                  bottom: 0,
                  left: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _FloatingAddButton(
                          onPressed: () => context.go(AppRoutes.formMedicament),
                        ),
                      ],
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
}

// Bouton flottant pour ajouter un médicament
class _FloatingAddButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _FloatingAddButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
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
              color: AppColors.blue700.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}

class _MedCard extends StatelessWidget {
  final Medicament medicament;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MedCard(
      {required this.medicament, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                    color: AppColors.blue50,
                    borderRadius: BorderRadius.circular(14)),
                child: Center(
                    child: Text(medicament.icone,
                        style: const TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(medicament.nom,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.gray900)),
                    Text(medicament.dosage,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.gray400)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.gray400),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Modifier')
                      ])),
                  const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete_outline,
                            size: 18, color: AppColors.red),
                        SizedBox(width: 8),
                        Text('Supprimer',
                            style: TextStyle(color: AppColors.red))
                      ])),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Tags horaires
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _Tag('${medicament.frequenceParJour}x/jour'),
              ...medicament.horaires.map((h) => _Tag(h, isTime: true)),
            ],
          ),
          const SizedBox(height: 10),
          // Stock
          Row(
            children: [
              const Text('Stock ',
                  style: TextStyle(fontSize: 11, color: AppColors.gray400)),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: (medicament.joursRestants / 30).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: AppColors.gray100,
                    valueColor: AlwaysStoppedAnimation(
                      medicament.joursRestants <= 3
                          ? AppColors.red
                          : medicament.joursRestants <= 7
                              ? AppColors.orange
                              : AppColors.green,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StockIndicator(medicament: medicament),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final bool isTime;
  const _Tag(this.label, {this.isTime = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.blue50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.blue700,
            fontFamily: isTime ? 'DM Mono' : null,
          )),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('💊', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          const Text('Aucun médicament',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray600)),
          const SizedBox(height: 6),
          const Text('Appuyez sur + pour ajouter votre premier traitement',
              style: TextStyle(fontSize: 13, color: AppColors.gray400),
              textAlign: TextAlign.center),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => context.go(AppRoutes.formMedicament),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un médicament'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
