import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/post.dart';
import '../models/comment.dart';
import '../services/firestore_service.dart';
import '../controllers/auth_controller.dart';
import '../controllers/community_controller.dart';
import 'edit_post_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final Post post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _commentController = TextEditingController();
  List<Comment> _comments = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _loadComments() {
    _firestoreService.getCommentsStream(widget.post.id).listen((comments) {
      setState(() {
        _comments = comments;
      });
    });
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final authController = Get.find<AuthController>();
      final user = authController.currentUser.value;

      if (user == null) {
        Get.snackbar('알림', '로그인이 필요합니다', snackPosition: SnackPosition.BOTTOM);
        return;
      }

      final comment = Comment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        postId: widget.post.id,
        userId: user.uid,
        userName: user.displayName,
        userProfileImage: user.profileImageUrl,
        content: _commentController.text.trim(),
        timestamp: DateTime.now(),
      );

      await _firestoreService.addComment(comment);
      _commentController.clear();
      
      Get.snackbar(
        '성공',
        '댓글이 작성되었습니다',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF2D7A4F),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        '오류',
        '댓글 작성에 실패했습니다',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showPostMenu() {
    final authController = Get.find<AuthController>();
    final isMyPost = widget.post.userId == authController.currentUserId;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.only(top: 20, bottom: 40),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: isMyPost
              ? [
                  // 내 게시물
                  _buildMenuTile(
                    icon: Icons.edit,
                    title: '수정하기',
                    onTap: () {
                      Get.back();
                      Get.to(
                        () => EditPostScreen(post: widget.post),
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
                      _deletePost();
                    },
                  ),
                ]
              : [
                  // 다른 사람 게시물
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

  void _deletePost() {
    Get.defaultDialog(
      title: '게시물 삭제',
      middleText: '이 게시물을 삭제하시겠습니까?',
      textConfirm: '삭제',
      textCancel: '취소',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () async {
        try {
          final communityController = Get.find<CommunityController>();
          await communityController.deletePost(widget.post.id);
          Get.back(); // 다이얼로그 닫기
          Get.back(); // 상세 화면 닫기
          Get.snackbar(
            '삭제 완료',
            '게시물이 삭제되었습니다',
            snackPosition: SnackPosition.BOTTOM,
          );
        } catch (e) {
          Get.back();
          Get.snackbar(
            '오류',
            '게시물 삭제에 실패했습니다',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: _showPostMenu,
          ),
        ],
      ),
      body: Column(
        children: [
          // 게시물 내용
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 16.0,
                bottom: 100.0, // 댓글 입력 바 공간 확보
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 프로필 정보
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: NetworkImage(widget.post.userProfileImage),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.post.userName,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _getTimeAgo(widget.post.timestamp),
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 게시물 내용
                  Text(
                    widget.post.content,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 해시태그
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.post.hashtags.map((tag) {
                      return Text(
                        tag,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF2D7A4F),
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // 게시물 이미지
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.post.postImage,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 좋아요/댓글 수
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          final controller = Get.find<CommunityController>();
                          controller.toggleLike(widget.post.id);
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.favorite, color: Colors.red, size: 24),
                            const SizedBox(width: 6),
                            Text(
                              '${widget.post.likes}',
                              style: GoogleFonts.poppins(fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Row(
                        children: [
                          const Icon(Icons.chat_bubble_outline, size: 24),
                          const SizedBox(width: 6),
                          Text(
                            '${_comments.length}',
                            style: GoogleFonts.poppins(fontSize: 15),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const Divider(height: 32),

                  // 댓글 제목
                  Text(
                    '댓글 ${_comments.length}개',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 댓글 목록
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _comments.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final comment = _comments[index];
                      return _buildCommentItem(comment);
                    },
                  ),
                ],
              ),
            ),
          ),

          // 댓글 입력 바
          Container(
            padding: EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 16.0,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: '댓글을 입력하세요...',
                        hintStyle: GoogleFonts.poppins(),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _isSubmitting
                      ? const SizedBox(
                          width: 40,
                          height: 40,
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          onPressed: _submitComment,
                          icon: const Icon(
                            Icons.send,
                            color: Color(0xFF2D7A4F),
                          ),
                          iconSize: 28,
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(Comment comment) {
    final authController = Get.find<AuthController>();
    final isMyComment = comment.userId == authController.currentUserId;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundImage: NetworkImage(comment.userProfileImage),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    comment.userName,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getTimeAgo(comment.timestamp),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                comment.content,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        if (isMyComment)
          IconButton(
            icon: const Icon(Icons.delete, size: 18, color: Colors.grey),
            onPressed: () {
              _deleteComment(comment);
            },
          ),
      ],
    );
  }

  void _deleteComment(Comment comment) {
    Get.defaultDialog(
      title: '댓글 삭제',
      middleText: '이 댓글을 삭제하시겠습니까?',
      textConfirm: '삭제',
      textCancel: '취소',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () async {
        try {
          await _firestoreService.deleteComment(widget.post.id, comment.id);
          Get.back();
          Get.snackbar(
            '삭제 완료',
            '댓글이 삭제되었습니다',
            snackPosition: SnackPosition.BOTTOM,
          );
        } catch (e) {
          Get.back();
          Get.snackbar(
            '오류',
            '댓글 삭제에 실패했습니다',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      },
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

  String _getTimeAgo(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${timestamp.year}.${timestamp.month}.${timestamp.day}';
    }
  }
}

