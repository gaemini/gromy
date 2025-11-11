enum HistoryType {
  watering,
  fertilizing,
  pruning,
  repotting,
  pestControl,
  memo,
}

class PlantHistory {
  final String id;
  final String plantId;
  final HistoryType type;
  final DateTime timestamp;
  final String? content;
  final String? imageUrl;
  final double? value;

  PlantHistory({
    required this.id,
    required this.plantId,
    required this.type,
    required this.timestamp,
    this.content,
    this.imageUrl,
    this.value,
  });

  // HistoryType을 문자열로 변환
  static String _typeToString(HistoryType type) {
    return type.toString().split('.').last;
  }

  // 문자열을 HistoryType으로 변환
  static HistoryType _stringToType(String typeStr) {
    return HistoryType.values.firstWhere(
      (type) => type.toString().split('.').last == typeStr,
      orElse: () => HistoryType.memo,
    );
  }

  // 활동 타입별 아이콘 이모지 반환
  String get iconEmoji {
    switch (type) {
      case HistoryType.watering:
        return '💧';
      case HistoryType.fertilizing:
        return '🌱';
      case HistoryType.pruning:
        return '✂️';
      case HistoryType.repotting:
        return '🪴';
      case HistoryType.pestControl:
        return '🐛';
      case HistoryType.memo:
        return '📝';
    }
  }

  // 활동 타입별 이름 반환
  String get displayName {
    switch (type) {
      case HistoryType.watering:
        return '물주기';
      case HistoryType.fertilizing:
        return '영양제';
      case HistoryType.pruning:
        return '가지치기';
      case HistoryType.repotting:
        return '분갈이';
      case HistoryType.pestControl:
        return '병충해 방제';
      case HistoryType.memo:
        return '메모';
    }
  }

  // 시간 표시 (예: "5분 전", "오늘, 08:30")
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inDays < 1) {
      final hour = timestamp.hour.toString().padLeft(2, '0');
      final minute = timestamp.minute.toString().padLeft(2, '0');
      return '오늘, $hour:$minute';
    } else if (difference.inDays == 1) {
      return '어제';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${timestamp.month}월 ${timestamp.day}일';
    }
  }

  // JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plantId': plantId,
      'type': _typeToString(type),
      'timestamp': timestamp.toIso8601String(),
      'content': content,
      'imageUrl': imageUrl,
      'value': value,
    };
  }

  // JSON에서 객체 생성
  factory PlantHistory.fromJson(Map<String, dynamic> json) {
    return PlantHistory(
      id: json['id'] ?? '',
      plantId: json['plantId'] ?? '',
      type: _stringToType(json['type'] ?? 'memo'),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      content: json['content'],
      imageUrl: json['imageUrl'],
      value: json['value']?.toDouble(),
    );
  }

  // WateringRecord를 PlantHistory로 변환
  factory PlantHistory.fromWateringRecord({
    required String id,
    required String plantId,
    required DateTime timestamp,
  }) {
    return PlantHistory(
      id: id,
      plantId: plantId,
      type: HistoryType.watering,
      timestamp: timestamp,
      content: '물주기',
    );
  }

  // PlantNote를 PlantHistory로 변환
  factory PlantHistory.fromPlantNote({
    required String id,
    required String plantId,
    required DateTime timestamp,
    required String content,
    String? imageUrl,
  }) {
    return PlantHistory(
      id: id,
      plantId: plantId,
      type: HistoryType.memo,
      timestamp: timestamp,
      content: content,
      imageUrl: imageUrl,
    );
  }
}



