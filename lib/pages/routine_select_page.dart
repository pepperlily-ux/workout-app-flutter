import 'package:flutter/material.dart';
import '../models/routine.dart';
import '../models/exercise.dart';
import '../constants/app_colors.dart';

// 루틴 선택 페이지 (홈에서 루틴 선택 시 사용)
class RoutineSelectPage extends StatefulWidget {
  final List<Routine> routines;
  final List<Exercise> exercises;
  final Function(Routine) onSelect;
  final Function(String name, List<String> exerciseIds) onAddNew;

  const RoutineSelectPage({
    super.key,
    required this.routines,
    required this.exercises,
    required this.onSelect,
    required this.onAddNew,
  });

  @override
  State<RoutineSelectPage> createState() => _RoutineSelectPageState();
}

class _RoutineSelectPageState extends State<RoutineSelectPage> {
  String? _selectedRoutineId;

  Exercise? _getExerciseById(String id) {
    try {
      return widget.exercises.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  void _handleSelectRoutine() {
    if (_selectedRoutineId == null) return;

    final routine = widget.routines.firstWhere(
      (r) => r.id == _selectedRoutineId,
    );
    widget.onSelect(routine);
    Navigator.pop(context);
  }

  // 새 루틴 만들기 모달
  void _showCreateRoutineModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreateRoutineModal(
        exercises: widget.exercises,
        existingRoutineNames: widget.routines.map((r) => r.name).toList(),
        onSave: (name, exerciseIds) {
          widget.onAddNew(name, exerciseIds);
        },
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
          '루틴 선택',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          GestureDetector(
            onTap: _showCreateRoutineModal,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  '+ 새 루틴',
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
            // 루틴 리스트
            Expanded(
              child: widget.routines.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/home.png',
                            width: 160,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(
                                  Icons.folder_open,
                                  size: 48,
                                  color: Colors.grey[300],
                                ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '저장된 루틴이 없습니다',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textHint,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '루틴 탭에서 새 루틴을 만들어보세요',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: widget.routines.length,
                      itemBuilder: (context, index) {
                        final routine = widget.routines[index];
                        final isSelected = _selectedRoutineId == routine.id;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedRoutineId = routine.id;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.border,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 체크박스 (운동 선택과 동일한 스타일)
                                Container(
                                  width: 20,
                                  height: 20,
                                  margin: const EdgeInsets.only(top: 2),
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
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // 루틴 이름 (운동 선택과 동일한 스타일)
                                      Text(
                                        routine.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      // 운동 목록 (태그 형태)
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: routine.exerciseIds.map((id) {
                                          final exercise = _getExerciseById(id);
                                          if (exercise == null) return const SizedBox();
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.backgroundGrey,
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: Text(
                                              exercise.name,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // 하단 선택 버튼
            if (_selectedRoutineId != null)
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
                    onTap: _handleSelectRoutine,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          '루틴 적용',
                          style: TextStyle(
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

// 새 루틴 만들기 모달 (루틴탭과 동일)
class _CreateRoutineModal extends StatefulWidget {
  final List<Exercise> exercises;
  final List<String> existingRoutineNames;
  final Function(String name, List<String> exerciseIds) onSave;

  const _CreateRoutineModal({
    required this.exercises,
    required this.existingRoutineNames,
    required this.onSave,
  });

  @override
  State<_CreateRoutineModal> createState() => _CreateRoutineModalState();
}

class _CreateRoutineModalState extends State<_CreateRoutineModal> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedTag = '전체';
  final List<String> _selectedExercises = [];

  List<String> get _tags {
    final tags = widget.exercises.map((e) => e.tag).toSet().toList();
    return ['전체', ...tags];
  }

  List<Exercise> get _filteredExercises {
    if (_selectedTag == '전체') return widget.exercises;
    return widget.exercises.where((e) => e.tag == _selectedTag).toList();
  }

  void _toggleExercise(String exerciseId) {
    setState(() {
      if (_selectedExercises.contains(exerciseId)) {
        _selectedExercises.remove(exerciseId);
      } else {
        _selectedExercises.add(exerciseId);
      }
    });
  }

  void _handleSave() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('루틴 이름을 입력하세요')),
      );
      return;
    }
    if (widget.existingRoutineNames.contains(name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미 같은 이름의 루틴이 있습니다!')),
      );
      return;
    }
    if (_selectedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('운동을 선택하세요')),
      );
      return;
    }

    widget.onSave(name, _selectedExercises);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: AppColors.textTertiary),
                ),
                const Text(
                  '새 루틴 만들기',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 24),
              ],
            ),
          ),

          // 내용
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 루틴 이름 입력
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: '루틴 이름 (예: 하체 루틴)',
                      hintStyle: const TextStyle(color: AppColors.textHint),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.borderLight),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.borderLight),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 운동 선택 헤더
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '운동 선택',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (_selectedExercises.isNotEmpty)
                        Text(
                          '${_selectedExercises.length}개 선택됨',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.primary,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // 태그 필터
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _tags.length,
                      itemBuilder: (context, index) {
                        final tag = _tags[index];
                        final isSelected = _selectedTag == tag;
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

                  const SizedBox(height: 12),

                  // 운동 목록
                  ..._filteredExercises.map((exercise) {
                    final isSelected = _selectedExercises.contains(exercise.id);
                    return GestureDetector(
                      onTap: () => _toggleExercise(exercise.id),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
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
                                  Flexible(
                                    child: Text(
                                      exercise.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
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
                          ],
                        ),
                      ),
                    );
                  }),

                  if (_filteredExercises.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          '이 태그의 운동이 없습니다',
                          style: TextStyle(fontSize: 14, color: AppColors.textHint),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 저장 버튼
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 16 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: GestureDetector(
              onTap: _handleSave,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    '루틴 저장',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
