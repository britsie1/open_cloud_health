import 'dart:io';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/database/app_database.dart';
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
                            if (settings.showAge) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Date of Birth: ${profile.formattedDate}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
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
                  if (settings.showChronicConditions) ...[
                    _buildSectionTitle('CHRONIC CONDITIONS'),
                    const SizedBox(height: 8),
                    profile.chronicConditions.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              'None',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          )
                        : Wrap(
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
                  if (settings.showAllergies) ...[
                    _buildSectionTitle('ALLERGIES & REACTION NOTES'),
                    const SizedBox(height: 8),
                    allergies.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              'None',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: allergies.map((allergy) => Card(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  color: Colors.red.shade50,
                                  child: ListTile(
                                    leading: Icon(Icons.warning, color: Colors.red.shade800),
                                    title: Text(allergy.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: allergy.note.isNotEmpty ? Text(allergy.note) : null,
                                  ),
                                )).toList(),
                          ),
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
    final themeColor = color ?? Colors.purple;
    final List<Widget> children = [
      Icon(icon, size: 16, color: themeColor),
      Text(
        '$label: ',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
        ),
      ),
    ];

    if (label == 'DOB' && value.contains(' (Age ')) {
      final parts = value.split(' (Age ');
      final dobPart = parts[0];
      final agePart = parts[1].replaceAll(')', '');
      children.addAll([
        Text(
          dobPart,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: themeColor,
          ),
        ),
        Text(
          '(Age $agePart)',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.normal,
            color: Colors.grey.shade600,
          ),
        ),
      ]);
    } else {
      children.add(
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: themeColor,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: themeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: themeColor.withOpacity(0.3)),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 4,
        children: children,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
        color: Colors.grey,
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchAllEmergencyDetails(WidgetRef ref) async {
    final db = ref.read(appDatabaseProvider);

    final activeSettings = await (db.select(db.lockScreenSettings)..where((tbl) => tbl.isEnabled.equals('true'))).get();
    if (activeSettings.isEmpty) {
      return [];
    }

    final List<Map<String, dynamic>> results = [];
    final fileService = ref.read(fileServiceProvider);

    for (final setRow in activeSettings) {
      final pId = setRow.profileId;

      final settings = LockScreenSetting(
        profileId: pId,
        showName: setRow.showName == 'true',
        showAge: setRow.showAge == 'true',
        showBloodType: setRow.showBloodType == 'true',
        showOrganDonor: setRow.showOrganDonor == 'true',
        showChronicConditions: setRow.showChronicConditions == 'true',
        showAllergies: setRow.showAllergies == 'true',
        showMedications: setRow.showMedications == 'true',
        showContacts: setRow.showContacts == 'true',
        isEnabled: true,
      );

      final p = await (db.select(db.profiles)..where((tbl) => tbl.id.equals(pId))).getSingleOrNull();
      if (p == null) continue;

      final chronicConditionsStr = p.chronicConditions ?? '';
      final chronicConditions = chronicConditionsStr
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final profile = Profile(
        id: p.id,
        name: p.name,
        middleNames: p.middleNames,
        surname: p.surname,
        dateOfBirth: DateTime.parse(p.dateOfBirth),
        gender: p.gender == 'male' ? Gender.male : Gender.female,
        bloodType: p.bloodType,
        isOrganDonor: p.isOrganDonor == 'true',
        chronicConditions: chronicConditions,
      );

      final allergiesData = await (db.select(db.allergy)..where((tbl) => tbl.profileId.equals(pId))).get();
      final allergies = allergiesData
          .map((row) => Allergy(
                id: row.id,
                profileId: row.profileId,
                name: row.name,
                note: row.note,
              ))
          .toList();

      final medsData = await (db.select(db.medications)..where((tbl) => tbl.profileId.equals(pId) & tbl.isActive.equals('true'))).get();
      final medications = medsData
          .map((row) => Medication(
                id: row.id,
                profileId: row.profileId,
                name: row.name,
                dosage: row.dosage,
                type: row.type ?? 'Other',
                isActive: row.isActive == 'true',
                notificationEnabled: row.notificationEnabled == 'true',
                alarmEnabled: row.alarmEnabled == 'true',
              ))
          .toList();

      final contactsData = await (db.select(db.emergencyContacts)..where((tbl) => tbl.profileId.equals(pId))).get();
      final contacts = contactsData
          .map((row) => EmergencyContact(
                id: row.id,
                profileId: row.profileId,
                name: row.name,
                relationship: row.relationship,
                phoneNumber: row.phoneNumber,
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

    final primaryId = await db.getPrimaryProfileId();
    if (primaryId != null) {
      results.sort((a, b) {
        final aId = (a['settings'] as LockScreenSetting).profileId;
        final bId = (b['settings'] as LockScreenSetting).profileId;
        if (aId == primaryId) return -1;
        if (bId == primaryId) return 1;
        return 0;
      });
    }

    return results;
  }
}
