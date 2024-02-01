import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_cupertino_datetime_picker/flutter_cupertino_datetime_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/providers/profiles_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_cloud_health/screens/profiles.dart';
import 'package:path_provider/path_provider.dart';

class ProfileDetailScreen extends ConsumerStatefulWidget {
  const ProfileDetailScreen({super.key, required this.profile});

  final Profile? profile;

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
  Gender? _selectedGender;
  var _selectedBloodType = 'Unknown';
  File? _pickImageFile;

  @override
  void dispose() {
    _selectedDateController.dispose();
    super.dispose();
  }

  void _pickImage(ImageSource imageSource) async {
    final pickedImage = await ImagePicker().pickImage(
      source: imageSource,
      maxWidth: 300,
    );

    if (pickedImage == null) {
      return;
    }

    setState(() {
      _pickImageFile = File(pickedImage.path);
    });
  }

  @override
  void initState() {
    super.initState();

    if (widget.profile != null) {
      _enteredName = widget.profile!.name;
      _enteredMiddleNames = widget.profile!.middleNames;
      _enteredSurname = widget.profile!.surname;
      _selectedDateController.text =
          formatter.format(widget.profile!.dateOfBirth);
      _selectedGender = widget.profile!.gender;
      _selectedBloodType = widget.profile!.bloodType;
      _isOrganDonor = widget.profile!.isOrganDonor;

      ref
          .read(profilesProvider.notifier)
          .getProfileImagePath(widget.profile!.id)
          .then((value) {
        setState(() {
          _pickImageFile = File.fromUri(Uri(path: value));
        });
      });
    }
  }

  void _saveProfile() async {
    final isValid = _form.currentState!.validate();
    if (!isValid) {
      return;
    }
    _form.currentState!.save();

    String profileId = '';
    if (widget.profile == null) {
      profileId = await ref.read(profilesProvider.notifier).addProfile(
          _enteredName,
          _enteredMiddleNames,
          _enteredSurname,
          DateTime.parse(_selectedDateController.text),
          _selectedGender!,
          _selectedBloodType,
          _isOrganDonor);
    } else {
      ref.read(profilesProvider.notifier).updateProfile(
            Profile(
                id: widget.profile!.id,
                name: _enteredName,
                middleNames: _enteredMiddleNames,
                surname: _enteredSurname,
                dateOfBirth: DateTime.parse(_selectedDateController.text),
                gender: _selectedGender!,
                bloodType: _selectedBloodType,
                isOrganDonor: _isOrganDonor),
          );
      profileId = widget.profile!.id;
    }

    if (_pickImageFile != null) {
      Directory appDir = await getApplicationDocumentsDirectory();
      final filePath = '${appDir.path}/$profileId.jpg';
      if (await File(filePath).exists()) {
        File(filePath).delete();
      }

      var newImage = await File(filePath).create();
      newImage.writeAsBytes(_pickImageFile!.readAsBytesSync());
    }

    if (!mounted) {
      return;
    }

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (ctx) => const ProfilesScreen(),
        ),
      );
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
            ? 'assets/images/male_placeholder.png'
            : 'assets/images/female_placeholder.png');

    if (_pickImageFile != null) {
      imageToShow = FileImage(_pickImageFile!);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.profile != null ? 'Profile Information' : 'Create Profile'),
        actions: [
          IconButton(
            onPressed: () {
              _saveProfile();
            },
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Column(
                children: [
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Container(
                          height: 160,
                          width: 160,
                          decoration: BoxDecoration(
                            borderRadius:
                                const BorderRadius.all(Radius.circular(80.0)),
                            border: Border.all(
                              color: Colors.white,
                              width: 4.0,
                            ),
                            image: DecorationImage(
                                image: imageToShow, fit: BoxFit.cover),
                          ),
                        ),
                        PopupMenuButton(
                          position: PopupMenuPosition.under,
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.white,
                          ),
                          itemBuilder: (ctx) => const [
                            PopupMenuItem(
                              value: 'camera',
                              child: ListTile(
                                leading: Icon(Icons.camera_alt_outlined),
                                title: Text('Camera'),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'gallery',
                              child: ListTile(
                                leading: Icon(Icons.image_search_rounded),
                                title: Text('Gallery'),
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'camera') {
                              _pickImage(ImageSource.camera);
                            } else {
                              _pickImage(ImageSource.gallery);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
                                  _selectedDateController.text =
                                      formatter.format(dateTime);
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
                          child: DropdownButtonFormField(
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
                            onChanged: (value) {
                              setState(() {
                                _selectedGender = value!;
                              });
                            },
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
                          child: DropdownButtonFormField(
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
