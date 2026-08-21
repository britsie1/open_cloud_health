import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:healthicons_flutter/healthicons_flutter.dart';
import 'package:open_cloud_health/models/allergy.dart';
import 'package:open_cloud_health/providers/allergies_provider.dart';

class AllergenInfo {
  final String name;
  final Widget Function({Color? color, double? width, double? height}) iconBuilder;
  final Color color;
  final String description;

  const AllergenInfo({
    required this.name,
    required this.iconBuilder,
    required this.color,
    required this.description,
  });
}

final List<AllergenInfo> commonAllergens = [
  AllergenInfo(
    name: 'Penicillin',
    iconBuilder: ({color, width, height}) => MedicinesOutline(color: color, width: width, height: height),
    color: Colors.red,
    description: 'Allergic reaction to penicillin and related beta-lactam antibiotics.',
  ),
  AllergenInfo(
    name: 'Sulfa Drugs',
    iconBuilder: ({color, width, height}) => MedicinesOutline(color: color, width: width, height: height),
    color: Colors.deepOrange,
    description: 'Adverse allergic reactions to sulfonamide-containing medications.',
  ),
  AllergenInfo(
    name: 'NSAIDs / Aspirin',
    iconBuilder: ({color, width, height}) => MedicinesOutline(color: color, width: width, height: height),
    color: Colors.pink,
    description: 'Hypersensitivity to ibuprofen, aspirin, and nonsteroidal anti-inflammatory drugs.',
  ),
  AllergenInfo(
    name: 'Peanuts',
    iconBuilder: ({color, width, height}) => Icon(Icons.egg_alt, color: color, size: width ?? 24),
    color: Colors.brown,
    description: 'Legume allergy frequently associated with severe and acute anaphylaxis.',
  ),
  AllergenInfo(
    name: 'Tree Nuts',
    iconBuilder: ({color, width, height}) => Icon(Icons.eco, color: color, size: width ?? 24),
    color: Colors.amber.shade800,
    description: 'Allergy to tree nuts (almonds, walnuts, cashews, hazelnuts, pecans, pistachios).',
  ),
  AllergenInfo(
    name: 'Shellfish',
    iconBuilder: ({color, width, height}) => Icon(Icons.set_meal, color: color, size: width ?? 24),
    color: Colors.cyan.shade700,
    description: 'Immune reaction to crustaceans (shrimp, crab, lobster) or mollusks (clams, oysters).',
  ),
  AllergenInfo(
    name: 'Fish',
    iconBuilder: ({color, width, height}) => Icon(Icons.set_meal, color: color, size: width ?? 24),
    color: Colors.blue,
    description: 'Allergic response to finned fish such as salmon, tuna, cod, or halibut.',
  ),
  AllergenInfo(
    name: 'Milk / Dairy',
    iconBuilder: ({color, width, height}) => Icon(Icons.local_drink, color: color, size: width ?? 24),
    color: Colors.lightBlue.shade700,
    description: 'Immune reaction to cow milk proteins (casein and whey).',
  ),
  AllergenInfo(
    name: 'Eggs',
    iconBuilder: ({color, width, height}) => Icon(Icons.egg_alt, color: color, size: width ?? 24),
    color: Colors.amber.shade700,
    description: 'Immune sensitivity to proteins found in egg whites or egg yolks.',
  ),
  AllergenInfo(
    name: 'Wheat / Gluten',
    iconBuilder: ({color, width, height}) => Icon(Icons.grass, color: color, size: width ?? 24),
    color: Colors.orange.shade800,
    description: 'Allergic sensitivity to proteins in wheat and gluten grains.',
  ),
  AllergenInfo(
    name: 'Soy',
    iconBuilder: ({color, width, height}) => Icon(Icons.eco, color: color, size: width ?? 24),
    color: Colors.green.shade700,
    description: 'Immune response to soybeans, soy milk, and soy-derived foods.',
  ),
  AllergenInfo(
    name: 'Latex',
    iconBuilder: ({color, width, height}) => BandagedOutline(color: color, width: width, height: height),
    color: Colors.purple,
    description: 'Hypersensitivity to natural rubber latex gloves, bandages, and medical items.',
  ),
  AllergenInfo(
    name: 'Pollen (Hay Fever)',
    iconBuilder: ({color, width, height}) => Icon(Icons.grass, color: color, size: width ?? 24),
    color: Colors.teal,
    description: 'Seasonal allergic rhinitis triggered by tree, grass, or weed pollens.',
  ),
  AllergenInfo(
    name: 'Dust Mites',
    iconBuilder: ({color, width, height}) => LungsOutline(color: color, width: width, height: height),
    color: Colors.blueGrey,
    description: 'Microscopic indoor allergen causing respiratory and asthma-like symptoms.',
  ),
  AllergenInfo(
    name: 'Pet Dander',
    iconBuilder: ({color, width, height}) => Icon(Icons.pets, color: color, size: width ?? 24),
    color: Colors.deepPurple,
    description: 'Allergy to proteins found in animal dander, saliva, or fur (cats, dogs).',
  ),
  AllergenInfo(
    name: 'Insect Stings',
    iconBuilder: ({color, width, height}) => Icon(Icons.pest_control, color: color, size: width ?? 24),
    color: Colors.redAccent.shade700,
    description: 'Systemic or localized severe reactions to bee, wasp, hornet, or ant venom.',
  ),
  AllergenInfo(
    name: 'Mold',
    iconBuilder: ({color, width, height}) => Icon(Icons.coronavirus, color: color, size: width ?? 24),
    color: Colors.teal.shade800,
    description: 'Allergic reactions to airborne fungal spores in damp indoor or outdoor areas.',
  ),
  AllergenInfo(
    name: 'Contrast Dye',
    iconBuilder: ({color, width, height}) => TestTubesOutline(color: color, width: width, height: height),
    color: Colors.indigo,
    description: 'Adverse sensitivity to iodinated radiocontrast media used in imaging scans.',
  ),
];

