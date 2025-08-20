import 'dart:io';
import 'package:ai_task_project_manager/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class ProfileDetailPage extends StatefulWidget {
  const ProfileDetailPage({super.key});

  @override
  State<ProfileDetailPage> createState() => _ProfileDetailPageState();
}

class _ProfileDetailPageState extends State<ProfileDetailPage> {
  final AuthController authController = Get.find<AuthController>();
  late TextEditingController _nameController;
  File? _profileImage;
  String? selectedAvatar;
  bool _isSaving = false;

  final List<String> avatars = [
    "https://i.pravatar.cc/150?img=1",
    "https://i.pravatar.cc/150?img=2",
    "https://i.pravatar.cc/150?img=3",
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: authController.name.value);
    selectedAvatar = authController.photoURL.value;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _profileImage = File(picked.path);
        selectedAvatar = null;
      });
    }
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      Get.snackbar("Error", "กรุณากรอกชื่อ");
      return;
    }

    setState(() => _isSaving = true);

    try {
      String? photo;
      if (_profileImage != null) {
        photo = await authController.uploadProfileImage(_profileImage!);
      } else {
        photo = selectedAvatar;
      }

      await authController.updateProfile(newName: name, newPhotoURL: photo);
      Get.snackbar("Success", "Profile updated successfully!");
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  Obx(() => CircleAvatar(
                        radius: 60,
                        backgroundImage: _profileImage != null
                            ? FileImage(_profileImage!)
                            : (authController.photoURL.value.isNotEmpty
                                ? NetworkImage(authController.photoURL.value)
                                : const AssetImage("assets/default_avatar.png")
                                    as ImageProvider),
                      )),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.deepPurple),
                      onPressed: _pickImage,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Display Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              children: avatars.map((avatar) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedAvatar = avatar;
                      _profileImage = null;
                    });
                  },
                  child: CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(avatar),
                    child: (selectedAvatar == avatar)
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: _isSaving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save),
              label: const Text("Save"),
              onPressed: _isSaving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
