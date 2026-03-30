import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:sante_app/core/constants/app_colors.dart';
import 'package:sante_app/core/constants/app_routes.dart';
import 'package:sante_app/data/repositories/medicament_repository.dart';
import 'package:sante_app/data/models/medicament.dart';
import 'package:sante_app/services/notification_service.dart';

class MedicamentFormScreen extends StatefulWidget {
  const MedicamentFormScreen({super.key, this.medicamentId});

  final int? medicamentId;

  @override
  State<MedicamentFormScreen> createState() => _MedicamentFormScreenState();
}

class _MedicamentFormScreenState extends State<MedicamentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _stockController = TextEditingController(text: '30');
  final List<String> _hours = ['08:00'];

  final List<String> _icons = const ['💊', '🌿', '💉', '🔶', '🫀', '🧬', '🩺', '🩹'];
  final List<int> _intervalOptions = const [1, 2, 3, 4, 7, 14, 30];

  String _icon = '💊';
  int _frequency = 1;
  int _intervalDays = 1;
  bool _loading = false;

  bool get _isEdit => widget.medicamentId != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final id = widget.medicamentId;
      if (id == null) return;
      final existing = context.read<MedicamentRepository>().findById(id);
      if (existing == null) return;
      _nameController.text = existing.nom;
      _dosageController.text = existing.dosage;
      _stockController.text = existing.stockActuel.toString();
      _icon = existing.icone;
      _frequency = existing.frequenceParJour;
      _intervalDays = existing.intervalleJours;
      _hours
        ..clear()
        ..addAll(existing.horaires);
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickHour(int index) async {
    final parts = _hours[index].split(':');
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
    );
    if (time == null) return;
    setState(() {
      _hours[index] = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    });
  }

  void _syncHours() {
    while (_hours.length < _frequency) {
      _hours.add('08:00');
    }
    while (_hours.length > _frequency) {
      _hours.removeLast();
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final repo = context.read<MedicamentRepository>();
    final current = _isEdit ? repo.findById(widget.medicamentId!) : null;
    final medicament = Medicament(
      id: widget.medicamentId,
      nom: _nameController.text.trim(),
      dosage: _dosageController.text.trim(),
      icone: _icon,
      frequenceParJour: _frequency,
      intervalleJours: _intervalDays,
      horaires: List<String>.from(_hours),
      stockActuel: int.tryParse(_stockController.text) ?? 0,
      dateCreation: current?.dateCreation ?? DateTime.now(),
    );

    if (_isEdit) {
      await repo.modifier(medicament);
    } else {
      await repo.ajouter(medicament);
    }
    await repo.charger();
    final saved = _isEdit && widget.medicamentId != null
        ? repo.findById(widget.medicamentId!) ?? repo.medicaments.last
        : repo.medicaments.last;
    await NotificationService.instance.planifierPourMedicament(saved);

    if (!mounted) return;
    context.go(AppRoutes.medicaments);
  }

  @override
  Widget build(BuildContext context) {
    _syncHours();

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Modifier le medicament' : 'Nouveau medicament')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _FormSection(
              title: 'Informations',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _FieldLabel('Nom du medicament *'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(hintText: 'ex: Metformine'),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Champ requis' : null,
                  ),
                  const SizedBox(height: 14),
                  const _FieldLabel('Dosage'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _dosageController,
                    decoration: const InputDecoration(hintText: 'ex: 500mg'),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Champ requis' : null,
                  ),
                  const SizedBox(height: 14),
                  const _FieldLabel('Icone'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _icons
                        .map(
                          (icon) => GestureDetector(
                            onTap: () => setState(() => _icon = icon),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _icon == icon ? AppColors.blue50 : AppColors.gray100,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _icon == icon ? AppColors.blue500 : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(icon, style: const TextStyle(fontSize: 18)),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _FormSection(
              title: 'Frequence',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _FieldLabel('Prises par jour'),
                  const SizedBox(height: 8),
                  Row(
                    children: [1, 2, 3]
                        .map(
                          (value) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: GestureDetector(
                                onTap: () => setState(() => _frequency = value),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _frequency == value ? AppColors.blue50 : AppColors.gray100,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: _frequency == value ? AppColors.blue500 : AppColors.gray200,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${value}x/jour',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: _frequency == value ? AppColors.blue700 : AppColors.gray600,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 14),
                  const _FieldLabel('Intervalle (jours)'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: _intervalDays,
                    items: _intervalOptions
                        .map(
                          (value) => DropdownMenuItem<int>(
                            value: value,
                            child: Text(value == 1 ? 'Tous les jours' : 'Tous les $value jours'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _intervalDays = value ?? 1),
                  ),
                  const SizedBox(height: 14),
                  const _FieldLabel('Horaires'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var i = 0; i < _hours.length; i++)
                        GestureDetector(
                          onTap: () => _pickHour(i),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.blue50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.blue300),
                            ),
                            child: Text(
                              _hours[i],
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.blue700,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _FormSection(
              title: 'Stock',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _FieldLabel('Nombre de comprimés restants'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _stockController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'ex: 60 comprimés'),
                    validator: (value) => int.tryParse(value ?? '') == null ? 'Nombre invalide' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(_isEdit ? 'Enregistrer les modifications' : 'Enregistrer le medicament'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.blue700,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.gray600,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

