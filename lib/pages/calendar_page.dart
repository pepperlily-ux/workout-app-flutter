import 'package:flutter/material.dart';
import '../models/record.dart';
import '../models/exercise.dart';
import '../services/storage_service.dart';
import '../constants/app_colors.dart';

// 캘린더 화면
class CalendarPage extends StatefulWidget {
  final Function(String date)? onDateSelect; // 날짜 선택 시 홈으로 이동

  const CalendarPage({super.key, this.onDateSelect});

  @override
  State<CalendarPage> createState() => CalendarPageState();
}

class CalendarPageState extends State<CalendarPage> {
  void reload() => _loadData();
  final StorageService _storage = StorageService();
  DateTime _currentMonth = DateTime.now();
  int? _selectedDay;
  List<Record> _records = [];
  List<Exercise> _exercises = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // main()에서 이미 초기화 보장 — 여기선 데이터만 읽음
    if (!mounted) return;
    setState(() {
      _records = _storage.getRecords();
      _exercises = _storage.getExercises();
    });
  }

  // 날짜 포맷 (yyyy-MM-dd)
  String _formatDate(int day) {
    final month = _currentMonth.month.toString().padLeft(2, '0');
    final dayStr = day.toString().padLeft(2, '0');
    return '${_currentMonth.year}-$month-$dayStr';
  }

  // 해당 날짜의 기록 가져오기 (볼륨이 0보다 큰 것만)
  List<Record> _getRecordsForDate(int day) {
    final dateStr = _formatDate(day);
    return _records
        .where((r) => r.date == dateStr && r.totalVolume > 0)
        .toList();
  }

  // 해당 날짜에 운동 기록이 있는지 확인
  bool hasWorkout(int day) {
    return _getRecordsForDate(day).isNotEmpty;
  }

  // 이번 달 운동 횟수 계산 (날짜 기준, 볼륨이 0보다 큰 기록만)
  int getMonthWorkoutCount() {
    final year = _currentMonth.year;
    final month = _currentMonth.month;

    final datesWithWorkouts = <String>{};
    for (final record in _records) {
      if (record.totalVolume > 0) {
        final recordDate = DateTime.tryParse(record.date);
        if (recordDate != null &&
            recordDate.year == year &&
            recordDate.month == month) {
          datesWithWorkouts.add(record.date);
        }
      }
    }
    return datesWithWorkouts.length;
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
      _selectedDay = null;
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_currentMonth.year == now.year && _currentMonth.month == now.month) return;
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
      _selectedDay = null;
    });
  }

  String formatDateKorean(int day) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final date = DateTime(_currentMonth.year, _currentMonth.month, day);
    final weekday = weekdays[date.weekday - 1];
    return '${_currentMonth.month}월 $day일 $weekday요일';
  }

  // 볼륨 계산
  int _calculateVolume(List<dynamic> sets) {
    int total = 0;
    for (final set in sets) {
      final weight = double.tryParse(set.weight.toString()) ?? 0;
      final reps = double.tryParse(set.reps.toString()) ?? 0;
      total += (weight * reps).toInt();
    }
    return total;
  }

  // 운동 찾기
  Exercise? _getExerciseById(String id) {
    try {
      return _exercises.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  // 해당 날짜의 대표 태그 계산 (가장 많은 태그, 동점이면 '종합')
  String _getDominantTag(int day) {
    final records = _getRecordsForDate(day);
    if (records.isEmpty) return '';

    final tagCounts = <String, int>{};
    for (final record in records) {
      final exercise = _getExerciseById(record.exerciseId);
      if (exercise != null && exercise.tag.isNotEmpty) {
        tagCounts[exercise.tag] = (tagCounts[exercise.tag] ?? 0) + 1;
      }
    }

    if (tagCounts.isEmpty) return '종합';

    final maxCount = tagCounts.values.reduce((a, b) => a > b ? a : b);
    final topTags = tagCounts.entries.where((e) => e.value == maxCount).toList();

    if (topTags.length > 1) return '종합';
    return topTags.first.key;
  }

  // 이 날짜 편집하기 버튼 클릭
  void _handleEditDate() {
    if (_selectedDay == null) return;
    final dateStr = _formatDate(_selectedDay!);
    if (widget.onDateSelect != null) {
      widget.onDateSelect!(dateStr);
    }
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month, 1).weekday % 7;
    final monthWorkoutCount = getMonthWorkoutCount();
    final selectedDayRecords =
        _selectedDay != null ? _getRecordsForDate(_selectedDay!) : <Record>[];

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 이번 달 운동 횟수
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryBackground,
                  border: Border.all(color: AppColors.primaryBorder),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: '이번달은 ',
                        style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                      ),
                      TextSpan(
                        text: '$monthWorkoutCount번',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const TextSpan(
                        text: ' 헬스장에 갔습니다',
                        style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 8),

              // 월 선택
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _previousMonth,
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.chevron_left, size: 24, color: AppColors.divider),
                    ),
                  ),
                  Text(
                    '${_currentMonth.year}년 ${_currentMonth.month}월',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Builder(builder: (context) {
                    final now = DateTime.now();
                    final isCurrentMonth = _currentMonth.year == now.year && _currentMonth.month == now.month;
                    return GestureDetector(
                      onTap: isCurrentMonth ? null : _nextMonth,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(Icons.chevron_right, size: 24,
                          color: isCurrentMonth ? AppColors.border : AppColors.divider,
                        ),
                      ),
                    );
                  }),
                ],
              ),

              const SizedBox(height: 10),

              // 요일 헤더
              Row(
                children: ['일', '월', '화', '수', '목', '금', '토']
                    .map((day) => Expanded(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                day,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),

              const SizedBox(height: 6),

              // 날짜 그리드
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  childAspectRatio: 1,
                ),
                itemCount: firstDayOfMonth + daysInMonth,
                itemBuilder: (context, index) {
                  if (index < firstDayOfMonth) {
                    return const SizedBox();
                  }

                  final day = index - firstDayOfMonth + 1;
                  final hasRecords = hasWorkout(day);
                  final isSelected = _selectedDay == day;
                  final now = DateTime.now();
                  final isToday = _currentMonth.year == now.year &&
                      _currentMonth.month == now.month &&
                      day == now.day;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDay = day;
                      });
                    },
                    child: Container(
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : hasRecords
                                ? AppColors.primaryBackground
                                : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : isToday
                                  ? AppColors.primary
                                  : hasRecords
                                      ? AppColors.primaryBorder
                                      : AppColors.border,
                          width: isToday && !isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$day',
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                          if (hasRecords && !isSelected) ...[
                            const SizedBox(height: 1),
                            Text(
                              _getDominantTag(day),
                              maxLines: 1,
                              overflow: TextOverflow.clip,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                height: 1.0,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // 선택된 날짜의 운동 요약
              if (_selectedDay != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatDateKorean(_selectedDay!),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (selectedDayRecords.isNotEmpty) ...[
                        // 운동 기록 있음
                        ...selectedDayRecords.map((record) {
                          final exercise = _getExerciseById(record.exerciseId);
                          if (exercise == null) return const SizedBox();

                          final setStrings = record.sets
                              .where((s) => s.weight != null && s.reps != null)
                              .map((s) => '${s.weight! % 1 == 0 ? s.weight!.toInt() : s.weight}kg × ${s.reps}회')
                              .toList();
                          final volume = _calculateVolume(record.sets);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _WorkoutRecordCard(
                              name: exercise.name,
                              tag: exercise.tag,
                              sets: setStrings,
                              totalVolume: volume,
                            ),
                          );
                        }),
                        // 메모 표시
                        Builder(
                          builder: (context) {
                            final memo = _storage.getDailyMemo(_formatDate(_selectedDay!));
                            if (memo == null || memo.isEmpty) return const SizedBox();
                            return Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '메모',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    memo,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        GestureDetector(
                          onTap: _handleEditDate,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Text(
                                '이 날짜 편집하기',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        // 운동 기록 없음
                        SizedBox(
                          height: 240,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/Sad.png',
                                      width: 130,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const SizedBox(height: 100),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      '왜 운동 안하냐몽!?',
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 14, color: AppColors.textHint),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: _handleEditDate,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      '이 날짜 편집하기',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkoutRecordCard extends StatelessWidget {
  final String name;
  final String tag;
  final List<String> sets;
  final int totalVolume;

  const _WorkoutRecordCard({
    required this.name,
    required this.tag,
    required this.sets,
    required this.totalVolume,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.4,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...sets.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '세트 ${entry.key + 1}: ${entry.value}',
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                ),
              ),
          const SizedBox(height: 4),
          Text(
            '총 볼륨: ${totalVolume.toStringAsFixed(0)}kg',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
