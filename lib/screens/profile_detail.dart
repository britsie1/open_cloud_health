import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_cupertino_datetime_picker/flutter_cupertino_datetime_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/providers/profiles_provider.dart';
import 'package:open_cloud_health/utils/constants.dart';
import 'package:open_cloud_health/utils/result.dart';
import 'package:open_cloud_health/widgets/allergy_list_section.dart';
import 'package:open_cloud_health/widgets/profile_image_picker.dart';
import 'package:open_cloud_health/widgets/chronic_conditions_section.dart';

class ProfileDetailScreen extends ConsumerStatefulWidget {
  const ProfileDetailScreen({super.key, this.profile, this.profileId});

  final Profile? profile;
  final String? profileId;

  @override
  ConsumerState<ProfileDetailScreen> createState() =>
      _CreateProfileScreenState();
}

class _CreateProfileScreenState extends ConsumerState<ProfileDetailScreen> {
  final _selectedDateController = TextEditingController();
  final _form = GlobalKey<FormState>();
  var _enteredName = '';
  var _enteredMiddleNames = '';
  var _enteredSurname = '';
  var _isOrganDonor = false;
  var _trackOvulation = true;
  Gender? _selectedGender;
  var _selectedBloodType = 'Unknown';
  File? _pickImageFile;
  bool _isNewImagePicked = false;
  Profile? _activeProfile;
  bool _isEditing = false;
  List<String> _selectedChronicConditions = [];

  @override
  void dispose() {
    _selectedDateController.dispose();
    super.dispose();
  }

