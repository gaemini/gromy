import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/community_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/notification_controller.dart';
import '../controllers/challenge_controller.dart';
import '../models/post.dart';
import '../models/advertisement.dart';
import '../models/challenge.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';
import 'search_screen.dart';
import 'edit_post_screen.dart';
import 'notifications_screen.dart';
import 'my_challenges_screen.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final CommunityController controller = Get.put(CommunityController());
    final NotificationController notificationController = Get.put(NotificationController());
    final ChallengeController challengeController = Get.put(ChallengeController());

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Gromy',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
        actions: [
          // 알림 아이콘
          Stack(
            children: [
              IconButton(
                icon: Icon(
                  Icons.notifications_outlined,
                  size: 26,
                  color: AppColors.gray700,
                ),
                onPressed: () {
                  Get.to(
                    () => const NotificationsScreen(),
                    transition: Transition.rightToLeft,
                  );
                },
              ),
              // 알림 배지
              Obx(() {
                if (notificationController.unreadCount.value > 0) {
                  return Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColors.heartRed,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        notificationController.unreadCount.value > 9
                            ? '9+'
                            : '${notificationController.unreadCount.value}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.white,
                          fontSize: 9,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
          // 검색 아이콘
          IconButton(
            icon: Icon(
              Icons.search_rounded,
              size: 26,
              color: AppColors.gray700,
            ),
            onPressed: () {
              Get.to(
                () => const SearchScreen(),
                transition: Transition.fadeIn,
              );
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          // Trending Challenges 섹션
          Container(
            color: AppColors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Text(
                    '인기 챌린지',
                    style: AppTextStyles.headlineSmall,
                  ),
                ),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: 3,
                    itemBuilder: (context, index) {
                      return _buildChallengeCard(index);
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          
          const Divider(height: 1, thickness: 0.5, color: AppColors.borderLight),
          
          // 피드 목록 (광고 포함)
          Obx(() => ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _calculateTotalItems(controller.posts.length),
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              thickness: 0.5,
              color: AppColors.borderLight,
            ),
            itemBuilder: (context, index) {
              // 3개 게시물마다 광고 삽입
              if ((index + 1) % 4 == 0 && controller.advertisements.isNotEmpty) {
                // 광고 위치 (4번째, 8번째, 12번째...)
                final adIndex = ((index + 1) ~/ 4 - 1) % controller.advertisements.length;
                return _buildAdvertisementItem(controller.advertisements[adIndex]);
              } else {
                // 실제 게시물 인덱스 계산
                final adjustedIndex = controller.advertisements.isNotEmpty 
                    ? index - (index ~/ 4)
                    : index;
                if (adjustedIndex < controller.posts.length) {
                  return _buildPostItem(controller.posts[adjustedIndex], controller);
                }
                return const SizedBox.shrink();
              }
            },
          )),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(
            () => const CreatePostScreen(),
            transition: Transition.downToUp,
          );
        },
        backgroundColor: AppColors.primaryGreen,
        child: const Icon(Icons.add_rounded, color: AppColors.white, size: 28),
      ),
    );
  }

  // 전체 아이템 수 계산 (게시물 + 광고)
  int _calculateTotalItems(int postCount) {
    if (postCount == 0) return 0;
    // 광고가 있을 때만 광고 슬롯 추가
    final controller = Get.find<CommunityController>();
    if (controller.advertisements.isEmpty) {
      return postCount;
    }
    // 3개마다 광고 1개 추가
    return postCount + (postCount ~/ 3);
  }

  // 챌린지 카드
  Widget _buildChallengeCard(int index) {
    final challengeController = Get.find<ChallengeController>();
    
    // 실제 챌린지 데이터 사용
    final allChallenges = Challenge.defaultChallenges;
    if (index >= allChallenges.length) return const SizedBox.shrink();
    
    final challenge = allChallenges[index];
    
    // 아이콘과 색상 매핑
    final iconData = {
      'water_drop': Icons.water_drop_rounded,
      'local_florist': Icons.local_florist_rounded,
      'eco': Icons.eco_rounded,
    }[challenge.icon] ?? Icons.emoji_events_rounded;
    
    final iconColor = {
      'water_drop': AppColors.primaryBlue,
      'local_florist': Colors.pink,
      'eco': AppColors.primaryGreen,
    }[challenge.icon] ?? AppColors.primaryGreen;
    
    // 참여자 수 가져오기
    final participantCount = challengeController.participantsCounts[challenge.id] ?? 0;
    final formattedCount = participantCount >= 1000 
        ? '${(participantCount / 1000).toStringAsFixed(1)}k' 
        : participantCount.toString();
    
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () {
          // 챌린지 참여 여부 확인
          if (challengeController.isParticipating(challenge.id)) {
            // 이미 참여 중이면 My Challenges 화면으로 이동
            Get.to(
              () => const MyChallengesScreen(),
              transition: Transition.rightToLeft,
            );
          } else {
            // 참여하지 않은 경우 참여 다이얼로그 표시
            _showChallengeJoinDialog(challenge);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.lightGreen,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  iconData,
                  color: iconColor,
                  size: 26,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                challenge.title.length > 10 
                    ? '${challenge.title.substring(0, 10)}...' 
                    : challenge.title,
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Obx(() {
                final currentCount = challengeController.participantsCounts[challenge.id] ?? 0;
                final formatted = currentCount >= 1000 
                    ? '${(currentCount / 1000).toStringAsFixed(1)}k' 
                    : currentCount.toString();
                return Text(
                  '$formatted 참여',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.gray600,
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // 광고 아이템 위젯
  Widget _buildAdvertisementItem(Advertisement ad) {
    return Container(
      color: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단: 광고주 정보
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.business,
                      size: 16,
                      color: AppColors.gray600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            ad.advertiser,
                            style: AppTextStyles.username,
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.gray100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '광고',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '후원',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz, size: 20),
                  onPressed: () {
                    Get.snackbar(
                      '광고',
                      '광고 숨기기 기능은 준비 중입니다',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          
          // 광고 이미지
          GestureDetector(
            onTap: () async {
              final Uri url = Uri.parse(ad.targetUrl);
              try {
                final bool launched = await launchUrl(
                  url, 
                  mode: LaunchMode.externalApplication,
                );
                if (!launched) {
                  // 첫 시도 실패 시 기본 모드로 재시도
                  await launchUrl(
                    url,
                    mode: LaunchMode.platformDefault,
                  );
                }
              } catch (e) {
                print('Error launching URL: $e');
                Get.snackbar(
                  '오류',
                  '링크를 열 수 없습니다: $e',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppColors.error,
                  colorText: AppColors.white,
                );
              }
            },
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: AppColors.gray50,
                child: ad.imageUrl.isNotEmpty
                    ? Image.network(
                        ad.imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildAdPlaceholder();
                        },
                      )
                    : _buildAdPlaceholder(),
              ),
            ),
          ),
          
          // 광고 정보
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ad.title,
                  style: AppTextStyles.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  ad.description,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                // CTA 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final Uri url = Uri.parse(ad.targetUrl);
                      try {
                        final bool launched = await launchUrl(
                          url, 
                          mode: LaunchMode.externalApplication,
                        );
                        if (!launched) {
                          // 첫 시도 실패 시 기본 모드로 재시도
                          await launchUrl(
                            url,
                            mode: LaunchMode.platformDefault,
                          );
                        }
                      } catch (e) {
                        print('Error launching URL: $e');
                        Get.snackbar(
                          '오류',
                          '링크를 열 수 없습니다: $e',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: AppColors.error,
                          colorText: AppColors.white,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      '자세히 알아보기',
                      style: AppTextStyles.button.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAdPlaceholder() {
    return Container(
      color: AppColors.gray100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.campaign_outlined,
              size: 48,
              color: AppColors.gray400,
            ),
            const SizedBox(height: 8),
            Text(
              '광고',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.gray400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 피드 아이템
  Widget _buildPostItem(Post post, CommunityController controller) {
    return GestureDetector(
      onTap: () {
        // 게시글 클릭 시 상세 페이지로 이동
        Get.to(
          () => PostDetailScreen(post: post),
          transition: Transition.rightToLeft,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.gray200,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단: 프로필 정보
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(post.userProfileImage),
                    backgroundColor: AppColors.gray200,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.userName,
                          style: AppTextStyles.titleSmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _getTimeAgo(post.timestamp),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.gray600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.more_vert, size: 20, color: AppColors.gray600),
                    onPressed: () => _showPostMenu(post, controller),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          
            
            // 이미지
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 200,
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                child: Image.network(
                  post.postImage,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.gray100,
                      child: Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          size: 50,
                          color: AppColors.gray400,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            
            // 내용
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.content,
                    style: AppTextStyles.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (post.hashtags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: post.hashtags.map((hashtag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.lightGreen,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            hashtag,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          
            // 액션 버튼
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppColors.gray200,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // 좋아요
                  InkWell(
                    onTap: () => controller.toggleLike(post.id),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Obx(() {
                            final isLiked = controller.isPostLiked(post.id);
                            return AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                isLiked ? Icons.favorite : Icons.favorite_outline,
                                key: ValueKey(isLiked),
                                size: 22,
                                color: isLiked ? AppColors.heartRed : AppColors.gray600,
                              ),
                            );
                          }),
                          const SizedBox(width: 4),
                          Obx(() {
                            final currentPost = controller.posts.firstWhere(
                              (p) => p.id == post.id,
                              orElse: () => post,
                            );
                            return Text(
                              '${currentPost.likes}',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.gray700,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 댓글
                  InkWell(
                    onTap: () {
                      Get.to(
                        () => PostDetailScreen(post: post),
                        transition: Transition.rightToLeft,
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 22,
                            color: AppColors.gray600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${post.comments}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.gray700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPostMenu(Post post, CommunityController controller) {
    final authController = Get.find<AuthController>();
    final isMyPost = post.userId == authController.currentUserId;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.only(top: 20, bottom: 40), // 하단 여백 추가
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: isMyPost
                ? [
                    _buildMenuTile(
                      icon: Icons.edit,
                      title: '수정하기',
                      onTap: () {
                        Get.back();
                        Get.to(
                          () => EditPostScreen(post: post),
                          transition: Transition.rightToLeft,
                        );
                      },
                    ),
                    _buildMenuTile(
                      icon: Icons.delete,
                      title: '삭제하기',
                      color: Colors.red,
                      onTap: () {
                        Get.back();
                        _deletePost(post, controller);
                      },
                    ),
                  ]
                : [
                    _buildMenuTile(
                      icon: Icons.report,
                      title: '신고하기',
                      color: Colors.red,
                      onTap: () {
                        Get.back();
                        Get.snackbar('신고', '신고 기능 준비중입니다',
                            snackPosition: SnackPosition.BOTTOM);
                      },
                    ),
                    _buildMenuTile(
                      icon: Icons.block,
                      title: '차단하기',
                      color: Colors.red,
                      onTap: () {
                        Get.back();
                        Get.snackbar('차단', '차단 기능 준비중입니다',
                            snackPosition: SnackPosition.BOTTOM);
                      },
                    ),
                  ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.black),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          color: color ?? Colors.black,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  void _deletePost(Post post, CommunityController controller) {
    Get.defaultDialog(
      title: '게시물 삭제',
      middleText: '이 게시물을 삭제하시겠습니까?\n삭제된 게시물은 복구할 수 없습니다.',
      textConfirm: '삭제',
      textCancel: '취소',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () async {
        try {
          // Firestore에서 게시물 삭제
          await controller.deletePost(post.id);
          Get.back(); // 다이얼로그 닫기
          Get.snackbar(
            '삭제 완료',
            '게시물이 삭제되었습니다',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFF2D7A4F),
            colorText: Colors.white,
          );
        } catch (e) {
          Get.back();
          Get.snackbar(
            '오류',
            '게시물 삭제에 실패했습니다: $e',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      },
    );
  }
  
  // 시간 표시 헬퍼 메서드
  String _getTimeAgo(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }
  
  // 하트 애니메이션 표시
  void _showHeartAnimation(String postId) {
    // 간단한 스낵바로 표시 (실제로는 오버레이 애니메이션 구현 가능)
    Get.showSnackbar(
      GetSnackBar(
        message: '❤️',
        duration: const Duration(milliseconds: 500),
        backgroundColor: Colors.transparent,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.only(top: 100),
      ),
    );
  }

  // 챌린지 참여 다이얼로그
  void _showChallengeJoinDialog(Challenge challenge) {
    final challengeController = Get.find<ChallengeController>();
    
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.lightGreen,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                _getChallengeIcon(challenge.icon),
                color: _getChallengeColor(challenge.icon),
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              challenge.title,
              style: AppTextStyles.titleLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              challenge.description,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildChallengeInfo(
                    '목표 기간',
                    '${challenge.targetDays}일',
                    Icons.calendar_today_outlined,
                  ),
                  const SizedBox(height: 8),
                  _buildChallengeInfo(
                    '목표 횟수',
                    '${challenge.requiredWatering}회',
                    Icons.water_drop_outlined,
                  ),
                  const SizedBox(height: 8),
                  _buildChallengeInfo(
                    '난이도',
                    _getDifficultyText(challenge.difficulty),
                    Icons.signal_cellular_alt,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              '취소',
              style: AppTextStyles.button.copyWith(
                color: AppColors.gray600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await challengeController.joinChallenge(challenge.id);
              // 참여 후 My Challenges 화면으로 이동
              Get.to(
                () => const MyChallengesScreen(),
                transition: Transition.rightToLeft,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              '참여하기',
              style: AppTextStyles.button.copyWith(
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeInfo(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.gray600),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.gray600,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  IconData _getChallengeIcon(String icon) {
    return {
      'water_drop': Icons.water_drop_rounded,
      'local_florist': Icons.local_florist_rounded,
      'eco': Icons.eco_rounded,
    }[icon] ?? Icons.emoji_events_rounded;
  }

  Color _getChallengeColor(String icon) {
    return {
      'water_drop': AppColors.primaryBlue,
      'local_florist': Colors.pink,
      'eco': AppColors.primaryGreen,
    }[icon] ?? AppColors.primaryGreen;
  }

  String _getDifficultyText(String difficulty) {
    return {
      'easy': '쉬움',
      'medium': '보통',
      'hard': '어려움',
    }[difficulty] ?? '보통';
  }
}

