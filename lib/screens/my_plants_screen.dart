import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'plant_detail_screen.dart';

class MyPlantsScreen extends StatelessWidget {
  const MyPlantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeController controller = Get.put(HomeController());

    return Scaffold(
      appBar: AppBar(
        title: Text('나의 식물', style: AppTextStyles.appBarTitle),
        backgroundColor: AppColors.white,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.plants.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_florist_outlined,
                  size: 80,
                  color: AppColors.gray300,
                ),
                const SizedBox(height: 16),
                Text(
                  '등록된 식물이 없습니다',
                  style: AppTextStyles.emptyStateTitle,
                ),
                const SizedBox(height: 8),
                Text(
                  'Home 탭에서 식물을 추가해보세요!',
                  style: AppTextStyles.emptyStateSubtitle,
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(2),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // 3열 그리드
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
            childAspectRatio: 1, // 정사각형
          ),
          itemCount: controller.plants.length,
          itemBuilder: (context, index) {
            return _buildPlantGridItem(controller.plants[index]);
          },
        );
      }),
    );
  }

  Widget _buildPlantGridItem(plant) {
    return GestureDetector(
      onTap: () {
        Get.to(
          () => PlantDetailScreen(plant: plant),
          transition: Transition.cupertino,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.gray100,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 식물 이미지
            Image.network(
              plant.imageUrls?.isNotEmpty == true 
                  ? plant.imageUrls![0] 
                  : plant.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: AppColors.gray200,
                  child: Icon(
                    Icons.local_florist_outlined,
                    size: 40,
                    color: AppColors.gray400,
                  ),
                );
              },
            ),
            
            // 그라데이션 오버레이 (하단에 식물 이름 표시용)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.black.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
                padding: const EdgeInsets.all(8),
                child: Text(
                  plant.name,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.white,
                    shadows: [
                      Shadow(
                        offset: const Offset(0, 1),
                        blurRadius: 3,
                        color: Colors.black.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            
            // 건강 상태 표시
            if (plant.isHealthy)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

