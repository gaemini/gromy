import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../services/storage_service.dart';
import '../services/ai_service.dart';
import '../services/firestore_service.dart';
import '../models/diagnosis_history.dart';
import '../controllers/auth_controller.dart';

class DiagnosisController extends GetxController {
  final ImagePicker _picker = ImagePicker();
  final StorageService _storageService = StorageService();
  final AiService _aiService = AiService();
  final FirestoreService _firestoreService = FirestoreService();
  
  // 스캔 상태
  final RxBool isScanning = false.obs;
  final RxBool isUploading = false.obs;
  final Rxn<File> selectedImage = Rxn<File>();
  final RxString uploadedImageUrl = ''.obs;
  final RxString diagnosisResult = ''.obs;
  final RxList<String> recommendations = <String>[].obs;

  // 이미지 선택 (갤러리)
  Future<void> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        selectedImage.value = File(image.path);
        await _uploadAndAnalyze();
      }
    } catch (e) {
      print('❌ Error picking image: $e');
      Get.snackbar(
        '오류',
        '이미지를 선택할 수 없습니다',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // 이미지 선택 (카메라)
  Future<void> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        selectedImage.value = File(image.path);
        await _uploadAndAnalyze();
      }
    } catch (e) {
      print('❌ Error taking photo: $e');
      Get.snackbar(
        '오류',
        '사진을 촬영할 수 없습니다',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // 이미지 업로드 및 AI 분석
  Future<void> _uploadAndAnalyze() async {
    if (selectedImage.value == null) return;

    try {
      // 1단계: 스캔 시작
      isScanning.value = true;
      diagnosisResult.value = '';
      recommendations.clear();

      // 2단계: Firebase Storage에 이미지 업로드
      isUploading.value = true;
      print('📤 Uploading image to Firebase Storage...');
      
      final imageUrl = await _storageService.uploadImage(
        selectedImage.value!,
        'diagnoses',
      );
      
      uploadedImageUrl.value = imageUrl;
      isUploading.value = false;
      print('✅ Image uploaded: $imageUrl');

      // 3단계: AI 분석
      print('🤖 Starting AI analysis...');
      
      // AI 서버 연결 확인
      final isServerHealthy = await _aiService.checkHealth();
      
      DiagnosisResult? result;
      
      if (isServerHealthy) {
        // 실제 AI API 호출
        result = await _aiService.diagnosePlantWithFile(selectedImage.value!);
      }
      
      // AI 서버가 없거나 오류 발생 시 더미 데이터 사용
      if (result == null) {
        print('⚠️ Using dummy AI result');
        result = await _aiService.getDummyDiagnosis();
      }
      
      // 결과 저장
      diagnosisResult.value = result.disease;
      recommendations.value = result.recommendations;

      print('✅ Analysis complete: ${diagnosisResult.value} (${result.confidencePercent})');
      
      // 4단계: Firestore에 진단 히스토리 저장
      await _saveDiagnosisHistory(result);
      
      Get.snackbar(
        '진단 완료',
        '${diagnosisResult.value} (신뢰도: ${result.confidencePercent})',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('❌ Error in upload and analyze: $e');
      Get.snackbar(
        '오류',
        '진단 중 오류가 발생했습니다: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isScanning.value = false;
      isUploading.value = false;
    }
  }

  // 진단 히스토리 저장
  Future<void> _saveDiagnosisHistory(DiagnosisResult result) async {
    try {
      final authController = Get.find<AuthController>();
      final userId = authController.currentUserId;
      
      if (userId == null) {
        print('⚠️ No user ID, skipping history save');
        return;
      }

      final history = DiagnosisHistory(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        imageUrl: uploadedImageUrl.value,
        disease: result.disease,
        confidence: result.confidence,
        recommendations: result.recommendations,
        severity: result.severity,
        timestamp: DateTime.now(),
      );

      await _firestoreService.saveDiagnosisHistory(history);
      print('✅ Diagnosis history saved to Firestore');
    } catch (e) {
      print('❌ Error saving diagnosis history: $e');
      // 저장 실패해도 진단은 계속 진행
    }
  }

  // 진단 초기화
  void resetDiagnosis() {
    selectedImage.value = null;
    uploadedImageUrl.value = '';
    diagnosisResult.value = '';
    recommendations.clear();
    isScanning.value = false;
    isUploading.value = false;
  }
}

