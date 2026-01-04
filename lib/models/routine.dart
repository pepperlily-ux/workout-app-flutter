// 루틴 모델
// 여러 운동을 묶어서 저장
class Routine {
  final String id;
  final String name;            // 루틴 이름 (예: "가슴 루틴", "하체 루틴")
  final List<String> exerciseIds; // 포함된 운동 ID들

  Routine({
    required this.id,
    required this.name,
    required this.exerciseIds,
  });

  // JSON으로 변환
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'exerciseIds': exerciseIds,
  };

  // JSON에서 생성
  factory Routine.fromJson(Map<String, dynamic> json) => Routine(
    id: json['id'],
    name: json['name'],
    exerciseIds: List<String>.from(json['exerciseIds']),
  );
}
