import 'workout_set.dart';

// 운동 기록 모델
// 특정 날짜에 특정 운동을 한 기록
class Record {
  final String id;
  final String date;       // 날짜 (yyyy-MM-dd)
  final String exerciseId; // 운동 종목 ID
  List<WorkoutSet> sets;   // 세트들
  String? difficulty;      // 난이도 (easy, medium, hard)
  int order;               // 순서

  Record({
    required this.id,
    required this.date,
    required this.exerciseId,
    required this.sets,
    this.difficulty,
    this.order = 0,
  });

  // JSON으로 변환
  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'exerciseId': exerciseId,
    'sets': sets.map((s) => s.toJson()).toList(),
    'difficulty': difficulty,
    'order': order,
  };

  // JSON에서 생성
  factory Record.fromJson(Map<String, dynamic> json) => Record(
    id: json['id'],
    date: json['date'],
    exerciseId: json['exerciseId'],
    sets: (json['sets'] as List).map((s) => WorkoutSet.fromJson(s)).toList(),
    difficulty: json['difficulty'],
    order: json['order'] ?? 0,
  );

  // 총 볼륨 계산 (무게 x 횟수의 합)
  double get totalVolume {
    double total = 0;
    for (var set in sets) {
      if (set.weight != null && set.reps != null) {
        total += set.weight! * set.reps!;
      }
    }
    return total;
  }
}
