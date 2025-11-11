import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../models/plant.dart';
import '../models/plant_history.dart';
import '../models/plant_status.dart';
import '../models/watering_record.dart';
import '../models/sun_time.dart';
import '../models/plant_note.dart';
import '../controllers/plant_detail_controller.dart';
import '../controllers/home_controller.dart';
import '../services/firestore_service.dart';
import '../services/weather_service.dart';
import '../widgets/watering_chart.dart';
import '../widgets/sunlight_chart.dart';
import 'create_plant_note_screen.dart';
import 'edit_plant_screen.dart';

class PlantDetailScreen extends StatefulWidget {
  final Plant plant;
  
  const PlantDetailScreen({super.key, required this.plant});

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final WeatherService _weatherService = WeatherService();
  
  late PlantDetailController _controller;
  List<WateringRecord> _wateringRecords = [];
  List<DailySunTime> _sunTimes = [];
  List<PlantNote> _notes = [];
  bool _isLoadingWeather = true;
  Plant? _currentPlant;
  Map<String, dynamic>? _currentWeather;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentPlant = widget.plant;
    _controller = PlantDetailController(widget.plant);
    Get.put(_controller);
    _loadData();
    _loadPlantData();
    _loadNotes();
    
    // 물주기 기록 실시간 업데이트 리스너
    ever(_controller.obs, (_) {
      _loadWateringRecords();
    });
  }
  
  Future<void> _loadWateringRecords() async {
    final records = await _firestoreService.getWeeklyWateringRecords(widget.plant.id);
    if (mounted) {
      setState(() {
        _wateringRecords = records;
      });
    }
  }

  @override
  void dispose() {
    Get.delete<PlantDetailController>();
    super.dispose();
  }

  void _loadPlantData() {
    _firestoreService.getPlantStream(widget.plant.id).listen((plant) {
      if (mounted && plant != null) {
        setState(() {
          _currentPlant = plant;
          _controller.plant.value = plant;
        });
      }
    });
  }

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
    // 모든 데이터를 병렬로 로드
    final futures = await Future.wait([
      _firestoreService.getWeeklyWateringRecords(widget.plant.id),
      _weatherService.getWeeklySunTimes(),
      _weatherService.getCurrentWeather(),
    ]);

    if (mounted) {
      setState(() {
        _wateringRecords = futures[0] as List<WateringRecord>;
        _sunTimes = futures[1] as List<DailySunTime>;
        _currentWeather = futures[2] as Map<String, dynamic>;
        _isLoadingWeather = false;
      });
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
            onPressed: () async {
              final result = await Get.to(() => EditPlantScreen(plant: _currentPlant ?? widget.plant));
              if (result != null && result is Plant) {
                setState(() {
                  _currentPlant = result;
                });
                _controller.plant.value = result;
              }
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
            // 식물 이미지 슬라이더
            SizedBox(
              height: 300,
              child: Stack(
                children: [
                  PageView.builder(
                    itemCount: plant.imageUrls.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return Hero(
                        tag: index == 0 ? 'plant_${plant.id}' : 'plant_${plant.id}_$index',
                        child: Image.network(
                          plant.imageUrls[index],
                          height: 300,
                          width: double.infinity,
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
                      );
                    },
                  ),
                  
                  // 이미지 개수 표시
                  if (plant.imageUrls.length > 1)
                    Positioned(
                      bottom: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_currentImageIndex + 1}/${plant.imageUrls.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 섹션 1: 상태 요약 카드
                  _buildStatusSummaryCard(),
                  
                  const SizedBox(height: 24),
                  
                  // 섹션 2: 주간 요약 캘린더
                  _buildWeeklySummary(),
                  
                  const SizedBox(height: 24),
                  
                  // 섹션 3: 최근 활동 타임라인
                  _buildRecentActivities(),
                  
                  const SizedBox(height: 24),
                  
                  // 기존 그래프 섹션 (축소)
                  _buildChartsSection(),
                ],
              ),
            ),
          ],
        ),
      ),
      // 섹션 4: 확장형 FAB
      floatingActionButton: _buildExpandableFAB(),
    );
  }

  // 섹션 1: 상태 요약 카드
  Widget _buildStatusSummaryCard() {
    return Obx(() {
      final status = _controller.plantStatus.value;
      
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF2D7A4F).withOpacity(0.1),
                Colors.white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D7A4F),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.eco,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '식물 상태',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _currentPlant?.isHealthy ?? false
                          ? Colors.green[100]
                          : Colors.orange[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _currentPlant?.isHealthy ?? false ? '건강함' : '주의 필요',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _currentPlant?.isHealthy ?? false
                            ? Colors.green[800]
                            : Colors.orange[800],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: Colors.grey[300]),
              const SizedBox(height: 16),
              
              // 물주기 정보
              Row(
                children: [
                  const Icon(
                    Icons.water_drop,
                    color: Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      status?.wateringStatusText ?? '물주기 정보 없음',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              
              // 경고 메시지 (있을 경우)
              if (status?.hasWarning ?? false) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          status!.warningMessage!,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.orange[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  // 섹션 2: 주간 요약 캘린더
  Widget _buildWeeklySummary() {
    return Obx(() {
      final weeklyActivities = _controller.weeklyActivities;
      final sortedDates = weeklyActivities.keys.toList()..sort();
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '이번 주 활동 기록',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: sortedDates.map((date) {
                final activities = weeklyActivities[date] ?? [];
                final weekdayNames = ['월', '화', '수', '목', '금', '토', '일'];
                final weekdayIndex = date.weekday - 1;
                
                return Expanded(
                  child: Column(
                    children: [
                      Text(
                        weekdayNames[weekdayIndex],
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${date.day}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // 활동 아이콘들
                      if (activities.isEmpty)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            shape: BoxShape.circle,
                          ),
                        )
                      else
                        Column(
                          children: _buildActivityIcons(activities),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      );
    });
  }

  // 활동 아이콘 생성
  List<Widget> _buildActivityIcons(List<PlantHistory> activities) {
    // 활동 타입별 개수 카운트
    final Map<HistoryType, int> activityCount = {};
    for (var activity in activities) {
      activityCount[activity.type] = (activityCount[activity.type] ?? 0) + 1;
    }
    
    List<Widget> icons = [];
    activityCount.forEach((type, count) {
      icons.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getActivityEmoji(type),
              style: const TextStyle(fontSize: 16),
            ),
            if (count > 1)
              Text(
                'x$count',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D7A4F),
                ),
              ),
          ],
        ),
      );
      icons.add(const SizedBox(height: 2));
    });
    
    return icons;
  }

  String _getActivityEmoji(HistoryType type) {
    switch (type) {
      case HistoryType.watering:
        return '💧';
      case HistoryType.fertilizing:
        return '🌱';
      case HistoryType.pruning:
        return '✂️';
      case HistoryType.repotting:
        return '🪴';
      case HistoryType.pestControl:
        return '🐛';
      case HistoryType.memo:
        return '📝';
    }
  }

  // 섹션 3: 최근 활동 타임라인
  Widget _buildRecentActivities() {
    return Obx(() {
      final activities = _controller.recentActivities;
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '최근 활동',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          if (activities.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '아직 활동 기록이 없습니다',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            )
          else
            ...activities.map((activity) => _buildActivityItem(activity)).toList(),
          
          if (activities.length >= 3)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Center(
                child: TextButton.icon(
                  onPressed: () {
                    Get.snackbar(
                      '준비 중',
                      '전체 기록 보기 기능이 곧 추가됩니다',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(
                    '모든 기록 보기',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildActivityItem(PlantHistory activity) {
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              activity.iconEmoji,
              style: const TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.displayName,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                if (activity.content != null && activity.content!.isNotEmpty)
                  Text(
                    activity.content!,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  activity.timeAgo,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                
                // 메모에 이미지가 있으면 썸네일 표시
                if (activity.type == HistoryType.memo && activity.imageUrl != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      activity.imageUrl!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 120,
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 기존 그래프 섹션
  Widget _buildChartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '상세 통계',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // 날씨 정보 - 항상 표시
        _buildWeatherWidget(),
        const SizedBox(height: 20),
        
        // 물주기 기록 - 항상 표시
        Text(
          '물주기 기록',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        if (_wateringRecords.isEmpty && !_isLoadingWeather)
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '물주기 기록이 없습니다',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
          )
        else if (_isLoadingWeather)
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2D7A4F),
              ),
            ),
          )
        else
          WateringChart(records: _wateringRecords),
        const SizedBox(height: 20),
        
        // 일조 시간 - 항상 표시
        Text(
          '일조 시간',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        if (_isLoadingWeather)
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2D7A4F),
              ),
            ),
          )
        else if (_sunTimes.isEmpty)
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '일조 시간 데이터를 불러올 수 없습니다',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
          )
        else
          SunlightChart(weeklyData: _sunTimes),
      ],
    );
  }

  // 날씨 정보 위젯
  Widget _buildWeatherWidget() {
    // 로딩 중일 때
    if (_isLoadingWeather || _currentWeather == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade50,
              Colors.blue.shade100.withOpacity(0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.blue.shade200,
            width: 1,
          ),
        ),
        child: const Center(
          child: SizedBox(
            height: 120,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: Color(0xFF2D7A4F),
                ),
                SizedBox(height: 16),
                Text(
                  '날씨 정보를 불러오는 중...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    final weather = _currentWeather!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade50,
            Colors.blue.shade100.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.thermostat,
                color: Colors.blue.shade700,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                '현재 날씨',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const Spacer(),
              Text(
                weather['city'] ?? '위치 정보 없음',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 현재 온도
              Column(
                children: [
                  Text(
                    '${weather['temp'].toStringAsFixed(1)}°C',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  Text(
                    weather['description'] ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              
              // 세부 정보
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWeatherDetail(
                    '체감',
                    '${weather['feels_like'].toStringAsFixed(1)}°C',
                    Icons.sentiment_satisfied_alt,
                  ),
                  const SizedBox(height: 8),
                  _buildWeatherDetail(
                    '습도',
                    '${weather['humidity']}%',
                    Icons.water_drop_outlined,
                  ),
                  const SizedBox(height: 8),
                  _buildWeatherDetail(
                    '최저/최고',
                    '${weather['temp_min'].toStringAsFixed(0)}° / ${weather['temp_max'].toStringAsFixed(0)}°',
                    Icons.thermostat_outlined,
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 식물 관리 팁
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.tips_and_updates,
                  color: Colors.orange.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getWeatherTip(weather['temp'], weather['humidity']),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherDetail(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  String _getWeatherTip(double temp, int humidity) {
    if (temp > 30) {
      return '기온이 높습니다. 식물에게 충분한 물을 주고 직사광선을 피해주세요.';
    } else if (temp < 10) {
      return '기온이 낮습니다. 실내로 옮기거나 보온에 신경써주세요.';
    } else if (humidity < 30) {
      return '습도가 낮습니다. 분무기로 잎에 물을 뿌려주세요.';
    } else if (humidity > 80) {
      return '습도가 높습니다. 통풍에 신경쓰고 과습에 주의하세요.';
    } else {
      return '식물이 자라기 좋은 날씨입니다. 정기적인 관리를 계속해주세요.';
    }
  }

  // 섹션 4: 확장형 FAB (Speed Dial)
  Widget _buildExpandableFAB() {
    return SpeedDial(
      icon: Icons.add,
      activeIcon: Icons.close,
      backgroundColor: const Color(0xFF2D7A4F),
      foregroundColor: Colors.white,
      activeBackgroundColor: Colors.grey[700],
      activeForegroundColor: Colors.white,
      visible: true,
      closeManually: false,
      curve: Curves.bounceIn,
      overlayColor: Colors.black,
      overlayOpacity: 0.5,
      elevation: 8.0,
      shape: const CircleBorder(),
      children: [
        SpeedDialChild(
          child: const Icon(Icons.note_add, color: Colors.white),
          backgroundColor: const Color(0xFF2D7A4F),
          foregroundColor: Colors.white,
          label: '메모 추가',
          labelStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          labelBackgroundColor: const Color(0xFF2D7A4F),
          onTap: () {
            Get.to(() => CreatePlantNoteScreen(plant: widget.plant));
          },
        ),
        SpeedDialChild(
          child: const Icon(Icons.content_cut, color: Colors.white),
          backgroundColor: Colors.brown,
          foregroundColor: Colors.white,
          label: '가지치기',
          labelStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          labelBackgroundColor: Colors.brown,
          onTap: () async {
            await _controller.addPruning();
          },
        ),
        SpeedDialChild(
          child: const Icon(Icons.grass, color: Colors.white),
          backgroundColor: Colors.green[400],
          foregroundColor: Colors.white,
          label: '영양제',
          labelStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          labelBackgroundColor: Colors.green[400],
          onTap: () async {
            await _controller.addFertilizing();
          },
        ),
        SpeedDialChild(
          child: const Icon(Icons.water_drop, color: Colors.white),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          label: '물주기',
          labelStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          labelBackgroundColor: Colors.blue,
          onTap: () async {
            await _controller.addWatering();
          },
        ),
      ],
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
        Get.back();
        Get.back();
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
