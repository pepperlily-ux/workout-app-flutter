import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/exercise.dart';
import '../models/record.dart';
import '../models/routine.dart';

// 로컬 저장소 서비스
// SharedPreferences를 사용해서 데이터를 저장/불러오기
class StorageService {
  static const String _exercisesKey = 'workout_exercises';
  static const String _recordsKey = 'workout_records';
  static const String _routinesKey = 'workout_routines';
  static const String _checkedSetsKey = 'metamong-checked-sets';

  // 싱글톤 패턴 (앱 전체에서 하나의 인스턴스만 사용)
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  // 초기화
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // === 운동 종목 ===

  // 운동 목록 불러오기
  List<Exercise> getExercises() {
    final String? data = _prefs?.getString(_exercisesKey);
    if (data == null) return [];

    final List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((json) => Exercise.fromJson(json)).toList();
  }

  // 운동 목록 저장
  Future<void> saveExercises(List<Exercise> exercises) async {
    final String data = jsonEncode(exercises.map((e) => e.toJson()).toList());
    await _prefs?.setString(_exercisesKey, data);
  }

  // 운동 추가
  Future<void> addExercise(Exercise exercise) async {
    final exercises = getExercises();
    exercises.add(exercise);
    await saveExercises(exercises);
  }

  // === 운동 기록 ===

  // 기록 목록 불러오기
  List<Record> getRecords() {
    final String? data = _prefs?.getString(_recordsKey);
    if (data == null) return [];

    final List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((json) => Record.fromJson(json)).toList();
  }

  // 기록 목록 저장
  Future<void> saveRecords(List<Record> records) async {
    final String data = jsonEncode(records.map((r) => r.toJson()).toList());
    await _prefs?.setString(_recordsKey, data);
  }

  // 특정 날짜의 기록 가져오기
  List<Record> getRecordsByDate(String date) {
    final records = getRecords();
    final dateRecords = records.where((r) => r.date == date).toList();
    dateRecords.sort((a, b) => a.order.compareTo(b.order));
    return dateRecords;
  }

  // 기록 추가
  Future<void> addRecord(Record record) async {
    final records = getRecords();
    records.add(record);
    await saveRecords(records);
  }

  // 기록 업데이트
  Future<void> updateRecord(Record record) async {
    final records = getRecords();
    final index = records.indexWhere((r) => r.id == record.id);
    if (index != -1) {
      records[index] = record;
      await saveRecords(records);
    }
  }

  // 기록 삭제
  Future<void> deleteRecord(String recordId) async {
    final records = getRecords();
    records.removeWhere((r) => r.id == recordId);
    await saveRecords(records);
  }

  // 특정 운동의 이전 기록 가져오기 (성장률 계산용)
  List<Record> getExerciseHistory(String exerciseId) {
    final records = getRecords();
    final history = records.where((r) => r.exerciseId == exerciseId).toList();
    history.sort((a, b) => b.date.compareTo(a.date)); // 최신순
    return history;
  }

  // === 루틴 ===

  // 루틴 목록 불러오기
  List<Routine> getRoutines() {
    final String? data = _prefs?.getString(_routinesKey);
    if (data == null) return [];

    final List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((json) => Routine.fromJson(json)).toList();
  }

  // 루틴 목록 저장
  Future<void> saveRoutines(List<Routine> routines) async {
    final String data = jsonEncode(routines.map((r) => r.toJson()).toList());
    await _prefs?.setString(_routinesKey, data);
  }

  // === 체크된 세트 ===

  // 체크된 세트 불러오기
  Map<String, bool> getCheckedSets() {
    final String? data = _prefs?.getString(_checkedSetsKey);
    if (data == null) return {};

    final Map<String, dynamic> jsonMap = jsonDecode(data);
    return jsonMap.map((key, value) => MapEntry(key, value as bool));
  }

  // 체크된 세트 저장
  Future<void> saveCheckedSets(Map<String, bool> checkedSets) async {
    final String data = jsonEncode(checkedSets);
    await _prefs?.setString(_checkedSetsKey, data);
  }

  // 세트 체크 토글
  Future<void> toggleSetCheck(String recordId, int setIndex) async {
    final checkedSets = getCheckedSets();
    final key = '$recordId-$setIndex';
    checkedSets[key] = !(checkedSets[key] ?? false);
    await saveCheckedSets(checkedSets);
  }
}
