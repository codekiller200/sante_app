import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../data/models/medicament.dart';
import '../../../data/repositories/medicament_repository.dart';
import '../../../services/notification_service.dart';

class FormMedicamentScreen extends StatefulWidget {
  final int? medicamentId;
  const FormMedicamentScreen({super.key, this.medicamentId});

  @override
  State<FormMedicamentScreen> createState() => _FormMedicamentScreenState();
}

class _FormMedicamentScreenState extends State<FormMedicamentScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nomController = TextEditingController();
  final _dosageController = TextEditingController();
  final _stockController = TextEditingController();

  String _iconeChoisie = '💊';
  int _frequenceParJour = 1;
  List<String> _horaires = ['08:00'];
  bool _isLoading = false;
  bool get _isEditMode => widget.medicamentId != null;

  final List<String> _icones = [
    '💊',
    '🌿',
    '💉',
    '🔶',
    '🫀',
    '🧬',
    '🩺',
    '🧪',
    '💧',
    '🔴'
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _chargerMedicament());
    }
  }

  void _chargerMedicament() {
    final med =
        context.read<MedicamentRepository>().findById(widget.medicamentId!);
    if (med == null) return;
    setState(() {
      _nomController.text = med.nom;
      _dosageController.text = med.dosage;
      _stockController.text = med.stockActuel.toString();
      _iconeChoisie = med.icone;
      _frequenceParJour = med.frequenceParJour;
      _horaires = List.from(med.horaires);
    });
  }

  @override
  void dispose() {
    _nomController.dispose();
    _dosageController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  void _changerFrequence(int freq) {
    setState(() {
      _frequenceParJour = freq;
      final defaults = {
        1: ['08:00'],
        2: ['08:00', '20:00'],
        3: ['08:00', '12:00', '20:00'],
      };
      _horaires = defaults[freq] ?? List.generate(freq, (i) => '08:00');
    });
  }

  Future<void> _choisirHoraire(int index) async {
    final parts = _horaires[index].split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.blue700),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _horaires[index] =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _sauvegarder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final repo = context.read<MedicamentRepository>();
    final notificationService = NotificationService.instance;

    final med = Medicament(
      id: widget.medicamentId,
      nom: _nomController.text.trim(),
      dosage: _dosageController.text.trim(),
      icone: _iconeChoisie,
      frequenceParJour: _frequenceParJour,
      horaires: _horaires,
      stockActuel: int.tryParse(_stockController.text) ?? 0,
      dateCreation: DateTime.now(),
    );

    try {
      if (_isEditMode) {
        await repo.modifier(med);
        if (mounted) {
          // Planifier les notifications pour ce médicament modifié
          await notificationService.planifierPourMedicament(med);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${med.nom} modifié ✓\n🔔 Rappel activé pour ${med.horaires.length} horaire(s)'),
              backgroundColor: AppColors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          context.go(AppRoutes.medicaments);
        }
      } else {
        await repo.ajouter(med);
        if (mounted) {
          // Recharger les médicaments pour obtenir l'ID
          await repo.charger();
          final savedMed = repo.medicaments.last;

          // Planifier les notifications
          await notificationService.planifierPourMedicament(savedMed);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${med.nom} ajouté ✓\n🔔 Rappel activé pour ${med.horaires.length} horaire(s)'),
              backgroundColor: AppColors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          context.go(AppRoutes.medicaments);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
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
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.go(AppRoutes.medicaments),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.arrow_back,
                              color: Colors.white, size: 18),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _isEditMode
                            ? 'Modifier le médicament'
                            : 'Nouveau médicament',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionCard(
                      title: 'Informations',
                      children: [
                        _label('Nom du médicament *'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _nomController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.medication_outlined),
                            hintText: 'ex: Metformine',
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Champ requis'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        _label('Dosage'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _dosageController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.scale_outlined),
                            hintText: 'ex: 500mg',
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Champ requis'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        _label('Icône'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _icones
                              .map((ic) => GestureDetector(
                                    onTap: () =>
                                        setState(() => _iconeChoisie = ic),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 150),
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: _iconeChoisie == ic
                                            ? AppColors.blue50
                                            : AppColors.gray100,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _iconeChoisie == ic
                                              ? AppColors.blue500
                                              : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      child: Center(
                                          child: Text(ic,
                                              style: const TextStyle(
                                                  fontSize: 20))),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _SectionCard(
                      title: 'Fréquence',
                      children: [
                        _label('Prises par jour'),
                        const SizedBox(height: 8),
                        Row(
                          children: [1, 2, 3]
                              .map((f) => Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 3),
                                      child: GestureDetector(
                                        onTap: () => _changerFrequence(f),
                                        child: AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 150),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          decoration: BoxDecoration(
                                            color: _frequenceParJour == f
                                                ? AppColors.blue50
                                                : AppColors.gray100,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: _frequenceParJour == f
                                                  ? AppColors.blue500
                                                  : Colors.transparent,
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Text(
                                            '${f}x/jour',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: _frequenceParJour == f
                                                  ? AppColors.blue700
                                                  : AppColors.gray600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 14),
                        _label('Horaires'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(
                              _horaires.length,
                              (i) => GestureDetector(
                                    onTap: () => _choisirHoraire(i),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: AppColors.blue50,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: AppColors.blue300),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.access_time,
                                              size: 14,
                                              color: AppColors.blue700),
                                          const SizedBox(width: 6),
                                          Text(
                                            _horaires[i],
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.blue700,
                                              fontFamily: 'DM Mono',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _SectionCard(
                      title: 'Stock',
                      children: [
                        _label('Nombre de comprimés restants'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _stockController,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.inventory_2_outlined),
                            hintText: 'ex: 60',
                            suffixText: 'comprimés',
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Champ requis';
                            if (int.tryParse(v) == null)
                              return 'Nombre invalide';
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.blue50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.blue100),
                          ),
                          child: const Row(
                            children: [
                              Text('💡', style: TextStyle(fontSize: 14)),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Une alerte sera envoyée quand il restera 7 jours de stock.',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.blue700,
                                      height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _sauvegarder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.blue700,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                _isEditMode
                                    ? '✓ Enregistrer les modifications'
                                    : '💾 Enregistrer le médicament',
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.gray600),
      );
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.blue700,
                letterSpacing: 1),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}
