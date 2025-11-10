import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/community_controller.dart';
import '../controllers/auth_controller.dart';
import '../models/post.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';
import 'search_screen.dart';
import 'edit_post_screen.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final CommunityController controller = Get.put(CommunityController());

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
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trending Challenges',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                _buildChallengeItem(),
              ],
            ),
          ),
          
          const Divider(height: 1, thickness: 1),
          
          // 피드 목록
          Obx(() => ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.posts.length,
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              thickness: 1,
              color: Colors.grey,
            ),
            itemBuilder: (context, index) {
              final post = controller.posts[index];
              return _buildPostItem(post, controller);
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
        backgroundColor: const Color(0xFF2D7A4F),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // 챌린지 아이템
  Widget _buildChallengeItem() {
    return InkWell(
      onTap: () {
        Get.snackbar(
          'Challenge',
          '30-Day Watering Challenge',
          snackPosition: SnackPosition.BOTTOM,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF2D7A4F).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFC8E6C9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events,
                color: Color(0xFF2D7A4F),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '30-Day Watering Challenge',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '14k participants',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[600],
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  // 피드 아이템
  Widget _buildPostItem(Post post, CommunityController controller) {
    // 경과 시간 계산
    String getTimeAgo(DateTime timestamp) {
      final difference = DateTime.now().difference(timestamp);
      if (difference.inHours < 1) {
        return '${difference.inMinutes}m';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h';
      } else {
        return '${difference.inDays}d';
      }
    }

    return GestureDetector(
      onTap: () {
        Get.to(
          () => PostDetailScreen(post: post),
          transition: Transition.rightToLeft,
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단: 프로필 이미지 + 이름 + 시간
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(post.userProfileImage),
                backgroundColor: Colors.grey[300],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.userName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      getTimeAgo(post.timestamp),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_horiz),
                onPressed: () => _showPostMenu(post, controller),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // 중간: 게시물 내용 + 해시태그
          Text(
            post.content,
            style: const TextStyle(
              fontSize: 15,
              height: 1.4,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Wrap(
            spacing: 8,
            children: post.hashtags.map((hashtag) {
                  return Text(
                    hashtag,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF2D7A4F),
                      fontWeight: FontWeight.w500,
                    ),
                  );
            }).toList(),
          ),
          
          const SizedBox(height: 12),
          
          // 이미지: 둥근 모서리
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              post.postImage,
              width: double.infinity,
              height: 300,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 300,
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      size: 50,
                      color: Colors.grey,
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 12),
          
          // 하단: 좋아요 + 댓글
          Row(
            children: [
              InkWell(
                onTap: () => controller.toggleLike(post.id),
                child: Row(
                  children: [
                    const Icon(
                      Icons.favorite,
                      size: 24,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${post.likes}',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              InkWell(
                onTap: () {
                  Get.snackbar(
                    'Comments',
                    'Comments feature coming soon!',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
                child: Row(
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline,
                      size: 24,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${post.comments}',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
}

