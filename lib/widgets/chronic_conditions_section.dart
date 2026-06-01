import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:healthicons_flutter/healthicons_flutter.dart';
import 'package:open_cloud_health/models/profile.dart';

class ChronicConditionInfo {
  final String name;
  final Widget Function({Color? color, double? width, double? height}) iconBuilder;
  final Color color;
  final String description;

  const ChronicConditionInfo({
    required this.name,
    required this.iconBuilder,
    required this.color,
    required this.description,
  });
}

final List<ChronicConditionInfo> commonChronicConditions = [
  ChronicConditionInfo(
    name: 'Hypertension',
    iconBuilder: ({color, width, height}) => BloodPressureOutline(color: color, width: width, height: height),
    color: Colors.red,
    description: 'High blood pressure, requiring regular monitoring and lifestyle adjustments.',
  ),
  ChronicConditionInfo(
    name: 'Diabetes',
    iconBuilder: ({color, width, height}) => SugarOutline(color: color, width: width, height: height),
    color: Colors.orange,
    description: 'Chronic metabolic disorder affecting glucose levels.',
  ),
  ChronicConditionInfo(
    name: 'Hypercholesterolemia',
    iconBuilder: ({color, width, height}) => BloodDropOutline(color: color, width: width, height: height),
    color: Colors.pink,
    description: 'High blood cholesterol levels, requiring dietary or medical control.',
  ),
  ChronicConditionInfo(
    name: 'Asthma',
    iconBuilder: ({color, width, height}) => AsthmaInhalerOutline(color: color, width: width, height: height),
    color: Colors.cyan,
    description: 'Inflammatory disease of airways causing breathing difficulties.',
  ),
  ChronicConditionInfo(
    name: 'COPD',
    iconBuilder: ({color, width, height}) => LungsOutline(color: color, width: width, height: height),
    color: Colors.teal,
    description: 'Chronic obstructive pulmonary disease, causing long-term breathing issues.',
  ),
  ChronicConditionInfo(
    name: 'Chronic Kidney Disease',
    iconBuilder: ({color, width, height}) => KidneysOutline(color: color, width: width, height: height),
    color: Colors.purple,
    description: 'Gradual loss of kidney function over time.',
  ),
  ChronicConditionInfo(
    name: 'Coronary Artery Disease',
    iconBuilder: ({color, width, height}) => HeartbeatOutline(color: color, width: width, height: height),
    color: Colors.redAccent,
    description: 'Reduction of blood flow to the heart muscle.',
  ),
  ChronicConditionInfo(
    name: 'Depression',
    iconBuilder: ({color, width, height}) => MentalHealthOutline(color: color, width: width, height: height),
    color: Colors.indigo,
    description: 'Persistent feelings of sadness and loss of interest.',
  ),
  ChronicConditionInfo(
    name: 'Arthritis',
    iconBuilder: ({color, width, height}) => SkeletonOutline(color: color, width: width, height: height),
    color: Colors.green,
    description: 'Joint inflammation causing pain, stiffness, and reduced mobility.',
  ),
  ChronicConditionInfo(
    name: 'Osteoporosis',
    iconBuilder: ({color, width, height}) => SkeletonOutline(color: color, width: width, height: height),
    color: Colors.blueGrey,
    description: 'Weakening of bones, making them fragile and more likely to break.',
  ),
  ChronicConditionInfo(
    name: 'Endometriosis',
    iconBuilder: ({color, width, height}) => GynecologyOutline(color: color, width: width, height: height),
    color: Colors.purpleAccent,
    description: 'Growth of uterine-like tissue outside the uterus, causing pain.',
  ),
  ChronicConditionInfo(
    name: 'Polycystic Ovary Syndrome (PCOS)',
    iconBuilder: ({color, width, height}) => FemaleOutline(color: color, width: width, height: height),
    color: Colors.deepOrangeAccent,
    description: 'Hormonal disorder common among women of reproductive age.',
  ),
  ChronicConditionInfo(
    name: 'Hypothyroidism',
    iconBuilder: ({color, width, height}) => ThyroidOutline(color: color, width: width, height: height),
    color: Colors.blue,
    description: 'Underactive thyroid gland, resulting in lack of thyroid hormone.',
  ),
];

class ChronicConditionsSection extends StatelessWidget {
  const ChronicConditionsSection({
    super.key,
    required this.profileId,
    required this.chronicConditions,
    required this.gender,
    required this.onChanged,
  });

