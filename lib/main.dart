import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'controllers/main_controller.dart';
import 'controllers/auth_controller.dart';
import 'screens/home_screen.dart';
import 'screens/diagnosis_screen.dart';
import 'screens/community_screen.dart';
import 'screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
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
      home: const MainScreen(),
    );
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
      body: screens[mainController.selectedIndex.value],
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
