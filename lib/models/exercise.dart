// 운동 종목 모델
// 예: 벤치프레스, 스쿼트, 데드리프트 등
class Exercise {
  final String id;
  final String name; // 운동 이름
  final String tag;  // 태그 (가슴, 등, 하체 등)

  Exercise({
    required this.id,
    required this.name,
    required this.tag,
  });

  // JSON으로 변환 (저장용)
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'tag': tag,
  };

  // JSON에서 생성 (불러오기용)
  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
    id: json['id'],
    name: json['name'],
    tag: json['tag'],
  );
}
