import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/challenge.dart';
import '../models/challenge_participation.dart';
import '../services/firestore_service.dart';

class ChallengeController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 하드코딩된 챌린지 목록
  final List<Challenge> allChallenges = Challenge.defaultChallenges;
  
  // 사용자의 참여 중인 챌린지
  final RxList<ChallengeParticipation> userParticipations = <ChallengeParticipation>[].obs;
  
  // 각 챌린지별 참여자 수
  final RxMap<String, int> participantsCounts = <String, int>{}.obs;
  
  // 로딩 상태
  final RxBool isLoading = false.obs;
  final RxBool isJoiningChallenge = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserChallenges();
    loadParticipantsCounts();
  }

  // 현재 사용자 ID
  String? get currentUserId => _auth.currentUser?.uid;

  // 사용자의 챌린지 목록 로드
  Future<void> loadUserChallenges() async {
    if (currentUserId == null) return;
    
    try {
      isLoading.value = true;
      
      // 실시간 스트림 구독
      _firestoreService.getUserChallengesStream(currentUserId!).listen((participations) {
        userParticipations.value = participations;
      });
    } catch (e) {
      print('❌ Error loading user challenges: $e');
      Get.snackbar(
        '오류',
        '챌린지 목록을 불러오는데 실패했습니다',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // 참여자 수 로드
  Future<void> loadParticipantsCounts() async {
    try {
      for (final challenge in allChallenges) {
        // 실시간 스트림 구독
        _firestoreService.getChallengeParticipantsStream(challenge.id).listen((count) {
          participantsCounts[challenge.id] = count;
        });
      }
    } catch (e) {
      print('❌ Error loading participants counts: $e');
    }
  }

  // 챌린지 참여 여부 확인
  bool isParticipating(String challengeId) {
    return userParticipations.any((p) => p.challengeId == challengeId && p.isActive);
  }

  // 특정 챌린지의 참여 정보 가져오기
  ChallengeParticipation? getParticipation(String challengeId) {
    try {
      return userParticipations.firstWhere(
        (p) => p.challengeId == challengeId && p.isActive,
      );
    } catch (e) {
      return null;
    }
  }

  // 챌린지 참여
  Future<void> joinChallenge(String challengeId) async {
    if (currentUserId == null) {
      Get.snackbar(
        '로그인 필요',
        '챌린지에 참여하려면 로그인이 필요합니다',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (isParticipating(challengeId)) {
      Get.snackbar(
        '이미 참여 중',
        '이미 참여 중인 챌린지입니다',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isJoiningChallenge.value = true;
      
      await _firestoreService.joinChallenge(currentUserId!, challengeId);
      
      // 챌린지 정보 가져오기
      final challenge = Challenge.findById(challengeId);
      if (challenge != null) {
        Get.snackbar(
          '챌린지 참여',
          '${challenge.title}에 참여했습니다!',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      }
      
      // 목록 새로고침
      await loadUserChallenges();
    } catch (e) {
      print('❌ Error joining challenge: $e');
      Get.snackbar(
        '오류',
        '챌린지 참여에 실패했습니다',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isJoiningChallenge.value = false;
    }
  }

  // 챌린지 취소
  Future<void> leaveChallenge(String challengeId) async {
    if (currentUserId == null) return;

    try {
      // 확인 다이얼로그
      final confirm = await Get.dialog<bool>(
        AlertDialog(
          title: Text('챌린지 취소'),
          content: Text('정말로 챌린지를 취소하시겠습니까?\n진행 상황이 초기화됩니다.'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text('아니오'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: Text('예', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      await _firestoreService.leaveChallenge(currentUserId!, challengeId);
      
      final challenge = Challenge.findById(challengeId);
      if (challenge != null) {
        Get.snackbar(
          '챌린지 취소',
          '${challenge.title}를 취소했습니다',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      
      // 목록 새로고침
      await loadUserChallenges();
    } catch (e) {
      print('❌ Error leaving challenge: $e');
      Get.snackbar(
        '오류',
        '챌린지 취소에 실패했습니다',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // 챌린지 진행률 업데이트 (물주기 시 호출)
  Future<void> updateProgress() async {
    if (currentUserId == null) return;
    
    try {
      await _firestoreService.updateChallengeProgress(currentUserId!);
      
      // 목록 새로고침
      await loadUserChallenges();
    } catch (e) {
      print('❌ Error updating progress: $e');
    }
  }

  // 챌린지별 진행 상황 가져오기
  Map<String, dynamic> getChallengeStatus(String challengeId) {
    final participation = getParticipation(challengeId);
    final challenge = Challenge.findById(challengeId);
    
    if (participation == null || challenge == null) {
      return {
        'isActive': false,
        'progress': 0.0,
        'daysRemaining': 0,
        'streakDays': 0,
        'completedDays': 0,
      };
    }
    
    return {
      'isActive': true,
      'progress': participation.getProgress(challenge.requiredWatering),
      'daysRemaining': participation.getDaysRemaining(challenge.targetDays),
      'streakDays': participation.getStreakDays(),
      'completedDays': participation.completedDays.length,
    };
  }

  // 챌린지 완료 확인
  bool isChallengeCompleted(String challengeId) {
    final status = getChallengeStatus(challengeId);
    return status['progress'] >= 1.0;
  }

  // 오늘 물을 줬는지 확인
  bool hasWateredToday(String challengeId) {
    final participation = getParticipation(challengeId);
    return participation?.hasWateredToday() ?? false;
  }
}
