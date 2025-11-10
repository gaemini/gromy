import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/storage_service.dart';
import '../services/firestore_service.dart';
import '../controllers/auth_controller.dart';
import '../models/user_model.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _bioController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final StorageService _storageService = StorageService();
  final FirestoreService _firestoreService = FirestoreService();
  
  File? _selectedImage;
  bool _isSaving = false;
  String? _currentProfileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final authController = Get.find<AuthController>();
    final user = authController.currentUser.value;
    
    if (user != null) {
      _nameController.text = user.displayName;
      _emailController.text = user.email;
      _currentProfileImageUrl = user.profileImageUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      Get.snackbar(
        '오류',
        '이미지를 선택할 수 없습니다',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final authController = Get.find<AuthController>();
      final currentUser = authController.currentUser.value;
      
      if (currentUser == null) return;

      String profileImageUrl = _currentProfileImageUrl ?? '';

      // 1. 이미지 업로드 (선택한 경우)
      if (_selectedImage != null) {
        print('📤 Uploading profile image...');
        profileImageUrl = await _storageService.uploadImage(
          _selectedImage!,
          'profile_images',
        );
        print('✅ Profile image uploaded');
      }

      // 2. 사용자 정보 업데이트
      final updatedUser = UserModel(
        uid: currentUser.uid,
        displayName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        profileImageUrl: profileImageUrl,
      );

      await _firestoreService.saveUser(updatedUser);

      // AuthController 새로고침하여 즉시 반영
      await authController.refreshUserProfile();

      Get.back();
      Get.snackbar(
        '성공',
        '프로필이 업데이트되었습니다',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF2D7A4F),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        '오류',
        '프로필 업데이트에 실패했습니다',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    '저장',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: 20.0,
          right: 20.0,
          top: 20.0,
          bottom: 100.0,
        ),
        child: Column(
          children: [
            // 프로필 이미지
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!) as ImageProvider
                        : _currentProfileImageUrl != null
                            ? NetworkImage(_currentProfileImageUrl!)
                            : const NetworkImage('https://i.pravatar.cc/150?img=5'),
                    backgroundColor: Colors.grey[300],
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D7A4F),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // 이름
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: '이름',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 이메일
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: '이메일',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            
            const SizedBox(height: 16),
            
            // 소개
            TextField(
              controller: _bioController,
              decoration: InputDecoration(
                labelText: '소개',
                prefixIcon: const Icon(Icons.description),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 3,
              maxLength: 150,
            ),
            
            const SizedBox(height: 30),
            
            // 안내 메시지
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue[700],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '프로필 정보는 다른 사용자에게 공개됩니다.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[900],
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
}

