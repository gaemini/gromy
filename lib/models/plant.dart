class Plant {
  final String id;
  final String name;
  final String imageUrl;
  final bool isHealthy;
  final DateTime createdAt;
  final String userId;

  Plant({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.isHealthy,
    required this.createdAt,
    required this.userId,
  });

  // JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'isHealthy': isHealthy,
      'createdAt': createdAt.toIso8601String(),
      'userId': userId,
    };
  }

  // JSON에서 객체 생성
  factory Plant.fromJson(Map<String, dynamic> json) {
    return Plant(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      isHealthy: json['isHealthy'] ?? false,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      userId: json['userId'] ?? '',
    );
  }
}

