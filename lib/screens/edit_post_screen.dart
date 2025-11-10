import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../models/post.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class EditPostScreen extends StatefulWidget {
  final Post post;

  const EditPostScreen({super.key, required this.post});

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final _contentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  
  File? _newImage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _contentController.text = widget.post.content;
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _newImage = File(image.path);
        });
      }
    } catch (e) {
      Get.snackbar('오류', '이미지를 선택할 수 없습니다', snackPosition: SnackPosition.BOTTOM);
    }
  }

  List<String> _extractHashtags(String text) {
    final RegExp hashtagRegex = RegExp(r'#\w+');
    final matches = hashtagRegex.allMatches(text);
    return matches.map((match) => match.group(0)!).toList();
  }

  Future<void> _savePost() async {
    if (_contentController.text.trim().isEmpty) {
      Get.snackbar('알림', '게시물 내용을 입력해주세요', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      String imageUrl = widget.post.postImage;

      // 새 이미지가 선택된 경우 업로드
      if (_newImage != null) {
        imageUrl = await _storageService.uploadImage(_newImage!, 'posts');
      }

      final hashtags = _extractHashtags(_contentController.text);

      // Firestore 업데이트
      await _firestoreService.updatePost(widget.post.id, {
        'content': _contentController.text.trim(),
        'postImage': imageUrl,
        'hashtags': hashtags,
      });

      Get.back();
      Get.snackbar(
        '성공',
        '게시물이 수정되었습니다',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF2D7A4F),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        '오류',
        '게시물 수정에 실패했습니다',
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
        title: Text('게시물 수정', style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _savePost,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    '완료',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 16.0,
          bottom: 100.0,
        ),
        child: Column(
          children: [
            // 이미지
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: _newImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(_newImage!, fit: BoxFit.cover),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          widget.post.postImage,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _contentController,
              maxLines: 5,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: '게시물 내용을 입력하세요...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

