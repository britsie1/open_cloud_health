import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_cupertino_datetime_picker/flutter_cupertino_datetime_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/providers/profiles_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_cloud_health/screens/profiles.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:open_cloud_health/models/allergy.dart';
import 'package:open_cloud_health/providers/allergies_provider.dart';

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
    PermissionStatus cameraPermission = PermissionStatus.denied;
    PermissionStatus photoPermission = PermissionStatus.denied;

    if (imageSource == ImageSource.camera){
      cameraPermission = await Permission.camera.request();
      if (cameraPermission != PermissionStatus.granted){
        //TODO: show a snackbar to say the permission is denied
        return;
      }
    } else if (imageSource == ImageSource.gallery){
      photoPermission = await Permission.photos.request();
      if (photoPermission != PermissionStatus.granted){
        //TODO: show a snackbar to say the permission is denied
        return;
      }
    }

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
        if (value.isNotEmpty) {
          setState(() {
            _pickImageFile = File.fromUri(Uri(path: value));
          });
        }
      });

      Future.microtask(() {
        ref.read(allergiesProvider.notifier).loadAllergies(widget.profile!.id);
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
      final profileImagesDir = Directory(path.join(appDir.path, 'profileImages'));
      if (!profileImagesDir.existsSync()){
        profileImagesDir.create();
      }

      final filePath = path.join(appDir.path, 'profileImages/$profileId.jpg');
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
            if (widget.profile != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Allergies',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        IconButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => _AddAllergyDialog(profileId: widget.profile!.id),
                            );
                          },
                          icon: const Icon(Icons.add),
                        )
                      ],
                    ),
                    const SizedBox(height: 10),
                    Consumer(builder: (context, ref, child) {
                       final allergies = ref.watch(allergiesProvider);
                       if (allergies.isEmpty) {
                         return const Padding(
                           padding: EdgeInsets.only(top: 8.0),
                           child: Text('No allergies added.'),
                         );
                       }
                       return Column(
                         children: allergies.map((allergy) {
                           return ListTile(
                             contentPadding: EdgeInsets.zero,
                             title: Text(allergy.name),
                             subtitle: allergy.note.isNotEmpty ? Text(allergy.note) : null,
                             trailing: IconButton(
                               icon: const Icon(Icons.delete, color: Colors.red),
                               onPressed: () {
                                 showDialog(
                                   context: context,
                                   builder: (ctx) => AlertDialog(
                                     title: const Text('Delete Allergy'),
                                     content: const Text('Are you sure you want to delete this allergy?'),
                                     actions: [
                                       TextButton(
                                         onPressed: () => Navigator.of(context).pop(),
                                         child: const Text('Cancel'),
                                       ),
                                       ElevatedButton(
                                         style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                         onPressed: () {
                                           ref.read(allergiesProvider.notifier).deleteAllergy(allergy.id);
                                           Navigator.of(context).pop();
                                         },
                                         child: const Text('Delete'),
                                       ),
                                     ],
                                   ),
                                 );
                               },
                             ),
                           );
                         }).toList(),
                       );
                    }),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AddAllergyDialog extends ConsumerStatefulWidget {
  const _AddAllergyDialog({required this.profileId});
  final String profileId;

  @override
  ConsumerState<_AddAllergyDialog> createState() => _AddAllergyDialogState();
}

class _AddAllergyDialogState extends ConsumerState<_AddAllergyDialog> {
  final _nameController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nameController.text.trim().isEmpty) {
      return;
    }
    
    final newAllergy = Allergy(
      profileId: widget.profileId,
      name: _nameController.text.trim(),
      note: _noteController.text.trim(),
    );

    ref.read(allergiesProvider.notifier).addAllergy(newAllergy);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Allergy'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Allergy Name'),
            ),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
