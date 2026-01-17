import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/exercise.dart';
import '../services/storage_service.dart';
import '../constants/app_colors.dart';

// 운동 화면
class ExercisePage extends StatefulWidget {
  const ExercisePage({super.key});

  @override
  State<ExercisePage> createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage> {
  final StorageService _storage = StorageService();

  String _selectedTag = '전체';
  List<Exercise> _exercises = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _storage.init();
    setState(() {
      _exercises = _storage.getExercises();
    });
  }

  // 모든 태그 목록
  List<String> get _allTags {
    final tags = _exercises.map((e) => e.tag).toSet().toList();
    tags.sort();
    return ['전체', ...tags];
  }

  // 필터링된 운동 목록
  List<Exercise> get _filteredExercises {
    if (_selectedTag == '전체') {
      return _exercises;
    }
    return _exercises.where((e) => e.tag == _selectedTag).toList();
  }

  // 운동별 기록 횟수 가져오기 (볼륨이 0보다 큰 기록만)
  int _getRecordCount(String exerciseId) {
    return _storage.getExerciseHistory(exerciseId)
        .where((r) => r.totalVolume > 0)
        .length;
  }

  // 운동 추가 모달
  void _showAddExerciseModal() {
    final nameController = TextEditingController();
    final tagController = TextEditingController();
    String? selectedTag;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '운동 추가',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: AppColors.textTertiary),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 운동 이름 입력
              const Text(
                '운동 이름',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: '예: 벤치프레스',
                  hintStyle: const TextStyle(color: AppColors.textHint),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 운동 종류 선택
              const Text(
                '운동 종류',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),

              // 운동 종류 직접 입력
              TextField(
                controller: tagController,
                decoration: InputDecoration(
                  hintText: '예: 가슴, 등, 하체...',
                  hintStyle: const TextStyle(color: AppColors.textHint),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) {
                  setModalState(() {
                    selectedTag = value.trim().isEmpty ? null : value.trim();
                  });
                },
              ),
              const SizedBox(height: 12),

              // 기존 태그 목록 (빠른 선택용)
              Builder(
                builder: (context) {
                  // 기존 운동들에서 태그 추출 + 기본 태그
                  final existingTags = _exercises.map((e) => e.tag).toSet();
                  final defaultTags = {'등', '가슴', '하체', '어깨'};
                  final allTags = {...defaultTags, ...existingTags}.toList()..sort();

                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: allTags.map((tag) {
                      final isSelected = selectedTag == tag;
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            selectedTag = tag;
                            tagController.text = tag;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.0,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textTertiary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 24),

              // 추가 버튼
              GestureDetector(
                onTap: () async {
                  if (nameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('운동 이름을 입력하세요')),
                    );
                    return;
                  }
                  if (tagController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('운동 종류를 입력하세요')),
                    );
                    return;
                  }

                  final exercise = Exercise(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text.trim(),
                    tag: tagController.text.trim(),
                  );

                  await _storage.addExercise(exercise);
                  setState(() {
                    _exercises = _storage.getExercises();
                  });

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${nameController.text.trim()} 추가됨'),
                      ),
                    );
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      '추가',
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
      ),
    );
  }

  // 운동 클릭 시 히스토리 + 편집 아이콘 모달 (원본과 동일)
  void _showExerciseDetailModal(Exercise exercise) {
    // 볼륨이 0보다 큰 기록만 표시
    final history = _storage.getExerciseHistory(exercise.id)
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
      builder: (modalContext) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더: 운동 이름 + 태그 + 편집 아이콘
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            exercise.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            exercise.tag,
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.0,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 편집 아이콘
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(modalContext);
                      _showEditExerciseModal(exercise);
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.edit_outlined,
                        size: 20,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 히스토리 목록
              Expanded(
                child: history.isNotEmpty
                    ? ListView.builder(
                        controller: scrollController,
                        itemCount: history.length,
                        itemBuilder: (context, index) {
                          final record = history[index];
                          final dateParts = record.date.split('-');
                          final dateStr = dateParts.length == 3
                              ? '${int.parse(dateParts[1])}월 ${int.parse(dateParts[2])}일'
                              : record.date;

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
                                // 날짜
                                Text(
                                  dateStr,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // 세트 정보
                                ...List.generate(
                                  record.sets.length,
                                  (setIndex) {
                                    final set = record.sets[setIndex];
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        '세트 ${setIndex + 1}: ${set.weight ?? 0}kg × ${set.reps ?? 0}회',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 4),
                                // 총 볼륨
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
                      )
                    : const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Text(
                            '기록이 없습니다',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textHint,
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 운동 수정 모달
  void _showEditExerciseModal(Exercise exercise) {
    final nameController = TextEditingController(text: exercise.name);
    final tagController = TextEditingController(text: exercise.tag);
    String? selectedTag = exercise.tag;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '운동 수정',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: AppColors.textTertiary),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 운동 이름 입력
              const Text(
                '운동 이름',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: '예: 벤치프레스',
                  hintStyle: const TextStyle(color: AppColors.textHint),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 운동 종류
              const Text(
                '운동 종류',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),

              // 태그 목록
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['등', '어깨', '가슴', '하체', '힙', '팔', '복근', '유산소', '기타']
                    .map((tag) {
                  final isSelected = selectedTag == tag;
                  return GestureDetector(
                    onTap: () {
                      setModalState(() {
                        selectedTag = tag;
                        tagController.text = tag;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.0,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textTertiary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // 저장 버튼
              GestureDetector(
                onTap: () async {
                  if (nameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('운동 이름을 입력하세요')),
                    );
                    return;
                  }
                  if (tagController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('운동 종류를 입력하세요')),
                    );
                    return;
                  }

                  final updatedExercise = Exercise(
                    id: exercise.id,
                    name: nameController.text.trim(),
                    tag: tagController.text.trim(),
                  );

                  // 운동 목록 업데이트
                  final exercises = _storage.getExercises();
                  final index = exercises.indexWhere((e) => e.id == exercise.id);
                  if (index != -1) {
                    exercises[index] = updatedExercise;
                    await _storage.saveExercises(exercises);
                  }

                  setState(() {
                    _exercises = _storage.getExercises();
                  });

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('수정되었습니다')),
                    );
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      '저장',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 삭제 버튼
              GestureDetector(
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('운동 삭제'),
                      content: Text(
                        '${exercise.name}을(를) 삭제하시겠습니까?\n관련 기록도 모두 삭제됩니다.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('취소'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.error,
                          ),
                          child: const Text('삭제'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    // 운동 삭제
                    final exercises = _storage.getExercises();
                    exercises.removeWhere((e) => e.id == exercise.id);
                    await _storage.saveExercises(exercises);

                    // 관련 기록도 삭제
                    final records = _storage.getRecords();
                    records.removeWhere((r) => r.exerciseId == exercise.id);
                    await _storage.saveRecords(records);

                    setState(() {
                      _exercises = _storage.getExercises();
                    });

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${exercise.name} 삭제됨')),
                      );
                    }
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: const Center(
                    child: Text(
                      '운동 삭제',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 삭제 확인 다이얼로그 (리스트에서 바로 삭제)
  void _showDeleteConfirmDialog(Exercise exercise) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('운동 삭제'),
        content: Text(
          '${exercise.name}을(를) 삭제하시겠습니까?\n관련 기록도 모두 삭제됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              // 운동 삭제
              final exercises = _storage.getExercises();
              exercises.removeWhere((e) => e.id == exercise.id);
              await _storage.saveExercises(exercises);

              // 관련 기록도 삭제
              final records = _storage.getRecords();
              records.removeWhere((r) => r.exerciseId == exercise.id);
              await _storage.saveRecords(records);

              setState(() {
                _exercises = _storage.getExercises();
              });

              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${exercise.name} 삭제됨')),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 새 운동 추가 버튼
            GestureDetector(
              onTap: _showAddExerciseModal,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    '+ 새 운동 추가',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 태그 필터
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _allTags.length,
                itemBuilder: (context, index) {
                  final tag = _allTags[index];
                  final isSelected = _selectedTag == tag;
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedTag = tag;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.0,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textTertiary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // 운동 리스트
            Expanded(
              child: _filteredExercises.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/home.png',
                            width: 160,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(
                                  Icons.fitness_center,
                                  size: 48,
                                  color: Colors.grey[300],
                                ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '운동이 없습니다몽',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredExercises.length,
                      itemBuilder: (context, index) {
                        final exercise = _filteredExercises[index];
                        final recordCount = _getRecordCount(exercise.id);

                        return GestureDetector(
                          onTap: () => _showExerciseDetailModal(exercise),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      // 운동 이름
                                      Flexible(
                                        child: Text(
                                          exercise.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.textPrimary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // 태그
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          exercise.tag,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            height: 1.0,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // 기록 횟수 + 삭제 아이콘
                                Row(
                                  children: [
                                    if (recordCount > 0) ...[
                                      Text(
                                        '$recordCount회',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textHint,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    // 삭제 아이콘
                                    GestureDetector(
                                      onTap: () => _showDeleteConfirmDialog(exercise),
                                      child: Padding(
                                        padding: const EdgeInsets.all(4),
                                        child: SvgPicture.asset(
                                          'assets/icons/remove.svg',
                                          width: 20,
                                          height: 18,
                                          colorFilter: const ColorFilter.mode(
                                            AppColors.iconBackground,
                                            BlendMode.srcIn,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
