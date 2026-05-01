import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_app_flutter/pages/analysis_page.dart';

void main() {
  group('AnalysisPage Unit Tests', () {
    test('formatVolume should format weights correctly', () {
      // Test standard weights
      expect(AnalysisPageState.formatVolume(500.0), '500kg');
      expect(AnalysisPageState.formatVolume(9999.0), '9999kg');
      
      // Test tons conversion
      expect(AnalysisPageState.formatVolume(10000.0), '10.0t');
      expect(AnalysisPageState.formatVolume(12500.0), '12.5t');
    });
  });

  group('AnalysisPage Widget Tests', () {
    testWidgets('Should display current month and year on load', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: AnalysisPage()));
      await tester.pumpAndSettle();

      final now = DateTime.now();
      final expectedMonthText = '${now.year}년 ${now.month}월';
      
      expect(find.text(expectedMonthText), findsOneWidget);
    });

    testWidgets('Should show empty state message when no records exist', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: AnalysisPage()));
      await tester.pumpAndSettle();

      expect(find.text('이 달의 운동 기록이 없습니다'), findsOneWidget);
    });

    testWidgets('Level display should default to Lv.1', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: AnalysisPage()));
      await tester.pumpAndSettle();

      expect(find.text('Lv.1'), findsOneWidget);
    });

    testWidgets('Navigation: Previous month button should update header', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: AnalysisPage()));
      await tester.pumpAndSettle();

      final now = DateTime.now();
      final lastMonth = DateTime(now.year, now.month - 1);
      
      // Tap the chevron left icon
      // We use find.byWidgetPredicate because LucideIcons might be nested
      final prevButton = find.byType(GestureDetector).first;
      await tester.tap(prevButton);
      await tester.pumpAndSettle();

      expect(find.text('${lastMonth.year}년 ${lastMonth.month}월'), findsOneWidget);
    });
  });
}
