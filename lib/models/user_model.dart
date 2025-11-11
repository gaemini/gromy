class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final String profileImageUrl;
  final String? bio;

  UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.profileImageUrl,
    this.bio,
  });

  // JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'bio': bio,
    };
  }

  // JSON에서 객체 생성
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      displayName: json['displayName'] ?? '',
      email: json['email'] ?? '',
      profileImageUrl: json['profileImageUrl'] ?? '',
      bio: json['bio'],
    );
  }
}

