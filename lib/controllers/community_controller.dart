import 'dart:io';
import 'package:get/get.dart';
import '../models/post.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../controllers/auth_controller.dart';

class CommunityController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  
  // 게시물 목록
  final RxList<Post> posts = <Post>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadPosts();
  }

  // Firestore에서 게시물 로드
  Future<void> loadPosts() async {
    try {
      isLoading.value = true;
      
      // Firestore 실시간 스트림으로 게시물 가져오기
      _firestoreService.getPostsStream().listen((postList) {
        posts.value = postList;
        print('✅ ${postList.length} posts loaded from Firestore');
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

      // Firestore에 좋아요 토글 (중복 자동 처리)
      await _firestoreService.toggleLike(postId, userId);
      print('✅ Like toggled for post: $postId');
      
      // Firestore 스트림이 자동으로 UI 업데이트
    } catch (e) {
      print('❌ Error toggling like: $e');
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
}

