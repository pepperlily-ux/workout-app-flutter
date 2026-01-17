import 'package:flutter/material.dart';
import '../models/routine.dart';
import '../models/exercise.dart';
import '../models/record.dart';
import '../constants/app_colors.dart';
import '../services/storage_service.dart';

// 불러오기 페이지 (날짜/루틴 탭으로 구성)
class RoutineSelectPage extends StatefulWidget {
  final List<Routine> routines;
  final List<Exercise> exercises;
  final Function(Routine) onSelect;
  final Function(String name, List<String> exerciseIds)? onAddNew; // 더 이상 사용 안 함 (호환성 유지)
  final StorageService storage;
  final Function(List<Record>)? onSelectDateRecords; // 날짜 선택 시 해당 날짜의 기록들 전달

  const RoutineSelectPage({
    super.key,
    required this.routines,
    required this.exercises,
    required this.onSelect,
    this.onAddNew,
    required this.storage,
    this.onSelectDateRecords,
  });

  @override
  State<RoutineSelectPage> createState() => _RoutineSelectPageState();
}

class _RoutineSelectPageState extends State<RoutineSelectPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedRoutineId;
  String? _selectedDate;
  late List<Routine> _routines;
  List<Map<String, dynamic>> _dateRecordsList = []; // 날짜별 기록 리스트

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _routines = List.from(widget.routines);
    _loadDateRecords();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 날짜별 기록 불러오기
  void _loadDateRecords() {
    final allRecords = widget.storage.getRecords();

    // 날짜별로 그룹핑
    final Map<String, List<Record>> recordsByDate = {};
    for (final record in allRecords) {
      if (!recordsByDate.containsKey(record.date)) {
        recordsByDate[record.date] = [];
      }
      recordsByDate[record.date]!.add(record);
    }

    // 날짜 리스트 생성 (최신순 정렬)
    final dates = recordsByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    _dateRecordsList = dates.map((date) {
      final records = recordsByDate[date]!;
      records.sort((a, b) => a.order.compareTo(b.order)); // 순서대로 정렬

      // 운동 정보 수집
      final exerciseNames = <String>[];
      final tags = <String>[];
      final seenTags = <String>{};

      for (final record in records) {
        final exercise = _getExerciseById(record.exerciseId);
        if (exercise != null) {
          exerciseNames.add(exercise.name);
          // 태그 처리: 중복되지 않은 태그만 순서대로 추가
          if (!seenTags.contains(exercise.tag)) {
            tags.add(exercise.tag);
            seenTags.add(exercise.tag);
          }
        }
      }

      return {
        'date': date,
        'records': records,
        'exerciseNames': exerciseNames,
        'tags': tags,
      };
    }).toList();

    setState(() {});
  }

  Exercise? _getExerciseById(String id) {
    try {
      return widget.exercises.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  // 날짜 문자열을 한국어로 변환 (예: "1월 15일")
  String _formatDateKorean(String dateStr) {
    final parts = dateStr.split('-');
    if (parts.length != 3) return dateStr;
    return '${int.parse(parts[1])}월 ${int.parse(parts[2])}일';
  }

  void _handleSelectRoutine() {
    if (_selectedRoutineId == null) return;

    final routine = _routines.firstWhere(
      (r) => r.id == _selectedRoutineId,
    );
    widget.onSelect(routine);
    Navigator.pop(context);
  }

  void _handleSelectDate() {
    if (_selectedDate == null) return;

    final dateData = _dateRecordsList.firstWhere(
      (d) => d['date'] == _selectedDate,
    );
    final records = dateData['records'] as List<Record>;

    if (widget.onSelectDateRecords != null) {
      widget.onSelectDateRecords!(records);
    }
    Navigator.pop(context);
  }

  void _handleSelect() {
    if (_tabController.index == 0) {
      // 날짜 탭
      _handleSelectDate();
    } else {
      // 루틴 탭
      _handleSelectRoutine();
    }
  }

  bool get _hasSelection {
    if (_tabController.index == 0) {
      return _selectedDate != null;
    } else {
      return _selectedRoutineId != null;
    }
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
          '불러오기',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => setState(() {}), // 탭 변경 시 UI 갱신
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textTertiary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2,
          tabs: const [
            Tab(text: '날짜'),
            Tab(text: '루틴'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 탭 내용
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // 날짜 탭
                  _buildDateTab(),
                  // 루틴 탭
                  _buildRoutineTab(),
                ],
              ),
            ),

            // 하단 선택 버튼
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
                  onTap: _hasSelection ? _handleSelect : null,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _hasSelection
                          ? AppColors.primary
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        _hasSelection ? '불러오기' : '항목을 선택하세요',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _hasSelection
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

  // 날짜 탭 위젯
  Widget _buildDateTab() {
    if (_dateRecordsList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/home.png',
              width: 160,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(
                    Icons.calendar_today,
                    size: 48,
                    color: Colors.grey[300],
                  ),
            ),
            const SizedBox(height: 16),
            const Text(
              '운동 기록이 없습니다',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _dateRecordsList.length,
      itemBuilder: (context, index) {
        final dateData = _dateRecordsList[index];
        final date = dateData['date'] as String;
        final exerciseNames = dateData['exerciseNames'] as List<String>;
        final tags = dateData['tags'] as List<String>;
        final isSelected = _selectedDate == date;

        return GestureDetector(
          onTap: () {
            setState(() {
              if (_selectedDate == date) {
                _selectedDate = null;
              } else {
                _selectedDate = date;
              }
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
                // 체크박스 (루틴 탭과 동일한 스타일)
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
                      // 날짜 + 태그들
                      Row(
                        children: [
                          Text(
                            _formatDateKorean(date),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // 태그 뱃지들
                          Expanded(
                            child: Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: tags.map((tag) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    tag,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // 운동 목록 (태그 형태)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: exerciseNames.map((name) {
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
                              name,
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
    );
  }

  // 루틴 탭 위젯
  Widget _buildRoutineTab() {
    if (_routines.isEmpty) {
      return Center(
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
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _routines.length,
      itemBuilder: (context, index) {
        final routine = _routines[index];
        final isSelected = _selectedRoutineId == routine.id;

        return GestureDetector(
          onTap: () {
            setState(() {
              if (_selectedRoutineId == routine.id) {
                _selectedRoutineId = null;
              } else {
                _selectedRoutineId = routine.id;
              }
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
                // 체크박스
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
                      // 루틴 이름
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
    );
  }
}
