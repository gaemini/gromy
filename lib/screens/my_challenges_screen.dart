import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class MyChallengesScreen extends StatelessWidget {
  const MyChallengesScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 진행 중인 챌린지
          Text(
            '진행 중인 챌린지',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          
          _buildChallengeCard(
            title: '30-Day Watering Challenge',
            progress: 0.6,
            daysRemaining: 12,
            participants: 14523,
            isActive: true,
          ),
          
          const SizedBox(height: 30),
          
          // 추천 챌린지
          Text(
            '추천 챌린지',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          
          _buildChallengeCard(
            title: 'First Bloom Challenge',
            progress: 0.0,
            daysRemaining: 0,
            participants: 8234,
            isActive: false,
          ),
          
          _buildChallengeCard(
            title: 'Green Thumb Month',
            progress: 0.0,
            daysRemaining: 0,
            participants: 5678,
            isActive: false,
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeCard({
    required String title,
    required double progress,
    required int daysRemaining,
    required int participants,
    required bool isActive,
  }) {
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
                child: const Icon(
                  Icons.emoji_events,
                  color: Color(0xFF2D7A4F),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
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
          
          const SizedBox(height: 16),
          
          // 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (isActive) {
                  Get.snackbar(
                    '챌린지',
                    '챌린지 상세 화면 준비중입니다',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                } else {
                  Get.snackbar(
                    '챌린지 참여',
                    '$title에 참여하시겠습니까?',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                }
              },
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
}

