import 'package:flutter/material.dart';

// 커스텀 숫자 키보드 위젯
class CustomKeyboard extends StatelessWidget {
  final Function(String) onKeyPressed;
  final VoidCallback onNext;
  final VoidCallback onClose;

  const CustomKeyboard({
    super.key,
    required this.onKeyPressed,
    required this.onNext,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFCCCCCC),
      padding: const EdgeInsets.all(4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: 1, 2, 3, -1, +1
          Row(
            children: [
              _buildNumberKey('1'),
              _buildNumberKey('2'),
              _buildNumberKey('3'),
              _buildModifierKey('-1'),
              _buildModifierKey('+1'),
            ],
          ),
          const SizedBox(height: 4),
          // Row 2: 4, 5, 6, -5, +5
          Row(
            children: [
              _buildNumberKey('4'),
              _buildNumberKey('5'),
              _buildNumberKey('6'),
              _buildModifierKey('-5'),
              _buildModifierKey('+5'),
            ],
          ),
          const SizedBox(height: 4),
          // Row 3: 7, 8, 9, NEXT (2칸)
          Row(
            children: [
              _buildNumberKey('7'),
              _buildNumberKey('8'),
              _buildNumberKey('9'),
              _buildNextKey(),
            ],
          ),
          const SizedBox(height: 4),
          // Row 4: ., 0, 백스페이스, 닫기 (2칸)
          Row(
            children: [
              _buildNumberKey('.'),
              _buildNumberKey('0'),
              _buildBackspaceKey(),
              _buildCloseKey(),
            ],
          ),
        ],
      ),
    );
  }

  // 숫자 키 (1.2fr)
  Widget _buildNumberKey(String value) {
    return Expanded(
      flex: 12,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: GestureDetector(
          onTap: () => onKeyPressed(value),
          child: Container(
            height: 53,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  color: Color(0xFF373737),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 수정 키 (-1, +1, -5, +5) (0.8fr)
  Widget _buildModifierKey(String value) {
    return Expanded(
      flex: 8,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: GestureDetector(
          onTap: () => onKeyPressed(value),
          child: Container(
            height: 53,
            decoration: BoxDecoration(
              color: const Color(0xFFEBE7FA),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  color: Color(0xFF320D3E),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // NEXT 키 (2칸 = 0.8fr * 2 = 1.6fr)
  Widget _buildNextKey() {
    return Expanded(
      flex: 16,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: GestureDetector(
          onTap: onNext,
          child: Container(
            height: 53,
            decoration: BoxDecoration(
              color: const Color(0xFFA295D5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Center(
              child: Text(
                'NEXT',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 백스페이스 키
  Widget _buildBackspaceKey() {
    return Expanded(
      flex: 12,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: GestureDetector(
          onTap: () => onKeyPressed('backspace'),
          child: Container(
            height: 53,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: CustomPaint(
                size: const Size(24, 24),
                painter: BackspaceIconPainter(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 닫기 키 (2칸)
  Widget _buildCloseKey() {
    return Expanded(
      flex: 16,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: GestureDetector(
          onTap: onClose,
          child: Container(
            height: 53,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Center(
              child: Text(
                '닫기',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 백스페이스 아이콘 페인터
class BackspaceIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final path = Path();

    // 백스페이스 아이콘 경로 (원본 SVG 기반)
    // 스케일: 24x24 기준
    final scale = size.width / 24;

    // 외곽선
    path.moveTo(20.25 * scale, 3.75 * scale);
    path.lineTo(6.42 * scale, 3.75 * scale);
    path.cubicTo(
      6.17 * scale, 3.75 * scale,
      5.91 * scale, 3.82 * scale,
      5.69 * scale, 3.95 * scale,
    );
    path.cubicTo(
      5.46 * scale, 4.07 * scale,
      5.27 * scale, 4.26 * scale,
      5.14 * scale, 4.48 * scale,
    );
    path.lineTo(0.86 * scale, 11.61 * scale);
    path.cubicTo(
      0.79 * scale, 11.73 * scale,
      0.75 * scale, 11.86 * scale,
      0.75 * scale, 12 * scale,
    );
    path.cubicTo(
      0.75 * scale, 12.14 * scale,
      0.79 * scale, 12.27 * scale,
      0.86 * scale, 12.39 * scale,
    );
    path.lineTo(5.14 * scale, 19.52 * scale);
    path.cubicTo(
      5.27 * scale, 19.74 * scale,
      5.46 * scale, 19.93 * scale,
      5.69 * scale, 20.05 * scale,
    );
    path.cubicTo(
      5.91 * scale, 20.18 * scale,
      6.17 * scale, 20.25 * scale,
      6.42 * scale, 20.25 * scale,
    );
    path.lineTo(20.25 * scale, 20.25 * scale);
    path.cubicTo(
      20.65 * scale, 20.25 * scale,
      21.03 * scale, 20.09 * scale,
      21.31 * scale, 19.81 * scale,
    );
    path.cubicTo(
      21.59 * scale, 19.53 * scale,
      21.75 * scale, 19.15 * scale,
      21.75 * scale, 18.75 * scale,
    );
    path.lineTo(21.75 * scale, 5.25 * scale);
    path.cubicTo(
      21.75 * scale, 4.85 * scale,
      21.59 * scale, 4.47 * scale,
      21.31 * scale, 4.19 * scale,
    );
    path.cubicTo(
      21.03 * scale, 3.91 * scale,
      20.65 * scale, 3.75 * scale,
      20.25 * scale, 3.75 * scale,
    );
    path.close();

    // 내부 (흰색 영역)
    path.moveTo(20.25 * scale, 18.75 * scale);
    path.lineTo(6.42 * scale, 18.75 * scale);
    path.lineTo(2.37 * scale, 12 * scale);
    path.lineTo(6.42 * scale, 5.25 * scale);
    path.lineTo(20.25 * scale, 5.25 * scale);
    path.lineTo(20.25 * scale, 18.75 * scale);
    path.close();

    // X 마크
    path.moveTo(9.97 * scale, 13.72 * scale);
    path.lineTo(11.69 * scale, 12 * scale);
    path.lineTo(9.97 * scale, 10.28 * scale);
    path.cubicTo(
      9.83 * scale, 10.14 * scale,
      9.75 * scale, 9.95 * scale,
      9.75 * scale, 9.75 * scale,
    );
    path.cubicTo(
      9.75 * scale, 9.55 * scale,
      9.83 * scale, 9.36 * scale,
      9.97 * scale, 9.22 * scale,
    );
    path.cubicTo(
      10.11 * scale, 9.08 * scale,
      10.30 * scale, 9 * scale,
      10.5 * scale, 9 * scale,
    );
    path.cubicTo(
      10.70 * scale, 9 * scale,
      10.89 * scale, 9.08 * scale,
      11.03 * scale, 9.22 * scale,
    );
    path.lineTo(12.75 * scale, 10.94 * scale);
    path.lineTo(14.47 * scale, 9.22 * scale);
    path.cubicTo(
      14.61 * scale, 9.08 * scale,
      14.80 * scale, 9 * scale,
      15 * scale, 9 * scale,
    );
    path.cubicTo(
      15.20 * scale, 9 * scale,
      15.39 * scale, 9.08 * scale,
      15.53 * scale, 9.22 * scale,
    );
    path.cubicTo(
      15.67 * scale, 9.36 * scale,
      15.75 * scale, 9.55 * scale,
      15.75 * scale, 9.75 * scale,
    );
    path.cubicTo(
      15.75 * scale, 9.95 * scale,
      15.67 * scale, 10.14 * scale,
      15.53 * scale, 10.28 * scale,
    );
    path.lineTo(13.81 * scale, 12 * scale);
    path.lineTo(15.53 * scale, 13.72 * scale);
    path.cubicTo(
      15.67 * scale, 13.86 * scale,
      15.75 * scale, 14.05 * scale,
      15.75 * scale, 14.25 * scale,
    );
    path.cubicTo(
      15.75 * scale, 14.45 * scale,
      15.67 * scale, 14.64 * scale,
      15.53 * scale, 14.78 * scale,
    );
    path.cubicTo(
      15.39 * scale, 14.92 * scale,
      15.20 * scale, 15 * scale,
      15 * scale, 15 * scale,
    );
    path.cubicTo(
      14.80 * scale, 15 * scale,
      14.61 * scale, 14.92 * scale,
      14.47 * scale, 14.78 * scale,
    );
    path.lineTo(12.75 * scale, 13.06 * scale);
    path.lineTo(11.03 * scale, 14.78 * scale);
    path.cubicTo(
      10.89 * scale, 14.92 * scale,
      10.70 * scale, 15 * scale,
      10.5 * scale, 15 * scale,
    );
    path.cubicTo(
      10.30 * scale, 15 * scale,
      10.11 * scale, 14.92 * scale,
      9.97 * scale, 14.78 * scale,
    );
    path.cubicTo(
      9.83 * scale, 14.64 * scale,
      9.75 * scale, 14.45 * scale,
      9.75 * scale, 14.25 * scale,
    );
    path.cubicTo(
      9.75 * scale, 14.05 * scale,
      9.83 * scale, 13.86 * scale,
      9.97 * scale, 13.72 * scale,
    );
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 키보드 상태 관리를 위한 Mixin
mixin KeyboardStateMixin<T extends StatefulWidget> on State<T> {
  bool isKeyboardVisible = false;
  String? activeField; // 'weight' or 'reps'
  int? activeSetIndex;
  String? activeRecordId;
  String currentValue = '';

  void showKeyboard(String recordId, int setIndex, String field, String initialValue) {
    setState(() {
      isKeyboardVisible = true;
      activeRecordId = recordId;
      activeSetIndex = setIndex;
      activeField = field;
      currentValue = initialValue;
    });
  }

  void hideKeyboard() {
    setState(() {
      isKeyboardVisible = false;
      activeRecordId = null;
      activeSetIndex = null;
      activeField = null;
      currentValue = '';
    });
  }

  void handleKeyboardInput(String key) {
    setState(() {
      if (key == 'backspace') {
        if (currentValue.isNotEmpty) {
          currentValue = currentValue.substring(0, currentValue.length - 1);
        }
      } else if (key.startsWith('+') || key.startsWith('-')) {
        // 증감 연산
        final modifier = int.tryParse(key) ?? 0;
        final current = double.tryParse(currentValue) ?? 0;
        final newValue = current + modifier;
        if (newValue >= 0) {
          // 정수인 경우 정수로, 소수인 경우 소수로 표시
          if (newValue == newValue.toInt()) {
            currentValue = newValue.toInt().toString();
          } else {
            currentValue = newValue.toString();
          }
        }
      } else if (key == '.') {
        if (!currentValue.contains('.')) {
          if (currentValue.isEmpty) {
            currentValue = '0.';
          } else {
            currentValue += '.';
          }
        }
      } else {
        // 숫자 입력
        currentValue += key;
      }
    });
  }

  // 다음 필드로 이동 (서브클래스에서 구현)
  void moveToNextField();
}
