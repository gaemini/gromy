class SunTime {
  final DateTime sunrise;
  final DateTime sunset;

  SunTime({required this.sunrise, required this.sunset});

  // 일조 시간 계산
  Duration get daylightDuration => sunset.difference(sunrise);

  // 시간으로 표시
  String get daylightHours {
    final hours = daylightDuration.inHours;
    final minutes = daylightDuration.inMinutes % 60;
    return '$hours시간 $minutes분';
  }

  // 일출 시간 포맷
  String get sunriseTime {
    final hour = sunrise.hour;
    final minute = sunrise.minute.toString().padLeft(2, '0');
    return hour < 12 ? '오전 $hour:$minute' : '오후 ${hour - 12}:$minute';
  }

  // 일몰 시간 포맷
  String get sunsetTime {
    final hour = sunset.hour;
    final minute = sunset.minute.toString().padLeft(2, '0');
    return hour < 12 ? '오전 $hour:$minute' : '오후 ${hour - 12}:$minute';
  }
}

class DailySunTime {
  final DateTime date;
  final DateTime sunrise;
  final DateTime sunset;

  DailySunTime({
    required this.date,
    required this.sunrise,
    required this.sunset,
  });

  // 요일 한글 (월, 화, 수...)
  String get weekdayKorean {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return weekdays[(date.weekday - 1) % 7];
  }

  SunTime get sunTime => SunTime(sunrise: sunrise, sunset: sunset);
  
  // 일출 시간 (시.분 형식, 그래프용)
  double get sunriseHour => sunrise.hour + sunrise.minute / 60.0;
  
  // 일몰 시간 (시.분 형식, 그래프용)
  double get sunsetHour => sunset.hour + sunset.minute / 60.0;
}

