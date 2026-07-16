class LessonStats {
  LessonStats();

  factory LessonStats.fromJson(Map<String, dynamic> json) {
    final Object? lastCompletedAt = json['lastCompletedAt'];
    return LessonStats()
      ..attempts = _readInt(json['attempts'])
      ..completions = _readInt(json['completions'])
      ..totalErrors = _readInt(json['totalErrors'])
      ..totalStrokes = _readInt(json['totalStrokes'])
      ..bestWpm = _readDouble(json['bestWpm'])
      ..bestAccuracy = _readDouble(json['bestAccuracy'])
      ..lastWpm = _readDouble(json['lastWpm'])
      ..lastAccuracy = _readDouble(json['lastAccuracy'])
      ..lastCompletedAt = lastCompletedAt is String ? lastCompletedAt : null;
  }

  int attempts = 0;
  int completions = 0;
  int totalErrors = 0;
  int totalStrokes = 0;
  double bestWpm = 0;
  double bestAccuracy = 0;
  double lastWpm = 0;
  double lastAccuracy = 0;
  String? lastCompletedAt;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'attempts': attempts,
      'completions': completions,
      'totalErrors': totalErrors,
      'totalStrokes': totalStrokes,
      'bestWpm': bestWpm,
      'bestAccuracy': bestAccuracy,
      'lastWpm': lastWpm,
      'lastAccuracy': lastAccuracy,
      'lastCompletedAt': lastCompletedAt,
    };
  }

  static int _readInt(Object? value) {
    return value is num ? value.toInt() : 0;
  }

  static double _readDouble(Object? value) {
    return value is num ? value.toDouble() : 0;
  }
}
