import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../models/sun_time.dart';

class WeatherService {
  // Sunrise Sunset API - 완전 무료, API 키 불필요!
  static const String _baseUrl = 'https://api.sunrise-sunset.org/json';
  
  DateTime? _lastFetchTime;
  List<DailySunTime>? _cachedWeeklyData;

  // 현재 위치 가져오기
  Future<Position> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('위치 서비스가 비활성화되어 있습니다');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('위치 권한이 거부되었습니다');
        }
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
    } catch (e) {
      print('❌ Error getting location: $e');
      // 기본 위치 (서울) 반환
      return Position(
        latitude: 37.5665,
        longitude: 126.9780,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    }
  }

  // 오늘 일출/일몰 시간
  Future<SunTime> getTodaySunTime() async {
    try {
      final position = await _getCurrentLocation();

      final url = '$_baseUrl'
          '?lat=${position.latitude}'
          '&lon=${position.longitude}'
          '&formatted=0'; // ISO 8601 형식

      print('📡 Calling Sunrise API: $url');
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          final sunrise = DateTime.parse(data['results']['sunrise']).toLocal();
          final sunset = DateTime.parse(data['results']['sunset']).toLocal();
          
          print('✅ Sunrise: ${sunrise.hour}:${sunrise.minute}');
          print('✅ Sunset: ${sunset.hour}:${sunset.minute}');

          return SunTime(sunrise: sunrise, sunset: sunset);
        } else {
          throw Exception('API 응답 오류');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error getting sun time: $e');
      // 더미 데이터 반환
      return _getDummySunTime();
    }
  }

  // 이번 주 월요일 기준 7일 일출/일몰
  Future<List<DailySunTime>> getWeeklySunTimes() async {
    try {
      // 캐시 확인
      if (_cachedWeeklyData != null && _lastFetchTime != null) {
        if (!_shouldUpdateWeeklyData(_lastFetchTime!)) {
          print('✅ Using cached weekly sun times');
          return _cachedWeeklyData!;
        }
      }

      print('📡 Fetching fresh weekly sun times...');
      
      final weeklyData = await _fetchWeeklySunTimesFromAPI();
      
      // 데이터가 비어있으면 더미 사용
      if (weeklyData.isEmpty) {
        print('⚠️ No data fetched, using dummy data');
        return _getDummyWeeklySunTimes();
      }
      
      _cachedWeeklyData = weeklyData;
      _lastFetchTime = DateTime.now();
      
      return weeklyData;
    } catch (e) {
      print('❌ Error getting weekly sun times: $e');
      return _getDummyWeeklySunTimes();
    }
  }

  Future<List<DailySunTime>> _fetchWeeklySunTimesFromAPI() async {
    final position = await _getCurrentLocation();
    final startOfWeek = _getStartOfWeek(DateTime.now());
    
    List<DailySunTime> weeklyData = [];

    print('📡 Fetching weekly sun times for 7 days...');

    // 월요일부터 일요일까지 7일치 데이터 가져오기
    for (int i = 0; i < 7; i++) {
      final targetDate = startOfWeek.add(Duration(days: i));
      
      try {
        final dateStr = targetDate.toIso8601String().split('T')[0]; // YYYY-MM-DD
        final url = '$_baseUrl'
            '?lat=${position.latitude}'
            '&lon=${position.longitude}'
            '&date=$dateStr'
            '&formatted=0';
        
        final response = await http.get(Uri.parse(url));
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          
          if (data['status'] == 'OK') {
            final sunrise = DateTime.parse(data['results']['sunrise']).toLocal();
            final sunset = DateTime.parse(data['results']['sunset']).toLocal();
            
            weeklyData.add(DailySunTime(
              date: targetDate,
              sunrise: sunrise,
              sunset: sunset,
            ));
          }
        }
        
        // API 부담 줄이기 (100ms 대기)
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        print('❌ Error fetching day $i: $e');
        // 오류 발생 시 더미 데이터로 대체
        weeklyData.add(_getDummyDailySunTime(targetDate));
      }
    }

    print('✅ Fetched ${weeklyData.length} days of sun times');
    return weeklyData;
  }

  // 더미 일별 데이터
  DailySunTime _getDummyDailySunTime(DateTime date) {
    return DailySunTime(
      date: date,
      sunrise: DateTime(date.year, date.month, date.day, 6, 30),
      sunset: DateTime(date.year, date.month, date.day, 17, 45),
    );
  }

  // 월요일 기준 주의 시작일 계산
  DateTime _getStartOfWeek(DateTime date) {
    final weekday = date.weekday; // 1=월요일, 7=일요일
    final monday = date.subtract(Duration(days: weekday - 1));
    return DateTime(monday.year, monday.month, monday.day);
  }

  // 다음 주 월요일인지 확인
  bool _shouldUpdateWeeklyData(DateTime lastUpdate) {
    final currentMonday = _getStartOfWeek(DateTime.now());
    final lastUpdateMonday = _getStartOfWeek(lastUpdate);
    return currentMonday.isAfter(lastUpdateMonday);
  }

  // 더미 일출/일몰 데이터 (API 실패 시)
  SunTime _getDummySunTime() {
    final now = DateTime.now();
    return SunTime(
      sunrise: DateTime(now.year, now.month, now.day, 6, 30), // 오전 6:30
      sunset: DateTime(now.year, now.month, now.day, 17, 45), // 오후 5:45
    );
  }

  // 더미 일주일 데이터
  List<DailySunTime> _getDummyWeeklySunTimes() {
    final startOfWeek = _getStartOfWeek(DateTime.now());
    
    print('⚠️ Using dummy weekly sun times (API failed or no permission)');
    
    return List.generate(7, (index) {
      final date = startOfWeek.add(Duration(days: index));
      // 11월 기준 실제 같은 시간
      final sunriseMinute = 30 + (index * 2); // 6:30 ~ 6:42
      final sunsetMinute = 15 + (index * 3);  // 17:15 ~ 17:33
      
      return DailySunTime(
        date: date,
        sunrise: DateTime(date.year, date.month, date.day, 6, sunriseMinute),
        sunset: DateTime(date.year, date.month, date.day, 17, sunsetMinute),
      );
    });
  }
}

