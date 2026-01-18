import 'package:flutter/material.dart';
import 'dart:math';
import '../constants/app_colors.dart';
import '../constants/metamon_messages.dart';
import '../services/storage_service.dart';
import '../models/record.dart';
import '../models/exercise.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  final StorageService _storage = StorageService();

  // 현재 보고 있는 월 (월간 통계용)
  late DateTime _currentMonth;

  // 데이터
  List<Record> _allRecords = [];
  List<Exercise> _exercises = [];

  // 메타몽 데이터
  int _level = 1;
  int _currentXp = 0;
  int _totalWorkoutDays = 0;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
    _loadData();
  }

  Future<void> _loadData() async {
    await _storage.init();
    setState(() {
      _allRecords = _storage.getRecords();
      _exercises = _storage.getExercises();
      _calculateMetamonStats();
    });
  }

  // 메타몽 레벨/경험치 계산
  void _calculateMetamonStats() {
    // 운동한 날짜들 (중복 제거)
    final workoutDates = _allRecords
        .where((r) => r.totalVolume > 0)
        .map((r) => r.date)
        .toSet();

    _totalWorkoutDays = workoutDates.length;

    // 레벨 계산 (누적 운동 일수 기준)
    _level = 1;
    for (int lv = maxLevel; lv >= 1; lv--) {
      if (_totalWorkoutDays >= levelRequirements[lv]!) {
        _level = lv;
        break;
      }
    }

    // 현재 레벨 내 경험치 계산
    final currentLevelReq = levelRequirements[_level]!;
    final nextLevelReq = _level < maxLevel ? levelRequirements[_level + 1]! : currentLevelReq;
    final levelRange = nextLevelReq - currentLevelReq;

    if (_level >= maxLevel) {
      _currentXp = levelRange;
    } else {
      _currentXp = _totalWorkoutDays - currentLevelReq;
    }
  }

  // 다음 레벨까지 필요한 운동 일수
  int get _nextLevelRequirement {
    if (_level >= maxLevel) return levelRequirements[maxLevel]!;
    return levelRequirements[_level + 1]! - levelRequirements[_level]!;
  }

  // 현재 레벨 내 진행률 (0.0 ~ 1.0)
  double get _levelProgress {
    if (_level >= maxLevel) return 1.0;
    final required = _nextLevelRequirement;
    if (required == 0) return 1.0;
    return (_currentXp / required).clamp(0.0, 1.0);
  }

  // 이전 달로 이동
  void _goToPreviousMonth() {
    final oneYearAgo = DateTime(DateTime.now().year - 1, DateTime.now().month);
    final previousMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);

    if (previousMonth.isBefore(oneYearAgo)) {
      // 1년 제한 메시지
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(historyLimitMessage),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _currentMonth = previousMonth;
    });
  }

  // 다음 달로 이동
  void _goToNextMonth() {
    final now = DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month);

    if (_currentMonth.year == currentMonthStart.year &&
        _currentMonth.month == currentMonthStart.month) {
      // 이번 달이면 이동 불가
      return;
    }

    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  // 이번 달인지 확인
  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _currentMonth.year == now.year && _currentMonth.month == now.month;
  }

  // 해당 월의 기록 가져오기
  List<Record> _getMonthRecords() {
    final monthStr = '${_currentMonth.year}-${_currentMonth.month.toString().padLeft(2, '0')}';
    return _allRecords.where((r) => r.date.startsWith(monthStr) && r.totalVolume > 0).toList();
  }

  // 월간 운동 일수
  int _getMonthWorkoutDays() {
    return _getMonthRecords().map((r) => r.date).toSet().length;
  }

  // 월간 총 볼륨
  double _getMonthTotalVolume() {
    return _getMonthRecords().fold(0.0, (sum, r) => sum + r.totalVolume);
  }

  // 가장 많이 한 운동
  String? _getMostFrequentExercise() {
    final records = _getMonthRecords();
    if (records.isEmpty) return null;

    final countMap = <String, int>{};
    for (final record in records) {
      countMap[record.exerciseId] = (countMap[record.exerciseId] ?? 0) + 1;
    }

    final mostFrequentId = countMap.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    return _getExerciseName(mostFrequentId);
  }

  // 가장 많이 한 부위
  String? _getMostFrequentBodyPart() {
    final records = _getMonthRecords();
    if (records.isEmpty) return null;

    final countMap = <String, int>{};
    for (final record in records) {
      final tag = _getExerciseTag(record.exerciseId);
      if (tag.isNotEmpty) {
        countMap[tag] = (countMap[tag] ?? 0) + 1;
      }
    }

    if (countMap.isEmpty) return null;

    return countMap.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  // 성장률 가장 좋은 운동
  Map<String, dynamic>? _getBestGrowthExercise() {
    final records = _getMonthRecords();
    if (records.isEmpty) return null;

    // 운동별로 그룹화
    final exerciseRecords = <String, List<Record>>{};
    for (final record in records) {
      exerciseRecords.putIfAbsent(record.exerciseId, () => []);
      exerciseRecords[record.exerciseId]!.add(record);
    }

    String? bestExerciseId;
    double bestGrowth = double.negativeInfinity;

    for (final entry in exerciseRecords.entries) {
      final sortedRecords = entry.value..sort((a, b) => a.date.compareTo(b.date));
      if (sortedRecords.length >= 2) {
        final firstVolume = sortedRecords.first.totalVolume;
        final lastVolume = sortedRecords.last.totalVolume;
        if (firstVolume > 0) {
          final growth = ((lastVolume - firstVolume) / firstVolume) * 100;
          if (growth > bestGrowth) {
            bestGrowth = growth;
            bestExerciseId = entry.key;
          }
        }
      }
    }

    if (bestExerciseId == null) return null;

    return {
      'name': _getExerciseName(bestExerciseId),
      'growth': bestGrowth,
    };
  }

  // 운동 이름 가져오기
  String _getExerciseName(String exerciseId) {
    final exercise = _exercises.firstWhere(
      (e) => e.id == exerciseId,
      orElse: () => Exercise(id: '', name: '알 수 없음', tag: ''),
    );
    return exercise.name;
  }

  // 운동 태그 가져오기
  String _getExerciseTag(String exerciseId) {
    final exercise = _exercises.firstWhere(
      (e) => e.id == exerciseId,
      orElse: () => Exercise(id: '', name: '', tag: ''),
    );
    return exercise.tag;
  }

  // 훈수/칭찬 메시지 생성
  String? _getMetamonMessage() {
    final random = Random(DateTime.now().day); // 매일 같은 메시지
    final workoutDays = _getMonthWorkoutDays();

    // 가능한 메시지들 수집
    final List<String> possibleMessages = [];

    // 1. 운동 횟수 체크
    if (workoutDays < workoutCountWarningThreshold) {
      final msg = workoutCountWarnings[random.nextInt(workoutCountWarnings.length)]
          .replaceAll('{count}', workoutDays.toString());
      possibleMessages.add(msg);
    } else if (workoutDays >= workoutCountPraiseThreshold) {
      final msg = workoutCountPraises[random.nextInt(workoutCountPraises.length)]
          .replaceAll('{count}', workoutDays.toString());
      possibleMessages.add(msg);
    }

    // 2. 오래 쉼 체크
    final daysSinceLastWorkout = _getDaysSinceLastWorkout();
    if (daysSinceLastWorkout != null && daysSinceLastWorkout >= restDaysWarningThreshold) {
      final msg = restDaysWarnings[random.nextInt(restDaysWarnings.length)]
          .replaceAll('{days}', daysSinceLastWorkout.toString());
      possibleMessages.add(msg);
    }

    // 3. 연속 운동 체크
    final streakDays = _getStreakDays();
    if (streakDays >= streakDaysPraiseThreshold) {
      final msg = streakPraises[random.nextInt(streakPraises.length)]
          .replaceAll('{days}', streakDays.toString());
      possibleMessages.add(msg);
    }

    // 4. 부위 밸런스 체크
    final bodyPartBalance = _getBodyPartBalance();
    if (bodyPartBalance != null) {
      final underBalanced = bodyPartBalance.entries
          .where((e) => e.value < bodyPartWarningThreshold && e.value > 0)
          .toList();

      if (underBalanced.isNotEmpty) {
        final weakPart = underBalanced.first;
        final msg = bodyPartWarnings[random.nextInt(bodyPartWarnings.length)]
            .replaceAll('{bodyPart}', weakPart.key)
            .replaceAll('{percent}', weakPart.value.toStringAsFixed(0));
        possibleMessages.add(msg);
      } else if (bodyPartBalance.values.every((v) => v >= bodyPartPraiseThreshold)) {
        possibleMessages.add(bodyPartPraises[random.nextInt(bodyPartPraises.length)]);
      }
    }

    // 5. 특정 운동 편식 체크
    final exerciseBias = _getExerciseBias();
    if (exerciseBias != null && exerciseBias['percent'] >= exerciseBiasWarningThreshold) {
      final msg = exerciseBiasWarnings[random.nextInt(exerciseBiasWarnings.length)]
          .replaceAll('{exercise}', exerciseBias['name'] as String)
          .replaceAll('{percent}', (exerciseBias['percent'] as double).toStringAsFixed(0));
      possibleMessages.add(msg);
    }

    // 6. 성장률 체크
    final bestGrowth = _getBestGrowthExercise();
    if (bestGrowth != null && bestGrowth['growth'] >= growthPraiseThreshold) {
      final msg = growthPraises[random.nextInt(growthPraises.length)]
          .replaceAll('{exercise}', bestGrowth['name'] as String)
          .replaceAll('{percent}', (bestGrowth['growth'] as double).toStringAsFixed(1));
      possibleMessages.add(msg);
    }

    if (possibleMessages.isEmpty) return null;

    // 랜덤으로 하나 선택
    return possibleMessages[random.nextInt(possibleMessages.length)];
  }

  // 마지막 운동 이후 경과 일수
  int? _getDaysSinceLastWorkout() {
    if (_allRecords.isEmpty) return null;

    final sortedRecords = _allRecords
        .where((r) => r.totalVolume > 0)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (sortedRecords.isEmpty) return null;

    final lastDate = DateTime.tryParse(sortedRecords.first.date);
    if (lastDate == null) return null;

    return DateTime.now().difference(lastDate).inDays;
  }

  // 연속 운동 일수
  int _getStreakDays() {
    final dates = _allRecords
        .where((r) => r.totalVolume > 0)
        .map((r) => r.date)
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // 최신순

    if (dates.isEmpty) return 0;

    int streak = 0;
    DateTime checkDate = DateTime.now();

    for (final dateStr in dates) {
      final date = DateTime.tryParse(dateStr);
      if (date == null) continue;

      final diff = checkDate.difference(date).inDays;
      if (diff <= 1) {
        streak++;
        checkDate = date;
      } else {
        break;
      }
    }

    return streak;
  }

  // 부위별 비율
  Map<String, double>? _getBodyPartBalance() {
    final records = _getMonthRecords();
    if (records.isEmpty) return null;

    final countMap = <String, int>{};
    int total = 0;

    for (final record in records) {
      final tag = _getExerciseTag(record.exerciseId);
      if (tag.isNotEmpty) {
        countMap[tag] = (countMap[tag] ?? 0) + 1;
        total++;
      }
    }

    if (total == 0) return null;

    return countMap.map((key, value) => MapEntry(key, (value / total) * 100));
  }

  // 특정 운동 편식 체크
  Map<String, dynamic>? _getExerciseBias() {
    final records = _getMonthRecords();
    if (records.isEmpty) return null;

    final countMap = <String, int>{};
    for (final record in records) {
      countMap[record.exerciseId] = (countMap[record.exerciseId] ?? 0) + 1;
    }

    if (countMap.isEmpty) return null;

    final total = countMap.values.reduce((a, b) => a + b);
    final mostFrequent = countMap.entries.reduce((a, b) => a.value > b.value ? a : b);
    final percent = (mostFrequent.value / total) * 100;

    return {
      'name': _getExerciseName(mostFrequent.key),
      'percent': percent,
    };
  }

  // 볼륨 포맷
  String _formatVolume(double volume) {
    if (volume >= 10000) {
      return '${(volume / 1000).toStringAsFixed(1)}t';
    }
    return '${volume.toStringAsFixed(0)}kg';
  }

  @override
  Widget build(BuildContext context) {
    final message = _getMetamonMessage();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 메타몽 섹션
              _buildMetamonSection(message),

              const SizedBox(height: 24),

              // 월간 분석 헤더
              _buildMonthHeader(),

              const SizedBox(height: 16),

              // 월간 통계
              _buildMonthlyStats(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetamonSection(String? message) {
    return Column(
      children: [
        // 훈수 말풍선 (메타몽 위에)
        if (message != null)
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // 말풍선 꼬리
              CustomPaint(
                size: const Size(20, 10),
                painter: _BubbleTailPainter(),
              ),
            ],
          ),

        // 메타몽 이미지
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            color: AppColors.primaryBackground,
            borderRadius: BorderRadius.circular(75),
          ),
          child: Center(
            child: Image.asset(
              'assets/metamon.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.catching_pokemon,
                      size: 60,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Lv.$_level',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 레벨 바 (메인)
        Column(
          children: [
            Text(
              'Lv.$_level',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            // 프로그레스 바
            SizedBox(
              width: 200,
              child: Container(
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.backgroundGrey,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: _levelProgress,
                      child: Container(
                        height: 12,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // 레벨 업까지 남은 횟수
            if (_level < maxLevel)
              Text(
                '레벨 업까지 남은 운동 횟수: ${_nextLevelRequirement - _currentXp}회',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              )
            else
              const Text(
                '만렙 달성!',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMonthHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 이전 달 버튼
        GestureDetector(
          onTap: _goToPreviousMonth,
          child: Container(
            padding: const EdgeInsets.all(8),
            child: const Icon(
              Icons.chevron_left,
              color: AppColors.textTertiary,
            ),
          ),
        ),

        // 월 표시
        Text(
          '${_currentMonth.year}년 ${_currentMonth.month}월',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),

        // 다음 달 버튼 (이번 달이면 숨김)
        GestureDetector(
          onTap: _isCurrentMonth ? null : _goToNextMonth,
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.chevron_right,
              color: _isCurrentMonth ? Colors.transparent : AppColors.textTertiary,
            ),
          ),
        ),
      ],
    );
  }

  // 주간 운동 빈도 계산
  String _getWeeklyFrequency() {
    final workoutDays = _getMonthWorkoutDays();

    // 현재 월의 경과 주 수 계산
    final now = DateTime.now();
    final isCurrentMonth = _currentMonth.year == now.year && _currentMonth.month == now.month;

    double weeksElapsed;
    if (isCurrentMonth) {
      // 이번 달이면 현재 날짜까지 경과한 주 수
      weeksElapsed = now.day / 7.0;
    } else {
      // 지난 달이면 해당 월의 총 일수를 주로 환산
      final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
      weeksElapsed = lastDayOfMonth / 7.0;
    }

    // 최소 1주 이상으로 설정 (0으로 나누기 방지)
    if (weeksElapsed < 1) weeksElapsed = 1;

    final frequency = workoutDays / weeksElapsed;

    // 소수점 첫째자리까지 표시, 정수면 정수로
    if (frequency == frequency.roundToDouble()) {
      return '주 ${frequency.toInt()}회';
    } else {
      return '주 ${frequency.toStringAsFixed(1)}회';
    }
  }

  Widget _buildMonthlyStats() {
    final workoutDays = _getMonthWorkoutDays();
    final totalVolume = _getMonthTotalVolume();
    final mostExercise = _getMostFrequentExercise();
    final mostBodyPart = _getMostFrequentBodyPart();
    final bestGrowth = _getBestGrowthExercise();

    if (workoutDays == 0) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: const Center(
          child: Text(
            '이 달의 운동 기록이 없습니다',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textHint,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildHorizontalStatCard(
          '운동 빈도',
          _getWeeklyFrequency(),
          Icons.fitness_center,
        ),
        const SizedBox(height: 12),
        _buildHorizontalStatCard(
          '총 볼륨',
          _formatVolume(totalVolume),
          Icons.show_chart,
        ),
        if (mostExercise != null) ...[
          const SizedBox(height: 12),
          _buildHorizontalStatCard(
            '많이 한 운동',
            mostExercise,
            Icons.star,
          ),
        ],
        if (mostBodyPart != null) ...[
          const SizedBox(height: 12),
          _buildHorizontalStatCard(
            '많이 한 부위',
            mostBodyPart,
            Icons.accessibility_new,
          ),
        ],
        if (bestGrowth != null) ...[
          const SizedBox(height: 12),
          _buildHorizontalStatCard(
            '성장률 최고',
            '${bestGrowth['name']} +${(bestGrowth['growth'] as double).toStringAsFixed(1)}%',
            Icons.trending_up,
          ),
        ],
      ],
    );
  }

  Widget _buildHorizontalStatCard(String title, String value, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// 말풍선 꼬리 그리기
class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
