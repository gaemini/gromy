import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/profile_controller.dart';
import '../controllers/auth_controller.dart';
import 'edit_profile_screen.dart';
import 'my_plants_screen.dart';
import 'diagnosis_history_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ProfileController controller = Get.put(ProfileController());

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Get.snackbar(
                'Settings',
                'Settings coming soon!',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),
        ],
      ),
      body: Obx(() {
        final user = controller.currentUser.value;
        
        if (user == null) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              
              // 프로필 이미지
              CircleAvatar(
                radius: 60,
                backgroundImage: NetworkImage(user.profileImageUrl),
                backgroundColor: Colors.grey[300],
              ),
              
              const SizedBox(height: 20),
              
              // 사용자 이름
              Text(
                user.displayName,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // 이메일
              Text(
                user.email,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // 통계 섹션
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem('12', 'Plants'),
                  Container(
                    height: 50,
                    width: 1,
                    color: Colors.grey[300],
                  ),
                  _buildStatItem('48', 'Posts'),
                  Container(
                    height: 50,
                    width: 1,
                    color: Colors.grey[300],
                  ),
                  _buildStatItem('234', 'Followers'),
                ],
              ),
              
              const SizedBox(height: 30),
              
              // Edit Profile 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Get.to(
                      () => const EditProfileScreen(),
                      transition: Transition.rightToLeft,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D7A4F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Edit Profile',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              
              // 메뉴 항목들
              _buildMenuItem(
                icon: Icons.local_florist,
                title: 'My Plants',
                onTap: () {
                  Get.to(
                    () => const MyPlantsScreen(),
                    transition: Transition.rightToLeft,
                  );
                },
              ),
              
              _buildMenuItem(
                icon: Icons.bookmark_border,
                title: 'Saved Posts',
                onTap: () {
                  Get.snackbar(
                    '준비 중',
                    'Saved Posts 기능 준비중입니다',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),
              
              _buildMenuItem(
                icon: Icons.emoji_events_outlined,
                title: 'My Challenges',
                onTap: () {
                  Get.snackbar(
                    '준비 중',
                    'My Challenges 기능 준비중입니다',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),
              
              _buildMenuItem(
                icon: Icons.history,
                title: 'Diagnosis History',
                onTap: () {
                  Get.to(
                    () => const DiagnosisHistoryScreen(),
                    transition: Transition.rightToLeft,
                  );
                },
              ),
              
              const SizedBox(height: 20),
              
              // Logout 버튼
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Get.defaultDialog(
                      title: '로그아웃',
                      middleText: '정말 로그아웃 하시겠습니까?',
                      textConfirm: '확인',
                      textCancel: '취소',
                      confirmTextColor: Colors.white,
                      onConfirm: () async {
                        final authController = Get.find<AuthController>();
                        await authController.signOut();
                        Get.back();
                        Get.snackbar(
                          '로그아웃',
                          '새로운 익명 계정으로 자동 로그인되었습니다',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFF2D7A4F),
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }
}

