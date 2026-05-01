import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class SplashPage extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashPage({super.key, required this.onComplete});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // 2초 후에 페이드 아웃 시작
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        _fadeController.forward().then((_) {
          widget.onComplete();
        });
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: ReverseAnimation(_fadeController),
      child: Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    // 상단 텍스트
                    Column(
                      children: [
                        const Text(
                          '헬스몽과 함께하는',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                            height: 1.36,
                          ),
                        ),
                        const Text(
                          '점진적 과부하',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark,
                            height: 1.36,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    // 로고 이미지
                    Image.asset(
                      'assets/Normal.png',
                      width: 203,
                      height: 203,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 203,
                        height: 203,
                        decoration: BoxDecoration(
                          color: AppColors.primaryBackground,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.fitness_center,
                          size: 80,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}
