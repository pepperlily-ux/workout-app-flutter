import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../constants/app_colors.dart';
import '../constants/metamon_messages.dart';
import '../services/storage_service.dart';
import '../models/record.dart';
import '../models/exercise.dart';
import 'settings_page.dart';

// 프로필 캐릭터 정의
const _profileCharacters = [
  {'id': 'baby', 'type': 'asset', 'value': 'assets/Baby.png'},
  {'id': 'normal', 'type': 'asset', 'value': 'assets/Normal.png'},
  {'id': 'power', 'type': 'asset', 'value': 'assets/Power.png'},
  {'id': 'sad', 'type': 'asset', 'value': 'assets/Sad.png'},
  {'id': 'heart', 'type': 'icon', 'value': 'heart'},
  {'id': 'star', 'type': 'icon', 'value': 'star'},
  {'id': 'bang', 'type': 'icon', 'value': 'bang'},
  {'id': 'dumbbell', 'type': 'icon', 'value': 'dumbbell'},
];

// 파스텔 무지개 14색 (7열 2행)
const _profileColors = [
  0xFFFFB3BA, // 핑크
  0xFFFFCBA4, // 살구
  0xFFFFD9A0, // 복숭아
  0xFFFFEE99, // 노랑
  0xFFD4F0A0, // 연두
  0xFFB3E8B3, // 초록
  0xFFA0E8D4, // 민트
  0xFFA0D4F0, // 하늘
  0xFFA0B8F8, // 파랑
  0xFFB8A0F8, // 보라
  0xFFD4A0F8, // 라벤더
  0xFFF0A0E8, // 연보라
  0xFFF8C0D0, // 로즈
  0xFFD0E8E0, // 세이지
];

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => AnalysisPageState();
}

class AnalysisPageState extends State<AnalysisPage> {
  void reload() => _loadData();
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

  // 프로필 데이터
  String _profileCharacter = 'baby';
  int _profileColor = 0xFFFFEE99;
  String _profileName = '헬스몽';

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
      _profileCharacter = _storage.getProfileCharacter();
      _profileColor = _storage.getProfileColor();
      _profileName = _storage.getProfileName();
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
    final nextLevelReq = _level < maxLevel
        ? levelRequirements[_level + 1]!
        : currentLevelReq;
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
    final monthStr =
        '${_currentMonth.year}-${_currentMonth.month.toString().padLeft(2, '0')}';
    return _allRecords
        .where((r) => r.date.startsWith(monthStr) && r.totalVolume > 0)
        .toList();
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

    return countMap.entries.reduce((a, b) => a.value > b.value ? a : b).key;
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
      final sortedRecords = entry.value
        ..sort((a, b) => a.date.compareTo(b.date));
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

    return {'name': _getExerciseName(bestExerciseId), 'growth': bestGrowth};
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

  // 볼륨 포맷
  String _formatVolume(double volume) {
    if (volume >= 10000) {
      return '${(volume / 1000).toStringAsFixed(1)}t';
    }
    return '${volume.toStringAsFixed(0)}kg';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 메타몽 섹션
              _buildMetamonSection(),

              const SizedBox(height: 15),

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

  Widget _buildProfileWidget() {
    final char = _profileCharacters.firstWhere(
      (c) => c['id'] == _profileCharacter,
      orElse: () => _profileCharacters.first,
    );
    Widget inner;
    if (char['type'] == 'asset') {
      inner = Image.asset(
        char['value']!,
        width: 36,
        height: 36,
        fit: BoxFit.contain,
      );
    } else {
      IconData icon;
      switch (char['value']) {
        case 'star':
          icon = LucideIcons.star;
          break;
        case 'bang':
          icon = LucideIcons.alertCircle;
          break;
        case 'dumbbell':
          icon = LucideIcons.dumbbell;
          break;
        default:
          icon = LucideIcons.heart;
      }
      inner = Icon(icon, size: 32, color: Colors.white);
    }
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Color(_profileColor),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Center(child: inner),
    );
  }

