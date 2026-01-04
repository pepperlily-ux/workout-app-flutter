import 'package:flutter/material.dart';
import '../models/record.dart';
import '../models/exercise.dart';
import '../services/storage_service.dart';

// 캘린더 화면
class CalendarPage extends StatefulWidget {
  final Function(String date)? onDateSelect; // 날짜 선택 시 홈으로 이동

  const CalendarPage({super.key, this.onDateSelect});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
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
    await _storage.init();
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

  // 해당 날짜의 기록 가져오기
  List<Record> _getRecordsForDate(int day) {
    final dateStr = _formatDate(day);
    return _records
        .where((r) => r.date == dateStr && r.sets.isNotEmpty)
        .toList();
  }

  // 해당 날짜에 운동 기록이 있는지 확인
  bool hasWorkout(int day) {
    return _getRecordsForDate(day).isNotEmpty;
  }

  // 이번 달 운동 횟수 계산 (날짜 기준)
  int getMonthWorkoutCount() {
    final year = _currentMonth.year;
    final month = _currentMonth.month;

    final datesWithWorkouts = <String>{};
    for (final record in _records) {
      if (record.sets.isNotEmpty) {
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
                  color: const Color(0xFFF3F1FA),
                  border: Border.all(color: const Color(0xFFD4CDEB)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: '이번달은 ',
                        style: TextStyle(fontSize: 14, color: Color(0xFF374151)),
                      ),
                      TextSpan(
                        text: '$monthWorkoutCount번',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFA295D5),
                        ),
                      ),
                      const TextSpan(
                        text: ' 헬스장에 갔습니다',
                        style: TextStyle(fontSize: 14, color: Color(0xFF374151)),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 16),

              // 월 선택
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _previousMonth,
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.chevron_left, size: 24, color: Color(0xFF3F4146)),
                    ),
                  ),
                  Text(
                    '${_currentMonth.year}년 ${_currentMonth.month}월',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  GestureDetector(
                    onTap: _nextMonth,
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.chevron_right, size: 24, color: Color(0xFF3F4146)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

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

              const SizedBox(height: 8),

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

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDay = day;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFA295D5)
                            : hasRecords
                                ? const Color(0xFFF3F1FA)
                                : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFA295D5)
                              : hasRecords
                                  ? const Color(0xFFD4CDEB)
                                  : const Color(0xFFE5E7EB),
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$day',
                            style: TextStyle(
                              fontSize: 14,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF1F2937),
                            ),
                          ),
                          if (hasRecords && !isSelected) ...[
                            const SizedBox(height: 2),
                            const Text(
                              '●',
                              style: TextStyle(fontSize: 10, color: Color(0xFFA295D5)),
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
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatDateKorean(_selectedDay!),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (selectedDayRecords.isNotEmpty) ...[
                        // 운동 기록 있음
                        ...selectedDayRecords.map((record) {
                          final exercise = _getExerciseById(record.exerciseId);
                          if (exercise == null) return const SizedBox();

                          final setStrings = record.sets
                              .map((s) => '${s.weight}kg × ${s.reps}회')
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
                        GestureDetector(
                          onTap: _handleEditDate,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFA295D5),
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
                          height: 270,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/home.png',
                                      width: 160,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const SizedBox(height: 100),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      '왜 운동 안하냐몽!?',
                                      style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
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
                                    color: const Color(0xFFA295D5),
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
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
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
                    style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
                  ),
                ),
              ),
          const SizedBox(height: 4),
          Text(
            '총 볼륨: ${totalVolume.toStringAsFixed(0)}kg',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}
