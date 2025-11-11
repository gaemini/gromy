import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../models/plant.dart';
import '../models/plant_history.dart';
import '../models/watering_record.dart';
import '../models/plant_note.dart';
import '../services/firestore_service.dart';
import 'plant_note_detail_screen.dart';

class AllActivitiesScreen extends StatefulWidget {
  final Plant plant;

  const AllActivitiesScreen({
    super.key,
    required this.plant,
  });

  @override
  State<AllActivitiesScreen> createState() => _AllActivitiesScreenState();
}

class _AllActivitiesScreenState extends State<AllActivitiesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  
  List<PlantHistory> _allActivities = [];
  Map<DateTime, List<PlantHistory>> _groupedActivities = {};
  bool _isLoading = true;
  String _selectedFilter = '전체';
  
  final List<String> _filterOptions = [
    '전체',
    '물주기',
    '메모',
    '영양제',
    '가지치기',
  ];

  @override
  void initState() {
    super.initState();
    _loadAllActivities();
  }

  Future<void> _loadAllActivities() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final List<PlantHistory> activities = [];

      // 물주기 기록 가져오기
      final wateringRecords = await _firestoreService.getAllWateringRecords(widget.plant.id);
      for (var record in wateringRecords) {
        activities.add(PlantHistory.fromWateringRecord(
          id: record.id,
          plantId: record.plantId,
          timestamp: record.timestamp,
        ));
      }

      // 메모 가져오기
      final notes = await _firestoreService.getPlantNotes(widget.plant.id);
      for (var note in notes) {
        activities.add(PlantHistory.fromPlantNote(
          id: note.id,
          plantId: note.plantId,
          timestamp: note.timestamp,
          content: note.content,
          imageUrl: note.imageUrl,
        ));
      }

      // 기타 활동 기록 가져오기 (영양제, 가지치기 등)
      final histories = await _firestoreService.getPlantHistories(widget.plant.id);
      activities.addAll(histories);

      // 시간순 정렬 (최신순)
      activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // 날짜별 그룹화
      _groupActivitiesByDate(activities);

      setState(() {
        _allActivities = activities;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading activities: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _groupActivitiesByDate(List<PlantHistory> activities) {
    _groupedActivities.clear();
    
    for (var activity in activities) {
      final date = DateTime(
        activity.timestamp.year,
        activity.timestamp.month,
        activity.timestamp.day,
      );
      
      if (_groupedActivities.containsKey(date)) {
        _groupedActivities[date]!.add(activity);
      } else {
        _groupedActivities[date] = [activity];
      }
    }
  }

  List<PlantHistory> _getFilteredActivities() {
    if (_selectedFilter == '전체') {
      return _allActivities;
    }

    return _allActivities.where((activity) {
      switch (_selectedFilter) {
        case '물주기':
          return activity.type == HistoryType.watering;
        case '메모':
          return activity.type == HistoryType.memo;
        case '영양제':
          return activity.type == HistoryType.fertilizing;
        case '가지치기':
          return activity.type == HistoryType.pruning;
        default:
          return true;
      }
    }).toList();
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      final filtered = _getFilteredActivities();
      _groupActivitiesByDate(filtered);
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredActivities = _getFilteredActivities();
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          '${widget.plant.name}의 모든 기록',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2D7A4F),
              ),
            )
          : Column(
              children: [
                // 필터 칩들
                Container(
                  color: Colors.white,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Row(
                      children: _filterOptions.map((filter) {
                        final isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(filter),
                            selected: isSelected,
                            onSelected: (_) => _applyFilter(filter),
                            selectedColor: const Color(0xFF2D7A4F).withOpacity(0.2),
                            checkmarkColor: const Color(0xFF2D7A4F),
                            labelStyle: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected ? const Color(0xFF2D7A4F) : Colors.grey[700],
                            ),
                            backgroundColor: Colors.grey[100],
                            side: BorderSide(
                              color: isSelected ? const Color(0xFF2D7A4F) : Colors.transparent,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                
                // 기록 개수 표시
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  color: Colors.white,
                  child: Text(
                    '총 ${filteredActivities.length}개의 기록',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // 활동 리스트
                Expanded(
                  child: filteredActivities.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history,
                                size: 64,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '아직 기록이 없습니다',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '식물 관리 활동을 시작해보세요',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                              // 하단바를 고려한 여백
                              const SizedBox(height: 80),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(
                            left: 20,
                            right: 20,
                            top: 8,
                            bottom: 100, // 하단바를 고려한 패딩
                          ),
                          itemCount: _groupedActivities.length,
                          itemBuilder: (context, index) {
                            final date = _groupedActivities.keys.elementAt(index);
                            final activities = _groupedActivities[date]!;
                            
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 날짜 헤더
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 16,
                                    bottom: 8,
                                  ),
                                  child: Text(
                                    _getDateHeader(date),
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                                
                                // 해당 날짜의 활동들
                                ...activities.map((activity) => _buildActivityCard(activity)),
                              ],
                            );
                          },
                        ),
                ),
                
                // 하단 안내 메시지 (리스트가 있을 때만)
                if (filteredActivities.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '최근 30일간의 기록을 표시합니다',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  String _getDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    if (date == today) {
      return '오늘';
    } else if (date == yesterday) {
      return '어제';
    } else {
      return DateFormat('MM월 dd일 (E)', 'ko_KR').format(date);
    }
  }

  Widget _buildActivityCard(PlantHistory activity) {
    return GestureDetector(
      onTap: () {
        // 메모인 경우 상세 화면으로 이동
        if (activity.type == HistoryType.memo) {
          _navigateToNoteDetail(activity);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
            // 아이콘
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getActivityColor(activity.type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                activity.iconEmoji,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // 내용
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        activity.displayName,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        DateFormat('HH:mm').format(activity.timestamp),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  
                  if (activity.content != null && activity.content!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      activity.content!,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  
                  // 메모에 이미지가 있으면 썸네일 표시
                  if (activity.type == HistoryType.memo && activity.imageUrl != null) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        activity.imageUrl!,
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  
                  // 메모인 경우 더 보기 표시
                  if (activity.type == HistoryType.memo) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '자세히 보기',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF2D7A4F),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: Color(0xFF2D7A4F),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getActivityColor(HistoryType type) {
    switch (type) {
      case HistoryType.watering:
        return Colors.blue;
      case HistoryType.memo:
        return const Color(0xFF2D7A4F);
      case HistoryType.fertilizing:
        return Colors.green;
      case HistoryType.pruning:
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  Future<void> _navigateToNoteDetail(PlantHistory activity) async {
    // Firestore에서 실제 PlantNote 객체를 가져오기
    final notes = await _firestoreService.getPlantNotes(widget.plant.id);
    final note = notes.firstWhereOrNull((n) => n.id == activity.id);
    
    if (note != null) {
      final result = await Get.to(
        () => PlantNoteDetailScreen(
          note: note,
          plantId: widget.plant.id,
        ),
      );
      
      if (result == true) {
        _loadAllActivities(); // 변경사항 반영
      }
    }
  }
}