  int _calculateAge(DateTime dob) {
    final today = DateTime.now();
    int age = today.year - dob.year;
    if (today.month < dob.month ||
        (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    return age;
  }

  bool _isFertilityToggleVisible() {
    if (_selectedGender != Gender.female) return false;
    if (_selectedDateController.text.isEmpty) return true;
    try {
      final dob = DateTime.parse(_selectedDateController.text);
      final age = _calculateAge(dob);
      return age > 10;
    } catch (_) {
      return true;
    }
  }

  void _checkFertilityToggleConstraint() {
    if (!_isFertilityToggleVisible()) {
      _trackOvulation = false;
    }
  }

  void _onGenderChanged(Gender? newGender) {
    if (newGender == null) return;
    setState(() {
      final oldGender = _selectedGender;
      _selectedGender = newGender;
      
      // If switching from male/null to female, and the age is > 10, default trackOvulation to true.
      if (newGender == Gender.female && oldGender != Gender.female) {
        if (_selectedDateController.text.isNotEmpty) {
          try {
            final dob = DateTime.parse(_selectedDateController.text);
            if (_calculateAge(dob) > 10) {
              _trackOvulation = true;
            }
          } catch (_) {
            _trackOvulation = true;
          }
        } else {
          _trackOvulation = true;
        }
      }
      
      _checkFertilityToggleConstraint();
    });
  }

  void _onDateOfBirthChanged(DateTime dateTime) {
    setState(() {
      final dobStr = formatter.format(dateTime);
      final ageBefore = _selectedDateController.text.isNotEmpty 
          ? _calculateAge(DateTime.parse(_selectedDateController.text)) 
          : null;
      _selectedDateController.text = dobStr;
      
      final ageAfter = _calculateAge(dateTime);
      
      // If it becomes an adult female, and was previously a child female (where it was forced off),
      // we can default trackOvulation back to true.
      if (_selectedGender == Gender.female && ageAfter > 10 && (ageBefore != null && ageBefore <= 10)) {
        _trackOvulation = true;
      }
      
      _checkFertilityToggleConstraint();
    });
  }

  @override
  void initState() {
    super.initState();
    _isEditing = widget.profile != null || widget.profileId != null;
    _initializeProfile();
  }

  void _initializeProfile() {
    Profile? profile = widget.profile;
    if (profile == null && widget.profileId != null) {
      profile =
          ref.read(profilesProvider.notifier).getProfile(widget.profileId!);
    }

    profile ??= Profile(
      name: '',
      middleNames: '',
      surname: '',
      dateOfBirth: DateTime.now().subtract(const Duration(days: 365 * 18)),
      gender: Gender.male,
      bloodType: 'Unknown',
      isOrganDonor: false,
    );
    _activeProfile = profile;

    if (_isEditing && _activeProfile != null) {
      _enteredName = _activeProfile!.name;
      _enteredMiddleNames = _activeProfile!.middleNames;
      _enteredSurname = _activeProfile!.surname;
      _selectedDateController.text =
          formatter.format(_activeProfile!.dateOfBirth);
      _selectedGender = _activeProfile!.gender;
      _selectedBloodType = _activeProfile!.bloodType;
      _isOrganDonor = _activeProfile!.isOrganDonor;
      _trackOvulation = _activeProfile!.trackOvulation;
      _selectedChronicConditions = List.from(_activeProfile!.chronicConditions);
      _checkFertilityToggleConstraint();

      ref
          .read(profilesProvider.notifier)
          .getProfileImagePath(_activeProfile!.id)
          .then((value) {
        if (value.isNotEmpty) {
          if (!mounted) return;
          setState(() {
            _pickImageFile = File.fromUri(Uri(path: value));
            _isNewImagePicked = false;
          });
        }
      });
    } else {
      _trackOvulation = true;
      _selectedChronicConditions = [];
      _checkFertilityToggleConstraint();
    }
  }

  void _saveProfile() async {
    final isValid = _form.currentState!.validate();
    if (!isValid) {
      return;
    }
    _form.currentState!.save();

    final result = await ref.read(profilesProvider.notifier).saveProfile(
          id: _activeProfile?.id,
          name: _enteredName,
          middleNames: _enteredMiddleNames,
          surname: _enteredSurname,
          dateOfBirth: DateTime.parse(_selectedDateController.text),
          gender: _selectedGender!,
          bloodType: _selectedBloodType,
          isOrganDonor: _isOrganDonor,
          trackOvulation: _trackOvulation,
          chronicConditions: _selectedChronicConditions,
          imageFile: _isNewImagePicked ? _pickImageFile : null,
          isUpdate: _isEditing,
        );

    if (!mounted) return;

    switch (result) {
      case Success():
        if (context.canPop()) {
          context.pop();
        } else {
          // If in tab, maybe show a success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        }
        break;
      case Failure(:final exception):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $exception')),
        );
        break;
    }
  }

  String getGenderDisplayString(Gender gender) {
    switch (gender) {
      case Gender.male:
        return 'Male';
      case Gender.female:
        return 'Female';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider imageToShow = AssetImage(
        _selectedGender == null || _selectedGender == Gender.male
            ? AppAssets.malePlaceholder
            : AppAssets.femalePlaceholder);

    if (_pickImageFile != null) {
      imageToShow = FileImage(_pickImageFile!);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.profile != null ? 'Profile Information' : 'Create Profile'),
        actions: [
          IconButton(
            onPressed: _saveProfile,
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ProfileImagePicker(
              imageToShow: imageToShow,
              onPickImage: (pickedImage) {
                setState(() {
                  _pickImageFile = pickedImage;
                  _isNewImagePicked = true;
                });
              },
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Form(
                key: _form,
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Column(
                          children: [
                            SizedBox(
                              height: 64,
                              child: Icon(Icons.account_circle_outlined),
                            ),
                          ],
                        ),
                        const SizedBox(
                          width: 16,
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              TextFormField(
                                initialValue: _enteredName,
                                decoration: const InputDecoration(
                                    labelText: 'First Name'),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your name';
                                  }
                                  return null;
                                },
                                onSaved: (newValue) {
                                  _enteredName = newValue!;
                                },
                              ),
                              TextFormField(
                                initialValue: _enteredMiddleNames,
                                decoration: const InputDecoration(
                                    labelText: 'Middle Names'),
                                onSaved: (newValue) {
                                  _enteredMiddleNames = newValue!;
                                },
                              ),
                              TextFormField(
                                initialValue: _enteredSurname,
                                decoration:
                                    const InputDecoration(labelText: 'Surname'),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your surname';
                                  }
                                  return null;
                                },
                                onSaved: (newValue) {
                                  _enteredSurname = newValue!;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.cake_outlined),
                        const SizedBox(
                          width: 16,
                        ),
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(
                                labelText: 'Date of Birth'),
                            readOnly: true,
                            controller: _selectedDateController,
                            onTap: () {
                              DatePicker.showDatePicker(
                                context,
                                maxDateTime: DateTime.now(),
                                dateFormat: 'yyyy-MMMM-dd',
                                initialDateTime:
                                    _selectedDateController.text.isEmpty
                                        ? DateTime(DateTime.now().year - 18)
                                        : DateTime.parse(
                                            _selectedDateController.text),
                                onConfirm: (dateTime, selectedIndex) {
                                  _onDateOfBirthChanged(dateTime);
                                },
                              );
                            },
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please select your date of birth';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (_selectedGender == null)
                          const Icon(Icons.transgender),
                        if (_selectedGender == Gender.male)
                          const Icon(Icons.male),
                        if (_selectedGender == Gender.female)
                          const Icon(Icons.female),
                        const SizedBox(
                          width: 16,
                        ),
                        Expanded(
                          child: DropdownButtonFormField<Gender>(
                            decoration:
                                const InputDecoration(labelText: 'Gender'),
                            value: _selectedGender,
                            items: Gender.values.map((gender) {
                              return DropdownMenuItem<Gender>(
                                value: gender,
                                child: Text(
                                  getGenderDisplayString(gender),
                                ),
                              );
                            }).toList(),
                            onChanged: _onGenderChanged,
                            validator: (value) {
                              if (value == null) {
                                return 'Please select your medical gender.';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(
                          width: 16,
                        ),
                        const Icon(Icons.bloodtype_outlined),
                        const SizedBox(
                          width: 16,
                        ),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration:
                                const InputDecoration(labelText: 'Blood type'),
                            value: _selectedBloodType,
                            items: [
                              'Unknown',
                              'A+',
                              'A-',
                              'B+',
                              'B-',
                              'AB+',
                              'AB-',
                              'O+',
                              'O-',
                            ].map((bloodType) {
                              return DropdownMenuItem<String>(
                                value: bloodType,
                                child: Text(bloodType),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(
                                () {
                                  _selectedBloodType = value!;
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Row(
                      children: [
                        const Icon(Icons.favorite_border),
                        const SizedBox(
                          width: 16,
                        ),
                        Expanded(
                          child: SwitchListTile(
                            title: const Text('Organ Donor'),
                            value: _isOrganDonor,
                            onChanged: (value) {
                              setState(() {
                                _isOrganDonor = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    if (_isFertilityToggleVisible())
                      Row(
                        children: [
                          const Icon(Icons.child_care),
                          const SizedBox(
                            width: 16,
                          ),
                          Expanded(
                            child: SwitchListTile(
                              title: const Text('Track Ovulation/Pregnancy'),
                              value: _trackOvulation,
                              onChanged: (value) {
                                setState(() {
                                  _trackOvulation = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    if (_activeProfile != null) ...[
                      AllergyListSection(profileId: _activeProfile!.id),
                      const SizedBox(height: 16),
                      ChronicConditionsSection(
                        profileId: _activeProfile!.id,
                        chronicConditions: _selectedChronicConditions,
                        gender: _selectedGender ?? Gender.male,
                        onChanged: (newConditions) {
                          setState(() {
                            _selectedChronicConditions = newConditions;
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
