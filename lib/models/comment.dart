class Comment {
  final String id;
  final String postId;
  final String userId;
  final String userName;
  final String userProfileImage;
  final String content;
  final DateTime timestamp;

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    required this.userProfileImage,
    required this.content,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'userId': userId,
      'userName': userName,
      'userProfileImage': userProfileImage,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? '',
      postId: json['postId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userProfileImage: json['userProfileImage'] ?? '',
      content: json['content'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}

