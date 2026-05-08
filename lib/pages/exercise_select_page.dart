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

const _kBookmarkTag = '__bookmark__';

class _ExerciseSelectPageState extends State<ExerciseSelectPage> {
  String _selectedTag = '전체';
  final Set<String> _selectedExerciseIds = {};
  late List<Exercise> _exercises;
  Set<String> _bookmarks = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _exercises = widget.storage.getExercises();
    _bookmarks = widget.storage.getBookmarks();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _allTags {
    final tags = _exercises.map((e) => e.tag).toSet().toList();
    tags.sort();
    final hasBookmarks = _bookmarks.isNotEmpty &&
        _exercises.any((e) => _bookmarks.contains(e.id));
    return ['전체', if (hasBookmarks) _kBookmarkTag, ...tags];
  }

  bool get _isSearching => _searchQuery.trim().isNotEmpty;

  List<Exercise> _sortByBookmark(List<Exercise> list) {
    return List.from(list)
      ..sort((a, b) {
        final aB = _bookmarks.contains(a.id) ? 0 : 1;
        final bB = _bookmarks.contains(b.id) ? 0 : 1;
        return aB.compareTo(bB);
      });
  }

  List<Exercise> get _filteredExercises {
    if (_isSearching) {
      final q = _searchQuery.trim().toLowerCase();
      final results = _exercises.where((e) => e.name.toLowerCase().contains(q)).toList();
      return _sortByBookmark(results);
    }
    if (_selectedTag == _kBookmarkTag) {
      return _sortByBookmark(_exercises.where((e) => _bookmarks.contains(e.id)).toList());
    }
    if (_selectedTag == '전체') return _sortByBookmark(List.from(_exercises));
    return _sortByBookmark(_exercises.where((e) => e.tag == _selectedTag).toList());
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
    final selectedExercises = _exercises
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

                      final name = nameController.text.trim();
                      final tag = tagController.text.trim();
                      Navigator.pop(modalContext);
                      await widget.onAddNew(name, tag);
                      if (mounted) {
                        setState(() {
                          _exercises = widget.storage.getExercises();
                          final newExercise = _exercises.where((e) => e.name == name && e.tag == tag).lastOrNull;
                          if (newExercise != null) {
                            _selectedExerciseIds.add(newExercise.id);
                          }
                        });
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
            fontSize: 16,
            fontWeight: FontWeight.w500,
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
                  // 검색 인풋
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '운동 이름으로 검색',
                      hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: AppColors.textHint, size: 20),
                      suffixIcon: _isSearching
                          ? GestureDetector(
                              onTap: () => _searchController.clear(),
                              child: const Icon(Icons.close, color: AppColors.textHint, size: 20),
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.backgroundLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 태그 필터 (검색 중이면 숨김)
                  if (!_isSearching) ...[
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
                  ] else
                    const SizedBox(height: 8),
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
                          if (!_isSearching)
                            Image.asset(
                              'assets/Baby.png',
                              width: 200,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                    Icons.fitness_center,
                                    size: 48,
                                    color: Colors.grey[300],
                                  ),
                            ),
                          if (!_isSearching) const SizedBox(height: 16),
                          Text(
                            _isSearching ? '찾으시는 운동이 없습니다' : '운동이 없습니다몽',
                            style: const TextStyle(
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

                        final isBookmarked = _bookmarks.contains(exercise.id);

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
                                // 운동 정보
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
                      },
                    ),
            ),

            // 하단 추가 버튼
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
                  onTap: _selectedExerciseIds.isNotEmpty ? _handleAddExercises : null,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _selectedExerciseIds.isNotEmpty
                          ? AppColors.primary
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        _selectedExerciseIds.isNotEmpty
                            ? '${_selectedExerciseIds.length}개 운동 추가'
                            : '운동을 선택하세요',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _selectedExerciseIds.isNotEmpty
                              ? Colors.white
                              : Colors.grey[500],
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
