import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:get/get.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirestoreService _firestoreService = FirestoreService();
  
  final Rxn<User> firebaseUser = Rxn<User>();
  final Rxn<UserModel> currentUser = Rxn<UserModel>();
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    // Firebase 인증 상태 변화 감지
    firebaseUser.bindStream(_auth.authStateChanges());
    
    // 사용자 정보 로드
    ever(firebaseUser, _loadUserData);
    
    // 앱 시작 시 로그인 체크
    _checkAuth();
  }

  // 로그인 상태 체크
  Future<void> _checkAuth() async {
    try {
      isLoading.value = true;
      
      if (_auth.currentUser != null) {
        print('✅ Already signed in: ${_auth.currentUser?.uid}');
        await _loadUserData(_auth.currentUser);
      } else {
        print('⚠️ Not signed in');
      }
    } catch (e) {
      print('❌ Error checking auth: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // 사용자 데이터 로드
  Future<void> _loadUserData(User? user) async {
    if (user == null) {
      currentUser.value = null;
      return;
    }

    try {
      // Firestore에서 사용자 정보 실시간 스트림
      _firestoreService.getUserStream(user.uid).listen((userData) {
        currentUser.value = userData;
        print('✅ User data updated: ${userData?.displayName}');
      });
    } catch (e) {
      print('❌ Error loading user data: $e');
    }
  }

  // 프로필 강제 새로고침
  Future<void> refreshUserProfile() async {
    if (firebaseUser.value != null) {
      await _loadUserData(firebaseUser.value);
    }
  }

  // Google 로그인
  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;
      print('🔐 Starting Google Sign In...');

      // Google Sign In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        print('⚠️ Google sign in cancelled');
        isLoading.value = false;
        return;
      }

      // Google 인증 정보 가져오기
      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      // Firebase 인증 자격증명 생성
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase에 로그인
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        print('✅ Google sign-in successful: ${user.email}');
        
        // Firestore에 사용자 정보 저장/업데이트
        await _saveUserToFirestore(user);
      }
    } catch (e) {
      print('❌ Error signing in with Google: $e');
      Get.snackbar(
        '로그인 오류',
        'Google 로그인에 실패했습니다: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Firestore에 사용자 정보 저장
  Future<void> _saveUserToFirestore(User user) async {
    try {
      final userModel = UserModel(
        uid: user.uid,
        displayName: user.displayName ?? 'Plant Lover',
        email: user.email ?? '',
        profileImageUrl: user.photoURL ?? 'https://i.pravatar.cc/150?img=5',
      );

      await _firestoreService.saveUser(userModel);
      print('✅ User saved to Firestore');
    } catch (e) {
      print('❌ Error saving user to Firestore: $e');
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      currentUser.value = null;
      print('✅ Sign out successful');
      
      Get.snackbar(
        '로그아웃',
        '로그아웃되었습니다',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('❌ Error signing out: $e');
      rethrow;
    }
  }

  // 현재 사용자 ID 가져오기
  String? get currentUserId => firebaseUser.value?.uid;
  
  // 로그인 여부 확인
  bool get isSignedIn => firebaseUser.value != null;
}

