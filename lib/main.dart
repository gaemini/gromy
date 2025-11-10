import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'controllers/main_controller.dart';
import 'controllers/auth_controller.dart';
import 'screens/home_screen.dart';
import 'screens/diagnosis_screen.dart';
import 'screens/community_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
    return GetMaterialApp(
      title: 'Gromy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // 주요 색상: 진한 녹색 계열
        primarySwatch: Colors.green,
        primaryColor: const Color(0xFF2D7A4F), // 진한 녹색
        
        // AppBar 테마
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          titleTextStyle: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        
        // 전체 폰트: Poppins
        textTheme: GoogleFonts.poppinsTextTheme(
          ThemeData.light().textTheme,
        ),
        
        // 추가 텍스트 스타일
        primaryTextTheme: GoogleFonts.poppinsTextTheme(),
        
        // 버튼 텍스트
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            textStyle: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        
        // Scaffold 배경색
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const AuthWrapper(),
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
            child: CircularProgressIndicator(
              color: Color(0xFF2D7A4F),
            ),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: mainController.selectedIndex.value,
        onTap: mainController.changeTab,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2D7A4F), // 진한 녹색
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              mainController.selectedIndex.value == 0 
                  ? Icons.home 
                  : Icons.home_outlined,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              mainController.selectedIndex.value == 1 
                  ? Icons.camera_alt 
                  : Icons.camera_alt_outlined,
            ),
            label: 'Diagnosis',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              mainController.selectedIndex.value == 2 
                  ? Icons.people 
                  : Icons.people_outline,
            ),
            label: 'Community',
            ),
          BottomNavigationBarItem(
            icon: Icon(
              mainController.selectedIndex.value == 3 
                  ? Icons.person 
                  : Icons.person_outline,
            ),
            label: 'Profile',
          ),
        ],
      ),
    ));
  }
}
