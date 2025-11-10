import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/watering_record.dart';

class WateringChart extends StatelessWidget {
  final List<WateringRecord> records;

  const WateringChart({super.key, required this.records});

  @override
  Widget build(BuildContext context) {
    final weekData = _groupByWeekday(records);
    final maxCount = weekData.values.reduce((a, b) => a > b ? a : b);

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '이번 주 물주기',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (maxCount + 1).toDouble(),
                barGroups: List.generate(7, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: weekData[index]?.toDouble() ?? 0,
                        color: const Color(0xFF2D7A4F),
                        width: 24,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
                        if (value.toInt() >= 0 && value.toInt() < 7) {
                          return Text(
                            weekdays[value.toInt()],
                            style: GoogleFonts.poppins(fontSize: 12),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[300]!,
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 요일별 물준 횟수 계산 (월요일=0)
  Map<int, int> _groupByWeekday(List<WateringRecord> records) {
    final startOfWeek = _getStartOfWeek(DateTime.now());
    final Map<int, int> counts = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0};

    for (var record in records) {
      // 이번 주 데이터만
      if (record.timestamp.isAfter(startOfWeek)) {
        final weekdayIndex = (record.timestamp.weekday - 1) % 7; // 월요일=0
        counts[weekdayIndex] = (counts[weekdayIndex] ?? 0) + 1;
      }
    }
    return counts;
  }

  DateTime _getStartOfWeek(DateTime date) {
    final weekday = date.weekday;
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: weekday - 1));
  }
}

