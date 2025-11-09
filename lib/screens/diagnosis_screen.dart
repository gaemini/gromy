import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/diagnosis_controller.dart';

class DiagnosisScreen extends StatelessWidget {
  const DiagnosisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DiagnosisController controller = Get.put(DiagnosisController());

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Diagnosis',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
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
                  
                  // SCANNING 텍스트
                  Obx(() => controller.isScanning.value
                      ? Positioned(
                          bottom: 20,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'SCANNING...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.5,
                              ),
                            ),
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
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.yellow[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.yellow[200]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.yellow[700],
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            controller.diagnosisResult.value,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.yellow[900],
                            ),
                          ),
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
                      backgroundColor: Colors.green[100],
                      foregroundColor: Colors.green[800],
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
                      backgroundColor: Colors.green[100],
                      foregroundColor: Colors.green[800],
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

