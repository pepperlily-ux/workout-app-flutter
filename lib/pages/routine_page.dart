import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/routine.dart';
import '../models/exercise.dart';
import '../services/storage_service.dart';
import '../constants/app_colors.dart';

const _kBookmarkTag = '__bookmark__';

// 루틴 화면
class RoutinePage extends StatefulWidget {
  const RoutinePage({super.key});

  @override
  State<RoutinePage> createState() => RoutinePageState();
}

class RoutinePageState extends State<RoutinePage> {
  final StorageService _storage = StorageService();
  List<Routine> _routines = [];
  List<Exercise> _exercises = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void reload() => _loadData();

  Future<void> _loadData() async {
    await _storage.init();
    if (!mounted) return;
    setState(() {
      _routines = _storage.getRoutines();
      _exercises = _storage.getExercises();
    });
  }

  Future<void> _addRoutine(String name, List<String> exerciseIds) async {
    final newRoutine = Routine(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      exerciseIds: exerciseIds,
    );
    _routines.add(newRoutine);
    await _storage.saveRoutines(_routines);
    setState(() {});
  }

  Future<void> _updateRoutine(Routine routine) async {
    final index = _routines.indexWhere((r) => r.id == routine.id);
    if (index != -1) {
      _routines[index] = routine;
      await _storage.saveRoutines(_routines);
      setState(() {});
    }
  }

  Future<void> _deleteRoutine(String routineId) async {
    _routines.removeWhere((r) => r.id == routineId);
    await _storage.saveRoutines(_routines);
    setState(() {});
  }

