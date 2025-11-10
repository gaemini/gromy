import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/sun_time.dart';

class SunlightChart extends StatelessWidget {
  final List<DailySunTime> weeklyData;

  const SunlightChart({super.key, required this.weeklyData});

  @override
  Widget build(BuildContext context) {
    if (weeklyData.isEmpty) {
      return Container(
        height: 220,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Center(
          child: Text('데이터를 불러오는 중...'),
        ),
      );
    }

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '이번 주 일출/일몰',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text('일출', style: GoogleFonts.poppins(fontSize: 12)),
                  const SizedBox(width: 12),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.purple,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text('일몰', style: GoogleFonts.poppins(fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  // 일출 시간 (주황색)
                  LineChartBarData(
                    spots: weeklyData.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        entry.value.sunriseHour,
                      );
                    }).toList(),
                    color: Colors.orange,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: false),
                  ),
                  // 일몰 시간 (보라색)
                  LineChartBarData(
                    spots: weeklyData.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        entry.value.sunsetHour,
                      );
                    }).toList(),
                    color: Colors.purple,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < weeklyData.length) {
                          return Text(
                            weeklyData[value.toInt()].weekdayKorean,
                            style: GoogleFonts.poppins(fontSize: 12),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 2,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}시',
                          style: GoogleFonts.poppins(fontSize: 11),
                        );
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
                minY: 4, // 오전 4시
                maxY: 20, // 오후 8시
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 2,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[200]!,
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
}

