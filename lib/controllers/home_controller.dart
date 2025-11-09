import 'package:get/get.dart';
import '../models/plant.dart';
import '../services/firestore_service.dart';
import '../controllers/auth_controller.dart';

class HomeController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  
  // 식물 목록
  final RxList<Plant> plants = <Plant>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadPlants();
  }

  // Firestore에서 식물 목록 로드
  Future<void> loadPlants() async {
    try {
      isLoading.value = true;
      final authController = Get.find<AuthController>();
      final userId = authController.currentUserId;
      
      if (userId != null) {
        // Firestore에서 실시간 스트림으로 가져오기
        _firestoreService.getPlantsStream(userId).listen((plantList) {
          plants.value = plantList;
        });
        
        print('✅ Plants loaded from Firestore for user: $userId');
      } else {
        print('⚠️ No user ID available');
      }
    } catch (e) {
      print('❌ Error loading plants: $e');
      // 오류 발생 시 더미 데이터로 대체
      _loadDummyPlants();
    } finally {
      isLoading.value = false;
    }
  }

  // 식물 추가 (Firestore에 저장)
  Future<void> addPlant(Plant plant) async {
    try {
      await _firestoreService.addPlant(plant);
      // Firestore 스트림이 자동으로 업데이트됨
      print('✅ Plant added to Firestore: ${plant.name}');
    } catch (e) {
      print('❌ Error adding plant: $e');
      // 오류 발생 시 로컬에만 추가
      plants.add(plant);
      rethrow;
    }
  }

  // 식물 삭제 (Firestore에서 삭제)
  Future<void> deletePlant(String plantId) async {
    try {
      // TODO: Firestore 삭제 메서드 구현
      plants.removeWhere((p) => p.id == plantId);
      print('✅ Plant deleted: $plantId');
    } catch (e) {
      print('❌ Error deleting plant: $e');
      rethrow;
    }
  }

  // 더미 데이터 로드 (Firestore 연동 실패 시 대체)
  void _loadDummyPlants() {
    plants.value = [
      Plant(
        id: '1',
        name: 'Pothos',
        imageUrl: 'https://images.unsplash.com/photo-1614594975525-e45190c55d0b?w=400',
        isHealthy: true,
        createdAt: DateTime.now(),
        userId: 'dummy',
      ),
      Plant(
        id: '2',
        name: 'Monstera',
        imageUrl: 'https://images.unsplash.com/photo-1614594895304-fe7116ac3b58?w=400',
        isHealthy: false,
        createdAt: DateTime.now(),
        userId: 'dummy',
      ),
      Plant(
        id: '3',
        name: 'Snake Plant',
        imageUrl: 'https://images.unsplash.com/photo-1593482892540-62cebf9b8180?w=400',
        isHealthy: true,
        createdAt: DateTime.now(),
        userId: 'dummy',
      ),
    ];
    print('⚠️ Using dummy plant data');
  }
}

