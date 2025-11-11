import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'controllers/main_controller.dart';
import 'controllers/auth_controller.dart';
import 'controllers/diagnosis_controller.dart';
import 'screens/home_screen.dart';
import 'screens/diagnosis_screen.dart';
import 'screens/community_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 한국어 날짜 형식 초기화
  await initializeDateFormatting('ko_KR', null);
  
  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // 익명 사용자 로그아웃 (Google 로그인 강제)
  final auth = FirebaseAuth.instance;
  if (auth.currentUser != null && auth.currentUser!.isAnonymous) {
    await auth.signOut();
    print('✅ Anonymous user logged out');
  }
  
  // AuthController 초기 바인딩
  Get.put(AuthController());
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone X 기준
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          title: 'Gromy',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const AuthWrapper(),
          getPages: [
            GetPage(
              name: '/diagnosis',
              page: () => const DiagnosisScreen(),
              binding: BindingsBuilder(() {
                if (!Get.isRegistered<DiagnosisController>()) {
                  Get.lazyPut(() => DiagnosisController());
                }
              }),
            ),
          ],
        );
      },
    );
  }
}

// 로그인 상태에 따라 화면 분기
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    return Obx(() {
      // 로딩 중
      if (authController.isLoading.value) {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // 로그인 여부 확인
      if (authController.firebaseUser.value == null) {
        return const LoginScreen();
      }

      // 로그인 완료 → 메인 화면
      return const MainScreen();
    });
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // MainController 초기화
    final MainController mainController = Get.put(MainController());
    if (!Get.isRegistered<DiagnosisController>()) {
      Get.lazyPut(() => DiagnosisController());
    }
    
    // 각 탭에 해당하는 화면 목록
    final List<Widget> screens = [
      const HomeScreen(),
      const DiagnosisScreen(),
      const CommunityScreen(),
      const ProfileScreen(),
    ];

    return Obx(() => Scaffold(
      body: SafeArea(
        bottom: false, // BottomNavigationBar가 SafeArea 처리
        child: screens[mainController.selectedIndex.value],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: mainController.selectedIndex.value,
          onTap: mainController.changeTab,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: const Color(0xFF2D7A4F),
          unselectedItemColor: Colors.grey[400],
          showSelectedLabels: false,
          showUnselectedLabels: false,
          items: [
            BottomNavigationBarItem(
              icon: Icon(
                mainController.selectedIndex.value == 0 
                    ? Icons.home_rounded
                    : Icons.home_outlined,
                size: 30,
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                mainController.selectedIndex.value == 1 
                    ? Icons.search_rounded
                    : Icons.search_outlined,
                size: 30,
              ),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                mainController.selectedIndex.value == 2 
                    ? Icons.add_box_rounded
                    : Icons.add_box_outlined,
                size: 30,
              ),
              label: 'Add',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                mainController.selectedIndex.value == 3 
                    ? Icons.account_circle_rounded
                    : Icons.account_circle_outlined,
                size: 30,
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    ));
  }
}
