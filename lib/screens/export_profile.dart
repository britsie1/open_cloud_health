import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:open_cloud_health/models/pdf_export_options.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/providers/profiles_provider.dart';
import 'package:open_cloud_health/services/medical_pdf_service.dart';
import 'package:open_cloud_health/utils/constants.dart';

class ExportProfileScreen extends ConsumerStatefulWidget {
  const ExportProfileScreen({super.key, required this.profile});

  final Profile profile;

  @override
  ConsumerState<ExportProfileScreen> createState() => _ExportProfileScreenState();
}

class _ExportProfileScreenState extends ConsumerState<ExportProfileScreen> {
  String _profileImagePath = '';
  bool _isLoadingImage = true;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    final path = await ref
        .read(profilesProvider.notifier)
        .getProfileImagePath(widget.profile.id);
    if (mounted) {
      setState(() {
        _profileImagePath = path;
        _isLoadingImage = false;
      });
    }
  }

  void _showPdfOptionsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _PdfExportOptionsSheet(
        profile: widget.profile,
        onPreview: (options) {
          Navigator.of(ctx).pop();
          context.push(
            AppRoutes.pdfPreview,
            extra: {
              'profile': widget.profile,
              'options': options,
            },
          );
        },
        onShare: (options) async {
          Navigator.of(ctx).pop();
          await _sharePdfDirectly(options);
        },
      ),
    );
  }

  Future<void> _sharePdfDirectly(MedicalPdfExportOptions options) async {
    setState(() => _isExporting = true);
    try {
      final pdfService = ref.read(medicalPdfServiceProvider);
      final pdfBytes = await pdfService.generateMedicalPdfBytes(
        widget.profile.id,
        options: options,
      );
      final sanitizedName = '${widget.profile.name}_${widget.profile.surname}'.replaceAll(RegExp(r'[^\w]'), '_');
      final fileName = 'Medical_Summary_$sanitizedName.pdf';

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: fileName,
        subject: '${widget.profile.name} ${widget.profile.surname} - Medical Health Summary',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to compile PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _simulateJsonExport() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (ctx.mounted) {
            Navigator.of(ctx).pop();
            _showJsonExportDialog();
          }
        });

        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              const Text(
                'Compiling health data into JSON...',
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Please wait while we package your local medical records securely.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showJsonExportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.code, color: Colors.teal),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'JSON Profile Export',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: const Text(
          'For complete raw data backups or migrating to another device, please use Settings > Google Drive Backup or Export Local Encrypted Backup (.ochbackup).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    
    ImageProvider avatarImage;
    if (_profileImagePath.isEmpty) {
      avatarImage = AssetImage(AppAssets.getGenderPlaceholder(profile.gender.name));
    } else {
      avatarImage = FileImage(File(_profileImagePath));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Profile'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Summary Card
              Card(
                elevation: 4,
                shadowColor: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
                        Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.2),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundImage: _isLoadingImage ? null : avatarImage,
                          child: _isLoadingImage
                              ? const CircularProgressIndicator(strokeWidth: 2)
                              : null,
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${profile.name} ${profile.surname}',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall!
                                    .copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Age: ${profile.age} years • ${profile.gender.name}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onBackground
                                          .withOpacity(0.6),
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Blood Type: ${profile.bloodType}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              Text(
                'Choose Export Format',
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select the format you would like to package and save your medical history in.',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onBackground
                          .withOpacity(0.6),
                    ),
              ),
              const SizedBox(height: 24),
              
              // PDF Export Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _isExporting ? null : _showPdfOptionsModal,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: _isExporting
                              ? const SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.red),
                                )
                              : const Icon(
                                  Icons.picture_as_pdf_outlined,
                                  size: 32,
                                  color: Colors.red,
                                ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Medical Practitioner PDF',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Compile a print-ready clinical summary with allergies, active medications, vitals, history, and doctor signature section.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall!
                                    .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onBackground
                                          .withOpacity(0.6),
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // JSON Export Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _simulateJsonExport,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.teal.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.code_outlined,
                            size: 32,
                            color: Colors.teal,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Export as JSON Backup Data',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Export all raw profile records, settings, and logs in JSON format. Best for transferring to a new device.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall!
                                    .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onBackground
                                          .withOpacity(0.6),
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Privacy Shield Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Data Privacy Guaranteed',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall!
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'All compilations are generated completely offline on your device. Your health metrics never leave your phone without your explicit consent.',
                            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onBackground
                                      .withOpacity(0.6),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _PdfExportOptionsSheet extends StatefulWidget {
  final Profile profile;
  final ValueChanged<MedicalPdfExportOptions> onPreview;
  final ValueChanged<MedicalPdfExportOptions> onShare;

  const _PdfExportOptionsSheet({
    required this.profile,
    required this.onPreview,
    required this.onShare,
  });

  @override
  State<_PdfExportOptionsSheet> createState() => _PdfExportOptionsSheetState();
}

class _PdfExportOptionsSheetState extends State<_PdfExportOptionsSheet> {
  bool _includeDemographics = true;
  bool _includeAllergies = true;
  bool _includeConditions = true;
  bool _includeMedications = true;
  bool _includeVitals = true;
  bool _includeHistory = true;
  bool _includeCheckups = true;
  bool _includeFertility = true;
  bool _includeEmergency = true;
  bool _includeDoctorNotes = true;
  PdfDateRangeFilter _dateRange = PdfDateRangeFilter.allTime;

  MedicalPdfExportOptions _buildOptions() {
    return MedicalPdfExportOptions(
      includeDemographics: _includeDemographics,
      includeAllergies: _includeAllergies,
      includeChronicConditions: _includeConditions,
      includeMedications: _includeMedications,
      includeVitals: _includeVitals,
      includeHistory: _includeHistory,
      includeCheckups: _includeCheckups,
      includeFertility: _includeFertility,
      includeEmergencyContacts: _includeEmergency,
      includeDoctorNotesSection: _includeDoctorNotes,
      dateRange: _dateRange,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFemale = widget.profile.gender == Gender.female && widget.profile.trackOvulation;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sheet Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.picture_as_pdf, color: Colors.red.shade700, size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customize Medical Summary',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Select modules and timeframe for practitioner review',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Scrollable Content
            Expanded(
              child: ListView(
                children: [
                  // Date Range Filter Dropdown
                  const Text(
                    'Timeframe Filter',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<PdfDateRangeFilter>(
                        value: _dateRange,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down),
                        items: PdfDateRangeFilter.values.map((filter) {
                          return DropdownMenuItem(
                            value: filter,
                            child: Row(
                              children: [
                                Text(
                                  filter.label,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '(${filter.description})',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _dateRange = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Module Inclusion Checkboxes
                  const Text(
                    'Clinical Modules to Include',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),

                  _buildSwitchTile('Patient Demographics & Photo', 'Name, DOB, Blood Type, Age, Donor status', _includeDemographics, (v) => setState(() => _includeDemographics = v)),
                  _buildSwitchTile('Allergies & Adverse Reactions', 'Critical alert callout for drug/food sensitivities', _includeAllergies, (v) => setState(() => _includeAllergies = v), isHighPriority: true),
                  _buildSwitchTile('Active Chronic Conditions', 'Long-term diagnoses and management tags', _includeConditions, (v) => setState(() => _includeConditions = v)),
                  _buildSwitchTile('Medications & Schedules', 'Active & PRN regimens with dosing times', _includeMedications, (v) => setState(() => _includeMedications = v)),
                  _buildSwitchTile('Vital Signs & Biometrics', 'Blood pressure, heart rate, glucose, weight', _includeVitals, (v) => setState(() => _includeVitals = v)),
                  _buildSwitchTile('Medical History & Encounters', 'Consultations, surgeries, hospitalizations, scans', _includeHistory, (v) => setState(() => _includeHistory = v)),
                  _buildSwitchTile('Preventive Health & Checkups', 'Routine screenings, intervals, and last dates', _includeCheckups, (v) => setState(() => _includeCheckups = v)),
                  if (isFemale)
                    _buildSwitchTile('Menstrual & Reproductive Health', 'Cycle durations, symptoms, and flow patterns', _includeFertility, (v) => setState(() => _includeFertility = v)),
                  _buildSwitchTile('Emergency Contacts', 'Next of kin and primary emergency phone numbers', _includeEmergency, (v) => setState(() => _includeEmergency = v)),
                  _buildSwitchTile('Doctor Notes & Signature Section', 'Blank clinician notes, sign-off line, and clinic stamp', _includeDoctorNotes, (v) => setState(() => _includeDoctorNotes = v)),
                  
                  const SizedBox(height: 12),
                ],
              ),
            ),

            // Bottom Actions: Preview & Share
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => widget.onShare(_buildOptions()),
                      icon: const Icon(Icons.share_outlined, size: 18),
                      label: const Text('Share PDF'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => widget.onPreview(_buildOptions()),
                      icon: const Icon(Icons.preview, size: 18),
                      label: const Text('Preview & Print'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged, {
    bool isHighPriority = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: value ? (isHighPriority ? Colors.red.shade50.withOpacity(0.5) : Colors.blue.shade50.withOpacity(0.3)) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: CheckboxListTile(
        dense: true,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        value: value,
        onChanged: (v) => onChanged(v ?? false),
        activeColor: isHighPriority ? Colors.red.shade700 : Theme.of(context).colorScheme.primary,
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: isHighPriority && value ? Colors.red.shade900 : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ),
    );
  }
}