  final String profileId;
  final List<String> chronicConditions;
  final Gender gender;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Chronic Conditions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            IconButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  builder: (ctx) => ManageChronicConditionsBottomSheet(
                    profileId: profileId,
                    initialConditions: chronicConditions,
                    gender: gender,
                    onChanged: onChanged,
                  ),
                );
              },
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (chronicConditions.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
            child: Text('No chronic conditions selected. Tap edit to select.'),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: chronicConditions.map((conditionName) {
                final isCustom = conditionName.startsWith('Other: ');
                final displayName = isCustom ? conditionName.substring(7) : conditionName;
                
                final info = isCustom
                    ? null
                    : commonChronicConditions.firstWhere(
                        (c) => c.name == conditionName,
                        orElse: () => commonChronicConditions.first);

                final chipColor = isCustom ? Colors.grey : info!.color;

                return Chip(
                  avatar: isCustom
                      ? const DiagnosticsOutline(color: Colors.grey, width: 18, height: 18)
                      : info!.iconBuilder(
                          color: chipColor.withOpacity(0.9),
                          width: 18,
                          height: 18,
                        ),
                  label: Text(
                    displayName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: chipColor.withOpacity(0.1),
                  side: BorderSide(
                    color: chipColor.withOpacity(0.3),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class ManageChronicConditionsBottomSheet extends StatefulWidget {
  const ManageChronicConditionsBottomSheet({
    super.key,
    required this.profileId,
    required this.initialConditions,
    required this.gender,
    required this.onChanged,
  });

  final String profileId;
  final List<String> initialConditions;
  final Gender gender;
  final ValueChanged<List<String>> onChanged;

  @override
  State<ManageChronicConditionsBottomSheet> createState() =>
      _ManageChronicConditionsBottomSheetState();
}

class _ManageChronicConditionsBottomSheetState
    extends State<ManageChronicConditionsBottomSheet> {
  late List<String> _selectedConditions;
  final _customController = TextEditingController();
  bool _showCustomInput = false;

  @override
  void initState() {
    super.initState();
    _selectedConditions = List.from(widget.initialConditions);

    final otherIndex =
        _selectedConditions.indexWhere((c) => c.startsWith('Other: '));
    if (otherIndex != -1) {
      _showCustomInput = true;
      _customController.text = _selectedConditions[otherIndex].substring(7);
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _save() {
    final conditionsToSave =
        _selectedConditions.where((c) => !c.startsWith('Other: ')).toList();
    if (_showCustomInput && _customController.text.trim().isNotEmpty) {
      conditionsToSave.add('Other: ${_customController.text.trim()}');
    }

    widget.onChanged(conditionsToSave);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final theme = Theme.of(context);
    final isMale = widget.gender == Gender.male;

    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 20,
        right: 20,
        bottom: mediaQuery.viewInsets.bottom + 24,
      ),
      constraints: BoxConstraints(
        maxHeight: mediaQuery.size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Chronic Conditions',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Select any active chronic conditions. These are loaded locally and will dynamically configure your medical checkup schedules.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...commonChronicConditions.where((info) {
                    if (isMale &&
                        (info.name == 'Endometriosis' ||
                            info.name == 'Polycystic Ovary Syndrome (PCOS)')) {
                      return false;
                    }
                    return true;
                  }).map((info) {
                    final isChecked = _selectedConditions.contains(info.name);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 0,
                      color: isChecked
                          ? info.color.withOpacity(0.05)
                          : theme.colorScheme.surfaceVariant.withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isChecked
                              ? info.color.withOpacity(0.4)
                              : theme.colorScheme.outline.withOpacity(0.1),
                        ),
                      ),
                      child: CheckboxListTile(
                        value: isChecked,
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedConditions.add(info.name);
                            } else {
                              _selectedConditions.remove(info.name);
                            }
                          });
                        },
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isChecked
                                ? info.color.withOpacity(0.15)
                                : theme.colorScheme.surfaceVariant.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: info.iconBuilder(
                            color: isChecked ? info.color : theme.colorScheme.onSurfaceVariant,
                            width: 24,
                            height: 24,
                          ),
                        ),
                        title: Text(
                          info.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          info.description,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        checkboxShape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      ),
                    );
                  }),
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: 0,
                    color: _showCustomInput
                        ? Colors.grey.withOpacity(0.05)
                        : theme.colorScheme.surfaceVariant.withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: _showCustomInput
                            ? Colors.grey.withOpacity(0.4)
                            : theme.colorScheme.outline.withOpacity(0.1),
                      ),
                    ),
                    child: CheckboxListTile(
                      value: _showCustomInput,
                      onChanged: (checked) {
                        setState(() {
                          _showCustomInput = checked == true;
                          if (!_showCustomInput) {
                            _selectedConditions.removeWhere((c) => c.startsWith('Other: '));
                            _customController.clear();
                          }
                        });
                      },
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _showCustomInput
                              ? Colors.grey.withOpacity(0.15)
                              : theme.colorScheme.surfaceVariant.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: DiagnosticsOutline(
                          color: _showCustomInput ? Colors.grey : theme.colorScheme.onSurfaceVariant,
                          width: 24,
                          height: 24,
                        ),
                      ),
                      title: const Text(
                        'Other Condition',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Specify a custom chronic condition not listed above.',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      checkboxShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    ),
                  ),
                  if (_showCustomInput)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 16, left: 4, right: 4),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        child: TextField(
                          controller: _customController,
                          decoration: InputDecoration(
                            labelText: 'Specify Chronic Condition',
                            hintText: 'e.g. Lyme Disease, Fibromyalgia',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            prefixIcon: const Icon(Icons.edit_note),
                          ),
                          autofocus: _customController.text.isEmpty,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            child: const Text(
              'Add Chronic Conditions',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
