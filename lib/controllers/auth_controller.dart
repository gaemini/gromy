import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Rxn<User> firebaseUser = Rxn<User>();
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    // Firebase 인증 상태 변화 감지
    firebaseUser.bindStream(_auth.authStateChanges());
    
    // 앱 시작 시 자동 로그인
    _autoSignIn();
  }

  // 자동 로그인 (익명)
  Future<void> _autoSignIn() async {
    try {
      isLoading.value = true;
      
      // 이미 로그인되어 있는지 확인
      if (_auth.currentUser == null) {
        // 익명 로그인 실행
        await _auth.signInAnonymously();
        print('✅ Anonymous sign-in successful: ${_auth.currentUser?.uid}');
      } else {
        print('✅ Already signed in: ${_auth.currentUser?.uid}');
      }
    } catch (e) {
      print('❌ Error auto signing in: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // 익명 로그인 (수동 호출용)
  Future<void> signInAnonymously() async {
    try {
      await _auth.signInAnonymously();
      print('✅ Manual anonymous sign-in successful');
    } catch (e) {
      print('❌ Error signing in anonymously: $e');
      rethrow;
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      print('✅ Sign out successful');
      
      // 로그아웃 후 자동으로 다시 익명 로그인
      await signInAnonymously();
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

