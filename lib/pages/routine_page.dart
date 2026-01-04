import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/routine.dart';
import '../models/exercise.dart';
import '../services/storage_service.dart';

// 루틴 화면
class RoutinePage extends StatefulWidget {
  const RoutinePage({super.key});

  @override
  State<RoutinePage> createState() => _RoutinePageState();
}

class _RoutinePageState extends State<RoutinePage> {
  final StorageService _storage = StorageService();
  List<Routine> _routines = [];
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
      _routines = _storage.getRoutines();
      _exercises = _storage.getExercises();
    });
  }

  // 루틴 추가
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

  // 루틴 업데이트
  Future<void> _updateRoutine(Routine routine) async {
    final index = _routines.indexWhere((r) => r.id == routine.id);
    if (index != -1) {
      _routines[index] = routine;
      await _storage.saveRoutines(_routines);
      setState(() {});
    }
  }

  // 루틴 삭제
  Future<void> _deleteRoutine(String routineId) async {
    _routines.removeWhere((r) => r.id == routineId);
    await _storage.saveRoutines(_routines);
    setState(() {});
  }

  // 새 루틴 만들기 모달
  void _showCreateRoutineModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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

  // 루틴 편집 모달
  void _showEditRoutineModal(Routine routine) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditRoutineModal(
        routine: routine,
        exercises: _exercises,
        onSave: (updatedRoutine) {
          _updateRoutine(updatedRoutine);
        },
      ),
    );
  }

  // 삭제 확인 다이얼로그
  void _showDeleteConfirm(Routine routine) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('루틴 삭제'),
        content: const Text('이 루틴을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteRoutine(routine.id);
            },
            child: const Text('삭제', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
  }

  // 데이터 관리 모달
  void _showDataModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              '데이터 관리',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                _exportData();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFA295D5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    '데이터 내보내기',
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
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                _importData();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFD1D5DB)),
                ),
                child: const Center(
                  child: Text(
                    '데이터 불러오기',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // 데이터 내보내기 (JSON 파일로 공유)
  Future<void> _exportData() async {
    try {
      // JSON 데이터 생성
      final jsonData = _storage.exportAllData();

      // 임시 파일 생성
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().toString().substring(0, 10);
      final file = File('${directory.path}/metamong_backup_$timestamp.json');
      await file.writeAsString(jsonData);

      // 공유 시트 열기
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: '메타몽 과부하 백업',
        text: '운동 기록 백업 파일',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('데이터를 내보냈습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('내보내기 실패: $e')),
        );
      }
    }
  }

  // 데이터 가져오기 (JSON 파일 선택)
  Future<void> _importData() async {
    try {
      // 파일 선택
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        return; // 취소됨
      }

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();

      // 확인 다이얼로그
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('데이터 가져오기'),
          content: const Text(
            '기존 데이터를 모두 덮어씁니다.\n계속하시겠습니까?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소', style: TextStyle(color: Color(0xFF6B7280))),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('가져오기', style: TextStyle(color: Color(0xFFA295D5))),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // 데이터 가져오기
      final counts = await _storage.importAllData(jsonString);

      // 데이터 새로고침
      _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '가져오기 완료: 운동 ${counts['exercises']}개, '
              '기록 ${counts['records']}개, 루틴 ${counts['routines']}개',
            ),
          ),
        );
      }
    } on FormatException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('가져오기 실패: $e')),
        );
      }
    }
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
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 새 루틴 만들기 버튼
                GestureDetector(
                  onTap: _showCreateRoutineModal,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA295D5),
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

                // 루틴 목록
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

                // 데이터 관리 버튼 공간
                const SizedBox(height: 50),
              ],
            ),
          ),

          // 데이터 관리 버튼 (하단 고정)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: GestureDetector(
                  onTap: _showDataModal,
                  child: const Text(
                    '데이터 관리',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9CA3AF),
                      decoration: TextDecoration.underline,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/home.png',
            width: 200,
            errorBuilder: (context, error, stackTrace) => const SizedBox(height: 100),
          ),
          const SizedBox(height: 16),
          const Text(
            '저장된 루틴이 없습니다',
            style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineCard(Routine routine) {
    return GestureDetector(
      onTap: () => _showEditRoutineModal(routine),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 루틴 이름 & 삭제 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  routine.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                GestureDetector(
                  onTap: () => _showDeleteConfirm(routine),
                  child: const Icon(
                    Icons.remove_circle_outline,
                    size: 20,
                    color: Color(0xFFC1BBC3),
                  ),
                ),
              ],
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    exercise.name,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF374151),
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
              border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Color(0xFF6B7280)),
                ),
                const Text(
                  '새 루틴 만들기',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
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
                      hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFA295D5)),
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
                          color: Color(0xFF374151),
                        ),
                      ),
                      if (_selectedExercises.isNotEmpty)
                        Text(
                          '${_selectedExercises.length}개 선택됨',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFFA295D5),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // 태그 필터
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _tags.map((tag) {
                        final isSelected = _selectedTag == tag;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedTag = tag),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFA295D5) : const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isSelected ? Colors.white : const Color(0xFF374151),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
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
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFA295D5) : Colors.white,
                                border: Border.all(
                                  color: isSelected ? const Color(0xFFA295D5) : const Color(0xFFD1D5DB),
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
                                  Text(
                                    exercise.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                  Text(
                                    exercise.tag,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6B7280),
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
                          style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 저장 버튼
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: GestureDetector(
              onTap: _handleSave,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFA295D5),
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

// 루틴 편집 모달
class _EditRoutineModal extends StatefulWidget {
  final Routine routine;
  final List<Exercise> exercises;
  final Function(Routine) onSave;

  const _EditRoutineModal({
    required this.routine,
    required this.exercises,
    required this.onSave,
  });

  @override
  State<_EditRoutineModal> createState() => _EditRoutineModalState();
}

class _EditRoutineModalState extends State<_EditRoutineModal> {
  late List<String> _exerciseIds;
  String _selectedTag = '전체';

  @override
  void initState() {
    super.initState();
    _exerciseIds = List.from(widget.routine.exerciseIds);
  }

  List<String> get _tags {
    final tags = widget.exercises.map((e) => e.tag).toSet().toList();
    return ['전체', ...tags];
  }

  List<Exercise> get _filteredExercises {
    if (_selectedTag == '전체') return widget.exercises;
    return widget.exercises.where((e) => e.tag == _selectedTag).toList();
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
    final updatedRoutine = Routine(
      id: widget.routine.id,
      name: widget.routine.name,
      exerciseIds: _exerciseIds,
    );
    widget.onSave(updatedRoutine);
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
              border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Color(0xFF6B7280)),
                ),
                Text(
                  '${widget.routine.name} 편집',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
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
                  // 현재 운동 목록
                  const Text(
                    '현재 운동 목록',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (_exerciseIds.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          '운동이 없습니다',
                          style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
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
                          color: const Color(0xFFF9FAFB),
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
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                  Text(
                                    exercise.tag,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _removeExercise(id),
                              child: const Icon(
                                Icons.remove_circle_outline,
                                size: 20,
                                color: Color(0xFFEF4444),
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
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 태그 필터
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _tags.map((tag) {
                        final isSelected = _selectedTag == tag;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedTag = tag),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFA295D5) : const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isSelected ? Colors.white : const Color(0xFF374151),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 추가할 수 있는 운동 목록
                  ..._filteredExercises
                      .where((e) => !_exerciseIds.contains(e.id))
                      .map((exercise) {
                    return GestureDetector(
                      onTap: () => _addExercise(exercise.id),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exercise.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            Text(
                              exercise.tag,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
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
                          style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 저장 버튼
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: GestureDetector(
              onTap: _handleSave,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFA295D5),
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
          ),
        ],
      ),
    );
  }
}
