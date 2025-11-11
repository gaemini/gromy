import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/auth_controller.dart';
import '../models/diagnosis_history.dart';
import '../services/ai_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class DiagnosisController extends GetxController {
  DiagnosisController({
    ImagePicker? picker,
    StorageService? storageService,
    AiService? aiService,
    FirestoreService? firestoreService,
  })  : _picker = picker ?? ImagePicker(),
        _storageService = storageService ?? StorageService(),
        _aiService = aiService ?? AiService(),
        _firestoreService = firestoreService ?? FirestoreService();

  final ImagePicker _picker;
  final StorageService _storageService;
  final AiService _aiService;
  final FirestoreService _firestoreService;

  final RxBool isLoading = false.obs;
  final Rx<DiagnosisResult?> currentResult = Rx<DiagnosisResult?>(null);
  final Rx<File?> selectedImage = Rx<File?>(null);
  final RxString uploadedImageUrl = ''.obs;

  Future<void> pickAndDiagnose({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (picked == null) {
        return;
      }

      final File imageFile = File(picked.path);
      selectedImage.value = imageFile;

      await _diagnose(imageFile);
    } catch (e) {
      Get.snackbar(
        '이미지 선택 실패',
        '이미지를 불러올 수 없습니다. 다시 시도해주세요.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _diagnose(File imageFile) async {
    final authController = Get.find<AuthController>();
    final userId = authController.currentUserId;

    if (userId == null) {
      Get.snackbar(
        '로그인이 필요해요',
        '진단 기능을 사용하려면 로그인해주세요.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isLoading.value = true;
      currentResult.value = null;

      final imageUrl = await _storageService.uploadImage(imageFile, 'diagnoses');
      uploadedImageUrl.value = imageUrl;

      final result = await _aiService.diagnose(imageFile);
      currentResult.value = result;

      await _saveDiagnosisHistory(
        userId: userId,
        result: result,
        imageUrl: imageUrl,
      );
    } on AiServiceException catch (e) {
      Get.snackbar(
        'AI 진단 실패',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        '진단 실패',
        '진단 중 문제가 발생했습니다. 다시 시도해주세요.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _saveDiagnosisHistory({
    required String userId,
    required DiagnosisResult result,
    required String imageUrl,
  }) async {
    try {
      final history = DiagnosisHistory(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        imageUrl: imageUrl,
        disease: result.diseaseKo.isNotEmpty ? result.diseaseKo : result.disease,
        confidence: result.confidence,
        recommendations: result.recommendations,
        severity: result.isHealthy ? 'healthy' : 'unhealthy',
        timestamp: DateTime.now(),
      );

      await _firestoreService.saveDiagnosisHistory(history);
    } catch (e) {
      // Firestore 저장 실패는 사용자에게 알리지 않고 로그만 출력
      debugPrint('Failed to save diagnosis history: $e');
    }
  }

  void reset() {
    isLoading.value = false;
    currentResult.value = null;
    selectedImage.value = null;
    uploadedImageUrl.value = '';
  }
}
