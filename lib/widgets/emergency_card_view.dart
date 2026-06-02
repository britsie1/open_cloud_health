import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/database/database_helper.dart';
import 'package:open_cloud_health/models/allergy.dart';
import 'package:open_cloud_health/models/medication.dart';
import 'package:open_cloud_health/models/emergency_contact.dart';
import 'package:open_cloud_health/models/lock_screen_setting.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/services/file_service.dart';

class EmergencyCardView extends ConsumerWidget {
  const EmergencyCardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red.shade900,
        foregroundColor: Colors.white,
        title: const Text('🚨 EMERGENCY MEDICAL ID'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchAllEmergencyDetails(ref),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Failed to load Emergency Medical ID.'));
          }

          final results = snapshot.data!;
          if (results.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'No Emergency Medical IDs are enabled.\nConfigure this feature in the profile settings first.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, height: 1.4),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24.0),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final data = results[index];
              final settings = data['settings'] as LockScreenSetting;
              final profile = data['profile'] as Profile;
              final allergies = data['allergies'] as List<Allergy>;
              final medications = data['medications'] as List<Medication>;
              final activeMeds = medications.where((m) => m.isActive).toList();
              final contacts = data['contacts'] as List<EmergencyContact>;
              final imagePath = data['imagePath'] as String;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (imagePath.isNotEmpty)
                        CircleAvatar(
                          radius: 36,
                          backgroundImage: FileImage(File(imagePath)),
                        )
                      else
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.red.shade900,
                          child: const Icon(Icons.person, size: 36, color: Colors.white),
                        ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              settings.showName
                                  ? '${profile.name} ${profile.middleNames} ${profile.surname}'.replaceAll(RegExp(r'\s+'), ' ').trim()
                                  : 'Medical Information',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      if (settings.showAge)
                        _buildInfoTag('AGE', '${profile.age}', Icons.calendar_month),
                      if (settings.showBloodType)
                        _buildInfoTag('BLOOD TYPE', profile.bloodType, Icons.bloodtype, color: Colors.red),
                      if (settings.showOrganDonor)
                        _buildInfoTag('ORGAN DONOR', profile.isOrganDonor ? 'YES' : 'NO', Icons.favorite, color: Colors.pink),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (settings.showChronicConditions && profile.chronicConditions.isNotEmpty) ...[
                    _buildSectionTitle('CHRONIC CONDITIONS'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: profile.chronicConditions
                          .map((cond) => Chip(
                                label: Text(
                                  cond,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                backgroundColor: Colors.red.shade800,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (settings.showAllergies && allergies.isNotEmpty) ...[
                    _buildSectionTitle('ALLERGIES & REACTION NOTES'),
                    const SizedBox(height: 8),
                    ...allergies.map((allergy) => Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: Colors.red.shade50,
                          child: ListTile(
                            leading: Icon(Icons.warning, color: Colors.red.shade800),
                            title: Text(allergy.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: allergy.note.isNotEmpty ? Text(allergy.note) : null,
                          ),
                        )),
                    const SizedBox(height: 24),
                  ],
                  if (settings.showMedications && activeMeds.isNotEmpty) ...[
                    _buildSectionTitle('ACTIVE MEDICATIONS'),
                    const SizedBox(height: 8),
                    ...activeMeds.map((med) => Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: Colors.blue.shade50,
                          child: ListTile(
                            leading: Icon(Icons.medication, color: Colors.blue.shade800),
                            title: Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: med.dosage.isNotEmpty ? Text(med.dosage) : null,
                          ),
                        )),
                    const SizedBox(height: 24),
                  ],
                  if (settings.showContacts && contacts.isNotEmpty) ...[
                    _buildSectionTitle('IN CASE OF EMERGENCY (ICE)'),
                    const SizedBox(height: 8),
                    ...contacts.map((contact) => Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.green,
                              child: Icon(Icons.phone, color: Colors.white),
                            ),
                            title: Text(contact.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${contact.relationship} • ${contact.phoneNumber}'),
                          ),
                        )),
                    const SizedBox(height: 24),
                  ],
                  if (index < results.length - 1) ...[
                    const Divider(height: 48, thickness: 2, color: Colors.grey),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoTag(String label, String value, IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (color ?? Colors.purple).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (color ?? Colors.purple).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color ?? Colors.purple),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.purple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
        letterSpacing: 1.1,
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchAllEmergencyDetails(WidgetRef ref) async {
    final dbHelper = ref.read(databaseHelperProvider);
    final db = await dbHelper.getDatabase();

    final settingsData = await db.query('lock_screen_settings', where: 'isEnabled = ?', whereArgs: ['true']);
    if (settingsData.isEmpty) {
      return [];
    }

    final List<Map<String, dynamic>> results = [];
    final fileService = ref.read(fileServiceProvider);

    for (final setRow in settingsData) {
      final pId = setRow['profileId'] as String;

      final settings = LockScreenSetting(
        profileId: pId,
        showName: setRow['showName'] == 'true',
        showAge: setRow['showAge'] == 'true',
        showBloodType: setRow['showBloodType'] == 'true',
        showOrganDonor: setRow['showOrganDonor'] == 'true',
        showChronicConditions: setRow['showChronicConditions'] == 'true',
        showAllergies: setRow['showAllergies'] == 'true',
        showMedications: setRow['showMedications'] == 'true',
        showContacts: setRow['showContacts'] == 'true',
        isEnabled: true,
      );

      final profileData = await db.query('profiles', where: 'id = ?', whereArgs: [pId]);
      if (profileData.isEmpty) continue;

      final p = profileData.first;
      final chronicConditionsStr = p['chronicConditions'] as String? ?? '';
      final chronicConditions = chronicConditionsStr
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final profile = Profile(
        id: p['id'] as String,
        name: p['name'] as String,
        middleNames: p['middleNames'] as String? ?? '',
        surname: p['surname'] as String,
        dateOfBirth: DateTime.parse(p['dateOfBirth'] as String),
        gender: p['gender'] == 'male' ? Gender.male : Gender.female,
        bloodType: p['bloodType'] as String,
        isOrganDonor: p['isOrganDonor'] == 'true',
        chronicConditions: chronicConditions,
      );

      final allergiesData = await db.query('allergy', where: 'profileId = ?', whereArgs: [pId]);
      final allergies = allergiesData
          .map((row) => Allergy(
                id: row['id'] as String,
                profileId: row['profileId'] as String,
                name: row['name'] as String,
                note: row['note'] as String? ?? '',
              ))
          .toList();

      final medsData = await db.query('medications', where: 'profileId = ? AND isActive = ?', whereArgs: [pId, 'true']);
      final medications = medsData
          .map((row) => Medication(
                id: row['id'] as String,
                profileId: row['profileId'] as String,
                name: row['name'] as String,
                dosage: row['dosage'] as String? ?? '',
                type: row['type'] as String? ?? 'Other',
                isActive: row['isActive'] == 'true',
                notificationEnabled: row['notificationEnabled'] == 'true',
                alarmEnabled: row['alarmEnabled'] == 'true',
              ))
          .toList();

      final contactsData = await db.query('emergency_contacts', where: 'profileId = ?', whereArgs: [pId]);
      final contacts = contactsData
          .map((row) => EmergencyContact(
                id: row['id'] as String,
                profileId: row['profileId'] as String,
                name: row['name'] as String,
                relationship: row['relationship'] as String,
                phoneNumber: row['phoneNumber'] as String,
              ))
          .toList();

      final imagePath = await fileService.getProfileImagePath(pId);

      results.add({
        'settings': settings,
        'profile': profile,
        'allergies': allergies,
        'medications': medications,
        'contacts': contacts,
        'imagePath': imagePath,
      });
    }

    return results;
  }
}
