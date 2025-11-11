import 'dart:io';
import 'package:get/get.dart';
import '../models/post.dart';
import '../models/advertisement.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../controllers/auth_controller.dart';
import '../controllers/notification_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommunityController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  
  // 게시물 목록
  final RxList<Post> posts = <Post>[].obs;
  final RxBool isLoading = false.obs;
  
  // 좋아요 상태 추적 (postId -> bool)
  final RxMap<String, bool> likedPosts = <String, bool>{}.obs;
  
  // 광고 목록
  final List<Advertisement> advertisements = Advertisement.defaultAds;

  @override
  void onInit() {
    super.onInit();
    loadPosts();
    loadLikedPosts();
  }
  
  // 현재 사용자가 좋아요한 게시물 로드
  Future<void> loadLikedPosts() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    try {
      for (final post in posts) {
        final hasLiked = await _firestoreService.hasUserLikedPost(post.id, currentUser.uid);
        likedPosts[post.id] = hasLiked;
      }
    } catch (e) {
      print('❌ Error loading liked posts: $e');
    }
  }

  // Firestore에서 게시물 로드
  Future<void> loadPosts() async {
    try {
      isLoading.value = true;
      
      // Firestore 실시간 스트림으로 게시물 가져오기
      _firestoreService.getPostsStream().listen((postList) {
        posts.value = postList;
        print('✅ ${postList.length} posts loaded from Firestore');
        loadLikedPosts(); // 게시물 로드 후 좋아요 상태 확인
      });
    } catch (e) {
      print('❌ Error loading posts: $e');
      // 오류 발생 시 더미 데이터로 대체
      _loadDummyPosts();
    } finally {
      isLoading.value = false;
    }
  }

  // 더미 데이터 로드 (Firestore 연동 실패 시)
  void _loadDummyPosts() {
    posts.value = [
      Post(
        id: '1',
        userName: 'Sarah Green',
        userId: 'user1',
        userProfileImage: 'https://i.pravatar.cc/150?img=1',
        postImage: 'https://images.unsplash.com/photo-1614594975525-e45190c55d0b?w=600',
        content: 'My pothos is thriving! Look at these beautiful new leaves 🌿',
        hashtags: ['#Pothos', '#PlantGrowth', '#HappyPlant'],
        likes: 124,
        comments: 18,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      Post(
        id: '2',
        userName: 'John Plant',
        userId: 'user2',
        userProfileImage: 'https://i.pravatar.cc/150?img=2',
        postImage: 'https://images.unsplash.com/photo-1614594895304-fe7116ac3b58?w=600',
        content: 'Finally got my monstera to produce a fenestrated leaf! 😍',
        hashtags: ['#Monstera', '#PlantGoals', '#IndoorJungle'],
        likes: 89,
        comments: 12,
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      Post(
        id: '3',
        userName: 'Emma Botanist',
        userId: 'user3',
        userProfileImage: 'https://i.pravatar.cc/150?img=3',
        postImage: 'https://images.unsplash.com/photo-1593482892540-62cebf9b8180?w=600',
        content: 'Snake plants are the best! Low maintenance and beautiful 💚',
        hashtags: ['#SnakePlant', '#LowMaintenance', '#BeginnerFriendly'],
        likes: 56,
        comments: 8,
        timestamp: DateTime.now().subtract(const Duration(hours: 8)),
      ),
    ];
    print('⚠️ Using dummy post data');
  }

  // 게시물 작성
  Future<void> createPost(Post post, File imageFile) async {
    try {
      print('📤 Uploading post image...');
      
      // 1. Storage에 이미지 업로드
      final imageUrl = await _storageService.uploadImage(imageFile, 'posts');
      
      // 2. 이미지 URL을 포함한 게시물 생성
      final postWithImage = Post(
        id: post.id,
        userName: post.userName,
        userId: post.userId,
        userProfileImage: post.userProfileImage,
        postImage: imageUrl,
        content: post.content,
        hashtags: post.hashtags,
        likes: post.likes,
        comments: post.comments,
        timestamp: post.timestamp,
      );
      
      // 3. Firestore에 저장
      await _firestoreService.addPost(postWithImage);
      
      print('✅ Post created successfully');
    } catch (e) {
      print('❌ Error creating post: $e');
      rethrow;
    }
  }

  // 좋아요 상태 확인
  Future<bool> hasLiked(String postId) async {
    try {
      final authController = Get.find<AuthController>();
      final userId = authController.currentUserId;
      if (userId == null) return false;
      
      return await _firestoreService.hasUserLikedPost(postId, userId);
    } catch (e) {
      print('❌ Error checking like status: $e');
      return false;
    }
  }

  // 좋아요 토글 (중복 방지)
  Future<void> toggleLike(String postId) async {
    try {
      final authController = Get.find<AuthController>();
      final userId = authController.currentUserId;
      
      if (userId == null) {
        Get.snackbar(
          '알림',
          '로그인이 필요합니다',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // 현재 좋아요 상태 확인
      final currentlyLiked = likedPosts[postId] ?? false;
      
      // UI 먼저 업데이트 (즉각적인 반응)
      likedPosts[postId] = !currentlyLiked;
      
      // 좋아요 수 즉시 업데이트
      final postIndex = posts.indexWhere((p) => p.id == postId);
      if (postIndex != -1) {
        final updatedPost = Post(
          id: posts[postIndex].id,
          userName: posts[postIndex].userName,
          userId: posts[postIndex].userId,
          userProfileImage: posts[postIndex].userProfileImage,
          postImage: posts[postIndex].postImage,
          content: posts[postIndex].content,
          hashtags: posts[postIndex].hashtags,
          likes: currentlyLiked ? posts[postIndex].likes - 1 : posts[postIndex].likes + 1,
          comments: posts[postIndex].comments,
          timestamp: posts[postIndex].timestamp,
        );
        posts[postIndex] = updatedPost;
      }

      // Firestore에 좋아요 토글 (백그라운드)
      await _firestoreService.toggleLike(postId, userId);
      print('✅ Like toggled for post: $postId');
      
      // 좋아요 알림 생성 (자신의 게시물이 아닌 경우만)
      if (!currentlyLiked && posts[postIndex].userId != userId) {
        final notificationController = Get.find<NotificationController>();
        final currentUser = await _firestoreService.getUser(userId);
        
        if (currentUser != null) {
          await notificationController.createNotification(
            userId: posts[postIndex].userId,
            type: 'like',
            title: '좋아요',
            message: '${currentUser.displayName}님이 회원님의 게시물을 좋아합니다.',
            actionUserId: userId,
            actionUserName: currentUser.displayName,
            actionUserImage: currentUser.profileImageUrl,
            targetId: postId,
          );
        }
      }
      
    } catch (e) {
      print('❌ Error toggling like: $e');
      // 에러 발생 시 원래 상태로 복구
      likedPosts[postId] = !(likedPosts[postId] ?? false);
      Get.snackbar(
        '오류',
        '좋아요 처리 중 오류가 발생했습니다',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // 게시물 삭제
  Future<void> deletePost(String postId) async {
    try {
      await _firestoreService.deletePost(postId);
      print('✅ Post deleted');
    } catch (e) {
      print('❌ Error deleting post: $e');
      rethrow;
    }
  }
  
  // 사용자가 특정 게시물에 좋아요를 눌렀는지 확인
  bool isPostLiked(String postId) {
    return likedPosts[postId] ?? false;
  }
}

