import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/plant.dart';
import '../models/plant_status.dart';
import '../models/plant_history.dart';
import '../models/watering_record.dart';
import '../models/plant_note.dart';
import '../services/firestore_service.dart';
import 'challenge_controller.dart';

class PlantDetailController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();

  // 현재 식물 정보
  late Rx<Plant> plant;

  // 식물 현재 상태
  final Rxn<PlantStatus> plantStatus = Rxn<PlantStatus>();

  // 주간 활동 데이터 (날짜별 활동 리스트)
  final RxMap<DateTime, List<PlantHistory>> weeklyActivities =
      <DateTime, List<PlantHistory>>{}.obs;

  // 최근 활동 타임라인 (3-5개)
  final RxList<PlantHistory> recentActivities = <PlantHistory>[].obs;

  // 로딩 상태
  final RxBool isLoading = false.obs;

  // 생성자
  PlantDetailController(Plant initialPlant) {
    plant = initialPlant.obs;
  }

  @override
  void onInit() {
    super.onInit();
    loadPlantData();
    loadPlantStatus();
    loadActivities();
  }

  // 식물 데이터 실시간 로드
  void loadPlantData() {
    _firestoreService.getPlantStream(plant.value.id).listen((updatedPlant) {
      if (updatedPlant != null) {
        plant.value = updatedPlant;
        loadPlantStatus(); // 상태도 업데이트
      }
    });
  }

  // 식물 상태 계산 및 로드
  void loadPlantStatus() {
    final currentPlant = plant.value;
    
    // 물주기까지 남은 일수 계산
    int? daysUntil;
    if (currentPlant.lastWatered != null) {
      final nextWatering = currentPlant.lastWatered!
          .add(Duration(days: currentPlant.wateringIntervalDays));
      daysUntil = nextWatering.difference(DateTime.now()).inDays;
    }

    // 경고 메시지 (예시)
    String? warning;
    if (daysUntil != null && daysUntil < 0) {
      warning = '⚠️ 물주기가 ${daysUntil.abs()}일 지났습니다!';
    }

    plantStatus.value = PlantStatus(
      daysUntilWatering: daysUntil,
      warningMessage: warning,
      healthStatus: currentPlant.isHealthy ? 'healthy' : 'warning',
      lastWatered: currentPlant.lastWatered,
      nextWateringDate: currentPlant.nextWateringDate,
    );
  }

  // 활동 데이터 로드
  Future<void> loadActivities() async {
    try {
      isLoading.value = true;

      // 최근 활동 로드 (실제 데이터 + 더미 데이터)
      final activities = await _loadRecentActivities();
      recentActivities.value = activities;

      // 주간 활동 데이터 생성
      final weekly = await _loadWeeklyActivities();
      weeklyActivities.value = weekly;

      isLoading.value = false;
    } catch (e) {
      print('❌ Error loading activities: $e');
      isLoading.value = false;
    }
  }

  // 최근 활동 로드 (실제 데이터)
  Future<List<PlantHistory>> _loadRecentActivities() async {
    final List<PlantHistory> activities = [];

    // 물주기 기록 가져오기
    final wateringRecords =
        await _firestoreService.getWeeklyWateringRecords(plant.value.id);
    for (var record in wateringRecords) {
      activities.add(PlantHistory.fromWateringRecord(
        id: record.id,
        plantId: record.plantId,
        timestamp: record.timestamp,
      ));
    }

    // 메모 가져오기
    final notes = await _firestoreService.getPlantNotes(plant.value.id);
    for (var note in notes.take(3)) {
      activities.add(PlantHistory.fromPlantNote(
        id: note.id,
        plantId: note.plantId,
        timestamp: note.timestamp,
        content: note.content,
        imageUrl: note.imageUrl,
      ));
    }

    // 더미 데이터 추가 (다양한 활동 시연용)
    activities.addAll(_generateDummyActivities());

    // 시간순 정렬 (최신순)
    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return activities.take(5).toList();
  }

  // 주간 활동 데이터 로드
  Future<Map<DateTime, List<PlantHistory>>> _loadWeeklyActivities() async {
    final Map<DateTime, List<PlantHistory>> weekly = {};

    // 이번 주의 시작일 (월요일)
    final now = DateTime.now();
    final weekday = now.weekday;
    final startOfWeek = now.subtract(Duration(days: weekday - 1));

    // 7일간의 날짜 생성
    for (int i = 0; i < 7; i++) {
      final date = DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day + i,
      );
      weekly[date] = [];
    }

    // 최근 활동을 날짜별로 분류
    for (var activity in recentActivities) {
      final activityDate = DateTime(
        activity.timestamp.year,
        activity.timestamp.month,
        activity.timestamp.day,
      );

      if (weekly.containsKey(activityDate)) {
        weekly[activityDate]!.add(activity);
      }
    }

    return weekly;
  }

  // 더미 활동 데이터 생성
  List<PlantHistory> _generateDummyActivities() {
    final now = DateTime.now();
    return [
      PlantHistory(
        id: 'dummy_1',
        plantId: plant.value.id,
        type: HistoryType.fertilizing,
        timestamp: now.subtract(const Duration(days: 3)),
        content: '액체 비료 투여',
      ),
      PlantHistory(
        id: 'dummy_2',
        plantId: plant.value.id,
        type: HistoryType.pruning,
        timestamp: now.subtract(const Duration(days: 5)),
        content: '노란 잎 제거',
      ),
    ];
  }

  // 물주기 추가
  Future<void> addWatering() async {
    try {
      final record = WateringRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        plantId: plant.value.id,
        timestamp: DateTime.now(),
      );

      await _firestoreService.addWateringRecord(plant.value.id, record);

      // 챌린지 진행률 업데이트
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId != null) {
        await _firestoreService.updateChallengeProgress(currentUserId);
        
        // ChallengeController가 있으면 새로고침
        if (Get.isRegistered<ChallengeController>()) {
          final challengeController = Get.find<ChallengeController>();
          await challengeController.loadUserChallenges();
        }
      }

      // 활동 새로고침
      await loadActivities();
      
      // PlantDetailScreen의 물주기 기록 새로고침을 위한 이벤트 발생
      Get.find<PlantDetailController>().refreshWateringRecords();

      Get.snackbar(
        '물주기 완료',
        '${plant.value.name}에게 물을 주었습니다',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        '오류',
        '물주기 기록에 실패했습니다',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
  
  // 물주기 기록 새로고침
  void refreshWateringRecords() {
    update(); // GetX 컨트롤러 업데이트 트리거
  }

  // 영양제 추가
  Future<void> addFertilizing() async {
    try {
      final history = PlantHistory(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        plantId: plant.value.id,
        type: HistoryType.fertilizing,
        timestamp: DateTime.now(),
        content: '영양제 투여',
      );

      await _firestoreService.addPlantHistory(history);
      await loadActivities();

      Get.snackbar(
        '영양제 추가 완료',
        '${plant.value.name}에게 영양제를 주었습니다',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        '오류',
        '영양제 기록에 실패했습니다',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // 가지치기 추가
  Future<void> addPruning() async {
    try {
      final history = PlantHistory(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        plantId: plant.value.id,
        type: HistoryType.pruning,
        timestamp: DateTime.now(),
        content: '가지치기',
      );

      await _firestoreService.addPlantHistory(history);
      await loadActivities();

      Get.snackbar(
        '가지치기 완료',
        '${plant.value.name}의 가지치기를 완료했습니다',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        '오류',
        '가지치기 기록에 실패했습니다',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}



