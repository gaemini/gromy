class PlantNote {
  final String id;
  final String plantId;
  final String content;
  final DateTime timestamp;
  final String? imageUrl;

  PlantNote({
    required this.id,
    required this.plantId,
    required this.content,
    required this.timestamp,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plantId': plantId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'imageUrl': imageUrl,
    };
  }

  factory PlantNote.fromJson(Map<String, dynamic> json) {
    return PlantNote(
      id: json['id'] ?? '',
      plantId: json['plantId'] ?? '',
      content: json['content'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      imageUrl: json['imageUrl'],
    );
  }

  // 시간 표시 (예: "5분 전", "3일 전")
  String get timeAgo {
    final difference = DateTime.now().difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}주 전';
    } else {
      return '${timestamp.month}월 ${timestamp.day}일';
    }
  }
}


