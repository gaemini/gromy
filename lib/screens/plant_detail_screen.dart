import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/plant.dart';
import '../models/watering_record.dart';
import '../models/sun_time.dart';
import '../models/plant_note.dart';
import '../controllers/home_controller.dart';
import '../services/firestore_service.dart';
import '../services/weather_service.dart';
import '../widgets/watering_chart.dart';
import '../widgets/sunlight_chart.dart';

class PlantDetailScreen extends StatefulWidget {
  final Plant plant;
  
  const PlantDetailScreen({super.key, required this.plant});

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final WeatherService _weatherService = WeatherService();
  
  List<WateringRecord> _wateringRecords = [];
  List<DailySunTime> _sunTimes = [];
  List<PlantNote> _notes = [];
  bool _isLoadingWeather = true;
  Plant? _currentPlant; // 실시간 업데이트용

  @override
  void initState() {
    super.initState();
    _currentPlant = widget.plant;
    _loadData();
    _loadPlantData();
    _loadNotes();
  }

  // 식물 데이터 실시간 로드
  void _loadPlantData() {
    _firestoreService.getPlantStream(widget.plant.id).listen((plant) {
      if (mounted && plant != null) {
        setState(() {
          _currentPlant = plant;
        });
      }
    });
  }

  // 메모 목록 실시간 로드
  void _loadNotes() {
    _firestoreService.getPlantNotesStream(widget.plant.id).listen((notes) {
      if (mounted) {
        setState(() {
          _notes = notes;
        });
      }
    });
  }

  Future<void> _loadData() async {
    // 물주기 기록 로드
    _firestoreService
        .getWeeklyWateringRecords(widget.plant.id)
        .then((records) {
      if (mounted) {
        setState(() {
          _wateringRecords = records;
        });
      }
    });

    // 일출/일몰 데이터 로드
    try {
      final sunTimes = await _weatherService.getWeeklySunTimes();
      print('📊 Loaded ${sunTimes.length} days of sun times');
      if (mounted) {
        setState(() {
          _sunTimes = sunTimes;
          _isLoadingWeather = false;
        });
      }
    } catch (e) {
      print('❌ Failed to load sun times: $e');
      if (mounted) {
        setState(() {
          _isLoadingWeather = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final plant = _currentPlant ?? widget.plant;
    
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
        padding: const EdgeInsets.only(bottom: 100.0),
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
                    value: plant.lastWateredDisplay,
                    color: Colors.blue,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 물주기 그래프
                  if (_wateringRecords.isNotEmpty)
                    WateringChart(records: _wateringRecords),
                  
                  const SizedBox(height: 20),
                  
                  _buildCareCard(
                    icon: Icons.wb_sunny,
                    title: '햇빛 노출',
                    value: _isLoadingWeather
                        ? '데이터 로딩 중...'
                        : _sunTimes.isNotEmpty
                            ? '일조 ${_sunTimes.first.sunTime.daylightHours}'
                            : '충분함',
                    color: Colors.orange,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 햇빛 그래프
                  if (_sunTimes.isNotEmpty)
                    SunlightChart(weeklyData: _sunTimes),
                  
                  const SizedBox(height: 30),
                  
                  // 메모 섹션
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle('메모'),
                      Text(
                        '${_notes.length}개',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // 메모 타임라인
                  if (_notes.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.note_add,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '메모가 없습니다',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '메모 추가 버튼을 눌러 기록해보세요!',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._notes.take(3).map((note) => _buildNoteItem(note)).toList(),
                  
                  // 메모가 3개 이상이면 "모두 보기" 버튼
                  if (_notes.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: TextButton(
                        onPressed: () {
                          _showAllNotes();
                        },
                        child: Text(
                          '메모 ${_notes.length}개 모두 보기',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF2D7A4F),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 30),
                  
                  // 액션 버튼들
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await _waterPlant();
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
                          onPressed: _showNoteDialog,
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
    final plant = _currentPlant ?? widget.plant;
    Get.defaultDialog(
      title: '식물 삭제',
      middleText: '${plant.name}를 삭제하시겠습니까?',
      textConfirm: '삭제',
      textCancel: '취소',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () async {
        final homeController = Get.find<HomeController>();
        await homeController.deletePlant(widget.plant.id);
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

  Widget _buildNoteItem(PlantNote note) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2D7A4F).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.edit_note,
              color: Color(0xFF2D7A4F),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.content,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  note.timeAgo,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            color: Colors.grey[400],
            onPressed: () => _deleteNote(note),
          ),
        ],
      ),
    );
  }

  void _showAllNotes() {
    Get.bottomSheet(
      Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '모든 메모',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _notes.length,
                  itemBuilder: (context, index) {
                    return _buildNoteItem(_notes[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteNote(PlantNote note) {
    Get.defaultDialog(
      title: '메모 삭제',
      middleText: '이 메모를 삭제하시겠습니까?',
      textConfirm: '삭제',
      textCancel: '취소',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () async {
        try {
          await _firestoreService.deletePlantNote(widget.plant.id, note.id);
          Get.back();
          Get.snackbar(
            '삭제 완료',
            '메모가 삭제되었습니다',
            snackPosition: SnackPosition.BOTTOM,
          );
        } catch (e) {
          Get.back();
          Get.snackbar(
            '오류',
            '메모 삭제에 실패했습니다',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      },
    );
  }

  void _showNoteDialog() {
    final noteController = TextEditingController();

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.edit_note,
                      color: Color(0xFF2D7A4F),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '새 메모 작성',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: noteController,
                maxLines: 5,
                maxLength: 200,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '식물 관리 메모를 작성하세요...\n예: 새 잎이 나왔어요!',
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF2D7A4F),
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        '취소',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (noteController.text.trim().isEmpty) {
                          Get.snackbar(
                            '알림',
                            '메모 내용을 입력해주세요',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                          return;
                        }

                        try {
                          final note = PlantNote(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            plantId: widget.plant.id,
                            content: noteController.text.trim(),
                            timestamp: DateTime.now(),
                          );

                          await _firestoreService.addPlantNote(note);

                          Get.back();
                          Get.snackbar(
                            '성공',
                            '메모가 추가되었습니다',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: const Color(0xFF2D7A4F),
                            colorText: Colors.white,
                          );
                        } catch (e) {
                          Get.back();
                          Get.snackbar(
                            '오류',
                            '메모 저장에 실패했습니다',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                        }
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
                        '저장',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _waterPlant() async {
    try {
      final record = WateringRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        plantId: widget.plant.id,
        timestamp: DateTime.now(),
      );
      
      await _firestoreService.addWateringRecord(widget.plant.id, record);
      
      // 물주기 기록 새로고침
      final newRecords = await _firestoreService.getWeeklyWateringRecords(widget.plant.id);
      setState(() {
        _wateringRecords = newRecords;
      });
      
      Get.snackbar(
        '물주기 완료',
        '${_currentPlant?.name ?? widget.plant.name}에게 물을 주었습니다',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        '오류',
        '물주기 기록에 실패했습니다',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}

