import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              
              // 앱 로고/아이콘
              Icon(
                Icons.local_florist,
                size: 100,
                color: const Color(0xFF2D7A4F),
              ),
              
              const SizedBox(height: 30),
              
              // 앱 이름
              Text(
                'Gromy',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D7A4F),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // 앱 설명
              Text(
                '식물과 함께 성장하는\nAI 기반 식물 관리 플랫폼',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              
              const Spacer(),
              
              // Google Sign In 버튼
              Obx(() => authController.isLoading.value
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: () async {
                        await authController.signInWithGoogle();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                        elevation: 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.network(
                            'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                            height: 24,
                            width: 24,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.login, size: 24);
                            },
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Google로 계속하기',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )),
              
              const SizedBox(height: 40),
              
              // 안내 문구
              Text(
                '로그인하시면 이용약관 및 개인정보 처리방침에\n동의하는 것으로 간주됩니다.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[500],
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

