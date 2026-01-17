import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/exercise.dart';
import '../models/record.dart';
import '../models/routine.dart';
import '../models/workout_set.dart';
import '../services/storage_service.dart';
import '../widgets/custom_keyboard.dart';
import '../constants/app_colors.dart';
import 'exercise_select_page.dart';
import 'routine_select_page.dart';

// 홈 화면
class HomePage extends StatefulWidget {
  final String? initialDate; // 외부에서 전달받은 초기 날짜 (yyyy-MM-dd)

  const HomePage({
    super.key,
    this.initialDate,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final StorageService _storage = StorageService();

  late DateTime selectedDate;
  List<Record> dateRecords = [];
  List<Exercise> exercises = [];
  List<Routine> routines = [];
  Map<String, bool> checkedSets = {};

  // 메모 관련
  final TextEditingController _memoController = TextEditingController();
  final FocusNode _memoFocusNode = FocusNode();

  // 커스텀 키보드 상태
  bool _isKeyboardVisible = false;
  String? _activeRecordId;
  int? _activeSetIndex;
  String? _activeField; // 'weight' or 'reps'
  String _currentValue = '';
  bool _isFirstInput = true; // 첫 입력 시 기존 값 덮어쓰기용

  @override
  void initState() {
    super.initState();
    // 외부에서 전달받은 날짜가 있으면 그 날짜로, 아니면 오늘 날짜로 초기화
    if (widget.initialDate != null) {
      selectedDate = DateTime.tryParse(widget.initialDate!) ?? DateTime.now();
    } else {
      selectedDate = DateTime.now();
    }
    _loadData();
  }

  @override
  void dispose() {
    _removeKeyboardOverlay();
    _memoController.dispose();
    _memoFocusNode.dispose();
    super.dispose();
  }

  // 데이터 불러오기
  Future<void> _loadData() async {
    await _storage.init();
    setState(() {
      exercises = _storage.getExercises();
      routines = _storage.getRoutines();
      checkedSets = _storage.getCheckedSets();
      _loadDateRecords();
    });
  }

  // 선택된 날짜의 기록 불러오기
  void _loadDateRecords() {
    final dateStr = _formatDate(selectedDate);
    dateRecords = _storage.getRecordsByDate(dateStr);
    // 메모 불러오기
    _memoController.text = _storage.getDailyMemo(dateStr) ?? '';
  }

  // 메모 저장
  Future<void> _saveMemo(String memo) async {
    final dateStr = _formatDate(selectedDate);
    await _storage.saveDailyMemo(dateStr, memo);
  }

  // 메모 섹션 위젯
  Widget _buildMemoSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '오늘의 메모',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _memoController,
            focusNode: _memoFocusNode,
            maxLines: 3,
            minLines: 2,
            decoration: InputDecoration(
              hintText: '오늘 운동에 대한 메모를 남겨보세요',
              hintStyle: const TextStyle(
                color: AppColors.textHint,
                fontSize: 14,
              ),
              filled: true,
              fillColor: AppColors.backgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
            onChanged: _saveMemo,
          ),
        ],
      ),
    );
  }

  // 날짜 포맷 (yyyy-MM-dd)
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // 날짜를 한국어로 포맷 (예: "1월 4일 토요일")
  String _formatDateKorean(DateTime date) {
    const weekdays = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
    final weekday = weekdays[date.weekday - 1];
    return '${date.month}월 ${date.day}일 $weekday';
  }

  // 오늘인지 확인
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  // 오늘 날짜로 이동
  void _goToToday() {
    setState(() {
      selectedDate = DateTime.now();
      _loadDateRecords();
    });
  }

  // 날짜 선택
  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        _loadDateRecords();
      });
    }
  }

  // 운동 이름 가져오기
  String _getExerciseName(String exerciseId) {
    final exercise = exercises.firstWhere(
      (e) => e.id == exerciseId,
      orElse: () => Exercise(id: '', name: '알 수 없음', tag: ''),
    );
    return exercise.name;
  }

  // 운동 추가 (기록에)
  Future<void> _addExerciseToRecord(Exercise exercise) async {
    // 이전 기록에서 세트 정보 가져오기
    final history = _storage.getExerciseHistory(exercise.id);
    List<WorkoutSet> initialSets = [];

    if (history.isNotEmpty) {
      // 가장 최근 기록의 세트를 복사
      initialSets = history.first.sets.map((s) => WorkoutSet(
        weight: s.weight,
        reps: s.reps,
      )).toList();
    } else {
      // 이전 기록이 없으면 빈 세트 1개
      initialSets = [WorkoutSet()];
    }

    final record = Record(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: _formatDate(selectedDate),
      exerciseId: exercise.id,
      sets: initialSets,
      order: dateRecords.length,
    );

    await _storage.addRecord(record);
    setState(() {
      _loadDateRecords();
    });
  }

  // 루틴 선택 (여러 운동 한번에 추가)
  Future<void> _selectRoutine(Routine routine) async {
    for (final exerciseId in routine.exerciseIds) {
      final exercise = exercises.firstWhere(
        (e) => e.id == exerciseId,
        orElse: () => Exercise(id: '', name: '', tag: ''),
      );
      if (exercise.id.isNotEmpty) {
        await _addExerciseToRecord(exercise);
      }
    }
  }

  // 세트 추가 - 원본 로직: 이전 운동 참조 → 오늘 마지막 세트 → 빈 세트
  Future<void> _addSet(Record record) async {
    final nextSetIndex = record.sets.length;
    WorkoutSet newSet;

    // 1순위: 이전 운동 기록에서 같은 인덱스의 세트 가져오기
    final history = _storage.getExerciseHistory(record.exerciseId);
    final selectedDateStr = _formatDate(selectedDate);

    // 오늘 이전의 가장 최근 기록 찾기
    Record? previousRecord;
    for (final r in history) {
      if (r.date.compareTo(selectedDateStr) < 0 && r.totalVolume > 0) {
        previousRecord = r;
        break;
      }
    }

    if (previousRecord != null && nextSetIndex < previousRecord.sets.length) {
      // 이전 운동에 해당 인덱스 세트가 있으면 복사
      final prevSet = previousRecord.sets[nextSetIndex];
      newSet = WorkoutSet(weight: prevSet.weight, reps: prevSet.reps);
    } else if (record.sets.isNotEmpty) {
      // 2순위: 오늘 마지막 세트 복사
      final lastSet = record.sets.last;
      newSet = WorkoutSet(weight: lastSet.weight, reps: lastSet.reps);
    } else {
      // 3순위: 빈 세트
      newSet = WorkoutSet();
    }

    record.sets.add(newSet);
    await _storage.updateRecord(record);
    setState(() {
      _loadDateRecords();
    });
  }

  // 세트 삭제
  Future<void> _removeSet(Record record) async {
    if (record.sets.isNotEmpty) {
      record.sets.removeLast();
      await _storage.updateRecord(record);
      setState(() {
        _loadDateRecords();
      });
    }
  }

  // 세트 체크 토글
  Future<void> _toggleCheck(String recordId, int setIndex) async {
    await _storage.toggleSetCheck(recordId, setIndex);
    setState(() {
      checkedSets = _storage.getCheckedSets();
    });
  }

  // 세트 값 업데이트
  Future<void> _updateSet(Record record, int setIndex, {double? weight, int? reps}) async {
    if (setIndex < record.sets.length) {
      if (weight != null) record.sets[setIndex].weight = weight;
      if (reps != null) record.sets[setIndex].reps = reps;
      await _storage.updateRecord(record);
      setState(() {
        _loadDateRecords();
      });
    }
  }

  // 기록 삭제
  Future<void> _deleteRecord(String recordId) async {
    await _storage.deleteRecord(recordId);
    setState(() {
      _loadDateRecords();
    });
  }

  // 성장률 계산 (개별 운동) - 원본 PWA와 동일한 로직
  double? _calculateGrowth(String exerciseId) {
    final history = _storage.getExerciseHistory(exerciseId);
    final selectedDateStr = _formatDate(selectedDate);

    // 선택된 날짜의 기록 찾기
    final todayRecord = history.firstWhere(
      (r) => r.date == selectedDateStr,
      orElse: () => Record(id: '', date: '', exerciseId: '', sets: []),
    );

    // 이전 기록 찾기: 선택된 날짜보다 이전 날짜 중 가장 최근 기록
    // history는 이미 최신순 정렬되어 있음 (getExerciseHistory에서)
    Record? previousRecord;
    for (final r in history) {
      if (r.date.compareTo(selectedDateStr) < 0 && r.totalVolume > 0) {
        previousRecord = r;
        break;
      }
    }

    if (todayRecord.id.isEmpty || previousRecord == null) return null;
    if (todayRecord.totalVolume == 0 || previousRecord.totalVolume == 0) return null;

    final growth = ((todayRecord.totalVolume - previousRecord.totalVolume) / previousRecord.totalVolume) * 100;
    return growth;
  }

  // 루틴 전체 성장률 계산 - 원본 PWA와 동일한 로직
  // 원본: 총 볼륨을 합산한 후 비율 계산 (개별 성장률 평균 X)
  Map<String, dynamic>? _calculateRoutineGrowth() {
    if (dateRecords.isEmpty) return null;

    final selectedDateStr = _formatDate(selectedDate);
    double totalCurrentVolume = 0;
    double totalPreviousVolume = 0;
    int commonCount = 0;
    String? mostRecentComparisonDate;
    List<Map<String, dynamic>> comparisons = [];

    for (final record in dateRecords) {
      // 볼륨이 있는 기록만 처리
      if (record.totalVolume <= 0) continue;

      final history = _storage.getExerciseHistory(record.exerciseId);

      // 이전 기록 찾기: 선택된 날짜보다 이전 날짜 중 가장 최근 기록
      Record? previousRecord;
      for (final r in history) {
        if (r.date.compareTo(selectedDateStr) < 0 && r.totalVolume > 0) {
          previousRecord = r;
          break;
        }
      }

      if (previousRecord != null) {
        final currentVolume = record.totalVolume;
        final previousVolume = previousRecord.totalVolume;

        totalCurrentVolume += currentVolume;
        totalPreviousVolume += previousVolume;
        commonCount++;

        // 가장 최근 비교 날짜 추적
        if (mostRecentComparisonDate == null || previousRecord.date.compareTo(mostRecentComparisonDate) > 0) {
          mostRecentComparisonDate = previousRecord.date;
        }

        // 비교 데이터 저장 (모달에서 사용)
        comparisons.add({
          'exerciseId': record.exerciseId,
          'currentRecord': record,
          'previousRecord': previousRecord,
          'currentVolume': currentVolume,
          'previousVolume': previousVolume,
          'growth': ((currentVolume - previousVolume) / previousVolume) * 100,
        });
      }
    }

    if (commonCount == 0 || totalPreviousVolume == 0) return null;

    // 총 볼륨 비교로 성장률 계산 (원본과 동일)
    final growth = ((totalCurrentVolume - totalPreviousVolume) / totalPreviousVolume) * 100;

    return {
      'growth': growth,
      'previousDate': mostRecentComparisonDate,
      'commonCount': commonCount,
      'comparisons': comparisons,
    };
  }

  // 성장률에 따른 메시지 반환
  String _getGrowthMessage(double growth) {
    if (growth < -5) return '오늘은 퇴보하는 날이었네요';
    if (growth >= -5 && growth <= 0) return '오늘은 성장하지 못했습니다';
    if (growth > 0 && growth < 1.5) return '미세하지만 좋은 시도였습니다';
    if (growth >= 1.5 && growth < 3) return '근육이 성장하는 최적의 구간!';
    if (growth >= 3 && growth < 5) return '근육에 강한 자극을 받았습니다.';
    if (growth >= 5) return '헉! 너무 무리하시는거 아니에요?';
    return '';
  }

  // 날짜 문자열을 한국어로 변환
  String _formatDateStrKorean(String dateStr) {
    final parts = dateStr.split('-');
    if (parts.length != 3) return dateStr;
    return '${int.parse(parts[1])}월 ${int.parse(parts[2])}일';
  }

  // 루틴 선택 페이지로 이동
  void _showRoutineModal() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoutineSelectPage(
          routines: routines,
          exercises: exercises,
          onSelect: (routine) {
            _selectRoutine(routine);
          },
          onAddNew: (name, exerciseIds) async {
            final newRoutine = Routine(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: name,
              exerciseIds: exerciseIds,
            );
            routines.add(newRoutine);
            await _storage.saveRoutines(routines);
            setState(() {});
          },
        ),
      ),
    );
  }

  // 운동 선택 페이지로 이동
  void _showExerciseModal() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseSelectPage(
          exercises: exercises,
          storage: _storage,
          onSelectMultiple: (selectedExercises) async {
            for (final exercise in selectedExercises) {
              await _addExerciseToRecord(exercise);
            }
          },
          onAddNew: (name, tag) async {
            final exercise = Exercise(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: name,
              tag: tag,
            );
            await _storage.addExercise(exercise);
            setState(() {
              exercises = _storage.getExercises();
            });
            _addExerciseToRecord(exercise);
          },
        ),
      ),
    );
  }

  // 순서 변경 모달 표시
  void _showOrderModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (modalContext) => _OrderChangeModal(
        records: dateRecords,
        exercises: exercises,
        onOrderChanged: (newRecords) async {
          for (int i = 0; i < newRecords.length; i++) {
            newRecords[i].order = i;
            await _storage.updateRecord(newRecords[i]);
          }
          setState(() {
            _loadDateRecords();
          });
          if (modalContext.mounted) Navigator.pop(modalContext);
        },
        onDelete: (recordId) async {
          await _deleteRecord(recordId);
          if (modalContext.mounted) Navigator.pop(modalContext);
        },
      ),
    );
  }

  // 성장률 상세 모달 표시
  void _showGrowthDetailModal(Map<String, dynamic> routineGrowth) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _GrowthDetailModal(
        routineGrowth: routineGrowth,
        exercises: exercises,
        formatDateStrKorean: _formatDateStrKorean,
      ),
    );
  }

  // 개별 운동 히스토리 모달 표시
  void _showExerciseHistoryModal(String exerciseId, String exerciseName) {
    // 볼륨이 0보다 큰 기록만 표시
    final history = _storage.getExerciseHistory(exerciseId)
        .where((r) => r.totalVolume > 0)
        .toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _ExerciseHistoryModal(
        exerciseName: exerciseName,
        history: history,
        formatDateStrKorean: _formatDateStrKorean,
      ),
    );
  }

  // 이전 난이도 가져오기
  String? _getPreviousDifficulty(Record record) {
    final history = _storage.getExerciseHistory(record.exerciseId);
    for (final r in history) {
      if (r.date.compareTo(record.date) < 0 && r.difficulty != null) {
        return r.difficulty;
      }
    }
    return null;
  }

  // 난이도 선택 모달 표시
  void _showDifficultyModal(Record record, String exerciseName) {
    // 이전 기록에서 난이도 가져오기
    final history = _storage.getExerciseHistory(record.exerciseId);
    String? previousDifficulty;
    for (final r in history) {
      if (r.date.compareTo(record.date) < 0 && r.difficulty != null) {
        previousDifficulty = r.difficulty;
        break;
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (modalContext) => _DifficultyModal(
        exerciseName: exerciseName,
        currentDifficulty: record.difficulty,
        previousDifficulty: previousDifficulty,
        onSelect: (difficulty) async {
          record.difficulty = difficulty;
          await _storage.updateRecord(record);
          setState(() {
            _loadDateRecords();
          });
          if (modalContext.mounted) Navigator.pop(modalContext);
        },
        onDelete: () async {
          await _deleteRecord(record.id);
          if (modalContext.mounted) Navigator.pop(modalContext);
        },
      ),
    );
  }

  OverlayEntry? _keyboardOverlay;

  // 커스텀 키보드 표시
  void _showKeyboard(String recordId, int setIndex, String field, String initialValue) {
    setState(() {
      _isKeyboardVisible = true;
      _activeRecordId = recordId;
      _activeSetIndex = setIndex;
      _activeField = field;
      _currentValue = initialValue;
      _isFirstInput = true; // 필드 전환 시 첫 입력 상태로 리셋
    });
    _showKeyboardOverlay();
  }

  // 키보드 Overlay 표시
  void _showKeyboardOverlay() {
    _removeKeyboardOverlay();
    // SafeArea 적용 전의 원본 viewPadding을 가져옴
    final view = View.of(context);
    final bottomPadding = MediaQueryData.fromView(view).viewPadding.bottom;
    _keyboardOverlay = OverlayEntry(
      builder: (overlayContext) {
        return Stack(
          children: [
            // 키보드 외부 영역 - 탭하면 키보드 닫기
            Positioned.fill(
              child: GestureDetector(
                onTap: _hideKeyboard,
                behavior: HitTestBehavior.opaque,
                child: Container(color: Colors.transparent),
              ),
            ),
            // 키보드 + 하단 패딩 영역
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Material(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomKeyboard(
                      onKeyPressed: _handleKeyboardInput,
                      onNext: _moveToNextField,
                      onClose: _hideKeyboard,
                    ),
                    // 시스템 네비게이션 바 영역 (키보드와 같은 배경색)
                    Container(
                      height: bottomPadding,
                      color: const Color(0xFFCCCCCC),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
    Overlay.of(context).insert(_keyboardOverlay!);
  }

  // 키보드 Overlay 제거
  void _removeKeyboardOverlay() {
    _keyboardOverlay?.remove();
    _keyboardOverlay = null;
  }

  // 커스텀 키보드 숨기기
  void _hideKeyboard() {
    // 현재 값 저장
    if (_activeRecordId != null && _activeSetIndex != null && _activeField != null) {
      final record = dateRecords.firstWhere(
        (r) => r.id == _activeRecordId,
        orElse: () => Record(id: '', date: '', exerciseId: '', sets: []),
      );
      if (record.id.isNotEmpty && _activeSetIndex! < record.sets.length) {
        if (_activeField == 'weight') {
          final weight = double.tryParse(_currentValue);
          if (weight != null) {
            _updateSet(record, _activeSetIndex!, weight: weight);
          }
        } else if (_activeField == 'reps') {
          final reps = int.tryParse(_currentValue);
          if (reps != null) {
            _updateSet(record, _activeSetIndex!, reps: reps);
          }
        }
      }
    }

    setState(() {
      _isKeyboardVisible = false;
      _activeRecordId = null;
      _activeSetIndex = null;
      _activeField = null;
      _currentValue = '';
    });
    _removeKeyboardOverlay();
  }

  // 입력 제한 상수
  static const int _weightMax = 999;
  static const int _repsMax = 99;
  static const int _weightMaxLen = 5; // 999.9
  static const int _repsMaxLen = 2;   // 99

  // 키보드 입력 처리
  void _handleKeyboardInput(String key) {
    setState(() {
      // 숫자 키인지 확인
      final isNumberKey = RegExp(r'^[0-9]$').hasMatch(key);

      if (key == 'backspace') {
        if (_currentValue.isNotEmpty) {
          _currentValue = _currentValue.substring(0, _currentValue.length - 1);
        }
        _isFirstInput = false;
      } else if (key.startsWith('+') || key.startsWith('-')) {
        // 증감 연산
        final modifier = int.tryParse(key) ?? 0;
        final current = double.tryParse(_currentValue) ?? 0;
        final newValue = current + modifier;

        // 최대값 제한 적용
        final maxVal = _activeField == 'weight' ? _weightMax : _repsMax;
        if (newValue >= 0 && newValue <= maxVal) {
          if (newValue == newValue.toInt()) {
            _currentValue = newValue.toInt().toString();
          } else {
            _currentValue = newValue.toString();
          }
        }
        _isFirstInput = false;
      } else if (key == '.') {
        // 횟수(reps)에는 소수점 입력 방지
        if (_activeField == 'reps') return;

        // 첫 입력 시 기존 값 지우고 "0."으로 시작
        if (_isFirstInput && _currentValue.isNotEmpty) {
          _currentValue = '0.';
          _isFirstInput = false;
          return;
        }

        if (!_currentValue.contains('.')) {
          if (_currentValue.isEmpty) {
            _currentValue = '0.';
          } else {
            _currentValue += '.';
          }
        }
        _isFirstInput = false;
      } else if (isNumberKey) {
        // 첫 입력이고 기존 값이 있으면 덮어쓰기
        if (_isFirstInput && _currentValue.isNotEmpty && _currentValue != '0') {
          // 최대값 체크
          final newValue = double.tryParse(key);
          if (newValue != null) {
            final maxVal = _activeField == 'weight' ? _weightMax : _repsMax;
            if (newValue <= maxVal) {
              _currentValue = key;
            }
          }
          _isFirstInput = false;
          return;
        }

        // 글자 수 제한 체크
        final maxLen = _activeField == 'weight' ? _weightMaxLen : _repsMaxLen;
        if (_currentValue.length >= maxLen) return;

        // 새 값 미리 계산해서 최대값 체크
        final newValueStr = _currentValue + key;
        final newValue = double.tryParse(newValueStr);
        if (newValue != null) {
          final maxVal = _activeField == 'weight' ? _weightMax : _repsMax;
          if (newValue > maxVal) return;
        }

        _currentValue += key;
        _isFirstInput = false;
      }

      // 실시간으로 값 업데이트
      if (_activeRecordId != null && _activeSetIndex != null && _activeField != null) {
        final record = dateRecords.firstWhere(
          (r) => r.id == _activeRecordId,
          orElse: () => Record(id: '', date: '', exerciseId: '', sets: []),
        );
        if (record.id.isNotEmpty && _activeSetIndex! < record.sets.length) {
          if (_activeField == 'weight') {
            final weight = double.tryParse(_currentValue);
            record.sets[_activeSetIndex!].weight = weight;
            _storage.updateRecord(record);
          } else if (_activeField == 'reps') {
            final reps = int.tryParse(_currentValue);
            record.sets[_activeSetIndex!].reps = reps;
            _storage.updateRecord(record);
          }
        }
      }
    });
  }

  // 다음 필드로 이동
  void _moveToNextField() {
    if (_activeRecordId == null || _activeSetIndex == null || _activeField == null) return;

    final recordIndex = dateRecords.indexWhere((r) => r.id == _activeRecordId);
    if (recordIndex == -1) return;

    final record = dateRecords[recordIndex];

    if (_activeField == 'weight') {
      // 무게 -> 횟수로 이동
      final repsValue = record.sets[_activeSetIndex!].reps?.toString() ?? '';
      _showKeyboard(_activeRecordId!, _activeSetIndex!, 'reps', repsValue);
    } else if (_activeField == 'reps') {
      // 횟수 -> 다음 세트의 무게로 이동
      if (_activeSetIndex! + 1 < record.sets.length) {
        // 같은 운동의 다음 세트
        final weightValue = record.sets[_activeSetIndex! + 1].weight?.toString() ?? '';
        _showKeyboard(_activeRecordId!, _activeSetIndex! + 1, 'weight', weightValue);
      } else if (recordIndex + 1 < dateRecords.length) {
        // 다음 운동의 첫 번째 세트
        final nextRecord = dateRecords[recordIndex + 1];
        if (nextRecord.sets.isNotEmpty) {
          final weightValue = nextRecord.sets[0].weight?.toString() ?? '';
          _showKeyboard(nextRecord.id, 0, 'weight', weightValue);
        } else {
          _hideKeyboard();
        }
      } else {
        // 마지막 필드면 키보드 닫기
        _hideKeyboard();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Column(
            children: [
              // 상단 헤더 영역 (고정)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  children: [
                    // 날짜 헤더
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 왼쪽: 날짜 + Today 뱃지
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  _formatDateKorean(selectedDate),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Today 뱃지 또는 버튼
                              if (_isToday(selectedDate))
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Today',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                )
                              else
                                GestureDetector(
                                  onTap: _goToToday,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.backgroundGrey,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Today',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textHint,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // 오른쪽: 캘린더 아이콘 + 메뉴 아이콘
                        Row(
                          children: [
                            GestureDetector(
                              onTap: _selectDate,
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: SvgPicture.asset(
                                  'assets/icons/calendar.svg',
                                  width: 24,
                                  height: 24,
                                  colorFilter: const ColorFilter.mode(
                                    AppColors.textMuted,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: _showOrderModal,
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(
                                  Icons.menu,
                                  size: 24,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                const SizedBox(height: 16),

                // 루틴 성장률 카드
                Builder(
                  builder: (context) {
                    final routineGrowth = _calculateRoutineGrowth();
                    if (routineGrowth == null) return const SizedBox.shrink();

                    final growth = routineGrowth['growth'] as double;
                    final previousDate = routineGrowth['previousDate'] as String?;
                    final commonCount = routineGrowth['commonCount'] as int;

                    // 성장률에 따른 색상
                    Color bgColor;
                    Color borderColor;
                    Color textColor;

                    if (growth > 0) {
                      bgColor = AppColors.successBackground;
                      borderColor = AppColors.successLight;
                      textColor = AppColors.success;
                    } else if (growth == 0) {
                      bgColor = AppColors.primaryBackground;
                      borderColor = AppColors.primaryBorder;
                      textColor = AppColors.primaryDark;
                    } else {
                      bgColor = AppColors.warningBackground;
                      borderColor = AppColors.warningLight.withValues(alpha: 0.8);
                      textColor = AppColors.warning.withValues(alpha: 0.8);
                    }

                    return GestureDetector(
                      onTap: () => _showGrowthDetailModal(routineGrowth),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: bgColor,
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _getGrowthMessage(growth),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${growth >= 0 ? '+' : ''}${growth.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'vs ${previousDate != null ? _formatDateStrKorean(previousDate) : ''} · $commonCount개 운동 비교',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // 루틴 선택 / 운동 추가 버튼
                Row(
                  children: [
                    // 루틴 선택 버튼
                    Expanded(
                      child: GestureDetector(
                        onTap: _showRoutineModal,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFF8881CE)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Center(
                            child: Text(
                              '루틴 선택',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 운동 추가 버튼
                    Expanded(
                      child: GestureDetector(
                        onTap: _showExerciseModal,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Center(
                            child: Text(
                              '운동 추가',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),

          // 운동 기록 리스트 (스크롤 가능)
          Expanded(
            child: dateRecords.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/home.png',
                          width: 200,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '루틴을 선택하거나 운동을 추가하세요',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: dateRecords.length + 1, // +1 for memo
                    itemBuilder: (context, index) {
                      // 마지막 아이템은 메모 입력 영역
                      if (index == dateRecords.length) {
                        return _buildMemoSection();
                      }

                      final record = dateRecords[index];
                      final growth = _calculateGrowth(record.exerciseId);
                      final exerciseName = _getExerciseName(record.exerciseId);

                      return _ExerciseCard(
                        record: record,
                        exerciseName: exerciseName,
                        growth: growth,
                        checkedSets: checkedSets,
                        onAddSet: () => _addSet(record),
                        onRemoveSet: () => _removeSet(record),
                        onToggleCheck: (setIndex) => _toggleCheck(record.id, setIndex),
                        onUpdateSet: (setIndex, {weight, reps}) =>
                            _updateSet(record, setIndex, weight: weight, reps: reps),
                        onGrowthTap: () => _showExerciseHistoryModal(record.exerciseId, exerciseName),
                        onNameTap: () => _showDifficultyModal(record, exerciseName),
                        previousDifficulty: _getPreviousDifficulty(record),
                        // 커스텀 키보드 관련
                        isKeyboardActive: _isKeyboardVisible &&
                            _activeRecordId == record.id,
                        activeSetIndex: _activeSetIndex,
                        activeField: _activeField,
                        currentValue: _currentValue,
                        onFieldTap: (setIndex, field, initialValue) =>
                            _showKeyboard(record.id, setIndex, field, initialValue),
                      );
                    },
                  ),
            ),
          ],
        ),
        ],
      ),
    );
  }
}

// 운동 기록 카드 위젯
class _ExerciseCard extends StatelessWidget {
  final Record record;
  final String exerciseName;
  final double? growth;
  final Map<String, bool> checkedSets;
  final VoidCallback onAddSet;
  final VoidCallback onRemoveSet;
  final Function(int) onToggleCheck;
  final Function(int, {double? weight, int? reps}) onUpdateSet;
  final VoidCallback? onGrowthTap;
  final VoidCallback? onNameTap;
  final String? previousDifficulty;
  // 커스텀 키보드 관련
  final bool isKeyboardActive;
  final int? activeSetIndex;
  final String? activeField;
  final String currentValue;
  final Function(int setIndex, String field, String initialValue) onFieldTap;

  const _ExerciseCard({
    required this.record,
    required this.exerciseName,
    required this.growth,
    required this.checkedSets,
    required this.onAddSet,
    required this.onRemoveSet,
    required this.onToggleCheck,
    required this.onUpdateSet,
    this.onGrowthTap,
    this.onNameTap,
    required this.isKeyboardActive,
    this.activeSetIndex,
    this.activeField,
    required this.currentValue,
    required this.onFieldTap,
    this.previousDifficulty,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 운동 헤더 (이름 + 난이도 + 성장률)
          Row(
            children: [
              // 운동 이름 (클릭 가능)
              Expanded(
                child: GestureDetector(
                  onTap: onNameTap,
                  child: Text(
                    exerciseName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              // 난이도 뱃지
              if (record.difficulty != null || previousDifficulty != null)
                GestureDetector(
                  onTap: onNameTap,
                  child: _buildDifficultyBadge(
                    record.difficulty ?? previousDifficulty!,
                    isCurrentSelected: record.difficulty != null,
                  ),
                ),
              if (growth != null) const SizedBox(width: 8),
              // 성장률 뱃지
              if (growth != null)
                GestureDetector(
                  onTap: onGrowthTap,
                  child: _buildGrowthBadge(growth!),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // 세트 리스트
          ...List.generate(record.sets.length, (index) {
            final set = record.sets[index];
            final checkKey = '${record.id}-$index';
            final isChecked = checkedSets[checkKey] ?? false;

            // 현재 활성화된 필드인지 확인
            final isWeightActive = isKeyboardActive && activeSetIndex == index && activeField == 'weight';
            final isRepsActive = isKeyboardActive && activeSetIndex == index && activeField == 'reps';

            // 표시할 값 결정 (활성화된 필드면 currentValue, 아니면 저장된 값)
            final weightDisplay = isWeightActive ? currentValue : (set.weight?.toString() ?? '');
            final repsDisplay = isRepsActive ? currentValue : (set.reps?.toString() ?? '');

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  // 세트 번호
                  SizedBox(
                    width: 48,
                    child: Text(
                      '세트 ${index + 1}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textHint,
                      ),
                    ),
                  ),

                  // 무게 입력 (커스텀 키보드용)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onFieldTap(index, 'weight', set.weight?.toString() ?? ''),
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isWeightActive
                                ? AppColors.primary
                                : AppColors.borderLight,
                            width: isWeightActive ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            weightDisplay.isEmpty ? '무게' : weightDisplay,
                            style: TextStyle(
                              fontSize: 14,
                              color: weightDisplay.isEmpty
                                  ? AppColors.textHint
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text('kg', style: TextStyle(color: AppColors.textHint, fontSize: 14)),
                  ),

                  // 횟수 입력 (커스텀 키보드용)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onFieldTap(index, 'reps', set.reps?.toString() ?? ''),
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isRepsActive
                                ? AppColors.primary
                                : AppColors.borderLight,
                            width: isRepsActive ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            repsDisplay.isEmpty ? '횟수' : repsDisplay,
                            style: TextStyle(
                              fontSize: 14,
                              color: repsDisplay.isEmpty
                                  ? AppColors.textHint
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text('회', style: TextStyle(color: AppColors.textHint, fontSize: 14)),
                  ),

                  // 체크 버튼
                  GestureDetector(
                    onTap: () => onToggleCheck(index),
                    child: Container(
                      width: 34,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isChecked ? AppColors.primary : Colors.white,
                        border: Border.all(
                          color: isChecked ? AppColors.primary : AppColors.borderLight,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.check,
                        size: 20,
                        color: isChecked ? Colors.white : AppColors.border,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 8),

          // 세트 추가/삭제 버튼
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: record.sets.isEmpty ? null : onRemoveSet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.borderLight),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        '삭제',
                        style: TextStyle(
                          fontSize: 14,
                          color: record.sets.isEmpty
                              ? AppColors.borderLight
                              : AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: onAddSet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.borderLight),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Center(
                      child: Text(
                        '추가',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 난이도 정보 반환
  Map<String, dynamic> _getDifficultyInfo(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return {'text': '쉬웠다', 'icon': 'assets/icons/face_easy.svg'};
      case 'medium':
        return {'text': '할만했다', 'icon': 'assets/icons/face_medium.svg'};
      case 'hard':
        return {'text': '겨우했다', 'icon': 'assets/icons/face_hard.svg'};
      default:
        return {'text': '', 'icon': ''};
    }
  }

  Widget _buildDifficultyBadge(String difficulty, {required bool isCurrentSelected}) {
    final info = _getDifficultyInfo(difficulty);
    final color = isCurrentSelected ? AppColors.primary : AppColors.textHint;
    final bgColor = isCurrentSelected
        ? AppColors.primary.withValues(alpha: 0.1)
        : AppColors.textHint.withValues(alpha: 0.1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            info['icon'] as String,
            width: 16,
            height: 16,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          ),
          const SizedBox(width: 4),
          Text(
            info['text'] as String,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthBadge(double growth) {
    Color bgColor;
    Color borderColor;
    Color textColor;

    if (growth > 0) {
      bgColor = AppColors.successBackground;
      borderColor = AppColors.successLight.withValues(alpha: 0.5);
      textColor = AppColors.success;
    } else if (growth == 0) {
      bgColor = AppColors.primaryBackground;
      borderColor = AppColors.primaryBorder.withValues(alpha: 0.5);
      textColor = AppColors.primaryDark;
    } else {
      bgColor = AppColors.warningBackground;
      borderColor = AppColors.warningLight.withValues(alpha: 0.5);
      textColor = AppColors.warning;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${growth >= 0 ? '+' : ''}${growth.toStringAsFixed(1)}%',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}

// 순서 변경 모달
class _OrderChangeModal extends StatefulWidget {
  final List<Record> records;
  final List<Exercise> exercises;
  final Function(List<Record>) onOrderChanged;
  final Function(String) onDelete;

  const _OrderChangeModal({
    required this.records,
    required this.exercises,
    required this.onOrderChanged,
    required this.onDelete,
  });

  @override
  State<_OrderChangeModal> createState() => _OrderChangeModalState();
}

class _OrderChangeModalState extends State<_OrderChangeModal> {
  late List<Record> orderedRecords;

  @override
  void initState() {
    super.initState();
    orderedRecords = List.from(widget.records);
  }

  String _getExerciseName(String exerciseId) {
    final exercise = widget.exercises.firstWhere(
      (e) => e.id == exerciseId,
      orElse: () => Exercise(id: '', name: '알 수 없음', tag: ''),
    );
    return exercise.name;
  }

  String _getExerciseTag(String exerciseId) {
    final exercise = widget.exercises.firstWhere(
      (e) => e.id == exerciseId,
      orElse: () => Exercise(id: '', name: '', tag: ''),
    );
    return exercise.tag;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '운동 순서 변경',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () => widget.onOrderChanged(orderedRecords),
                child: const Text(
                  '완료',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '드래그해서 순서를 변경하세요',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 16),
          if (orderedRecords.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  '운동 기록이 없습니다',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textHint,
                  ),
                ),
              ),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              itemCount: orderedRecords.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = orderedRecords.removeAt(oldIndex);
                  orderedRecords.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                final record = orderedRecords[index];
                return Container(
                  key: ValueKey(record.id),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '#${index + 1}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textHint,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getExerciseName(record.exerciseId),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              _getExerciseTag(record.exerciseId),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => widget.onDelete(record.id),
                        child: const Icon(
                          Icons.delete_outline,
                          color: AppColors.error,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.drag_handle,
                        color: AppColors.textHint,
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// 성장률 상세 모달
class _GrowthDetailModal extends StatelessWidget {
  final Map<String, dynamic> routineGrowth;
  final List<Exercise> exercises;
  final String Function(String) formatDateStrKorean;

  const _GrowthDetailModal({
    required this.routineGrowth,
    required this.exercises,
    required this.formatDateStrKorean,
  });

  String _getExerciseName(String exerciseId) {
    final exercise = exercises.firstWhere(
      (e) => e.id == exerciseId,
      orElse: () => Exercise(id: '', name: '알 수 없음', tag: ''),
    );
    return exercise.name;
  }

  @override
  Widget build(BuildContext context) {
    final comparisons = routineGrowth['comparisons'] as List<Map<String, dynamic>>;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '성장률 상세',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: comparisons.length,
              itemBuilder: (context, index) {
                final comparison = comparisons[index];
                final exerciseId = comparison['exerciseId'] as String;
                final previousRecord = comparison['previousRecord'] as Record;
                final previousVolume = comparison['previousVolume'] as double;
                final growth = comparison['growth'] as double;

                // 성장률에 따른 색상
                Color textColor;
                if (growth > 0) {
                  textColor = AppColors.success;
                } else if (growth == 0) {
                  textColor = AppColors.primaryDark;
                } else {
                  textColor = AppColors.warning;
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 운동 이름과 성장률
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getExerciseName(exerciseId),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'vs ${formatDateStrKorean(previousRecord.date)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${growth >= 0 ? '+' : ''}${growth.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // 과거 기록
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...previousRecord.sets.asMap().entries.map((entry) {
                              final setIndex = entry.key;
                              final set = entry.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  '세트 ${setIndex + 1}: ${set.weight}kg × ${set.reps}회',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(height: 4),
                            Text(
                              '총 볼륨: ${previousVolume.toStringAsFixed(0)}kg',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// 난이도 선택 모달
class _DifficultyModal extends StatelessWidget {
  final String exerciseName;
  final String? currentDifficulty;
  final String? previousDifficulty;
  final Function(String?) onSelect;
  final VoidCallback onDelete;

  const _DifficultyModal({
    required this.exerciseName,
    required this.currentDifficulty,
    required this.previousDifficulty,
    required this.onSelect,
    required this.onDelete,
  });

  Map<String, dynamic> _getDifficultyInfo(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return {'text': '쉬웠다', 'icon': 'assets/icons/face_easy.svg'};
      case 'medium':
        return {'text': '할만했다', 'icon': 'assets/icons/face_medium.svg'};
      case 'hard':
        return {'text': '겨우했다', 'icon': 'assets/icons/face_hard.svg'};
      default:
        return {'text': '', 'icon': ''};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                exerciseName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: SvgPicture.asset(
                    'assets/icons/remove.svg',
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(
                      AppColors.iconBackground,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 지난 난이도
          Row(
            children: [
              const Text(
                '지난 난이도: ',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textTertiary,
                ),
              ),
              if (previousDifficulty != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        _getDifficultyInfo(previousDifficulty!)['icon'] as String,
                        width: 16,
                        height: 16,
                        colorFilter: const ColorFilter.mode(
                          AppColors.textHint,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getDifficultyInfo(previousDifficulty!)['text'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else
                const Text(
                  '없음',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textHint,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // 난이도 선택 버튼들
          ...['easy', 'medium', 'hard'].map((level) {
            final info = _getDifficultyInfo(level);
            final isSelected = currentDifficulty == level;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => onSelect(isSelected ? null : level),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryBackground : Colors.white,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        info['icon'] as String,
                        width: 20,
                        height: 20,
                        colorFilter: ColorFilter.mode(
                          isSelected ? AppColors.primary : AppColors.textTertiary,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        info['text'] as String,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? AppColors.primary : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// 개별 운동 히스토리 모달
class _ExerciseHistoryModal extends StatelessWidget {
  final String exerciseName;
  final List<Record> history;
  final String Function(String) formatDateStrKorean;

  const _ExerciseHistoryModal({
    required this.exerciseName,
    required this.history,
    required this.formatDateStrKorean,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$exerciseName 히스토리',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (history.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  '기록이 없습니다',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textHint,
                  ),
                ),
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final record = history[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatDateStrKorean(record.date),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...record.sets.asMap().entries.map((entry) {
                          final setIndex = entry.key;
                          final set = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '세트 ${setIndex + 1}: ${set.weight}kg × ${set.reps}회',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 4),
                        Text(
                          '총 볼륨: ${record.totalVolume.toStringAsFixed(0)}kg',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
