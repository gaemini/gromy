class Challenge {
  final String id;
  final String title;
  final String description;
  final int targetDays; // 목표 일수
  final int requiredWatering; // 필요한 물주기 횟수
  final String icon; // 아이콘 타입
  final String difficulty; // easy, medium, hard

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.targetDays,
    required this.requiredWatering,
    required this.icon,
    required this.difficulty,
  });

  // JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'targetDays': targetDays,
      'requiredWatering': requiredWatering,
      'icon': icon,
      'difficulty': difficulty,
    };
  }

  // JSON에서 객체 생성
  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      targetDays: json['targetDays'] ?? 30,
      requiredWatering: json['requiredWatering'] ?? 30,
      icon: json['icon'] ?? 'emoji_events',
      difficulty: json['difficulty'] ?? 'medium',
    );
  }

  // 하드코딩된 챌린지 목록
  static List<Challenge> get defaultChallenges => [
    Challenge(
      id: 'watering_30days',
      title: '30-Day Watering Challenge',
      description: '30일 동안 매일 식물에 물을 주세요',
      targetDays: 30,
      requiredWatering: 30,
      icon: 'water_drop',
      difficulty: 'hard',
    ),
    Challenge(
      id: 'first_bloom',
      title: 'First Bloom Challenge',
      description: '15일 연속으로 식물 관리하기',
      targetDays: 15,
      requiredWatering: 15,
      icon: 'local_florist',
      difficulty: 'medium',
    ),
    Challenge(
      id: 'green_thumb_month',
      title: 'Green Thumb Month',
      description: '한 달간 주 3회 이상 물주기',
      targetDays: 30,
      requiredWatering: 12, // 4주 x 3회
      icon: 'eco',
      difficulty: 'easy',
    ),
  ];

  // 챌린지 ID로 찾기
  static Challenge? findById(String id) {
    try {
      return defaultChallenges.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }
}
