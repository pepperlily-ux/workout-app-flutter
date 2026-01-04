import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// 페이지들 import
import 'pages/home_page.dart';
import 'pages/calendar_page.dart';
import 'pages/routine_page.dart';
import 'pages/exercise_page.dart';
import 'pages/splash_page.dart';
import 'constants/app_colors.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '메타몽 과부하',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const AppWrapper(),
    );
  }
}

// 스플래시 화면과 메인 화면을 감싸는 래퍼
class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  bool _showSplash = true;

  void _onSplashComplete() {
    setState(() {
      _showSplash = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashPage(onComplete: _onSplashComplete);
    }
    return const MainScreen();
  }
}

// 메인 화면 (하단 탭 네비게이션)
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0; // 현재 선택된 탭 (0: 홈, 1: 캘린더, 2: 루틴, 3: 운동)
  String? _selectedDate; // 캘린더에서 선택한 날짜

  // 캘린더에서 날짜 선택 시 홈으로 이동
  void _onCalendarDateSelect(String date) {
    setState(() {
      _selectedDate = date;
      _currentIndex = 0; // 홈 탭으로 이동
    });
  }

  @override
  Widget build(BuildContext context) {
    // 선택/비선택 색상
    const selectedColor = AppColors.primary;
    const unselectedColor = AppColors.textMuted;

    // 각 탭에 해당하는 화면들
    final List<Widget> pages = [
      HomePage(
        key: ValueKey(_selectedDate),
        initialDate: _selectedDate,
      ),
      CalendarPage(onDateSelect: _onCalendarDateSelect),
      const RoutinePage(),
      const ExercisePage(),
    ];

    return Scaffold(
      body: pages[_currentIndex], // 현재 선택된 탭의 화면 보여주기
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)), // 상단 테두리
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12), // py-3 = 12px
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, 'assets/icons/home.svg', '홈', selectedColor, unselectedColor),
                _buildNavItem(1, 'assets/icons/calendar.svg', '캘린더', selectedColor, unselectedColor),
                _buildNavItem(2, 'assets/icons/routine.svg', '루틴', selectedColor, unselectedColor),
                _buildNavItem(3, 'assets/icons/exercise.svg', '운동', selectedColor, unselectedColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 네비게이션 아이템 위젯 만들기
  Widget _buildNavItem(int index, String iconPath, String label, Color selectedColor, Color unselectedColor) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? selectedColor : unselectedColor;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
          // 다른 탭으로 이동 시 선택된 날짜 초기화
          if (index != 0) {
            _selectedDate = null;
          }
        });
      },
      behavior: HitTestBehavior.opaque, // 빈 공간도 터치 가능
      child: SizedBox(
        width: 80, // 터치 영역 넓히기
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              iconPath,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
            const SizedBox(height: 4), // 아이콘과 텍스트 사이 간격
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
