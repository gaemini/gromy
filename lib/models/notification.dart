import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId; // 알림을 받는 사용자 ID
  final String type; // 'like', 'comment', 'follow', 'challenge', 'watering'
  final String title;
  final String message;
  final String? actionUserId; // 액션을 한 사용자 ID
  final String? actionUserName; // 액션을 한 사용자 이름
  final String? actionUserImage; // 액션을 한 사용자 프로필 이미지
  final String? targetId; // 관련 게시물/식물/챌린지 ID
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.actionUserId,
    this.actionUserName,
    this.actionUserImage,
    this.targetId,
    this.isRead = false,
    required this.createdAt,
  });

  // JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'title': title,
      'message': message,
      'actionUserId': actionUserId,
      'actionUserName': actionUserName,
      'actionUserImage': actionUserImage,
      'targetId': targetId,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // JSON에서 객체 생성
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      actionUserId: json['actionUserId'],
      actionUserName: json['actionUserName'],
      actionUserImage: json['actionUserImage'],
      targetId: json['targetId'],
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  // 복사본 생성
  NotificationModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? message,
    String? actionUserId,
    String? actionUserName,
    String? actionUserImage,
    String? targetId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      actionUserId: actionUserId ?? this.actionUserId,
      actionUserName: actionUserName ?? this.actionUserName,
      actionUserImage: actionUserImage ?? this.actionUserImage,
      targetId: targetId ?? this.targetId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
