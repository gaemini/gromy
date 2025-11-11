import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/plant.dart';
import '../models/post.dart';
import '../models/diagnosis_history.dart';
import '../models/user_model.dart';
import '../models/comment.dart';
import '../models/watering_record.dart';
import '../models/plant_note.dart';
import '../models/plant_history.dart';
import '../models/challenge.dart';
import '../models/challenge_participation.dart';
import '../models/notification.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== 사용자 관련 ====================
  
  // 사용자 정보 저장/업데이트
  Future<void> saveUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set(
        user.toJson(),
        SetOptions(merge: true), // 기존 데이터와 병합
      );
      print('✅ User saved: ${user.displayName}');
      
      // 프로필 이미지가 변경된 경우 모든 게시글 업데이트
      await updateUserPostsProfile(user.uid, user.displayName, user.profileImageUrl);
    } catch (e) {
      print('❌ Error saving user: $e');
      rethrow;
    }
  }
  
  // 사용자의 모든 게시글 프로필 정보 업데이트
  Future<void> updateUserPostsProfile(String userId, String displayName, String profileImageUrl) async {
    try {
      // 해당 사용자의 모든 게시글 가져오기
      final querySnapshot = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .get();
      
      if (querySnapshot.docs.isEmpty) return;
      
      // Batch 작업으로 모든 게시글 업데이트
      final batch = _firestore.batch();
      
      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {
          'userName': displayName,
          'userProfileImage': profileImageUrl,
        });
      }
      
      await batch.commit();
      print('✅ Updated ${querySnapshot.docs.length} posts with new profile info');
    } catch (e) {
      print('❌ Error updating posts profile: $e');
    }
  }

  // 사용자 정보 가져오기
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('❌ Error getting user: $e');
      return null;
    }
  }

  // 사용자 실시간 스트림
  Stream<UserModel?> getUserStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    });
  }

  // ==================== 식물 관련 ====================

  // 식물 추가
  Future<void> addPlant(Plant plant) async {
    try {
      await _firestore.collection('plants').doc(plant.id).set(plant.toJson());
    } catch (e) {
      print('Error adding plant: $e');
      rethrow;
    }
  }

  // 식물 삭제
  Future<void> deletePlant(String plantId) async {
    try {
      await _firestore.collection('plants').doc(plantId).delete();
      print('✅ Plant deleted from Firestore');
    } catch (e) {
      print('❌ Error deleting plant: $e');
      rethrow;
    }
  }

  // 식물 메모 추가 (타임라인)
  Future<void> addPlantNote(PlantNote note) async {
    try {
      await _firestore
          .collection('plants')
          .doc(note.plantId)
          .collection('notes')
          .doc(note.id)
          .set(note.toJson());
      print('✅ Plant note added');
    } catch (e) {
      print('❌ Error adding plant note: $e');
      rethrow;
    }
  }

  // 식물 메모 목록 가져오기 (최신순)
  Future<List<PlantNote>> getPlantNotes(String plantId) async {
    try {
      final querySnapshot = await _firestore
          .collection('plants')
          .doc(plantId)
          .collection('notes')
          .get();

      final notes = querySnapshot.docs
          .map((doc) => PlantNote.fromJson(doc.data()))
          .toList();
      notes.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // 최신순
      return notes;
    } catch (e) {
      print('❌ Error getting plant notes: $e');
      return [];
    }
  }

  // 식물 메모 실시간 스트림
  Stream<List<PlantNote>> getPlantNotesStream(String plantId) {
    return _firestore
        .collection('plants')
        .doc(plantId)
        .collection('notes')
        .snapshots()
        .map((snapshot) {
      final notes = snapshot.docs
          .map((doc) => PlantNote.fromJson(doc.data()))
          .toList();
      notes.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return notes;
    });
  }

  // 메모 삭제
  Future<void> deletePlantNote(String plantId, String noteId) async {
    try {
      await _firestore
          .collection('plants')
          .doc(plantId)
          .collection('notes')
          .doc(noteId)
          .delete();
      print('✅ Plant note deleted');
    } catch (e) {
      print('❌ Error deleting plant note: $e');
      rethrow;
    }
  }

  // 물주기 기록 추가
  Future<void> addWateringRecord(String plantId, WateringRecord record) async {
    try {
      final batch = _firestore.batch();
      
      // 1. watering_records 서브컬렉션에 추가
      final recordRef = _firestore
          .collection('plants')
          .doc(plantId)
          .collection('watering_records')
          .doc(record.id);
      batch.set(recordRef, record.toJson());
      
      // 2. plant의 lastWatered 업데이트
      final plantRef = _firestore.collection('plants').doc(plantId);
      batch.update(plantRef, {
        'lastWatered': record.timestamp.toIso8601String(),
      });
      
      await batch.commit();
      print('✅ Watering record added');
    } catch (e) {
      print('❌ Error adding watering record: $e');
      rethrow;
    }
  }

  // 일주일 물주기 기록 가져오기 (월요일 기준)
  Future<List<WateringRecord>> getWeeklyWateringRecords(String plantId) async {
    try {
      final startOfWeek = _getStartOfWeek(DateTime.now());
      final endOfWeek = startOfWeek.add(const Duration(days: 7));
      
      final querySnapshot = await _firestore
          .collection('plants')
          .doc(plantId)
          .collection('watering_records')
          .get();
      
      final records = querySnapshot.docs
          .map((doc) => WateringRecord.fromJson(doc.data()))
          .where((record) =>
              record.timestamp.isAfter(startOfWeek) &&
              record.timestamp.isBefore(endOfWeek))
          .toList();
      
      return records;
    } catch (e) {
      print('❌ Error getting watering records: $e');
      return [];
    }
  }

  // 월요일 기준 주의 시작일 계산
  DateTime _getStartOfWeek(DateTime date) {
    final weekday = date.weekday; // 1=월요일, 7=일요일
    final monday = date.subtract(Duration(days: weekday - 1));
    return DateTime(monday.year, monday.month, monday.day);
  }

  // ==================== PlantHistory 관련 ====================

  // 식물 활동 기록 추가
  Future<void> addPlantHistory(PlantHistory history) async {
    try {
      await _firestore
          .collection('plants')
          .doc(history.plantId)
          .collection('histories')
          .doc(history.id)
          .set(history.toJson());
      print('✅ Plant history added: ${history.type}');
    } catch (e) {
      print('❌ Error adding plant history: $e');
      rethrow;
    }
  }

  // 식물 활동 기록 실시간 스트림
  Stream<List<PlantHistory>> getPlantHistoriesStream(String plantId) {
    return _firestore
        .collection('plants')
        .doc(plantId)
        .collection('histories')
        .snapshots()
        .map((snapshot) {
      final histories = snapshot.docs
          .map((doc) => PlantHistory.fromJson(doc.data()))
          .toList();
      histories.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return histories;
    });
  }

  // 최근 활동 기록 가져오기 (제한된 개수)
  Future<List<PlantHistory>> getRecentPlantHistories(
      String plantId, int limit) async {
    try {
      final querySnapshot = await _firestore
          .collection('plants')
          .doc(plantId)
          .collection('histories')
          .get();

      final histories = querySnapshot.docs
          .map((doc) => PlantHistory.fromJson(doc.data()))
          .toList();
      histories.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return histories.take(limit).toList();
    } catch (e) {
      print('❌ Error getting recent histories: $e');
      return [];
    }
  }

  // 주간 활동 기록 가져오기
  Future<List<PlantHistory>> getWeeklyPlantHistories(String plantId) async {
    try {
      final startOfWeek = _getStartOfWeek(DateTime.now());
      final endOfWeek = startOfWeek.add(const Duration(days: 7));

      final querySnapshot = await _firestore
          .collection('plants')
          .doc(plantId)
          .collection('histories')
          .get();

      final histories = querySnapshot.docs
          .map((doc) => PlantHistory.fromJson(doc.data()))
          .where((history) =>
              history.timestamp.isAfter(startOfWeek) &&
              history.timestamp.isBefore(endOfWeek))
          .toList();

      return histories;
    } catch (e) {
      print('❌ Error getting weekly histories: $e');
      return [];
    }
  }

  // 활동 기록 삭제
  Future<void> deletePlantHistory(String plantId, String historyId) async {
    try {
      await _firestore
          .collection('plants')
          .doc(plantId)
          .collection('histories')
          .doc(historyId)
          .delete();
      print('✅ Plant history deleted');
    } catch (e) {
      print('❌ Error deleting plant history: $e');
      rethrow;
    }
  }

  // 사용자의 식물 목록 조회
  Future<List<Plant>> getMyPlants(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('plants')
          .where('userId', isEqualTo: userId)
          .get();

      // 클라이언트 측에서 정렬 (인덱스 불필요)
      final plants = querySnapshot.docs
          .map((doc) => Plant.fromJson(doc.data()))
          .toList();
      plants.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return plants;
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
        .snapshots()
        .map((snapshot) {
      // 클라이언트 측에서 정렬 (인덱스 불필요)
      final plants = snapshot.docs
          .map((doc) => Plant.fromJson(doc.data()))
          .toList();
      plants.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return plants;
    });
  }

  // 특정 식물 실시간 스트림
  Stream<Plant?> getPlantStream(String plantId) {
    return _firestore
        .collection('plants')
        .doc(plantId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return Plant.fromJson(doc.data()!);
      }
      return null;
    });
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
          .limit(limit)
          .get();

      // 클라이언트 측에서 정렬
      final posts = querySnapshot.docs
          .map((doc) => Post.fromJson(doc.data()))
          .toList();
      posts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return posts;
    } catch (e) {
      print('Error getting posts: $e');
      return [];
    }
  }

  // 게시물 실시간 스트림
  Stream<List<Post>> getPostsStream({int limit = 20}) {
    return _firestore
        .collection('posts')
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      // 클라이언트 측에서 정렬
      final posts = snapshot.docs
          .map((doc) => Post.fromJson(doc.data()))
          .toList();
      posts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return posts;
    });
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

  // 게시물 삭제
  Future<void> deletePost(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).delete();
      print('✅ Post deleted from Firestore');
    } catch (e) {
      print('❌ Error deleting post: $e');
      rethrow;
    }
  }

  // 좋아요 확인
  Future<bool> hasUserLikedPost(String postId, String userId) async {
    try {
      final doc = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .doc(userId)
          .get();
      return doc.exists;
    } catch (e) {
      print('❌ Error checking like: $e');
      return false;
    }
  }

  // 좋아요 추가
  Future<void> likePost(String postId, String userId) async {
    try {
      final batch = _firestore.batch();
      
      // 1. likes 서브컬렉션에 추가
      final likeRef = _firestore
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .doc(userId);
      batch.set(likeRef, {
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      // 2. 게시물의 likes 카운트 증가
      final postRef = _firestore.collection('posts').doc(postId);
      batch.update(postRef, {
        'likes': FieldValue.increment(1),
      });
      
      await batch.commit();
      print('✅ Post liked');
    } catch (e) {
      print('❌ Error liking post: $e');
      rethrow;
    }
  }

  // 좋아요 취소
  Future<void> unlikePost(String postId, String userId) async {
    try {
      final batch = _firestore.batch();
      
      // 1. likes 서브컬렉션에서 삭제
      final likeRef = _firestore
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .doc(userId);
      batch.delete(likeRef);
      
      // 2. 게시물의 likes 카운트 감소
      final postRef = _firestore.collection('posts').doc(postId);
      batch.update(postRef, {
        'likes': FieldValue.increment(-1),
      });
      
      await batch.commit();
      print('✅ Post unliked');
    } catch (e) {
      print('❌ Error unliking post: $e');
      rethrow;
    }
  }

  // 좋아요 토글
  Future<void> toggleLike(String postId, String userId) async {
    final hasLiked = await hasUserLikedPost(postId, userId);
    if (hasLiked) {
      await unlikePost(postId, userId);
    } else {
      await likePost(postId, userId);
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
          .limit(50)
          .get();

      // 클라이언트 측에서 정렬
      final history = querySnapshot.docs
          .map((doc) => DiagnosisHistory.fromJson(doc.data()))
          .toList();
      history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return history;
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
        .limit(50)
        .snapshots()
        .map((snapshot) {
      // 클라이언트 측에서 정렬
      final history = snapshot.docs
          .map((doc) => DiagnosisHistory.fromJson(doc.data()))
          .toList();
      history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return history;
    });
  }

  // ==================== 댓글 관련 ====================

  // 댓글 추가
  Future<void> addComment(Comment comment) async {
    try {
      final batch = _firestore.batch();
      
      // 1. comments 서브컬렉션에 추가
      final commentRef = _firestore
          .collection('posts')
          .doc(comment.postId)
          .collection('comments')
          .doc(comment.id);
      batch.set(commentRef, comment.toJson());
      
      // 2. 게시물의 comments 카운트 증가
      final postRef = _firestore.collection('posts').doc(comment.postId);
      batch.update(postRef, {
        'comments': FieldValue.increment(1),
      });
      
      await batch.commit();
      print('✅ Comment added');
    } catch (e) {
      print('❌ Error adding comment: $e');
      rethrow;
    }
  }

  // 댓글 삭제
  Future<void> deleteComment(String postId, String commentId) async {
    try {
      final batch = _firestore.batch();
      
      // 1. comments 서브컬렉션에서 삭제
      final commentRef = _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId);
      batch.delete(commentRef);
      
      // 2. 게시물의 comments 카운트 감소
      final postRef = _firestore.collection('posts').doc(postId);
      batch.update(postRef, {
        'comments': FieldValue.increment(-1),
      });
      
      await batch.commit();
      print('✅ Comment deleted');
    } catch (e) {
      print('❌ Error deleting comment: $e');
      rethrow;
    }
  }

  // 게시물의 댓글 목록 가져오기
  Future<List<Comment>> getComments(String postId) async {
    try {
      final querySnapshot = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .get();

      final comments = querySnapshot.docs
          .map((doc) => Comment.fromJson(doc.data()))
          .toList();
      comments.sort((a, b) => a.timestamp.compareTo(b.timestamp)); // 시간순 정렬
      return comments;
    } catch (e) {
      print('❌ Error getting comments: $e');
      return [];
    }
  }

  // 댓글 실시간 스트림
  Stream<List<Comment>> getCommentsStream(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .snapshots()
        .map((snapshot) {
      final comments = snapshot.docs
          .map((doc) => Comment.fromJson(doc.data()))
          .toList();
      comments.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return comments;
    });
  }

  // ==================== 챌린지 관련 ====================

  // 챌린지 참여
  Future<void> joinChallenge(String userId, String challengeId) async {
    try {
      final participationId = '${userId}_$challengeId';
      final participation = ChallengeParticipation(
        id: participationId,
        userId: userId,
        challengeId: challengeId,
        startDate: DateTime.now(),
        completedDays: [],
        isActive: true,
        lastUpdated: DateTime.now(),
      );

      await _firestore
          .collection('challenge_participations')
          .doc(participationId)
          .set(participation.toJson());
      
      print('✅ Joined challenge: $challengeId');
    } catch (e) {
      print('❌ Error joining challenge: $e');
      rethrow;
    }
  }

  // 챌린지 취소
  Future<void> leaveChallenge(String userId, String challengeId) async {
    try {
      final participationId = '${userId}_$challengeId';
      await _firestore
          .collection('challenge_participations')
          .doc(participationId)
          .update({
        'isActive': false,
        'lastUpdated': DateTime.now().toIso8601String(),
      });
      
      print('✅ Left challenge: $challengeId');
    } catch (e) {
      print('❌ Error leaving challenge: $e');
      rethrow;
    }
  }

  // 사용자의 참여 중인 챌린지 목록
  Future<List<ChallengeParticipation>> getUserChallenges(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('challenge_participations')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ChallengeParticipation.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('❌ Error getting user challenges: $e');
      return [];
    }
  }

  // 특정 챌린지 참여 정보
  Future<ChallengeParticipation?> getChallengeParticipation(
      String userId, String challengeId) async {
    try {
      final participationId = '${userId}_$challengeId';
      final doc = await _firestore
          .collection('challenge_participations')
          .doc(participationId)
          .get();

      if (doc.exists && doc.data() != null) {
        return ChallengeParticipation.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('❌ Error getting challenge participation: $e');
      return null;
    }
  }

  // 챌린지 진행률 업데이트 (물주기 시 호출)
  Future<void> updateChallengeProgress(String userId) async {
    try {
      // 사용자의 활성 챌린지 목록 가져오기
      final challenges = await getUserChallenges(userId);
      
      if (challenges.isEmpty) return;
      
      final today = DateTime.now();
      final todayOnly = DateTime(today.year, today.month, today.day);
      
      for (final challenge in challenges) {
        // 오늘 이미 기록했으면 스킵
        if (challenge.hasWateredToday()) continue;
        
        // 새로운 완료 날짜 추가
        final updatedDays = List<DateTime>.from(challenge.completedDays)
          ..add(todayOnly);
        
        // Firestore 업데이트
        await _firestore
            .collection('challenge_participations')
            .doc(challenge.id)
            .update({
          'completedDays': updatedDays.map((d) => d.toIso8601String()).toList(),
          'lastUpdated': DateTime.now().toIso8601String(),
        });
        
        print('✅ Updated challenge progress: ${challenge.challengeId}');
      }
    } catch (e) {
      print('❌ Error updating challenge progress: $e');
    }
  }

  // 챌린지 참여자 수 조회
  Future<int> getChallengeParticipantsCount(String challengeId) async {
    try {
      final querySnapshot = await _firestore
          .collection('challenge_participations')
          .where('challengeId', isEqualTo: challengeId)
          .where('isActive', isEqualTo: true)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      print('❌ Error getting participants count: $e');
      return 0;
    }
  }

  // 사용자 챌린지 실시간 스트림
  Stream<List<ChallengeParticipation>> getUserChallengesStream(String userId) {
    return _firestore
        .collection('challenge_participations')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChallengeParticipation.fromJson(doc.data()))
          .toList();
    });
  }

  // 모든 사용자 챌린지 참여 정보 스트림 (특정 챌린지)
  Stream<int> getChallengeParticipantsStream(String challengeId) {
    return _firestore
        .collection('challenge_participations')
        .where('challengeId', isEqualTo: challengeId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
  
  // ==================== 알림 관련 ====================
  
  // 알림 생성
  Future<void> createNotification(NotificationModel notification) async {
    try {
      await _firestore.collection('notifications').doc(notification.id).set(
        notification.toJson(),
      );
      print('✅ Notification created');
    } catch (e) {
      print('❌ Error creating notification: $e');
      rethrow;
    }
  }
  
  // 사용자의 알림 스트림
  Stream<List<NotificationModel>> getNotificationsStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromJson({
                  ...doc.data(),
                  'id': doc.id,
                }))
            .toList());
  }
  
  // 알림을 읽음으로 표시
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
      print('✅ Notification marked as read');
    } catch (e) {
      print('❌ Error marking notification as read: $e');
      rethrow;
    }
  }
  
  // 사용자의 모든 알림을 읽음으로 표시
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      
      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      
      await batch.commit();
      print('✅ All notifications marked as read');
    } catch (e) {
      print('❌ Error marking all notifications as read: $e');
      rethrow;
    }
  }
  
  // 알림 삭제
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
      print('✅ Notification deleted');
    } catch (e) {
      print('❌ Error deleting notification: $e');
      rethrow;
    }
  }
}

