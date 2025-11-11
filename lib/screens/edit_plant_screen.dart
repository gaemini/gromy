import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/plant.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class EditPlantScreen extends StatefulWidget {
  final Plant plant;
  
  const EditPlantScreen({super.key, required this.plant});

  @override
  State<EditPlantScreen> createState() => _EditPlantScreenState();
}

class _EditPlantScreenState extends State<EditPlantScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();
  
  late TextEditingController _nameController;
  late TextEditingController _noteController;
  late TextEditingController _wateringIntervalController;
  
  List<String> _imageUrls = [];
  List<File> _newImageFiles = [];
  bool _isLoading = false;
  int _currentImageIndex = 0;
  
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.plant.name);
    _noteController = TextEditingController(text: widget.plant.note ?? '');
    _wateringIntervalController = TextEditingController(
      text: widget.plant.wateringIntervalDays.toString()
    );
    _imageUrls = List.from(widget.plant.imageUrls);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    _wateringIntervalController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_imageUrls.length + _newImageFiles.length >= 10) {
      Get.snackbar(
        '이미지 제한',
        '최대 10장까지만 추가할 수 있습니다',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _newImageFiles.add(File(pickedFile.path));
      });
    }
  }

  Future<void> _pickMultipleImages() async {
    final remainingSlots = 10 - (_imageUrls.length + _newImageFiles.length);
    if (remainingSlots <= 0) {
      Get.snackbar(
        '이미지 제한',
        '최대 10장까지만 추가할 수 있습니다',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final List<XFile> pickedFiles = await _picker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (pickedFiles.isNotEmpty) {
      final filesToAdd = pickedFiles.take(remainingSlots).toList();
      setState(() {
        _newImageFiles.addAll(filesToAdd.map((xFile) => File(xFile.path)));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      if (index < _imageUrls.length) {
        _imageUrls.removeAt(index);
      } else {
        _newImageFiles.removeAt(index - _imageUrls.length);
      }
      if (_currentImageIndex >= _imageUrls.length + _newImageFiles.length && _currentImageIndex > 0) {
        _currentImageIndex--;
      }
    });
  }

  Future<void> _saveChanges() async {
    if (_nameController.text.trim().isEmpty) {
      Get.snackbar(
        '오류',
        '식물 이름을 입력해주세요',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (_imageUrls.isEmpty && _newImageFiles.isEmpty) {
      Get.snackbar(
        '오류',
        '최소 1장의 이미지가 필요합니다',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 새 이미지 업로드
      List<String> newImageUrls = [];
      for (var imageFile in _newImageFiles) {
        final url = await _storageService.uploadPlantImage(imageFile);
        newImageUrls.add(url);
      }

      // 전체 이미지 URL 리스트
      final allImageUrls = [..._imageUrls, ...newImageUrls];

      // Plant 객체 업데이트
      final updatedPlant = Plant(
        id: widget.plant.id,
        name: _nameController.text.trim(),
        imageUrl: allImageUrls.first,
        imageUrls: allImageUrls,
        isHealthy: widget.plant.isHealthy,
        createdAt: widget.plant.createdAt,
        userId: widget.plant.userId,
        lastWatered: widget.plant.lastWatered,
        wateringIntervalDays: int.tryParse(_wateringIntervalController.text) ?? 7,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );

      // Firestore 업데이트
      await _firestoreService.addPlant(updatedPlant);

      Get.back(result: updatedPlant);
      Get.snackbar(
        '성공',
        '식물 정보가 업데이트되었습니다',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        '오류',
        '업데이트에 실패했습니다: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalImages = _imageUrls.length + _newImageFiles.length;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '식물 편집',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveChanges,
            child: Text(
              '저장',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _isLoading ? Colors.grey : const Color(0xFF2D7A4F),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 이미지 섹션
                  Text(
                    '사진 ($totalImages/10)',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // 이미지 슬라이더
                  if (totalImages > 0) ...[
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Stack(
                        children: [
                          PageView.builder(
                            itemCount: totalImages,
                            onPageChanged: (index) {
                              setState(() {
                                _currentImageIndex = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              if (index < _imageUrls.length) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    _imageUrls[index],
                                    fit: BoxFit.cover,
                                  ),
                                );
                              } else {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    _newImageFiles[index - _imageUrls.length],
                                    fit: BoxFit.cover,
                                  ),
                                );
                              }
                            },
                          ),
                          
                          // 이미지 인디케이터
                          Positioned(
                            bottom: 10,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                totalImages,
                                (index) => Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: index == _currentImageIndex
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          // 삭제 버튼
                          Positioned(
                            top: 10,
                            right: 10,
                            child: IconButton(
                              onPressed: () => _removeImage(_currentImageIndex),
                              icon: const Icon(Icons.delete, color: Colors.white),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.red.withOpacity(0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  // 이미지 추가 버튼들
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('카메라'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2D7A4F),
                            side: const BorderSide(color: Color(0xFF2D7A4F)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickMultipleImages,
                          icon: const Icon(Icons.photo_library),
                          label: const Text('갤러리'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2D7A4F),
                            side: const BorderSide(color: Color(0xFF2D7A4F)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 식물 이름
                  Text(
                    '식물 이름',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: '식물 이름을 입력하세요',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2D7A4F), width: 2),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 물주기 간격
                  Text(
                    '물주기 간격 (일)',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _wateringIntervalController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '물주기 간격을 입력하세요',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2D7A4F), width: 2),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 메모
                  Text(
                    '메모',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _noteController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: '식물에 대한 메모를 입력하세요',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2D7A4F), width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