  void _showProfileEditor() {
    String tempChar = _profileCharacter;
    int tempColor = _profileColor;
    String tempName = _profileName;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          Widget previewInner;
          final char = _profileCharacters.firstWhere(
            (c) => c['id'] == tempChar,
          );
          if (char['type'] == 'asset') {
            previewInner = Image.asset(
              char['value']!,
              width: 36,
              height: 36,
              fit: BoxFit.contain,
            );
          } else {
            IconData icon;
            switch (char['value']) {
              case 'star':
                icon = LucideIcons.star;
                break;
              case 'bang':
                icon = LucideIcons.alertCircle;
                break;
              case 'dumbbell':
                icon = LucideIcons.dumbbell;
                break;
              default:
                icon = LucideIcons.heart;
            }
            previewInner = Icon(icon, size: 32, color: Colors.white);
          }

          return SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom:
                  16 +
                  MediaQuery.of(ctx).viewInsets.bottom +
                  MediaQuery.of(ctx).padding.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '프로필 꾸미기',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await _storage.saveProfileCharacter(tempChar);
                        await _storage.saveProfileColor(tempColor);
                        await _storage.saveProfileName(tempName);
                        setState(() {
                          _profileCharacter = tempChar;
                          _profileColor = tempColor;
                          _profileName = tempName.trim().isEmpty
                              ? '헬스몽'
                              : tempName.trim();
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        '완료',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 미리보기
                Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Color(tempColor),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Center(child: previewInner),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '사용자 이름',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: tempName,
                  onChanged: (value) => tempName = value,
                  maxLength: 12,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: '헬스몽',
                    counterText: '',
                    filled: true,
                    fillColor: AppColors.backgroundGrey,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '캐릭터',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.0,
                  children: _profileCharacters.map((c) {
                    final isSelected = c['id'] == tempChar;
                    Widget inner;
                    if (c['type'] == 'asset') {
                      inner = Image.asset(
                        c['value']!,
                        width: 44,
                        height: 44,
                        fit: BoxFit.contain,
                      );
                    } else {
                      IconData icon;
                      switch (c['value']) {
                        case 'star':
                          icon = LucideIcons.star;
                          break;
                        case 'bang':
                          icon = LucideIcons.alertCircle;
                          break;
                        case 'dumbbell':
                          icon = LucideIcons.dumbbell;
                          break;
                        default:
                          icon = LucideIcons.heart;
                      }
                      inner = Icon(icon, size: 36, color: Colors.white);
                    }
                    return GestureDetector(
                      onTap: () => setModalState(() => tempChar = c['id']!),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryBackground
                              : AppColors.backgroundGrey,
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(color: AppColors.primary, width: 2)
                              : null,
                        ),
                        child: Center(child: inner),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                const Text(
                  '배경 컬러',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 7,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  children: _profileColors.map((color) {
                    final isSelected = color == tempColor;
                    return GestureDetector(
                      onTap: () => setModalState(() => tempColor = color),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color(color),
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: AppColors.primary, width: 2.5)
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(
                                LucideIcons.check,
                                size: 16,
                                color: AppColors.primary,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetamonSection() {
    return Row(
      children: [
        GestureDetector(
          onTap: _showProfileEditor,
          child: _buildProfileWidget(),
        ),
        const SizedBox(width: 16),
        // 레벨 + 프로그레스 바
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _showProfileEditor,
                      behavior: HitTestBehavior.opaque,
                      child: Text(
                        'Lv.$_level $_profileName',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsPage()),
                      );
                    },
                    icon: const Icon(LucideIcons.settings),
                    iconSize: 20,
                    color: AppColors.textTertiary,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
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
                      child: Container(height: 12, color: AppColors.primary),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Align(
                alignment: Alignment.centerRight,
                child: _level < maxLevel
                    ? Text(
                        '$_currentXp/$_nextLevelRequirement회',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      )
                    : const Text(
                        '만렙 달성!',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ],
          ),
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
              LucideIcons.chevronLeft,
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
              LucideIcons.chevronRight,
              color: _isCurrentMonth
                  ? Colors.transparent
                  : AppColors.textTertiary,
            ),
          ),
        ),
      ],
    );
  }

  // 이전 달 대비 총 볼륨 성장률
  String? _getOverallGrowthRate() {
    final prevMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    final prevMonthStr =
        '${prevMonth.year}-${prevMonth.month.toString().padLeft(2, '0')}';
    final prevVolume = _allRecords
        .where((r) => r.date.startsWith(prevMonthStr) && r.totalVolume > 0)
        .fold(0.0, (sum, r) => sum + r.totalVolume);

    if (prevVolume == 0) return null;

    final currentVolume = _getMonthTotalVolume();
    final growth = ((currentVolume - prevVolume) / prevVolume) * 100;
    final sign = growth >= 0 ? '+' : '';
    return '$sign${growth.toStringAsFixed(1)}%';
  }

  // 주간 운동 빈도 계산
  String _getWeeklyFrequency() {
    final workoutDays = _getMonthWorkoutDays();

    // 현재 월의 경과 주 수 계산
    final now = DateTime.now();
    final isCurrentMonth =
        _currentMonth.year == now.year && _currentMonth.month == now.month;

    double weeksElapsed;
    if (isCurrentMonth) {
      // 이번 달이면 현재 날짜까지 경과한 주 수
      weeksElapsed = now.day / 7.0;
    } else {
      // 지난 달이면 해당 월의 총 일수를 주로 환산
      final lastDayOfMonth = DateTime(
        _currentMonth.year,
        _currentMonth.month + 1,
        0,
      ).day;
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
    final overallGrowth = _getOverallGrowthRate();

    if (workoutDays == 0) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 32),
            Image.asset('assets/Sad.png', width: 200),
            const SizedBox(height: 16),
            const Text(
              '이 달의 운동 기록이 없습니다',
              style: TextStyle(fontSize: 14, color: AppColors.textHint),
            ),
            const SizedBox(height: 32),
          ],
        ),
      );
    }

    final stats = <Map<String, dynamic>>[
      {
        'title': '운동 빈도',
        'value': _getWeeklyFrequency(),
        'icon': LucideIcons.flame,
      },
      {
        'title': '헬스장 간 횟수',
        'value': '$workoutDays일',
        'icon': LucideIcons.calendar,
      },
      {
        'title': '총 볼륨',
        'value': _formatVolume(totalVolume),
        'icon': LucideIcons.lineChart,
      },
      {
        'title': '전달 대비 성장률',
        'value': overallGrowth ?? '+0.0%',
        'icon': LucideIcons.trendingUp,
      },
      {
        'title': '많이 한 운동',
        'value': mostExercise ?? '없음',
        'icon': LucideIcons.dumbbell,
      },
      {
        'title': '많이 한 부위',
        'value': mostBodyPart ?? '없음',
        'icon': LucideIcons.personStanding,
      },
      {
        'title': '성장률 최고',
        'value': bestGrowth != null
            ? '${bestGrowth['name']} +${(bestGrowth['growth'] as double).toStringAsFixed(1)}%'
            : '없음 +0.0%',
        'icon': LucideIcons.trophy,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: stats.length + 1,
      itemBuilder: (context, index) {
        if (index == stats.length) {
          return _buildAnalysisImageCard();
        }

        final stat = stats[index];
        return _buildStatCard(
          stat['title'] as String,
          stat['value'] as String,
          stat['icon'] as IconData,
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisImageCard() {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: const Color(0xFFA295D5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Image.asset(
        'assets/analysis.png',
        fit: BoxFit.fitHeight,
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }
}
