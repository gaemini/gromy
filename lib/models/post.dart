class Post {
  final String id;
  final String userName;
  final String userId;
  final String userProfileImage;
  final String postImage;
  final String content;
  final List<String> hashtags;
  final int likes;
  final int comments;
  final DateTime timestamp;

  Post({
    required this.id,
    required this.userName,
    required this.userId,
    required this.userProfileImage,
    required this.postImage,
    required this.content,
    required this.hashtags,
    required this.likes,
    required this.comments,
    required this.timestamp,
  });

  // JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userName': userName,
      'userId': userId,
      'userProfileImage': userProfileImage,
      'postImage': postImage,
      'content': content,
      'hashtags': hashtags,
      'likes': likes,
      'comments': comments,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // JSON에서 객체 생성
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] ?? '',
      userName: json['userName'] ?? '',
      userId: json['userId'] ?? '',
      userProfileImage: json['userProfileImage'] ?? '',
      postImage: json['postImage'] ?? '',
      content: json['content'] ?? '',
      hashtags: List<String>.from(json['hashtags'] ?? []),
      likes: json['likes'] ?? 0,
      comments: json['comments'] ?? 0,
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
    );
  }
}

