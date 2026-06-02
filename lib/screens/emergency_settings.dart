import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:open_cloud_health/models/allergy.dart';
import 'package:open_cloud_health/models/medication.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/models/emergency_contact.dart';
import 'package:open_cloud_health/models/lock_screen_setting.dart';
import 'package:open_cloud_health/providers/profiles_provider.dart';
import 'package:open_cloud_health/providers/allergies_provider.dart';
import 'package:open_cloud_health/providers/medications_provider.dart';
import 'package:open_cloud_health/providers/emergency_provider.dart';
import 'package:open_cloud_health/utils/result.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_cloud_health/services/notification_service.dart';
import 'package:open_cloud_health/widgets/emergency_card_view.dart';

class EmergencySettingsScreen extends ConsumerStatefulWidget {
  final String profileId;
  const EmergencySettingsScreen({super.key, required this.profileId});

  @override
  ConsumerState<EmergencySettingsScreen> createState() => _EmergencySettingsScreenState();
}

class _EmergencySettingsScreenState extends ConsumerState<EmergencySettingsScreen> with WidgetsBindingObserver {
  late String _currentProfileId;
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  String _selectedRelationship = 'Spouse';
  bool _notificationsEnabled = true;

  final List<String> _relationships = [
    'Spouse',
    'Partner',
    'Parent',
    'Sibling',
    'Child',
    'Friend',
    'Doctor',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentProfileId = widget.profileId;
    _checkNotificationPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkNotificationPermission();
    }
  }

  Future<void> _checkNotificationPermission() async {
    final status = await Permission.notification.status;
    bool isEnabled = status.isGranted;
    if (isEnabled) {
      final isChannelEnabled = await ref.read(notificationServiceProvider).isEmergencyChannelEnabled();
      isEnabled = isChannelEnabled;
    }
    if (mounted) {
      setState(() {
        _notificationsEnabled = isEnabled;
      });
    }
  }

  void _populateContactFields(String name, String phone) {
    setState(() {
      _contactNameController.text = name;
      _contactPhoneController.text = phone;
    });
  }

  Future<void> _importDeviceContact() async {
    // 1. Request Contacts Permission
    final permission = await FlutterContacts.requestPermission();
    if (!permission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contacts access permission is required to import contacts.')),
        );
      }
      return;
    }

    if (!mounted) return;

    // 2. Fetch system contacts
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    final navigator = Navigator.of(context);
    List<Contact> contacts = [];
    try {
      contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );
    } catch (e) {
      debugPrint('Error getting contacts: $e');
    } finally {
      if (mounted) navigator.pop(); // Dismiss spinner
    }

    if (contacts.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No contacts found on device.')),
        );
      }
      return;
    }

    // 3. Show searchable contact selector popup
    if (mounted) {
      showDialog(
        context: context,
        builder: (dialogCtx) {
          String searchQuery = '';
          return StatefulBuilder(
            builder: (context, setDialogState) {
              final filtered = contacts.where((c) {
                final fullName = '${c.name.first} ${c.name.last}'.toLowerCase();
                return fullName.contains(searchQuery.toLowerCase()) ||
                    c.phones.any((p) => p.number.contains(searchQuery));
              }).toList();

              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                title: Column(
                  children: [
                    const Text('Import Contact', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search contacts...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                      onChanged: (val) {
                        setDialogState(() {
                          searchQuery = val;
                        });
                      },
                    ),
                  ],
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  height: 350,
                  child: filtered.isEmpty
                      ? const Center(child: Text('No matching contacts.'))
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (ctx, idx) {
                            final c = filtered[idx];
                            final phone = c.phones.isNotEmpty ? c.phones.first.number : 'No phone number';
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.red.shade50,
                                child: Text(
                                  c.name.first.isNotEmpty ? c.name.first[0].toUpperCase() : '?',
                                  style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text('${c.name.first} ${c.name.last}'.trim()),
                              subtitle: Text(phone),
                              onTap: () {
                                Navigator.of(dialogCtx).pop();
                                if (c.phones.isNotEmpty) {
                                  _populateContactFields('${c.name.first} ${c.name.last}'.trim(), phone);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Contact has no phone number.')),
                                  );
                                }
                              },
                            );
                          },
                        ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogCtx).pop(),
                    child: const Text('Cancel'),
                  ),
                ],
              );
            },
          );
        },
      );
    }
  }

  Future<void> _addManualContact() async {
    final name = _contactNameController.text.trim();
    final phone = _contactPhoneController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter contact name and phone number.')),
      );
      return;
    }

    final contact = EmergencyContact(
      profileId: _currentProfileId,
      name: name,
      relationship: _selectedRelationship,
      phoneNumber: phone,
    );

    final res = await ref.read(emergencyContactsProvider(_currentProfileId).notifier).addContact(contact);
    if (res is Success) {
      _contactNameController.clear();
      _contactPhoneController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Emergency contact added successfully.')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add contact.')),
        );
      }
    }
  }

  void _showLockScreenSimulation(Profile profile, LockScreenSetting settings, List<Allergy> allergies, List<Medication> medications, List<EmergencyContact> contacts) {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.black,
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _LockScreenSimulationView(
          profile: profile,
          settings: settings,
          allergies: allergies,
          medications: medications,
          contacts: contacts,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(profilesProvider);

    return profilesAsync.when(
      data: (profiles) {
        if (profiles.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('Please create a profile first.')),
          );
        }

        final profile = profiles.firstWhere((p) => p.id == _currentProfileId, orElse: () => profiles.first);
        final settingsAsync = ref.watch(lockScreenSettingsProvider(profile.id));
        final contactsAsync = ref.watch(emergencyContactsProvider(profile.id));
        final allergiesAsync = ref.watch(allergiesProvider(profile.id));
        final medicationsAsync = ref.watch(medicationsProvider(profile.id));

        return Scaffold(
          appBar: AppBar(
            title: const Text('Emergency Lock Screen Info'),
            actions: [
              if (profiles.length > 1)
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _currentProfileId,
                      icon: const Icon(Icons.swap_horiz, color: Colors.blue),
                      items: profiles.map((p) {
                        return DropdownMenuItem(
                          value: p.id,
                          child: Text('${p.name} ${p.surname}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _currentProfileId = val;
                          });
                        }
                      },
                    ),
                  ),
                ),
            ],
          ),
          body: settingsAsync.when(
            data: (settings) {
              return contactsAsync.when(
                data: (contacts) {
                  return allergiesAsync.when(
                    data: (allergies) {
                      return medicationsAsync.when(
                        data: (medications) {
                          return SingleChildScrollView(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!_notificationsEnabled)
                                  Card(
                                    color: Colors.red.shade50,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    margin: const EdgeInsets.only(bottom: 20),
                                    child: ListTile(
                                      leading: const Icon(Icons.warning, color: Colors.red),
                                      title: const Text(
                                        'Emergency Channel Blocked',
                                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                                      ),
                                      subtitle: const Text(
                                        'The emergency notification channel is disabled. Turn it on in system settings to show your Medical ID.',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      trailing: TextButton(
                                        onPressed: () => ref.read(notificationServiceProvider).openNotificationSettings(),
                                        child: const Text('ENABLE'),
                                      ),
                                    ),
                                  ),
                                // Activation Toggle Card
                                Card(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  color: settings.isEnabled ? Colors.red.shade900 : Colors.grey.shade100,
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.emergency,
                                          color: settings.isEnabled ? Colors.white : Colors.grey.shade600,
                                          size: 32,
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Lock Screen Medical ID',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: settings.isEnabled ? Colors.white : Colors.black,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                settings.isEnabled
                                                    ? 'Persistent lockscreen alert is active.'
                                                    : 'Disabled. First responders will not see your details.',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: settings.isEnabled ? Colors.red.shade100 : Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Switch.adaptive(
                                          value: settings.isEnabled,
                                          activeTrackColor: Colors.red.shade400,
                                          activeColor: Colors.white,
                                          onChanged: (val) {
                                            ref.read(lockScreenSettingsProvider(profile.id).notifier).updateSettings(
                                              settings.copyWith(isEnabled: val),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Checklist customization
                                const Text(
                                  'CHOOSE WHAT TO DISPLAY',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                                ),
                                const SizedBox(height: 12),
                                Card(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  child: Column(
                                    children: [
                                      _buildCheckboxTile('Full Name', settings.showName, (val) {
                                        ref.read(lockScreenSettingsProvider(profile.id).notifier).updateSettings(
                                          settings.copyWith(showName: val),
                                        );
                                      }),
                                      _buildCheckboxTile('Age / Birth Date', settings.showAge, (val) {
                                        ref.read(lockScreenSettingsProvider(profile.id).notifier).updateSettings(
                                          settings.copyWith(showAge: val),
                                        );
                                      }),
                                      _buildCheckboxTile('Blood Type', settings.showBloodType, (val) {
                                        ref.read(lockScreenSettingsProvider(profile.id).notifier).updateSettings(
                                          settings.copyWith(showBloodType: val),
                                        );
                                      }),
                                      _buildCheckboxTile('Organ Donor Status', settings.showOrganDonor, (val) {
                                        ref.read(lockScreenSettingsProvider(profile.id).notifier).updateSettings(
                                          settings.copyWith(showOrganDonor: val),
                                        );
                                      }),
                                      _buildCheckboxTile('Chronic Conditions', settings.showChronicConditions, (val) {
                                        ref.read(lockScreenSettingsProvider(profile.id).notifier).updateSettings(
                                          settings.copyWith(showChronicConditions: val),
                                        );
                                      }),
                                      _buildCheckboxTile('Allergies & Reactions', settings.showAllergies, (val) {
                                        ref.read(lockScreenSettingsProvider(profile.id).notifier).updateSettings(
                                          settings.copyWith(showAllergies: val),
                                        );
                                      }),
                                      _buildCheckboxTile('Active Medications', settings.showMedications, (val) {
                                        ref.read(lockScreenSettingsProvider(profile.id).notifier).updateSettings(
                                          settings.copyWith(showMedications: val),
                                        );
                                      }),
                                      _buildCheckboxTile('Emergency Contacts', settings.showContacts, (val) {
                                        ref.read(lockScreenSettingsProvider(profile.id).notifier).updateSettings(
                                          settings.copyWith(showContacts: val),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 28),


                                // Test Lockscreen button
                                Center(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _showLockScreenSimulation(profile, settings, allergies, medications, contacts),
                                    icon: const Icon(Icons.screen_lock_portrait),
                                    label: const Text('Test Lock Screen Simulation', style: TextStyle(fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 32),
                                const Divider(),
                                const SizedBox(height: 24),

                                // Emergency Contacts Manager
                                SizedBox(
                                  width: double.infinity,
                                  child: Wrap(
                                    alignment: WrapAlignment.spaceBetween,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      const Text(
                                        'EMERGENCY CONTACTS',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                                      ),
                                      TextButton.icon(
                                        onPressed: _importDeviceContact,
                                        icon: const Icon(Icons.contact_phone, size: 16),
                                        label: const Text('Import from Device Contacts'),
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (contacts.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16.0),
                                    child: Center(child: Text('No emergency contacts added yet.', style: TextStyle(color: Colors.grey))),
                                  )
                                else
                                  ...contacts.map((c) => Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: const CircleAvatar(
                                        backgroundColor: Colors.green,
                                        child: Icon(Icons.phone, color: Colors.white),
                                      ),
                                      title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text('${c.relationship} • ${c.phoneNumber}'),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () {
                                          ref.read(emergencyContactsProvider(profile.id).notifier).deleteContact(c.id);
                                        },
                                      ),
                                    ),
                                  )),
                                const SizedBox(height: 16),

                                // Add contact fields
                                Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        const Text('Add Emergency Contact', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                        const SizedBox(height: 16),
                                        TextField(
                                          controller: _contactNameController,
                                          decoration: InputDecoration(
                                            hintText: 'Contact Name',
                                            prefixIcon: const Icon(Icons.person),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        TextField(
                                          controller: _contactPhoneController,
                                          keyboardType: TextInputType.phone,
                                          decoration: InputDecoration(
                                            hintText: 'Phone Number',
                                            prefixIcon: const Icon(Icons.phone),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        DropdownButtonFormField<String>(
                                          value: _selectedRelationship,
                                          items: _relationships.map((rel) {
                                            return DropdownMenuItem(
                                              value: rel,
                                              child: Text(rel),
                                            );
                                          }).toList(),
                                          onChanged: (val) {
                                            if (val != null) {
                                              setState(() {
                                                _selectedRelationship = val;
                                              });
                                            }
                                          },
                                          decoration: InputDecoration(
                                            labelText: 'Relationship',
                                            prefixIcon: const Icon(Icons.family_restroom),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton(
                                          onPressed: _addManualContact,
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                          child: const Text('Add Contact', style: TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, stack) => Text('Error loading medications: $err'),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Text('Error loading allergies: $err'),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Text('Error loading contacts: $err'),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Text('Error loading settings: $err'),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error loading profiles: $err'))),
    );
  }

  Widget _buildCheckboxTile(String title, bool value, ValueChanged<bool?> onChanged) {
    return CheckboxListTile(
      value: value,
      onChanged: onChanged,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      controlAffinity: ListTileControlAffinity.trailing,
      activeColor: Colors.red.shade900,
    );
  }


}

// Fullscreen Lock Screen Simulation
class _LockScreenSimulationView extends StatelessWidget {
  final Profile profile;
  final LockScreenSetting settings;
  final List<Allergy> allergies;
  final List<Medication> medications;
  final List<EmergencyContact> contacts;

  const _LockScreenSimulationView({
    required this.profile,
    required this.settings,
    required this.allergies,
    required this.medications,
    required this.contacts,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('h:mm').format(DateTime.now());
    final dateStr = DateFormat('EEEE, MMMM d').format(DateTime.now());

    void showMedicalCard() {
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Simulation Card',
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (ctx, anim, secAnim) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: const EmergencyCardView(),
          );
        },
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1D1B26), Color(0xFF2C243B), Color(0xFF13111A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Padlock and Clock
              Align(
                alignment: const Alignment(0, -0.85),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock, color: Colors.white70, size: 24),
                    const SizedBox(height: 12),
                    Text(
                      timeStr,
                      style: const TextStyle(
                        fontSize: 80,
                        fontWeight: FontWeight.w200,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              // Lock Screen Emergency Widget or Notification
              if (settings.isEnabled)
                Align(
                  alignment: const Alignment(0, 0.1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.red,
                                    ),
                                    child: const Icon(Icons.emergency, color: Colors.white, size: 14),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Emergency Medical ID Available',
                                    style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                  const Spacer(),
                                  const Text('now', style: TextStyle(color: Colors.white54, fontSize: 10)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                settings.showName ? '🚨 Medical Alert: ${profile.name} ${profile.surname}' : '🚨 Medical Alert',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Tapping "Emergency Medical ID" below reveals vital parameters and emergency contacts for first responders.',
                                style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Close Simulation Button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white70),
                    label: const Text('Exit Test', style: TextStyle(color: Colors.white70)),
                  ),
                ),
              ),

              // Bottom Actions (Flashlight / Pulse Button / Camera)
              Align(
                alignment: const Alignment(0, 0.95),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Simulated Flashlight
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.white.withOpacity(0.1),
                        child: const Icon(Icons.flashlight_on, color: Colors.white, size: 20),
                      ),

                      // Pulse Button
                      GestureDetector(
                        onTap: showMedicalCard,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.red.shade900,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.4),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.emergency, color: Colors.white, size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Emergency Medical ID',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Simulated Camera
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.white.withOpacity(0.1),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
