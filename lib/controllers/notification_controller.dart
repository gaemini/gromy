import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification.dart';
import '../services/firestore_service.dart';

class NotificationController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  
  // 알림 목록
  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxInt unreadCount = 0.obs;
  
  @override
  void onInit() {
    super.onInit();
    loadNotifications();
  }
  
  // 알림 로드
  Future<void> loadNotifications() async {
    try {
      isLoading.value = true;
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      // Firestore에서 알림 가져오기
      _firestoreService.getNotificationsStream(user.uid).listen((notificationList) {
        notifications.value = notificationList;
        // 읽지 않은 알림 개수 계산
        unreadCount.value = notificationList.where((n) => !n.isRead).length;
        print('✅ ${notificationList.length} notifications loaded');
      });
    } catch (e) {
      print('❌ Error loading notifications: $e');
      // 오류 발생 시 더미 데이터
      _loadDummyNotifications();
    } finally {
      isLoading.value = false;
    }
  }
  
  // 더미 알림 데이터
  void _loadDummyNotifications() {
    notifications.value = [
      NotificationModel(
        id: '1',
        userId: 'current_user',
        type: 'like',
        title: '좋아요',
        message: 'Sarah Green님이 회원님의 게시물을 좋아합니다.',
        actionUserId: 'user1',
        actionUserName: 'Sarah Green',
        actionUserImage: 'https://i.pravatar.cc/150?img=1',
        targetId: 'post1',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      NotificationModel(
        id: '2',
        userId: 'current_user',
        type: 'comment',
        title: '댓글',
        message: 'John Plant님이 댓글을 남겼습니다: "멋진 식물이네요!"',
        actionUserId: 'user2',
        actionUserName: 'John Plant',
        actionUserImage: 'https://i.pravatar.cc/150?img=2',
        targetId: 'post1',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      NotificationModel(
        id: '3',
        userId: 'current_user',
        type: 'challenge',
        title: '챌린지 완료',
        message: '30일 물주기 챌린지를 완료했습니다! 🎉',
        targetId: 'challenge1',
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      NotificationModel(
        id: '4',
        userId: 'current_user',
        type: 'watering',
        title: '물주기 알림',
        message: '토마토에 물을 줄 시간입니다.',
        targetId: 'plant1',
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
    unreadCount.value = notifications.where((n) => !n.isRead).length;
  }
  
  // 알림을 읽음으로 표시
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestoreService.markNotificationAsRead(notificationId);
      
      // 로컬 상태 업데이트
      final index = notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        notifications[index] = notifications[index].copyWith(isRead: true);
        unreadCount.value = notifications.where((n) => !n.isRead).length;
      }
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }
  
  // 모든 알림을 읽음으로 표시
  Future<void> markAllAsRead() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      await _firestoreService.markAllNotificationsAsRead(user.uid);
      
      // 로컬 상태 업데이트
      for (int i = 0; i < notifications.length; i++) {
        notifications[i] = notifications[i].copyWith(isRead: true);
      }
      unreadCount.value = 0;
    } catch (e) {
      print('❌ Error marking all notifications as read: $e');
    }
  }
  
  // 알림 삭제
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestoreService.deleteNotification(notificationId);
      
      // 로컬 상태에서 제거
      notifications.removeWhere((n) => n.id == notificationId);
      unreadCount.value = notifications.where((n) => !n.isRead).length;
    } catch (e) {
      print('❌ Error deleting notification: $e');
    }
  }
  
  // 알림 생성 (다른 컨트롤러에서 호출)
  Future<void> createNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    String? actionUserId,
    String? actionUserName,
    String? actionUserImage,
    String? targetId,
  }) async {
    try {
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        type: type,
        title: title,
        message: message,
        actionUserId: actionUserId,
        actionUserName: actionUserName,
        actionUserImage: actionUserImage,
        targetId: targetId,
        isRead: false,
        createdAt: DateTime.now(),
      );
      
      await _firestoreService.createNotification(notification);
    } catch (e) {
      print('❌ Error creating notification: $e');
    }
  }
}
