import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/diagnosis_controller.dart';

class DiagnosisScreen extends StatelessWidget {
  const DiagnosisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DiagnosisController controller = Get.put(DiagnosisController());

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Diagnosis',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            
            // 스캔 영역
            Container(
              height: 350,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 식물 이미지 (더미 이미지)
                  Obx(() => controller.selectedImage.value != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.file(
                            controller.selectedImage.value!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        )
                      : Image.network(
                          'https://images.unsplash.com/photo-1530836369250-ef72a3f5cda8?w=400',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.local_florist,
                                size: 80,
                                color: Colors.white30,
                              ),
                            );
                          },
                        ),
                  ),
                  
                  // 스캔 가이드라인
                  Container(
                    margin: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withOpacity(0.6),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  
                  // SCANNING 라인과 텍스트
                  Obx(() => controller.isScanning.value
                      ? Positioned.fill(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // 녹색 수평선
                              Container(
                                height: 2,
                                width: double.infinity,
                                margin: const EdgeInsets.symmetric(horizontal: 60),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      const Color(0xFF00FF00),
                                      Colors.transparent,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00FF00).withOpacity(0.5),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              // SCANNING 텍스트
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'SCANNING...',
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF00FF00),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink()),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // 진단 결과 (동적)
            Obx(() {
              if (controller.diagnosisResult.value.isEmpty) {
                return const SizedBox.shrink();
              }
              
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF9E6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3CD),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFFFA500),
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            controller.diagnosisResult.value,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF00C853),
                          size: 32,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              );
            }),
            
            // 추천 액션 버튼들 (동적)
            Obx(() {
              if (controller.recommendations.isEmpty) {
                return const SizedBox.shrink();
              }
              
              return Column(
                children: controller.recommendations.map((recommendation) {
                  final index = controller.recommendations.indexOf(recommendation);
                  return Padding(
                    padding: EdgeInsets.only(bottom: index < controller.recommendations.length - 1 ? 12 : 0),
                    child: _buildActionButton(
                      icon: _getIconForRecommendation(recommendation),
                      text: recommendation,
                      onTap: () {
                        Get.snackbar(
                          '액션',
                          recommendation,
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                    ),
                  );
                }).toList(),
              );
            }),
            
            const SizedBox(height: 30),
            
            // 이미지 선택 버튼들
            Row(
              children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: controller.pickImageFromGallery,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE8F5E9),
                        foregroundColor: const Color(0xFF2D7A4F),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: controller.pickImageFromCamera,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE8F5E9),
                        foregroundColor: const Color(0xFF2D7A4F),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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

  IconData _getIconForRecommendation(String recommendation) {
    if (recommendation.toLowerCase().contains('water') || 
        recommendation.toLowerCase().contains('fertilizer')) {
      return Icons.water_drop;
    } else if (recommendation.toLowerCase().contains('sun') || 
               recommendation.toLowerCase().contains('light')) {
      return Icons.wb_sunny;
    } else if (recommendation.toLowerCase().contains('temperature') || 
               recommendation.toLowerCase().contains('warm')) {
      return Icons.thermostat;
    } else {
      return Icons.check_circle;
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF00FF00), // 밝은 라임 그린
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00FF00).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.black,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

