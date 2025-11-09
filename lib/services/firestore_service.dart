import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/plant.dart';
import '../models/post.dart';
import '../models/diagnosis_history.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 식물 추가
  Future<void> addPlant(Plant plant) async {
    try {
      await _firestore.collection('plants').doc(plant.id).set(plant.toJson());
    } catch (e) {
      print('Error adding plant: $e');
      rethrow;
    }
  }

  // 사용자의 식물 목록 조회
  Future<List<Plant>> getMyPlants(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('plants')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Plant.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting plants: $e');
      return [];
    }
  }

  // 식물 실시간 스트림
  Stream<List<Plant>> getPlantsStream(String userId) {
    return _firestore
        .collection('plants')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Plant.fromJson(doc.data())).toList());
  }

  // 게시물 추가
  Future<void> addPost(Post post) async {
    try {
      await _firestore.collection('posts').doc(post.id).set(post.toJson());
    } catch (e) {
      print('Error adding post: $e');
      rethrow;
    }
  }

  // 게시물 목록 조회 (최신순)
  Future<List<Post>> getPosts({int limit = 20}) async {
    try {
      final querySnapshot = await _firestore
          .collection('posts')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => Post.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting posts: $e');
      return [];
    }
  }

  // 게시물 실시간 스트림
  Stream<List<Post>> getPostsStream({int limit = 20}) {
    return _firestore
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Post.fromJson(doc.data())).toList());
  }

  // 게시물 업데이트 (좋아요 등)
  Future<void> updatePost(String postId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('posts').doc(postId).update(data);
    } catch (e) {
      print('Error updating post: $e');
      rethrow;
    }
  }

  // 좋아요 토글
  Future<void> toggleLike(String postId, int currentLikes) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'likes': currentLikes + 1,
      });
    } catch (e) {
      print('Error toggling like: $e');
      rethrow;
    }
  }

  // 진단 히스토리 저장
  Future<void> saveDiagnosisHistory(DiagnosisHistory history) async {
    try {
      await _firestore
          .collection('diagnosis_history')
          .doc(history.id)
          .set(history.toJson());
      print('✅ Diagnosis history saved');
    } catch (e) {
      print('❌ Error saving diagnosis history: $e');
      rethrow;
    }
  }

  // 사용자의 진단 히스토리 조회
  Future<List<DiagnosisHistory>> getDiagnosisHistory(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('diagnosis_history')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      return querySnapshot.docs
          .map((doc) => DiagnosisHistory.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('❌ Error getting diagnosis history: $e');
      return [];
    }
  }

  // 진단 히스토리 실시간 스트림
  Stream<List<DiagnosisHistory>> getDiagnosisHistoryStream(String userId) {
    return _firestore
        .collection('diagnosis_history')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DiagnosisHistory.fromJson(doc.data()))
            .toList());
  }
}

