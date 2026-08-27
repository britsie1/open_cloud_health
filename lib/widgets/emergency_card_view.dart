import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/models/allergy.dart';
import 'package:open_cloud_health/models/medication.dart';
import 'package:open_cloud_health/models/emergency_contact.dart';
import 'package:open_cloud_health/models/insurance_policy.dart';
import 'package:open_cloud_health/models/lock_screen_setting.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/providers/emergency_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyCardView extends ConsumerWidget {
  const EmergencyCardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emergencyAsync = ref.watch(emergencyProfilesDetailsProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFB91C1C),
        foregroundColor: Colors.white,
        elevation: 2,
        title: const Text(
          '🚨 EMERGENCY MEDICAL ID',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
            fontSize: 16,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 26),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: emergencyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load Emergency Medical ID: $err')),
        data: (results) {
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
              final insurance = data['insurance'] as InsurancePolicy?;
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
                  if (settings.showInsurance && insurance != null) ...[
                    _buildSectionTitle('HEALTH INSURANCE / MEDICAL AID'),
                    const SizedBox(height: 8),
                    Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: Colors.teal.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              insurance.provider,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            if (insurance.planName != null && insurance.planName!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text('Plan: ${insurance.planName}', style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                            ],
                            const SizedBox(height: 4),
                            Text('Policy / Member ID: ${insurance.policyNumber}${insurance.groupNumber != null && insurance.groupNumber!.isNotEmpty ? " • Group: ${insurance.groupNumber}" : ""}'),
                            if (insurance.subscriberName != null && insurance.subscriberName!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text('Subscriber: ${insurance.subscriberName}', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                            ],
                            if (insurance.emergencyPhone != null && insurance.emergencyPhone!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              InkWell(
                                onTap: () => launchUrl(Uri.parse('tel:${insurance.emergencyPhone}')),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.teal.shade200),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.phone, size: 16, color: Colors.teal),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Pre-Auth Line: ${insurance.emergencyPhone}',
                                        style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
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
}
