import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/home_controller.dart';
import '../controllers/auth_controller.dart';
import '../services/storage_service.dart';
import '../models/plant.dart';

class AddPlantScreen extends StatefulWidget {
  const AddPlantScreen({super.key});

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final StorageService _storageService = StorageService();
  File? _selectedImage;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      Get.snackbar(
        '오류',
        '이미지를 선택할 수 없습니다: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _showImageSourceDialog() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 40),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text('갤러리에서 선택'),
              onTap: () {
                Get.back();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.green),
              title: const Text('사진 촬영'),
              onTap: () {
                Get.back();
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
        ),
      ),
    );
  }

  Future<void> _savePlant() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedImage == null) {
      Get.snackbar(
        '알림',
        '식물 사진을 선택해주세요',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authController = Get.find<AuthController>();
      final homeController = Get.find<HomeController>();

      // 1. Firebase Storage에 이미지 업로드
      print('📤 Uploading plant image...');
      final imageUrl = await _storageService.uploadImage(
        _selectedImage!,
        'plants',
      );
      print('✅ Image uploaded: $imageUrl');

      // 2. Plant 객체 생성
      final newPlant = Plant(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        imageUrl: imageUrl,
        isHealthy: true,
        createdAt: DateTime.now(),
        userId: authController.currentUserId ?? 'anonymous',
      );

      // 3. Firestore에 저장
      await homeController.addPlant(newPlant);
      print('✅ Plant saved to Firestore');

      Get.back();
      Get.snackbar(
        '성공',
        '${newPlant.name}가 추가되었습니다!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF2D7A4F),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        '오류',
        '식물 추가에 실패했습니다: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('식물 추가'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: 20.0,
          right: 20.0,
          top: 20.0,
          bottom: 100.0,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 이미지 선택 영역
              GestureDetector(
                onTap: _showImageSourceDialog,
                child: Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '식물 사진 추가',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '탭하여 사진 선택',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              
              const SizedBox(height: 30),
              
              // 식물 이름 입력
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: '식물 이름',
                  hintText: '예: 몬스테라',
                  prefixIcon: const Icon(Icons.local_florist),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '식물 이름을 입력해주세요';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 40),
              
              // 저장 버튼
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _savePlant,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D7A4F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          '식물 추가하기',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // 안내 메시지
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.green[700],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '식물을 추가하면 성장 과정을 기록하고 관리할 수 있습니다.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green[900],
                          height: 1.4,
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
    );
  }
}

