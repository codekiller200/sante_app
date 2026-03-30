import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:mediremind/core/constants/app_colors.dart';
import 'package:mediremind/core/constants/app_routes.dart';
import 'package:mediremind/models/emergency_contact.dart';
import 'package:mediremind/models/utilisateur.dart';
import 'package:mediremind/services/alarm_preferences_service.dart';
import 'package:mediremind/services/alarm_guard_service.dart';
import 'package:mediremind/services/alarm_service.dart';
import 'package:mediremind/services/auth_service.dart';
import 'package:mediremind/services/emergency_contacts_service.dart';
import 'package:mediremind/services/notification_center_service.dart';
import 'package:mediremind/widgets/main_navigation_scaffold.dart';
import 'package:mediremind/widgets/section_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isSavingProfile = false;
  AlarmGuardStatus? _alarmGuardStatus;

  @override
  void initState() {
    super.initState();
    _loadAlarmGuardStatus();
  }

  Future<void> _loadAlarmGuardStatus() async {
    final status = await AlarmGuardService.loadStatus();
    if (!mounted) return;
    setState(() => _alarmGuardStatus = status);
  }

  Future<void> _editText({
    required String title,
    required String initialValue,
    required ValueChanged<String> onSave,
  }) async {
    final controller = TextEditingController(text: initialValue);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Enregistrer')),
        ],
      ),
    );
    if (value != null && value.trim().isNotEmpty) {
      onSave(value.trim());
    }
  }

  Future<void> _showAddEmergencyContactDialog() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    final shouldSave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Ajouter un numéro'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nom'),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Téléphone'),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annuler')),
              FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Ajouter')),
            ],
          ),
        ) ??
        false;

    if (!shouldSave) return;

    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    if (name.isEmpty || phone.isEmpty) return;

    if (!mounted) return;
    await context.read<EmergencyContactsService>().addContact(
          EmergencyContact(name: name, phone: phone),
        );
  }

  Future<void> _updateUser(Utilisateur user) async {
    setState(() => _isSavingProfile = true);
    try {
      await context.read<AuthService>().mettreAJourProfil(user);
    } finally {
      if (mounted) {
        setState(() => _isSavingProfile = false);
      }
    }
  }

  Future<void> _pickBirthDate(Utilisateur user) async {
    final date = await showDatePicker(
      context: context,
      initialDate: user.dateNaissance ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      await _updateUser(user.copyWith(dateNaissance: date));
    }
  }

  Future<void> _pickAvatar(Utilisateur user) async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await _updateUser(user.copyWith(avatarPath: image.path));
    }
  }

  Future<void> _openAlarmSetup() async {
    await context.push(AppRoutes.alarmSetup);
    await _loadAlarmGuardStatus();
  }

  Future<void> _openBackgroundSettings() async {
    final opened = await AlarmService.instance.ouvrirParametresArrierePlan();
    if (!mounted) return;
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d ouvrir ce reglage sur cet appareil.'),
        ),
      );
      return;
    }
    await _loadAlarmGuardStatus();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.user;
    final alarmPreferences = context.watch<AlarmPreferencesService>();
    final notifications = context.watch<NotificationCenterService>();
    final emergencyContacts = context.watch<EmergencyContactsService>();

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return MainNavigationScaffold(
      currentIndex: 3,
      title: 'Mon Profil',
      subtitle: 'Données stockées localement · RGPD',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_isSavingProfile) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 16),
          ],
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.blue900, Color(0xFF1E3A5F)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  backgroundImage: user.avatarPath != null
                      ? FileImage(File(user.avatarPath!))
                      : null,
                  child: user.avatarPath == null
                      ? Text(user.avatarEmoji,
                          style: const TextStyle(fontSize: 28))
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  user.nomComplet,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.username,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _pickAvatar(user),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side:
                        BorderSide(color: Colors.white.withValues(alpha: 0.24)),
                  ),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Modifier la photo'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Informations personnelles',
            child: Column(
              children: [
                _ProfileRow(
                  icon: '👤',
                  color: AppColors.blue50,
                  label: 'Nom complet',
                  value: user.nomComplet,
                  onTap: () => _editText(
                    title: 'Nom complet',
                    initialValue: user.nomComplet,
                    onSave: (value) =>
                        _updateUser(user.copyWith(nomComplet: value)),
                  ),
                ),
                _ProfileRow(
                  icon: '🎂',
                  color: AppColors.blue50,
                  label: 'Date de naissance',
                  value: user.dateNaissance == null
                      ? 'Ajouter'
                      : DateFormat('dd/MM/yyyy').format(user.dateNaissance!),
                  onTap: () => _pickBirthDate(user),
                ),
                _ProfileRow(
                  icon: '🩺',
                  color: AppColors.green.withValues(alpha: 0.12),
                  label: 'Médecin traitant',
                  value: user.medecinTraitant ?? 'Ajouter',
                  onTap: () => _editText(
                    title: 'Médecin traitant',
                    initialValue: user.medecinTraitant ?? '',
                    onSave: (value) =>
                        _updateUser(user.copyWith(medecinTraitant: value)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Dossier sante',
            child: Column(
              children: [
                _ProfileRow(
                  icon: '🩸',
                  color: AppColors.red.withValues(alpha: 0.12),
                  label: 'Groupe sanguin',
                  value: user.groupeSanguin ?? 'Ajouter',
                  onTap: () => _editText(
                    title: 'Groupe sanguin',
                    initialValue: user.groupeSanguin ?? '',
                    onSave: (value) =>
                        _updateUser(user.copyWith(groupeSanguin: value)),
                  ),
                ),
                _ProfileRow(
                  icon: '⚠️',
                  color: AppColors.orange.withValues(alpha: 0.12),
                  label: 'Allergies',
                  value: user.allergies ?? 'Ajouter',
                  onTap: () => _editText(
                    title: 'Allergies',
                    initialValue: user.allergies ?? '',
                    onSave: (value) =>
                        _updateUser(user.copyWith(allergies: value)),
                  ),
                ),
                _ProfileRow(
                  icon: '📋',
                  color: AppColors.gray100,
                  label: 'Antecedents',
                  value: user.antecedents ?? 'Ajouter',
                  onTap: () => _editText(
                    title: 'Antecedents',
                    initialValue: user.antecedents ?? '',
                    onSave: (value) =>
                        _updateUser(user.copyWith(antecedents: value)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Numéros d\'urgence',
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _showAddEmergencyContactDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter'),
                  ),
                ),
                const SizedBox(height: 12),
                if (!emergencyContacts.loaded)
                  const Center(child: CircularProgressIndicator())
                else if (emergencyContacts.contacts.isEmpty)
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Aucun numéro d\'urgence enregistre.'),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: emergencyContacts.contacts.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final contact = emergencyContacts.contacts[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.blue50,
                          child: Icon(Icons.phone_in_talk_outlined,
                              color: AppColors.blue700),
                        ),
                        title: Text(contact.name),
                        subtitle: Text(contact.phone),
                        trailing: IconButton(
                          onPressed: () => context
                              .read<EmergencyContactsService>()
                              .removeContactAt(index),
                          icon: const Icon(Icons.delete_outline,
                              color: AppColors.red),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          if (user.hasUrgences) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🚨', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Informations d'urgence",
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: AppColors.red),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.resumeUrgences,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFF9B1C1C),
                                    height: 1.4,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          SectionCard(
            title: 'Notifications',
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Notifications globales'),
                  value: notifications.notificationsEnabled,
                  onChanged: notifications.setNotificationsEnabled,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Rappels de prises'),
                  value: notifications.medicationRemindersEnabled,
                  onChanged: notifications.notificationsEnabled
                      ? notifications.setMedicationRemindersEnabled
                      : null,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Alertes de stock'),
                  value: notifications.stockAlertsEnabled,
                  onChanged: notifications.notificationsEnabled
                      ? notifications.setStockAlertsEnabled
                      : null,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Son de l alarme'),
                  subtitle: Text(alarmPreferences.label),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final selected = await showModalBottomSheet<AlarmSoundType>(
                      context: context,
                      builder: (context) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: AlarmSoundType.values
                              .map(
                                (value) => ListTile(
                                  onTap: () => Navigator.pop(context, value),
                                  title: Text(
                                    switch (value) {
                                      AlarmSoundType.alarm => 'Alarme systeme',
                                      AlarmSoundType.ringtone =>
                                        'Sonnerie telephone',
                                      AlarmSoundType.notification =>
                                        'Notification',
                                    },
                                  ),
                                  trailing: value == alarmPreferences.soundType
                                      ? const Icon(Icons.check)
                                      : null,
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    );
                    if (selected != null) {
                      await alarmPreferences.setSoundType(selected);
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    (_alarmGuardStatus?.fullyReady ?? false)
                        ? Icons.verified_user_outlined
                        : Icons.warning_amber_rounded,
                    color: (_alarmGuardStatus?.fullyReady ?? false)
                        ? AppColors.green
                        : AppColors.orange,
                  ),
                  title: const Text('Fiabilite des alarmes'),
                  subtitle: Text(
                    (_alarmGuardStatus?.fullyReady ?? false)
                        ? 'Les reglages conseilles semblent actives.'
                        : 'Certaines protections Android peuvent bloquer les alarmes.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _openAlarmSetup,
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.open_in_new_outlined),
                  title: const Text('Autoriser fonctionnement en arriere-plan'),
                  subtitle: const Text(
                    'Ouvre les reglages batterie, optimisation ou acces special.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _openBackgroundSettings,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => context.read<AuthService>().deconnecter(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.red,
              side: const BorderSide(color: AppColors.red),
            ),
            child: const Text('Se deconnecter'),
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String icon;
  final Color color;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(icon),
      ),
      title: Text(label),
      subtitle: Text(
        value,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
