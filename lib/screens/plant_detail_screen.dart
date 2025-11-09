import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/plant.dart';
import '../controllers/home_controller.dart';

class PlantDetailScreen extends StatelessWidget {
  final Plant plant;
  
  const PlantDetailScreen({super.key, required this.plant});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(plant.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Get.snackbar(
                '편집',
                '식물 편집 기능 준비중입니다',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              _showDeleteDialog(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 식물 이미지
            Hero(
              tag: 'plant_${plant.id}',
              child: Image.network(
                plant.imageUrl,
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 300,
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.local_florist,
                      size: 100,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 식물 이름 및 건강 상태
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          plant.name,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: plant.isHealthy 
                              ? Colors.green[100] 
                              : Colors.red[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              plant.isHealthy 
                                  ? Icons.check_circle 
                                  : Icons.warning,
                              color: plant.isHealthy 
                                  ? Colors.green 
                                  : Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              plant.isHealthy ? '건강함' : '주의 필요',
                              style: TextStyle(
                                color: plant.isHealthy 
                                    ? Colors.green[800] 
                                    : Colors.red[800],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    '등록일: ${_formatDate(plant.createdAt)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // 관리 기록 섹션
                  _buildSectionTitle('관리 기록'),
                  const SizedBox(height: 12),
                  
                  _buildCareCard(
                    icon: Icons.water_drop,
                    title: '마지막 물주기',
                    value: '3일 전',
                    color: Colors.blue,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildCareCard(
                    icon: Icons.wb_sunny,
                    title: '햇빛 노출',
                    value: '충분함',
                    color: Colors.orange,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildCareCard(
                    icon: Icons.thermostat,
                    title: '온도',
                    value: '22°C (적정)',
                    color: Colors.green,
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // 메모 섹션
                  _buildSectionTitle('메모'),
                  const SizedBox(height: 12),
                  
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '새 잎이 잘 자라고 있습니다. 계속 관리 중...',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // 액션 버튼들
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Get.snackbar(
                              '물주기 완료',
                              '${plant.name}에게 물을 주었습니다',
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          },
                          icon: const Icon(Icons.water_drop),
                          label: const Text('물주기'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
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
                          onPressed: () {
                            Get.snackbar(
                              '메모 추가',
                              '메모 추가 기능 준비중입니다',
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          },
                          icon: const Icon(Icons.note_add),
                          label: const Text('메모 추가'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D7A4F),
                            foregroundColor: Colors.white,
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
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildCareCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Colors.grey[400],
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    Get.defaultDialog(
      title: '식물 삭제',
      middleText: '${plant.name}를 삭제하시겠습니까?',
      textConfirm: '삭제',
      textCancel: '취소',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        final homeController = Get.find<HomeController>();
        homeController.plants.removeWhere((p) => p.id == plant.id);
        Get.back(); // 다이얼로그 닫기
        Get.back(); // 상세 화면 닫기
        Get.snackbar(
          '삭제 완료',
          '${plant.name}가 삭제되었습니다',
          snackPosition: SnackPosition.BOTTOM,
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}

