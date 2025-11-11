import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../models/plant_note.dart';
import 'plant_note_card.dart';
import '../screens/plant_note_detail_screen.dart';
import '../screens/create_plant_note_screen.dart';
import '../services/firestore_service.dart';

class PlantNotesSection extends StatelessWidget {
  final String plantId;
  final List<PlantNote> notes;
  final VoidCallback? onRefresh;

  const PlantNotesSection({
    super.key,
    required this.plantId,
    required this.notes,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D7A4F).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.note_alt_outlined,
                      color: Color(0xFF2D7A4F),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '메모',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '${notes.length}개의 기록',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              // 메모 추가 버튼
              TextButton.icon(
                onPressed: () async {
                  final result = await Get.to(
                    () => CreatePlantNoteScreen(plantId: plantId),
                  );
                  if (result == true && onRefresh != null) {
                    onRefresh!();
                  }
                },
                icon: const Icon(
                  Icons.add,
                  size: 18,
                ),
                label: Text(
                  '메모 추가',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2D7A4F),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // 메모 리스트
          if (notes.isEmpty)
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.note_add_outlined,
                      size: 32,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '아직 메모가 없습니다',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '첫 번째 메모를 작성해보세요',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                // 최근 메모 3개만 표시
                ...notes.take(3).map((note) => PlantNoteCard(
                  note: note,
                  onTap: () async {
                    final result = await Get.to(
                      () => PlantNoteDetailScreen(
                        note: note,
                        plantId: plantId,
                      ),
                    );
                    if (result == true && onRefresh != null) {
                      onRefresh!();
                    }
                  },
                  onDelete: () => _showDeleteDialog(context, note),
                )).toList(),
                
                // 더 보기 버튼
                if (notes.length > 3)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    child: TextButton(
                      onPressed: () => _showAllNotes(context),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '모든 메모 보기 (${notes.length}개)',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: const Color(0xFF2D7A4F),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: Color(0xFF2D7A4F),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, PlantNote note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '메모 삭제',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          '이 메모를 삭제하시겠습니까?',
          style: GoogleFonts.poppins(
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '취소',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await FirestoreService().deletePlantNote(note.id);
              if (onRefresh != null) {
                onRefresh!();
              }
              Get.snackbar(
                '삭제 완료',
                '메모가 삭제되었습니다',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            child: Text(
              '삭제',
              style: GoogleFonts.poppins(
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAllNotes(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // 핸들 바
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // 헤더
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '모든 메모',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            
            // 메모 리스트
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  final note = notes[index];
                  return PlantNoteCard(
                    note: note,
                    onTap: () async {
                      Navigator.of(context).pop();
                      final result = await Get.to(
                        () => PlantNoteDetailScreen(
                          note: note,
                          plantId: plantId,
                        ),
                      );
                      if (result == true && onRefresh != null) {
                        onRefresh!();
                      }
                    },
                    onDelete: () {
                      Navigator.of(context).pop();
                      _showDeleteDialog(context, note);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
