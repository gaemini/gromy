import 'package:get/get.dart';
import '../models/user_model.dart';

class ProfileController extends GetxController {
  // 현재 사용자 정보
  final Rxn<UserModel> currentUser = Rxn<UserModel>();

  @override
  void onInit() {
    super.onInit();
    loadUserProfile();
  }

  // 사용자 프로필 로드 (추후 Firebase 연동)
  void loadUserProfile() {
    currentUser.value = UserModel(
      uid: 'user1',
      displayName: 'Plant Lover',
      email: 'plantlover@gromy.com',
      profileImageUrl: 'https://i.pravatar.cc/150?img=5',
    );
  }
}

