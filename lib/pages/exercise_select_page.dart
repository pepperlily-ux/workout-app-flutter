import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../services/storage_service.dart';
import '../constants/app_colors.dart';

// 운동 선택 페이지 (홈에서 운동 추가 시 사용)
class ExerciseSelectPage extends StatefulWidget {
  final List<Exercise> exercises;
  final StorageService storage;
  final Function(List<Exercise>) onSelectMultiple;
  final Function(String name, String tag) onAddNew;

  const ExerciseSelectPage({
    super.key,
    required this.exercises,
    required this.storage,
    required this.onSelectMultiple,
    required this.onAddNew,
  });

  @override
  State<ExerciseSelectPage> createState() => _ExerciseSelectPageState();
}

class _ExerciseSelectPageState extends State<ExerciseSelectPage> {
  String _selectedTag = '전체';
  final Set<String> _selectedExerciseIds = {};

  List<String> get _allTags {
    final tags = widget.exercises.map((e) => e.tag).toSet().toList();
    tags.sort();
    return ['전체', ...tags];
  }

  List<Exercise> get _filteredExercises {
    if (_selectedTag == '전체') return widget.exercises;
    return widget.exercises.where((e) => e.tag == _selectedTag).toList();
  }

  int _getRecordCount(String exerciseId) {
    return widget.storage.getExerciseHistory(exerciseId)
        .where((r) => r.totalVolume > 0)
        .length;
  }

  void _toggleExercise(String exerciseId) {
    setState(() {
      if (_selectedExerciseIds.contains(exerciseId)) {
        _selectedExerciseIds.remove(exerciseId);
      } else {
        _selectedExerciseIds.add(exerciseId);
      }
    });
  }

  void _handleAddExercises() {
    final selectedExercises = widget.exercises
        .where((e) => _selectedExerciseIds.contains(e.id))
        .toList();
    widget.onSelectMultiple(selectedExercises);
    Navigator.pop(context);
  }

  // 새 운동 추가 모달 (운동탭과 동일한 형태)
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
      builder: (modalContext) => StatefulBuilder(
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
                    onTap: () => Navigator.pop(modalContext),
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
                  final existingTags = widget.exercises.map((e) => e.tag).toSet();
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

                  Navigator.pop(modalContext);
                  widget.onAddNew(nameController.text.trim(), tagController.text.trim());
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '운동 선택',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          GestureDetector(
            onTap: _showAddExerciseModal,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  '+ 새 운동',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                ],
              ),
            ),

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
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredExercises.length,
                      itemBuilder: (context, index) {
                        final exercise = _filteredExercises[index];
                        final recordCount = _getRecordCount(exercise.id);
                        final isSelected = _selectedExerciseIds.contains(exercise.id);

                        return GestureDetector(
                          onTap: () => _toggleExercise(exercise.id),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.border,
                              ),
                            ),
                            child: Row(
                              children: [
                                // 체크박스
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primary : Colors.white,
                                    border: Border.all(
                                      color: isSelected ? AppColors.primary : AppColors.borderLight,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                                      : null,
                                ),
                                const SizedBox(width: 12),
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
                                // 기록 횟수
                                if (recordCount > 0)
                                  Text(
                                    '$recordCount회',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textHint,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // 하단 추가 버튼
            if (_selectedExerciseIds.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: GestureDetector(
                    onTap: _handleAddExercises,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${_selectedExerciseIds.length}개 운동 추가',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
