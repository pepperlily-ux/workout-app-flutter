import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/exercise.dart';
import '../models/routine.dart';
import '../services/storage_service.dart';
import '../constants/app_colors.dart';

const _kBookmarkTag = '__bookmark__';

// 운동 화면
class ExercisePage extends StatefulWidget {
  const ExercisePage({super.key});

  @override
  State<ExercisePage> createState() => ExercisePageState();
}

class ExercisePageState extends State<ExercisePage> {
  void reload() => _loadData();
  final StorageService _storage = StorageService();

  String _selectedTag = '전체';
  List<Exercise> _exercises = [];
  Set<String> _bookmarks = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _storage.init();
    setState(() {
      _exercises = _storage.getExercises();
      _bookmarks = _storage.getBookmarks();
    });
  }

  List<String> get _allTags {
    final tags = _exercises.map((e) => e.tag).toSet().toList();
    tags.sort();
    final hasBookmarks = _bookmarks.isNotEmpty &&
        _exercises.any((e) => _bookmarks.contains(e.id));
    return ['전체', if (hasBookmarks) _kBookmarkTag, ...tags];
  }

  List<Exercise> get _filteredExercises {
    List<Exercise> list;
    if (_selectedTag == _kBookmarkTag) {
      list = _exercises.where((e) => _bookmarks.contains(e.id)).toList();
    } else if (_selectedTag == '전체') {
      list = List.from(_exercises);
    } else {
      list = _exercises.where((e) => e.tag == _selectedTag).toList();
    }
    // 북마크 상단 고정, 이후 운동 횟수 내림차순, 동일 횟수는 추가 순서 유지
    final countCache = {for (final e in list) e.id: _getRecordCount(e.id)};
    list.sort((a, b) {
      final aB = _bookmarks.contains(a.id) ? 0 : 1;
      final bB = _bookmarks.contains(b.id) ? 0 : 1;
      if (aB != bB) return aB.compareTo(bB);
      return (countCache[b.id] ?? 0).compareTo(countCache[a.id] ?? 0);
    });
    return list;
  }

  int _getRecordCount(String exerciseId) {
    return _storage
        .getExerciseHistory(exerciseId)
        .where((r) => r.totalVolume > 0)
        .length;
  }

  Future<void> _toggleBookmark(String exerciseId) async {
    await _storage.toggleBookmark(exerciseId);
    setState(() {
      _bookmarks = _storage.getBookmarks();
      // 북마크 태그 선택 중 북마크 해제로 목록이 비면 전체로 리셋
      if (_selectedTag == _kBookmarkTag &&
          !_exercises.any((e) => _bookmarks.contains(e.id))) {
        _selectedTag = '전체';
      }
    });
  }

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

  Widget _buildDifficultyBadge(String difficulty) {
    final info = _getDifficultyInfo(difficulty);
    const color = AppColors.primary;
    final bgColor = AppColors.primary.withValues(alpha: 0.1);

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
            colorFilter: const ColorFilter.mode(color, BlendMode.srcIn),
          ),
          const SizedBox(width: 4),
          Text(
            info['text'] as String,
            style: const TextStyle(fontSize: 12, color: color),
          ),
        ],
      ),
    );
  }

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
            bottom: MediaQuery.of(context).viewInsets.bottom +
                MediaQuery.of(context).padding.bottom +
                16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '운동 추가',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
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
                      final inputName = nameController.text.trim();
                      final isDuplicate = _exercises.any(
                        (e) => e.name == inputName,
                      );
                      if (isDuplicate) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('이미 존재하는 운동 이름입니다')),
                        );
                        return;
                      }
                      final exercise = Exercise(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: inputName,
                        tag: tagController.text.trim(),
                      );
                      await _storage.addExercise(exercise);
                      setState(() {
                        _exercises = _storage.getExercises();
                      });
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$inputName 추가됨')),
                        );
                      }
                    },
                    child: const Text(
                      '저장',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
                maxLength: 20,
                decoration: InputDecoration(
                  hintText: '예: 벤치프레스',
                  hintStyle: const TextStyle(color: AppColors.textHint),
                  counterText: '',
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
                onChanged: (_) => setModalState(() {}),
              ),
              const SizedBox(height: 16),
              const Text(
                '운동 종류',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: tagController,
                maxLength: 10,
                decoration: InputDecoration(
                  hintText: '예: 가슴, 등, 하체...',
                  hintStyle: const TextStyle(color: AppColors.textHint),
                  counterText: '',
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
              Builder(
                builder: (context) {
                  final existingTags = _exercises.map((e) => e.tag).toSet();
                  final defaultTags = {'등', '가슴', '하체', '어깨'};
                  final allTags = {...defaultTags, ...existingTags}.toList()
                    ..sort();

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
                            color: isSelected ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.border,
                            ),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.0,
                              color: isSelected ? Colors.white : AppColors.textTertiary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExerciseDetailModal(Exercise exercise) {
    final history = _storage
        .getExerciseHistory(exercise.id)
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
              Row(
                children: [
                  Flexible(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(modalContext);
                        _showEditExerciseModal(exercise);
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              exercise.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            LucideIcons.pencil,
                            size: 16,
                            color: AppColors.textTertiary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
                                Row(
                                  children: [
                                    Text(
                                      dateStr,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    if (record.difficulty != null) ...[
                                      const SizedBox(width: 8),
                                      _buildDifficultyBadge(record.difficulty!),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ...List.generate(record.sets.length, (setIndex) {
                                  final set = record.sets[setIndex];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      '세트 ${setIndex + 1}: ${(set.weight ?? 0) % 1 == 0 ? (set.weight ?? 0).toInt() : set.weight ?? 0}kg × ${set.reps ?? 0}회',
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
                      )
                    : const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Text(
                            '기록이 없습니다',
                            style: TextStyle(fontSize: 14, color: AppColors.textHint),
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
            bottom: MediaQuery.of(context).viewInsets.bottom +
                MediaQuery.of(context).padding.bottom +
                16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '운동 수정',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
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
                    child: const Text(
                      '저장',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
                maxLength: 20,
                decoration: InputDecoration(
                  hintText: '예: 벤치프레스',
                  hintStyle: const TextStyle(color: AppColors.textHint),
                  counterText: '',
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
              const Text(
                '운동 종류',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: tagController,
                maxLength: 10,
                decoration: InputDecoration(
                  hintText: '예: 가슴, 등, 하체...',
                  hintStyle: const TextStyle(color: AppColors.textHint),
                  counterText: '',
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
              Builder(
                builder: (context) {
                  final existingTags = _exercises.map((e) => e.tag).toSet();
                  final defaultTags = {'등', '가슴', '하체', '어깨'};
                  final allTags = {...defaultTags, ...existingTags}.toList()
                    ..sort();

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
                            color: isSelected ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.border,
                            ),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.0,
                              color: isSelected ? Colors.white : AppColors.textTertiary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 24),
              // 삭제 버튼
              GestureDetector(
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('운동 삭제'),
                      content: Text(
                        '${exercise.name}을(를) 삭제하면 관련된 모든 기록, 통계, 루틴에서도 영구적으로 제거되며, 되돌릴 수 없습니다. 삭제하시겠습니까?',
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
                    final exercises = _storage.getExercises();
                    exercises.removeWhere((e) => e.id == exercise.id);
                    await _storage.saveExercises(exercises);

                    final records = _storage.getRecords();
                    records.removeWhere((r) => r.exerciseId == exercise.id);
                    await _storage.saveRecords(records);

                    final routines = _storage.getRoutines();
                    final updatedRoutines = routines
                        .map(
                          (r) => Routine(
                            id: r.id,
                            name: r.name,
                            exerciseIds: r.exerciseIds
                                .where((id) => id != exercise.id)
                                .toList(),
                          ),
                        )
                        .toList();
                    await _storage.saveRoutines(updatedRoutines);

                    // 북마크에서도 제거
                    final bookmarks = _storage.getBookmarks();
                    bookmarks.remove(exercise.id);
                    await _storage.saveBookmarks(bookmarks);

                    setState(() {
                      _exercises = _storage.getExercises();
                      _bookmarks = _storage.getBookmarks();
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
                    '+ 새 운동 만들기',
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

            // 태그 필터 (북마크 태그 포함)
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _allTags.length,
                itemBuilder: (context, index) {
                  final tag = _allTags[index];
                  final isSelected = _selectedTag == tag;

                  if (tag == _kBookmarkTag) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTag = tag),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.border,
                              ),
                            ),
                            child: Icon(
                              Icons.bookmark_border,
                              size: 16,
                              color: isSelected ? Colors.white : AppColors.textHint,
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTag = tag),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.border,
                            ),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.0,
                              color: isSelected ? Colors.white : AppColors.textTertiary,
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
                            'assets/Baby.png',
                            width: 200,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.fitness_center,
                              size: 48,
                              color: Colors.grey[300],
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '운동이 없습니다몽',
                            style: TextStyle(fontSize: 14, color: AppColors.textHint),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredExercises.length,
                      itemBuilder: (context, index) {
                        final exercise = _filteredExercises[index];
                        final recordCount = _getRecordCount(exercise.id);
                        final isBookmarked = _bookmarks.contains(exercise.id);

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
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
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
                                          if (recordCount > 0) ...[
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
                                                '$recordCount회',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  height: 1.0,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        exercise.tag,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textHint,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _toggleBookmark(exercise.id),
                                  behavior: HitTestBehavior.opaque,
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
                                    child: Icon(
                                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                                      size: 22,
                                      color: isBookmarked
                                          ? AppColors.primary
                                          : AppColors.border,
                                    ),
                                  ),
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
