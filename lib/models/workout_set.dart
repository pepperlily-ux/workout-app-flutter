// 세트 모델
// 각 운동의 세트별 무게와 횟수
class WorkoutSet {
  double? weight; // 무게 (kg)
  int? reps;      // 횟수 (회)

  WorkoutSet({
    this.weight,
    this.reps,
  });

  // JSON으로 변환
  Map<String, dynamic> toJson() => {
    'weight': weight,
    'reps': reps,
  };

  // JSON에서 생성
  factory WorkoutSet.fromJson(Map<String, dynamic> json) => WorkoutSet(
    weight: json['weight']?.toDouble(),
    reps: json['reps'],
  );

  // 복사본 만들기 (이전 기록에서 불러올 때)
  WorkoutSet copyWith({double? weight, int? reps}) => WorkoutSet(
    weight: weight ?? this.weight,
    reps: reps ?? this.reps,
  );
}
