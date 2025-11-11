import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // 이미지 업로드
  Future<String> uploadImage(File image, String path) async {
    try {
      // 파일명 생성 (타임스탬프 사용)
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = _storage.ref().child('$path/$fileName');

      // 이미지 업로드
      final UploadTask uploadTask = ref.putFile(image);
      final TaskSnapshot snapshot = await uploadTask;

      // 다운로드 URL 반환
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      rethrow;
    }
  }

  // 여러 이미지 업로드
  Future<List<String>> uploadImages(List<File> images, String path) async {
    try {
      List<String> urls = [];
      for (File image in images) {
        final String url = await uploadImage(image, path);
        urls.add(url);
      }
      return urls;
    } catch (e) {
      print('Error uploading images: $e');
      rethrow;
    }
  }

  // 이미지 삭제
  Future<void> deleteImage(String imageUrl) async {
    try {
      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      print('Error deleting image: $e');
      rethrow;
    }
  }

  // 식물 이미지 업로드
  Future<String> uploadPlantImage(File image) async {
    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = _storage.ref().child('plants/$fileName');

      final UploadTask uploadTask = ref.putFile(image);
      final TaskSnapshot snapshot = await uploadTask;

      final String downloadUrl = await snapshot.ref.getDownloadURL();
      print('✅ Plant image uploaded: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading plant image: $e');
      rethrow;
    }
  }

  // 식물 메모 이미지 업로드
  Future<String> uploadPlantNoteImage(File image, String plantId) async {
    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = _storage.ref().child('plant_notes/$plantId/$fileName');

      final UploadTask uploadTask = ref.putFile(image);
      final TaskSnapshot snapshot = await uploadTask;

      final String downloadUrl = await snapshot.ref.getDownloadURL();
      print('✅ Plant note image uploaded: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading plant note image: $e');
      rethrow;
    }
  }
}

