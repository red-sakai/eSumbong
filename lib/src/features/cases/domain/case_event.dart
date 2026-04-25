class CaseEvent {
  const CaseEvent({
    required this.title,
    required this.description,
    required this.timestamp,
  });

  final String title;
  final String description;
  final DateTime timestamp;

  factory CaseEvent.fromJson(Map<String, dynamic> json) => CaseEvent(
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        timestamp:
            DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'title': title,
        'description': description,
        'timestamp': timestamp.toIso8601String(),
      };
}
