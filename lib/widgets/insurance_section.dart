import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_cloud_health/models/insurance_policy.dart';
import 'package:open_cloud_health/providers/insurance_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class InsuranceSection extends ConsumerWidget {
  const InsuranceSection({
    super.key,
    required this.profileId,
    this.isReadOnly = false,
  });

  final String profileId;
  final bool isReadOnly;

  void _openEditDialog(BuildContext context, WidgetRef ref, [InsurancePolicy? current]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditInsuranceSheet(
        profileId: profileId,
        existing: current,
      ),
    );
  }

  void _viewCardImage(BuildContext context, String title, String imagePath) {
    if (imagePath.isEmpty || !File(imagePath).existsSync()) return;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 4.0,
                      child: Image.file(
                        File(imagePath),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton.filledTonal(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insuranceAsync = ref.watch(insuranceProvider(profileId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(
                    Icons.credit_card_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Health Insurance & Policy',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            if (!isReadOnly && insuranceAsync.value != null)
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: 'Edit Insurance Details',
                onPressed: () => _openEditDialog(context, ref, insuranceAsync.value),
              ),
          ],
        ),
        const SizedBox(height: 8),
        insuranceAsync.when(
          data: (policy) {
            if (policy == null) {
              return _buildEmptyState(context, ref);
            }
            return _buildPolicyCard(context, ref, policy);
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => Card(
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text('Error loading insurance: $err'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              Icons.health_and_safety_outlined,
              size: 40,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
            ),
            const SizedBox(height: 8),
            Text(
              'No Insurance Policy Added',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add medical aid details and card photos for emergency access and clinic check-ins.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            if (!isReadOnly) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _openEditDialog(context, ref),
                icon: const Icon(Icons.add_card, size: 18),
                label: const Text('Add Insurance Details'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyCard(BuildContext context, WidgetRef ref, InsurancePolicy policy) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primaryContainer.withOpacity(0.35),
              colorScheme.surface,
            ],
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header: Provider & Plan Name
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.shield_outlined, color: colorScheme.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        policy.provider,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (policy.planName != null && policy.planName!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            policy.planName!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!isReadOnly)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _openEditDialog(context, ref, policy);
                      } else if (value == 'delete') {
                        _confirmDelete(context, ref, policy);
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const Divider(height: 24),

            // Policy Details Grid
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                _buildInfoItem(context, 'Policy / Member #', policy.policyNumber, Icons.badge_outlined),
                if (policy.groupNumber != null && policy.groupNumber!.isNotEmpty)
                  _buildInfoItem(context, 'Group #', policy.groupNumber!, Icons.groups_outlined),
                if (policy.subscriberName != null && policy.subscriberName!.isNotEmpty)
                  _buildInfoItem(context, 'Main Member', policy.subscriberName!, Icons.person_outline),
                if (policy.memberId != null && policy.memberId!.isNotEmpty)
                  _buildInfoItem(context, 'Dependent Code', policy.memberId!, Icons.tag),
              ],
            ),

            // Emergency Pre-auth hotline
            if (policy.emergencyPhone != null && policy.emergencyPhone!.isNotEmpty) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _makePhoneCall(policy.emergencyPhone!),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.2)),
                  ),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      const Icon(Icons.phone_in_talk, size: 16, color: Colors.red),
                      Text(
                        'Pre-Auth / Emergency Hotline: ',
                        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        policy.emergencyPhone!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.red.shade900,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Card Photos (Front & Back)
            const SizedBox(height: 16),
            Text(
              'Card Photos',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildCardPhotoThumbnail(
                    context,
                    title: 'Front Side',
                    imagePath: policy.frontCardImagePath,
                    onTap: () => _viewCardImage(context, 'Insurance Card (Front)', policy.frontCardImagePath ?? ''),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCardPhotoThumbnail(
                    context,
                    title: 'Back Side',
                    imagePath: policy.backCardImagePath,
                    onTap: () => _viewCardImage(context, 'Insurance Card (Back)', policy.backCardImagePath ?? ''),
                  ),
                ),
              ],
            ),

            if (policy.notes != null && policy.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Notes: ${policy.notes}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, String label, String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.outline,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCardPhotoThumbnail(
    BuildContext context, {
    required String title,
    required String? imagePath,
    required VoidCallback onTap,
  }) {
    final hasImage = imagePath != null && imagePath.isNotEmpty && File(imagePath).existsSync();

    return InkWell(
      onTap: hasImage ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasImage
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    File(imagePath),
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      color: Colors.black54,
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.zoom_in, size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            title,
                            style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo_outlined, size: 24, color: Theme.of(context).colorScheme.outline),
                    const SizedBox(height: 4),
                    Text(
                      '$title (Not added)',
                      style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.outline),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, InsurancePolicy policy) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Insurance Policy'),
        content: Text('Are you sure you want to remove insurance details for "${policy.provider}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(insuranceProvider(profileId).notifier).deleteInsurance(policy.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _EditInsuranceSheet extends ConsumerStatefulWidget {
  const _EditInsuranceSheet({
    required this.profileId,
    this.existing,
  });

  final String profileId;
  final InsurancePolicy? existing;

  @override
  ConsumerState<_EditInsuranceSheet> createState() => _EditInsuranceSheetState();
}

class _EditInsuranceSheetState extends ConsumerState<_EditInsuranceSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _providerCtrl;
  late TextEditingController _planCtrl;
  late TextEditingController _policyCtrl;
  late TextEditingController _groupCtrl;
  late TextEditingController _subscriberCtrl;
  late TextEditingController _memberIdCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _notesCtrl;

  File? _frontImageFile;
  File? _backImageFile;
  String? _existingFrontPath;
  String? _existingBackPath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _providerCtrl = TextEditingController(text: p?.provider ?? '');
    _planCtrl = TextEditingController(text: p?.planName ?? '');
    _policyCtrl = TextEditingController(text: p?.policyNumber ?? '');
    _groupCtrl = TextEditingController(text: p?.groupNumber ?? '');
    _subscriberCtrl = TextEditingController(text: p?.subscriberName ?? '');
    _memberIdCtrl = TextEditingController(text: p?.memberId ?? '');
    _phoneCtrl = TextEditingController(text: p?.emergencyPhone ?? '');
    _notesCtrl = TextEditingController(text: p?.notes ?? '');

    _existingFrontPath = p?.frontCardImagePath;
    _existingBackPath = p?.backCardImagePath;
  }

  @override
  void dispose() {
    _providerCtrl.dispose();
    _planCtrl.dispose();
    _policyCtrl.dispose();
    _groupCtrl.dispose();
    _subscriberCtrl.dispose();
    _memberIdCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String side) async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo with Camera'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked != null) {
      setState(() {
        if (side == 'front') {
          _frontImageFile = File(picked.path);
        } else {
          _backImageFile = File(picked.path);
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final notifier = ref.read(insuranceProvider(widget.profileId).notifier);

      String? frontPath = _existingFrontPath;
      String? backPath = _existingBackPath;

      if (_frontImageFile != null) {
        frontPath = await notifier.saveCardImage('front', _frontImageFile!);
      }
      if (_backImageFile != null) {
        backPath = await notifier.saveCardImage('back', _backImageFile!);
      }

      final policy = InsurancePolicy(
        id: widget.existing?.id,
        profileId: widget.profileId,
        provider: _providerCtrl.text.trim(),
        planName: _planCtrl.text.trim().isEmpty ? null : _planCtrl.text.trim(),
        policyNumber: _policyCtrl.text.trim(),
        groupNumber: _groupCtrl.text.trim().isEmpty ? null : _groupCtrl.text.trim(),
        subscriberName: _subscriberCtrl.text.trim().isEmpty ? null : _subscriberCtrl.text.trim(),
        memberId: _memberIdCtrl.text.trim().isEmpty ? null : _memberIdCtrl.text.trim(),
        emergencyPhone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        frontCardImagePath: frontPath,
        backCardImagePath: backPath,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );

      await notifier.saveInsurance(policy);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Insurance policy saved successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save insurance: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.existing == null ? 'Add Health Insurance' : 'Edit Health Insurance',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _providerCtrl,
                decoration: const InputDecoration(
                  labelText: 'Insurance Provider / Medical Aid *',
                  hintText: 'e.g. Discovery Health, Blue Cross Blue Shield',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter insurance provider' : null,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _planCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Plan / Scheme Name',
                        hintText: 'e.g. Classic Comprehensive, Gold PPO',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _policyCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Policy / Member # *',
                        hintText: 'e.g. 123456789',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Please enter policy #' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _groupCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Group # (Optional)',
                        hintText: 'e.g. GRP-9988',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _memberIdCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Dependent Code / Member ID',
                        hintText: 'e.g. 01',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _subscriberCtrl,
                decoration: const InputDecoration(
                  labelText: 'Primary Insured / Main Member Name',
                  hintText: 'e.g. John Doe',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Pre-Authorization / Emergency Line',
                  hintText: 'e.g. +1 800 555 0199',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Insurance Card Photos',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildPhotoPickerButton(
                      side: 'front',
                      label: 'Front of Card',
                      file: _frontImageFile,
                      existingPath: _existingFrontPath,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPhotoPickerButton(
                      side: 'back',
                      label: 'Back of Card',
                      file: _backImageFile,
                      existingPath: _existingBackPath,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes / Co-pay info (Optional)',
                  hintText: 'e.g. \$20 Specialist co-pay, requires pre-auth for hospital stays',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Saving...' : 'Save Insurance Details'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoPickerButton({
    required String side,
    required String label,
    required File? file,
    required String? existingPath,
  }) {
    ImageProvider? imageProvider;
    if (file != null) {
      imageProvider = FileImage(file);
    } else if (existingPath != null && existingPath.isNotEmpty && File(existingPath).existsSync()) {
      imageProvider = FileImage(File(existingPath));
    }

    return InkWell(
      onTap: () => _pickImage(side),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          image: imageProvider != null
              ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
              : null,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: imageProvider != null ? Colors.black45 : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                imageProvider != null ? Icons.photo_camera : Icons.add_a_photo_outlined,
                color: imageProvider != null ? Colors.white : Theme.of(context).colorScheme.primary,
                size: 28,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: imageProvider != null ? Colors.white : Theme.of(context).colorScheme.onSurface,
                ),
              ),
              if (imageProvider != null)
                const Text(
                  'Tap to change',
                  style: TextStyle(fontSize: 10, color: Colors.white70),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
