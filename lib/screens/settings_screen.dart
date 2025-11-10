import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _waterReminders = true;
  bool _communityUpdates = true;
  bool _diagnosisAlerts = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 16.0,
          bottom: 100.0, // 하단 여백 추가
        ),
        children: [
          // 알림 섹션
          _buildSectionTitle('알림 설정'),
          const SizedBox(height: 12),
          
          _buildSwitchTile(
            title: '알림 활성화',
            subtitle: '모든 알림을 받습니다',
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),
          
          _buildSwitchTile(
            title: '물주기 알림',
            subtitle: '식물에 물줄 시간을 알려드립니다',
            value: _waterReminders,
            onChanged: (value) {
              setState(() {
                _waterReminders = value;
              });
            },
          ),
          
          _buildSwitchTile(
            title: '커뮤니티 업데이트',
            subtitle: '좋아요, 댓글 알림을 받습니다',
            value: _communityUpdates,
            onChanged: (value) {
              setState(() {
                _communityUpdates = value;
              });
            },
          ),
          
          _buildSwitchTile(
            title: '진단 알림',
            subtitle: '진단 결과를 알려드립니다',
            value: _diagnosisAlerts,
            onChanged: (value) {
              setState(() {
                _diagnosisAlerts = value;
              });
            },
          ),
          
          const SizedBox(height: 30),
          
          // 계정 섹션
          _buildSectionTitle('계정'),
          const SizedBox(height: 12),
          
          _buildMenuTile(
            icon: Icons.person,
            title: '계정 정보',
            onTap: () {
              Get.snackbar(
                '계정 정보',
                '계정 정보 화면 준비중입니다',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),
          
          _buildMenuTile(
            icon: Icons.lock,
            title: '비밀번호 변경',
            onTap: () {
              Get.snackbar(
                '비밀번호 변경',
                '비밀번호 변경 기능 준비중입니다',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),
          
          _buildMenuTile(
            icon: Icons.privacy_tip,
            title: '개인정보 처리방침',
            onTap: () {
              Get.snackbar(
                '개인정보 처리방침',
                '개인정보 처리방침 화면 준비중입니다',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),
          
          const SizedBox(height: 30),
          
          // 앱 정보 섹션
          _buildSectionTitle('앱 정보'),
          const SizedBox(height: 12),
          
          _buildMenuTile(
            icon: Icons.info,
            title: '버전 정보',
            trailing: Text(
              'v1.0.0',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            onTap: () {},
          ),
          
          _buildMenuTile(
            icon: Icons.help,
            title: '도움말',
            onTap: () {
              Get.snackbar(
                '도움말',
                '도움말 화면 준비중입니다',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),
          
          _buildMenuTile(
            icon: Icons.description,
            title: '이용약관',
            onTap: () {
              Get.snackbar(
                '이용약관',
                '이용약관 화면 준비중입니다',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF2D7A4F),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    Widget? trailing,
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
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            trailing ??
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

