class Notification {
  final String title;
  final String body;
  final DateTime date;

  Notification({
    required this.title,
    required this.body,
    required this.date,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      title: json['title'],
      body: json['content'],
      date: DateTime.parse(json['time']).toUtc(),
    );
  }

  factory Notification.fromEntity(Map<String, dynamic> entity) {
    return Notification(
      title: entity['title'],
      body: entity['content'],
      date: DateTime.parse(entity['date']).toUtc(),
    );
  }

  toJson() => {
        'title': title,
        'content': body,
        'date': date.toUtc().toIso8601String(),
      };
}