  void _showCreateRoutineModal() {
    _exercises = _storage.getExercises();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreateRoutineModal(
        exercises: _exercises,
        existingRoutineNames: _routines.map((r) => r.name).toList(),
        onSave: (name, exerciseIds) {
          _addRoutine(name, exerciseIds);
        },
      ),
    );
  }

  void _navigateToEditRoutine(Routine routine) {
    _exercises = _storage.getExercises();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoutineEditPage(
          routine: routine,
          exercises: _exercises,
          onSave: (updatedRoutine) {
            _updateRoutine(updatedRoutine);
          },
          onDelete: (routineId) {
            _deleteRoutine(routineId);
          },
        ),
      ),
    );
  }

  Exercise? _getExerciseById(String id) {
    try {
      return _exercises.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _showCreateRoutineModal,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    '+ 새 루틴 만들기',
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

            Expanded(
              child: _routines.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      itemCount: _routines.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final routine = _routines[index];
                        return _buildRoutineCard(routine);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/Baby.png',
            width: 200,
            errorBuilder: (context, error, stackTrace) => const SizedBox(height: 100),
          ),
          const SizedBox(height: 16),
          const Text(
            '저장된 루틴이 없습니다',
            style: TextStyle(fontSize: 14, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineCard(Routine routine) {
    return GestureDetector(
      onTap: () => _navigateToEditRoutine(routine),
      child: Container(
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
              routine.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: routine.exerciseIds.map((id) {
                final exercise = _getExerciseById(id);
                if (exercise == null) return const SizedBox();
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
    );
  }
}

// 새 루틴 만들기 모달
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
  final StorageService _storage = StorageService();
  final TextEditingController _nameController = TextEditingController();
  String _selectedTag = '전체';
  final List<String> _selectedExercises = [];
  Set<String> _bookmarks = {};


  @override
  void initState() {
    super.initState();
    _bookmarks = _storage.getBookmarks();
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  int _getRecordCount(String exerciseId) {
    return _storage.getExerciseHistory(exerciseId)
        .where((r) => r.totalVolume > 0)
        .length;
  }

  List<Exercise> _sortByBookmark(List<Exercise> list) {
    return List.from(list)
      ..sort((a, b) {
        final aB = _bookmarks.contains(a.id) ? 0 : 1;
        final bB = _bookmarks.contains(b.id) ? 0 : 1;
        return aB.compareTo(bB);
      });
  }

  List<String> get _tags {
    final tags = widget.exercises.map((e) => e.tag).toSet().toList();
    final hasBookmarks = _bookmarks.isNotEmpty &&
        widget.exercises.any((e) => _bookmarks.contains(e.id));
    return ['전체', if (hasBookmarks) _kBookmarkTag, ...tags];
  }

  List<Exercise> get _filteredExercises {
    if (_selectedTag == _kBookmarkTag) {
      return _sortByBookmark(widget.exercises.where((e) => _bookmarks.contains(e.id)).toList());
    }
    if (_selectedTag == '전체') return _sortByBookmark(List.from(widget.exercises));
    return _sortByBookmark(widget.exercises.where((e) => e.tag == _selectedTag).toList());
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '새 루틴 만들기',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: _handleSave,
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
          ),
          const SizedBox(height: 16),

          // 내용
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 루틴 이름 입력
                  TextField(
                    controller: _nameController,
                    maxLength: 20,
                    decoration: InputDecoration(
                      hintText: '루틴 이름 (예: 하체 루틴)',
                      hintStyle: const TextStyle(color: AppColors.textHint),
                      counterText: '',
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

                        if (tag == _kBookmarkTag) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedTag = tag),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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

                  const SizedBox(height: 12),

                  // 운동 목록
                  ..._filteredExercises.map((exercise) {
                    final isSelected = _selectedExercises.contains(exercise.id);
                    final isBookmarked = _bookmarks.contains(exercise.id);
                    final recordCount = _getRecordCount(exercise.id);
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
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                                    style: const TextStyle(fontSize: 14, color: AppColors.textHint),
                                  ),
                                ],
                              ),
                            ),
                            if (isBookmarked)
                              const Padding(
                                padding: EdgeInsets.only(left: 12),
                                child: Icon(
                                  Icons.bookmark,
                                  size: 22,
                                  color: AppColors.primary,
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
                          style: TextStyle(fontSize: 12, color: AppColors.textHint),
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

        ],
      ),
    );
  }
}

// 루틴 편집 페이지
class RoutineEditPage extends StatefulWidget {
  final Routine routine;
  final List<Exercise> exercises;
  final Function(Routine) onSave;
  final Function(String) onDelete;

  const RoutineEditPage({
    super.key,
    required this.routine,
    required this.exercises,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<RoutineEditPage> createState() => _RoutineEditPageState();
}

class _RoutineEditPageState extends State<RoutineEditPage> {
  final StorageService _storage = StorageService();
  late List<String> _exerciseIds;
  late TextEditingController _nameController;
  String _selectedTag = '전체';
  Set<String> _bookmarks = {};

  // 변경 감지용 원본 값
  late String _originalName;
  late List<String> _originalExerciseIds;

  bool get _hasChanges {
    if (_nameController.text.trim() != _originalName) return true;
    if (_exerciseIds.length != _originalExerciseIds.length) return true;
    for (int i = 0; i < _exerciseIds.length; i++) {
      if (_exerciseIds[i] != _originalExerciseIds[i]) return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _bookmarks = _storage.getBookmarks();
    _exerciseIds = List.from(widget.routine.exerciseIds);
    _nameController = TextEditingController(text: widget.routine.name);
    _originalName = widget.routine.name;
    _originalExerciseIds = List.from(widget.routine.exerciseIds);
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  int _getRecordCount(String exerciseId) {
    return _storage.getExerciseHistory(exerciseId)
        .where((r) => r.totalVolume > 0)
        .length;
  }

  List<Exercise> _sortByBookmark(List<Exercise> list) {
    return List.from(list)
      ..sort((a, b) {
        final aB = _bookmarks.contains(a.id) ? 0 : 1;
        final bB = _bookmarks.contains(b.id) ? 0 : 1;
        return aB.compareTo(bB);
      });
  }

  List<String> get _tags {
    final tags = widget.exercises.map((e) => e.tag).toSet().toList();
    final hasBookmarks = _bookmarks.isNotEmpty &&
        widget.exercises.any((e) => _bookmarks.contains(e.id));
    return ['전체', if (hasBookmarks) _kBookmarkTag, ...tags];
  }

  List<Exercise> get _filteredExercises {
    if (_selectedTag == _kBookmarkTag) {
      return _sortByBookmark(widget.exercises.where((e) => _bookmarks.contains(e.id)).toList());
    }
    if (_selectedTag == '전체') return _sortByBookmark(List.from(widget.exercises));
    return _sortByBookmark(widget.exercises.where((e) => e.tag == _selectedTag).toList());
  }

  Exercise? _getExerciseById(String id) {
    try {
      return widget.exercises.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  void _removeExercise(String exerciseId) {
    setState(() {
      _exerciseIds.remove(exerciseId);
    });
  }

  void _addExercise(String exerciseId) {
    setState(() {
      if (!_exerciseIds.contains(exerciseId)) {
        _exerciseIds.add(exerciseId);
      }
    });
  }

  void _handleSave() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('루틴 이름을 입력하세요')),
      );
      return;
    }
    final updatedRoutine = Routine(
      id: widget.routine.id,
      name: _nameController.text.trim(),
      exerciseIds: _exerciseIds,
    );
    widget.onSave(updatedRoutine);
    Navigator.pop(context);
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('루틴 삭제'),
        content: const Text('이 루틴을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소', style: TextStyle(color: AppColors.textTertiary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      widget.onDelete(widget.routine.id);
      if (mounted) Navigator.pop(context);
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('변경사항 미저장'),
        content: const Text('수정된 내용이 저장되지 않았습니다.\n뒤로 가시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소', style: TextStyle(color: AppColors.textTertiary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('확인', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && context.mounted) Navigator.pop(context);
            },
          ),
          title: const Text(
            '루틴 편집',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          centerTitle: true,
          actions: [
            GestureDetector(
              onTap: _handleSave,
              child: const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Text(
                  '저장',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 루틴 이름
                    const Text(
                      '루틴 이름',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      maxLength: 20,
                      decoration: InputDecoration(
                        hintText: '루틴 이름을 입력하세요',
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
                    const SizedBox(height: 24),

                    // 현재 운동 목록
                    const Text(
                      '현재 운동 목록',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (_exerciseIds.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            '운동이 없습니다',
                            style: TextStyle(fontSize: 12, color: AppColors.textHint),
                          ),
                        ),
                      )
                    else
                      ..._exerciseIds.map((id) {
                        final exercise = _getExerciseById(id);
                        if (exercise == null) return const SizedBox();
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      exercise.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      exercise.tag,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // 삭제 아이콘 - 회색
                              GestureDetector(
                                onTap: () => _removeExercise(id),
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
                            ],
                          ),
                        );
                      }),

                    const SizedBox(height: 16),

                    // 운동 추가 섹션
                    const Text(
                      '운동 추가',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 태그 필터
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _tags.length,
                        itemBuilder: (context, index) {
                          final tag = _tags[index];
                          final isSelected = _selectedTag == tag;

                          if (tag == _kBookmarkTag) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedTag = tag),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                                      color: isSelected ? Colors.white : AppColors.textTertiary,
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
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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

                    const SizedBox(height: 12),

                    // 추가할 수 있는 운동 목록
                    ..._filteredExercises
                        .where((e) => !_exerciseIds.contains(e.id))
                        .map((exercise) {
                      final isBookmarked = _bookmarks.contains(exercise.id);
                      final recordCount = _getRecordCount(exercise.id);
                      return GestureDetector(
                        onTap: () => _addExercise(exercise.id),
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
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
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                                      style: const TextStyle(fontSize: 14, color: AppColors.textHint),
                                    ),
                                  ],
                                ),
                              ),
                              if (isBookmarked)
                                const Padding(
                                  padding: EdgeInsets.only(left: 12),
                                  child: Icon(
                                    Icons.bookmark,
                                    size: 22,
                                    color: AppColors.primary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),

                    if (_filteredExercises.where((e) => !_exerciseIds.contains(e.id)).isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            '추가할 운동이 없습니다',
                            style: TextStyle(fontSize: 12, color: AppColors.textHint),
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // 하단 버튼 영역
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
              child: Column(
                children: [
                  // 루틴 삭제 버튼
                  GestureDetector(
                    onTap: _handleDelete,
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
                          '루틴 삭제',
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
          ],
        ),
      ),
    );
  }
}
