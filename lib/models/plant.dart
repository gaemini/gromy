class Plant {
  final String id;
  final String name;
  final String imageUrl;
  final List<String> imageUrls; // 여러 이미지 지원
  final bool isHealthy;
  final DateTime createdAt;
  final String userId;
  final DateTime? lastWatered;
  final int wateringIntervalDays;
  final String? note;

  Plant({
    required this.id,
    required this.name,
    required this.imageUrl,
    List<String>? imageUrls,
    required this.isHealthy,
    required this.createdAt,
    required this.userId,
    this.lastWatered,
    this.wateringIntervalDays = 7, // 기본 7일
    this.note,
  }) : imageUrls = imageUrls ?? [imageUrl]; // imageUrls가 없으면 imageUrl을 사용

  // 다음 물주기 날짜 계산
  DateTime? get nextWateringDate {
    if (lastWatered == null) return null;
    return lastWatered!.add(Duration(days: wateringIntervalDays));
  }

  // 물주기까지 남은 일수
  int? get daysUntilWatering {
    if (nextWateringDate == null) return null;
    return nextWateringDate!.difference(DateTime.now()).inDays;
  }

  // 마지막 물준 시간 표시
  String get lastWateredDisplay {
    if (lastWatered == null) return '아직 기록 없음';
    final days = DateTime.now().difference(lastWatered!).inDays;
    if (days == 0) return '오늘';
    return '$days일 전';
  }

  // JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'imageUrls': imageUrls,
      'isHealthy': isHealthy,
      'createdAt': createdAt.toIso8601String(),
      'userId': userId,
      'lastWatered': lastWatered?.toIso8601String(),
      'wateringIntervalDays': wateringIntervalDays,
      'note': note,
    };
  }

  // JSON에서 객체 생성
  factory Plant.fromJson(Map<String, dynamic> json) {
    final imageUrl = json['imageUrl'] ?? '';
    // imageUrls를 명시적으로 List<String>으로 변환
    final List<String> imageUrls;
    if (json['imageUrls'] != null) {
      // dynamic 리스트를 String 리스트로 안전하게 변환
      imageUrls = (json['imageUrls'] as List).map((e) => e.toString()).toList();
    } else {
      imageUrls = [imageUrl];
    }
    
    return Plant(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      imageUrl: imageUrl,
      imageUrls: imageUrls,
      isHealthy: json['isHealthy'] ?? true,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      userId: json['userId'] ?? '',
      lastWatered: json['lastWatered'] != null
          ? DateTime.parse(json['lastWatered'])
          : null,
      wateringIntervalDays: json['wateringIntervalDays'] ?? 7,
      note: json['note'],
    );
  }
}