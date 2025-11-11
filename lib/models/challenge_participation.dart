class ChallengeParticipation {
  final String id; // userId_challengeId
  final String userId;
  final String challengeId;
  final DateTime startDate;
  final List<DateTime> completedDays; // 물을 준 날짜 기록
  final bool isActive;
  final DateTime? lastUpdated;

  ChallengeParticipation({
    required this.id,
    required this.userId,
    required this.challengeId,
    required this.startDate,
    required this.completedDays,
    required this.isActive,
    this.lastUpdated,
  });

  // 진행률 계산 (0.0 ~ 1.0)
  double getProgress(int requiredWatering) {
    // 0으로 나누기 방지
    if (requiredWatering <= 0) {
      print('⚠️ Warning: requiredWatering is $requiredWatering, returning 0.0');
      return 0.0;
    }
    final completed = completedDays.length;
    final progress = completed / requiredWatering;
    return progress.clamp(0.0, 1.0);
  }

  // 남은 일수 계산
  int getDaysRemaining(int targetDays) {
    final daysPassed = DateTime.now().difference(startDate).inDays;
    final remaining = targetDays - daysPassed;
    return remaining > 0 ? remaining : 0;
  }

  // 오늘 물을 줬는지 확인
  bool hasWateredToday() {
    final today = DateTime.now();
    return completedDays.any((date) =>
        date.year == today.year &&
        date.month == today.month &&
        date.day == today.day);
  }

  // 연속 일수 계산
  int getStreakDays() {
    if (completedDays.isEmpty) return 0;
    
    // 날짜를 정렬 (최신순)
    final sortedDays = List<DateTime>.from(completedDays)
      ..sort((a, b) => b.compareTo(a));
    
    int streak = 0;
    DateTime checkDate = DateTime.now();
    
    for (final date in sortedDays) {
      // 날짜만 비교 (시간 제외)
      final dateOnly = DateTime(date.year, date.month, date.day);
      final checkDateOnly = DateTime(checkDate.year, checkDate.month, checkDate.day);
      
      if (dateOnly == checkDateOnly || 
          dateOnly == checkDateOnly.subtract(const Duration(days: 1))) {
        streak++;
        checkDate = date;
      } else {
        break;
      }
    }
    
    return streak;
  }

  // JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'challengeId': challengeId,
      'startDate': startDate.toIso8601String(),
      'completedDays': completedDays.map((d) => d.toIso8601String()).toList(),
      'isActive': isActive,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  // JSON에서 객체 생성
  factory ChallengeParticipation.fromJson(Map<String, dynamic> json) {
    return ChallengeParticipation(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      challengeId: json['challengeId'] ?? '',
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : DateTime.now(),
      completedDays: (json['completedDays'] as List<dynamic>?)
              ?.map((d) => DateTime.parse(d as String))
              .toList() ??
          [],
      isActive: json['isActive'] ?? true,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : null,
    );
  }

  // 복사본 생성 (업데이트용)
  ChallengeParticipation copyWith({
    String? id,
    String? userId,
    String? challengeId,
    DateTime? startDate,
    List<DateTime>? completedDays,
    bool? isActive,
    DateTime? lastUpdated,
  }) {
    return ChallengeParticipation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      challengeId: challengeId ?? this.challengeId,
      startDate: startDate ?? this.startDate,
      completedDays: completedDays ?? this.completedDays,
      isActive: isActive ?? this.isActive,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
