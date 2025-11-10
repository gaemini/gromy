import 'package:get/get.dart';
import '../models/user_model.dart';
import '../controllers/auth_controller.dart';

class ProfileController extends GetxController {
  // AuthController의 사용자 정보 사용
  UserModel? get currentUser {
    final authController = Get.find<AuthController>();
    return authController.currentUser.value;
  }
}

