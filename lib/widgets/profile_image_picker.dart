import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class ProfileImagePicker extends StatefulWidget {
  const ProfileImagePicker({
    super.key,
    required this.onPickImage,
    required this.imageToShow,
  });

  final void Function(File pickedImage) onPickImage;
  final ImageProvider imageToShow;

  @override
  State<ProfileImagePicker> createState() => _ProfileImagePickerState();
}

class _ProfileImagePickerState extends State<ProfileImagePicker> {
  void _pickImage(ImageSource imageSource) async {
    if (imageSource == ImageSource.camera) {
      final cameraPermission = await Permission.camera.request();
      if (cameraPermission != PermissionStatus.granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera permission denied')),
          );
        }
        return;
      }
    } else if (imageSource == ImageSource.gallery) {
      final photoPermission = await Permission.photos.request();
      if (photoPermission != PermissionStatus.granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gallery permission denied')),
          );
        }
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

    widget.onPickImage(File(pickedImage.path));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
                    borderRadius: const BorderRadius.all(Radius.circular(80.0)),
                    border: Border.all(
                      color: Colors.white,
                      width: 4.0,
                    ),
                    image: DecorationImage(
                      image: widget.imageToShow,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
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
                    } else if (value == 'gallery') {
                      _pickImage(ImageSource.gallery);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
