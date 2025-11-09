import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/home_controller.dart';
import 'plant_detail_screen.dart';
import 'add_plant_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeController controller = Get.put(HomeController());

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Plants',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: Obx(() => Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85,
          children: controller.plants.map((plant) {
            return _buildPlantCard(plant);
          }).toList(),
        ),
      )),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(
            () => const AddPlantScreen(),
            transition: Transition.downToUp,
          );
        },
        backgroundColor: const Color(0xFF2D7A4F),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildPlantCard(plant) {
    return GestureDetector(
      onTap: () {
        Get.to(
          () => PlantDetailScreen(plant: plant),
          transition: Transition.cupertino,
        );
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이미지 영역 (Stack으로 체크마크 겹치기)
          Expanded(
            child: Stack(
              children: [
                // 식물 이미지
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Image.network(
                    plant.imageUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.local_florist,
                          size: 50,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
                // 건강 상태 체크마크 (isHealthy가 true일 때만 표시)
                if (plant.isHealthy)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Color(0xFF2D7A4F),
                        size: 24,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // 식물 이름
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                plant.name,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
      ),
    );
  }
}

