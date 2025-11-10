class PostLike {
  final String postId;
  final String userId;
  final DateTime timestamp;

  PostLike({
    required this.postId,
    required this.userId,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'postId': postId,
      'userId': userId,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory PostLike.fromJson(Map<String, dynamic> json) {
    return PostLike(
      postId: json['postId'] ?? '',
      userId: json['userId'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}

