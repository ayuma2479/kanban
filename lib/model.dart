class Task {
  String title;
  int status; // 0:リード 1:商談 2:契約 3:失注
  DateTime? lastActionDate;
  Task(this.title, [this.status = 0, this.lastActionDate]);

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    json['title'] as String,
    json['status'] as int,
    DateTime.tryParse(json['lastActionDate'] as String? ?? ''),
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'status': status,
    'lastActionDate': lastActionDate?.toIso8601String(),
  };
}
