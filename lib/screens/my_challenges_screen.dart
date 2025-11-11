import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/challenge_controller.dart';
import '../models/challenge.dart';
import '../models/challenge_participation.dart';

class MyChallengesScreen extends StatelessWidget {
  const MyChallengesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ChallengeController 초기화
    final challengeController = Get.put(ChallengeController());
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Challenges',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: Obx(() {
        if (challengeController.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF2D7A4F),
            ),
          );
        }

        // 참여 중인 챌린지와 추천 챌린지 분류
        final activeChallenges = <Challenge>[];
        final recommendedChallenges = <Challenge>[];

        for (final challenge in challengeController.allChallenges) {
          if (challengeController.isParticipating(challenge.id)) {
            activeChallenges.add(challenge);
          } else {
            recommendedChallenges.add(challenge);
          }
        }

        return RefreshIndicator(
          onRefresh: () async {
            await challengeController.loadUserChallenges();
            await challengeController.loadParticipantsCounts();
          },
          color: const Color(0xFF2D7A4F),
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // 진행 중인 챌린지
              if (activeChallenges.isNotEmpty) ...[
                Text(
                  '진행 중인 챌린지',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                ...activeChallenges.map((challenge) {
                  final status = challengeController.getChallengeStatus(challenge.id);
                  final participation = challengeController.getParticipation(challenge.id);
                  
                  return _buildChallengeCard(
                    challenge: challenge,
                    progress: status['progress'] ?? 0.0,
                    daysRemaining: status['daysRemaining'] ?? 0,
                    participants: challengeController.participantsCounts[challenge.id] ?? 0,
                    isActive: true,
                    completedDays: participation?.completedDays.length ?? 0,
                    requiredDays: challenge.requiredWatering,
                    onButtonPressed: () {
                      if (status['progress'] >= 1.0) {
                        Get.snackbar(
                          '챌린지 완료!',
                          '${challenge.title}를 완료했습니다! 🎉',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: const Color(0xFF2D7A4F),
                          colorText: Colors.white,
                        );
                      } else {
                        Get.dialog(
                          _buildChallengeDetailDialog(
                            challenge: challenge,
                            status: status,
                            participation: participation,
                            onLeave: () {
                              Get.back();
                              challengeController.leaveChallenge(challenge.id);
                            },
                          ),
                        );
                      }
                    },
                  );
                }).toList(),
                const SizedBox(height: 30),
              ],

              // 추천 챌린지
              if (recommendedChallenges.isNotEmpty) ...[
                Text(
                  '추천 챌린지',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                ...recommendedChallenges.map((challenge) {
                  return _buildChallengeCard(
                    challenge: challenge,
                    progress: 0.0,
                    daysRemaining: challenge.targetDays,
                    participants: challengeController.participantsCounts[challenge.id] ?? 0,
                    isActive: false,
                    completedDays: 0,
                    requiredDays: challenge.requiredWatering,
                    onButtonPressed: () {
                      challengeController.joinChallenge(challenge.id);
                    },
                  );
                }).toList(),
              ],

              // 모든 챌린지에 참여 중인 경우
              if (activeChallenges.length == challengeController.allChallenges.length) ...[
                const SizedBox(height: 50),
                Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.emoji_events,
                        size: 64,
                        color: Color(0xFF2D7A4F),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '모든 챌린지에 참여 중입니다!',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      }),
    );
  }

  Widget _buildChallengeCard({
    required Challenge challenge,
    required double progress,
    required int daysRemaining,
    required int participants,
    required bool isActive,
    required int completedDays,
    required int requiredDays,
    required VoidCallback onButtonPressed,
  }) {
    // 아이콘 매핑
    IconData getIcon(String iconName) {
      switch (iconName) {
        case 'water_drop':
          return Icons.water_drop;
        case 'local_florist':
          return Icons.local_florist;
        case 'eco':
          return Icons.eco;
        default:
          return Icons.emoji_events;
      }
    }

    // 난이도 색상
    Color getDifficultyColor(String difficulty) {
      switch (difficulty) {
        case 'easy':
          return Colors.green;
        case 'medium':
          return Colors.orange;
        case 'hard':
          return Colors.red;
        default:
          return Colors.grey;
      }
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? const Color(0xFF2D7A4F) : Colors.grey[300]!,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 타이틀과 아이콘
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  getIcon(challenge.icon),
                  color: const Color(0xFF2D7A4F),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.title,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: getDifficultyColor(challenge.difficulty).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            challenge.difficulty.toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: getDifficultyColor(challenge.difficulty),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 참여자 수
          Row(
            children: [
              Icon(
                Icons.people,
                size: 18,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 6),
              Text(
                '${_formatNumber(participants)} participants',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          
          if (isActive) ...[
            const SizedBox(height: 16),
            
            // 진행 바
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '진행률',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D7A4F),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF2D7A4F),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$completedDays/$requiredDays 완료',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2D7A4F),
                      ),
                    ),
                    Text(
                      '$daysRemaining일 남음',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 16),
          
          // 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onButtonPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: isActive
                    ? const Color(0xFF2D7A4F)
                    : Colors.white,
                foregroundColor: isActive ? Colors.white : const Color(0xFF2D7A4F),
                side: isActive
                    ? null
                    : const BorderSide(color: Color(0xFF2D7A4F), width: 2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isActive ? '챌린지 보기' : '참여하기',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }

  // 챌린지 상세 다이얼로그
  Widget _buildChallengeDetailDialog({
    required Challenge challenge,
    required Map<String, dynamic> status,
    ChallengeParticipation? participation,
    required VoidCallback onLeave,
  }) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 아이콘
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconData(challenge.icon),
                color: const Color(0xFF2D7A4F),
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            
            // 제목
            Text(
              challenge.title,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            // 설명
            Text(
              challenge.description,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // 진행 상황
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        '진행률',
                        '${(status['progress'] * 100).toInt()}%',
                        Icons.trending_up,
                      ),
                      _buildStatItem(
                        '연속 일수',
                        '${status['streakDays']}일',
                        Icons.local_fire_department,
                      ),
                      _buildStatItem(
                        '남은 기간',
                        '${status['daysRemaining']}일',
                        Icons.calendar_today,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // 버튼들
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: onLeave,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      '챌린지 포기',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D7A4F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      '확인',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 통계 아이템
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFF2D7A4F),
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // 아이콘 데이터 가져오기
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'water_drop':
        return Icons.water_drop;
      case 'local_florist':
        return Icons.local_florist;
      case 'eco':
        return Icons.eco;
      default:
        return Icons.emoji_events;
    }
  }
}

