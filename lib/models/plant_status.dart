class PlantStatus {
  final int? daysUntilWatering;
  final String? warningMessage;
  final String healthStatus;
  final double? healthScore;
  final DateTime? lastWatered;
  final DateTime? nextWateringDate;

  PlantStatus({
    this.daysUntilWatering,
    this.warningMessage,
    this.healthStatus = 'healthy',
    this.healthScore,
    this.lastWatered,
    this.nextWateringDate,
  });

  // 물주기 상태 텍스트
  String get wateringStatusText {
    if (daysUntilWatering == null) {
      return '물주기 정보 없음';
    }
    
    if (daysUntilWatering! < 0) {
      return '💧 물주기 필요! (${daysUntilWatering!.abs()}일 지남)';
    } else if (daysUntilWatering! == 0) {
      return '💧 오늘 물주기';
    } else {
      return '💧 물주기까지 D-${daysUntilWatering}';
    }
  }

  // 건강 상태 색상
  String get healthStatusColor {
    switch (healthStatus.toLowerCase()) {
      case 'excellent':
      case 'healthy':
        return 'green';
      case 'warning':
      case 'caution':
        return 'orange';
      case 'critical':
      case 'unhealthy':
        return 'red';
      default:
        return 'grey';
    }
  }

  // 건강 상태 텍스트
  String get healthStatusText {
    switch (healthStatus.toLowerCase()) {
      case 'excellent':
        return '매우 건강함';
      case 'healthy':
        return '건강함';
      case 'warning':
        return '주의 필요';
      case 'caution':
        return '관리 필요';
      case 'critical':
        return '위험';
      case 'unhealthy':
        return '건강하지 않음';
      default:
        return '상태 정보 없음';
    }
  }

  // 경고 메시지가 있는지 확인
  bool get hasWarning => warningMessage != null && warningMessage!.isNotEmpty;

  // JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'daysUntilWatering': daysUntilWatering,
      'warningMessage': warningMessage,
      'healthStatus': healthStatus,
      'healthScore': healthScore,
      'lastWatered': lastWatered?.toIso8601String(),
      'nextWateringDate': nextWateringDate?.toIso8601String(),
    };
  }

  // JSON에서 객체 생성
  factory PlantStatus.fromJson(Map<String, dynamic> json) {
    return PlantStatus(
      daysUntilWatering: json['daysUntilWatering'],
      warningMessage: json['warningMessage'],
      healthStatus: json['healthStatus'] ?? 'healthy',
      healthScore: json['healthScore']?.toDouble(),
      lastWatered: json['lastWatered'] != null
          ? DateTime.parse(json['lastWatered'])
          : null,
      nextWateringDate: json['nextWateringDate'] != null
          ? DateTime.parse(json['nextWateringDate'])
          : null,
    );
  }

  // 더미 데이터 생성 (테스트용)
  factory PlantStatus.generateDummy({
    int? daysUntil,
    String? warning,
    String status = 'healthy',
  }) {
    return PlantStatus(
      daysUntilWatering: daysUntil ?? 2,
      warningMessage: warning,
      healthStatus: status,
      healthScore: 85.0,
      lastWatered: DateTime.now().subtract(const Duration(days: 5)),
      nextWateringDate: DateTime.now().add(Duration(days: daysUntil ?? 2)),
    );
  }
}



