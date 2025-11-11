import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/notification_controller.dart';
import '../models/notification.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final NotificationController controller = Get.put(NotificationController());
    
    return Scaffold(
      appBar: AppBar(
        title: Text('알림', style: AppTextStyles.appBarTitle),
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.black),
          onPressed: () => Get.back(),
        ),
        actions: [
          TextButton(
            onPressed: controller.notifications.isEmpty
                ? null
                : () => controller.markAllAsRead(),
            child: Text(
              '모두 읽음',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.primaryBlue,
              ),
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        if (controller.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_none_rounded,
                  size: 80,
                  color: AppColors.gray300,
                ),
                const SizedBox(height: 16),
                Text(
                  '알림이 없습니다',
                  style: AppTextStyles.emptyStateTitle,
                ),
                const SizedBox(height: 8),
                Text(
                  '새로운 활동이 있으면 여기에 표시됩니다',
                  style: AppTextStyles.emptyStateSubtitle,
                ),
              ],
            ),
          );
        }
        
        return RefreshIndicator(
          onRefresh: controller.loadNotifications,
          child: ListView.separated(
            itemCount: controller.notifications.length,
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              thickness: 1,
              color: AppColors.borderLight,
            ),
            itemBuilder: (context, index) {
              final notification = controller.notifications[index];
              return _buildNotificationItem(notification, controller);
            },
          ),
        );
      }),
    );
  }
  
  Widget _buildNotificationItem(
    NotificationModel notification,
    NotificationController controller,
  ) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppColors.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete_outline,
          color: AppColors.white,
          size: 24,
        ),
      ),
      onDismissed: (direction) {
        controller.deleteNotification(notification.id);
      },
      child: InkWell(
        onTap: () {
          if (!notification.isRead) {
            controller.markAsRead(notification.id);
          }
          // TODO: 알림 타입에 따라 해당 화면으로 이동
          _handleNotificationTap(notification);
        },
        child: Container(
          color: notification.isRead ? AppColors.white : AppColors.gray50,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 프로필 이미지 또는 아이콘
              _buildNotificationIcon(notification),
              const SizedBox(width: 12),
              
              // 알림 내용
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목
                    if (notification.actionUserName != null) ...[
                      RichText(
                        text: TextSpan(
                          style: AppTextStyles.bodyMedium,
                          children: [
                            TextSpan(
                              text: notification.actionUserName,
                              style: AppTextStyles.username,
                            ),
                            TextSpan(
                              text: _getActionText(notification.type),
                              style: AppTextStyles.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Text(
                        notification.title,
                        style: AppTextStyles.titleSmall,
                      ),
                    ],
                    const SizedBox(height: 4),
                    
                    // 메시지
                    Text(
                      notification.message,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    // 시간
                    Text(
                      _getTimeAgo(notification.createdAt),
                      style: AppTextStyles.timestamp,
                    ),
                  ],
                ),
              ),
              
              // 읽지 않은 알림 표시
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(left: 8, top: 6),
                  decoration: const BoxDecoration(
                    color: AppColors.notificationBadge,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildNotificationIcon(NotificationModel notification) {
    if (notification.actionUserImage != null) {
      return CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage(notification.actionUserImage!),
        backgroundColor: AppColors.gray200,
      );
    }
    
    IconData iconData;
    Color iconColor;
    
    switch (notification.type) {
      case 'like':
        iconData = Icons.favorite;
        iconColor = AppColors.heartRed;
        break;
      case 'comment':
        iconData = Icons.chat_bubble;
        iconColor = AppColors.primaryBlue;
        break;
      case 'follow':
        iconData = Icons.person_add;
        iconColor = AppColors.primaryBlue;
        break;
      case 'challenge':
        iconData = Icons.emoji_events;
        iconColor = Colors.amber;
        break;
      case 'watering':
        iconData = Icons.water_drop;
        iconColor = Colors.blue;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = AppColors.gray600;
    }
    
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }
  
  String _getActionText(String type) {
    switch (type) {
      case 'like':
        return '님이 회원님의 게시물을 좋아합니다';
      case 'comment':
        return '님이 댓글을 남겼습니다';
      case 'follow':
        return '님이 회원님을 팔로우하기 시작했습니다';
      default:
        return '';
    }
  }
  
  String _getTimeAgo(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return '방금';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}주 전';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}개월 전';
    } else {
      return '${(difference.inDays / 365).floor()}년 전';
    }
  }
  
  void _handleNotificationTap(NotificationModel notification) {
    // TODO: 알림 타입에 따라 적절한 화면으로 이동
    switch (notification.type) {
      case 'like':
      case 'comment':
        // 게시물 상세 화면으로 이동
        if (notification.targetId != null) {
          // Get.to(() => PostDetailScreen(postId: notification.targetId!));
        }
        break;
      case 'follow':
        // 프로필 화면으로 이동
        if (notification.actionUserId != null) {
          // Get.to(() => UserProfileScreen(userId: notification.actionUserId!));
        }
        break;
      case 'challenge':
        // 챌린지 화면으로 이동
        // Get.to(() => MyChallengesScreen());
        break;
      case 'watering':
        // 식물 상세 화면으로 이동
        if (notification.targetId != null) {
          // Get.to(() => PlantDetailScreen(plantId: notification.targetId!));
        }
        break;
    }
  }
}