AllergenInfo getAllergenInfo(String name) {
  final cleanName = name.startsWith('Other: ') ? name.substring(7) : name;
  return commonAllergens.firstWhere(
    (a) => a.name.toLowerCase() == cleanName.toLowerCase(),
    orElse: () => AllergenInfo(
      name: cleanName,
      iconBuilder: ({color, width, height}) => DiagnosticsOutline(color: color, width: width, height: height),
      color: Colors.grey,
      description: 'Custom specified allergy.',
    ),
  );
}

class AllergyListSection extends ConsumerWidget {
  const AllergyListSection({
    super.key,
    required this.profileId,
    this.allergies,
    this.onChanged,
    this.isReadOnly = false,
  });

  final String profileId;
  final List<Allergy>? allergies;
  final ValueChanged<List<Allergy>>? onChanged;
  final bool isReadOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (allergies != null && onChanged != null) {
      return _buildContent(context, allergies!, onChanged!);
    }

    final allergiesAsync = ref.watch(allergiesProvider(profileId));

    return allergiesAsync.when(
      data: (dbAllergies) => _buildContent(
        context,
        dbAllergies,
        (updated) async {
          await ref.read(allergiesProvider(profileId).notifier).setAllergies(updated);
        },
      ),
      loading: () => const Center(child: Padding(
        padding: EdgeInsets.all(16.0),
        child: CircularProgressIndicator(),
      )),
      error: (error, stack) => Text('Error loading allergies: $error'),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<Allergy> currentAllergies,
    ValueChanged<List<Allergy>> onChangeCallback,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(Icons.warning_amber_outlined),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Allergies',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton(
              onPressed: isReadOnly
                  ? null
                  : () {
                      showModalBottomSheet(
                        context: context,
                        useRootNavigator: true,
                        useSafeArea: true,
                        showDragHandle: true,
                        isScrollControlled: true,
                        isDismissible: true,
                        enableDrag: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        builder: (ctx) => ManageAllergiesBottomSheet(
                          profileId: profileId,
                          initialAllergies: currentAllergies,
                          onChanged: onChangeCallback,
                        ),
                      );
                    },
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (currentAllergies.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
            child: Text('No allergies added. Tap to select.'),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: currentAllergies.map((allergy) {
                final info = getAllergenInfo(allergy.name);
                final chipColor = info.color;
                final noteSuffix = allergy.note.trim().isNotEmpty ? ' (${allergy.note.trim()})' : '';

                return Chip(
                  avatar: info.iconBuilder(
                    color: chipColor.withOpacity(0.9),
                    width: 18,
                    height: 18,
                  ),
                  label: Text(
                    '${allergy.name}$noteSuffix',
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

class ManageAllergiesBottomSheet extends StatefulWidget {
  const ManageAllergiesBottomSheet({
    super.key,
    required this.profileId,
    required this.initialAllergies,
    required this.onChanged,
  });

  final String profileId;
  final List<Allergy> initialAllergies;
  final ValueChanged<List<Allergy>> onChanged;

  @override
  State<ManageAllergiesBottomSheet> createState() => _ManageAllergiesBottomSheetState();
}

class _ManageAllergiesBottomSheetState extends State<ManageAllergiesBottomSheet> {
  final Set<String> _selectedNames = {};
  final Map<String, String> _notesMap = {};
  final _customNameController = TextEditingController();
  final _customNoteController = TextEditingController();
  bool _showCustomInput = false;

  @override
  void initState() {
    super.initState();
    for (final allergy in widget.initialAllergies) {
      final matchingCommon = commonAllergens.cast<AllergenInfo?>().firstWhere(
        (a) => a?.name.toLowerCase() == allergy.name.toLowerCase(),
        orElse: () => null,
      );

      if (matchingCommon != null) {
        _selectedNames.add(matchingCommon.name);
        if (allergy.note.isNotEmpty) {
          _notesMap[matchingCommon.name] = allergy.note;
        }
      } else {
        _showCustomInput = true;
        _customNameController.text = allergy.name.startsWith('Other: ')
            ? allergy.name.substring(7)
            : allergy.name;
        _customNoteController.text = allergy.note;
      }
    }
  }

  @override
  void dispose() {
    _customNameController.dispose();
    _customNoteController.dispose();
    super.dispose();
  }

  void _save() {
    final List<Allergy> allergiesToSave = [];

    for (final name in _selectedNames) {
      allergiesToSave.add(
        Allergy(
          profileId: widget.profileId,
          name: name,
          note: _notesMap[name]?.trim() ?? '',
        ),
      );
    }

    if (_showCustomInput && _customNameController.text.trim().isNotEmpty) {
      allergiesToSave.add(
        Allergy(
          profileId: widget.profileId,
          name: _customNameController.text.trim(),
          note: _customNoteController.text.trim(),
        ),
      );
    }

    widget.onChanged(allergiesToSave);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final theme = Theme.of(context);

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
              Expanded(
                child: Text(
                  'Allergies & Sensitivities',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Select any known allergies or medical sensitivities. These are stored locally and will be highlighted during emergencies.',
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
                  ...commonAllergens.map((info) {
                    final isChecked = _selectedNames.contains(info.name);
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
                      child: Column(
                        children: [
                          CheckboxListTile(
                            value: isChecked,
                            onChanged: (checked) {
                              setState(() {
                                if (checked == true) {
                                  _selectedNames.add(info.name);
                                } else {
                                  _selectedNames.remove(info.name);
                                  _notesMap.remove(info.name);
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
                          if (isChecked)
                            Padding(
                              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                              child: TextFormField(
                                initialValue: _notesMap[info.name] ?? '',
                                decoration: InputDecoration(
                                  labelText: 'Reaction / Notes (optional)',
                                  hintText: 'e.g. Hives, Anaphylaxis, Swelling',
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  prefixIcon: const Icon(Icons.note_alt_outlined, size: 20),
                                ),
                                onChanged: (val) {
                                  _notesMap[info.name] = val;
                                },
                              ),
                            ),
                        ],
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
                            _customNameController.clear();
                            _customNoteController.clear();
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
                        'Other Allergy',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Specify a custom allergy not listed above.',
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
                      child: Column(
                        children: [
                          TextField(
                            controller: _customNameController,
                            decoration: InputDecoration(
                              labelText: 'Specify Allergy Name',
                              hintText: 'e.g. Strawberries, Nickel, Bee Venom',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              prefixIcon: const Icon(Icons.edit_note),
                            ),
                            autofocus: _customNameController.text.isEmpty,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _customNoteController,
                            decoration: InputDecoration(
                              labelText: 'Reaction / Notes (optional)',
                              hintText: 'e.g. Skin rash, severe nausea',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              prefixIcon: const Icon(Icons.description_outlined),
                            ),
                          ),
                        ],
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
              'Save Allergies',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
