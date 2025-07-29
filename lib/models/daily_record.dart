/// Model cho việc theo dõi hoạt động hàng ngày
class DailyRecord {
  final DateTime date;
  final double steps;
  final double waterIntake; // Lít
  final double sleepHours;
  final double? weight; // Cân nặng (tùy chọn)
  final MoodLevel? mood; // Tâm trạng (tùy chọn)
  final List<String> notes; // Ghi chú
  final Map<String, dynamic> additionalData; // Dữ liệu bổ sung

  DailyRecord({
    required this.date,
    this.steps = 0,
    this.waterIntake = 0,
    this.sleepHours = 0,
    this.weight,
    this.mood,
    this.notes = const [],
    this.additionalData = const {},
  });

  /// Tính điểm hoạt động tổng thể (0-100)
  double get activityScore {
    double score = 0;
    
    // Điểm bước chân (0-40)
    score += (steps / 10000 * 40).clamp(0, 40);
    
    // Điểm nước uống (0-30)
    score += (waterIntake / 2.0 * 30).clamp(0, 30);
    
    // Điểm giấc ngủ (0-30)
    score += (sleepHours / 8.0 * 30).clamp(0, 30);
    
    return score.clamp(0, 100);
  }

  /// Đánh giá mức độ hoạt động
  String get activityLevel {
    final score = activityScore;
    if (score >= 80) return 'Xuất sắc';
    if (score >= 60) return 'Tốt';
    if (score >= 40) return 'Trung bình';
    if (score >= 20) return 'Kém';
    return 'Rất kém';
  }

  /// Kiểm tra có đạt mục tiêu bước chân không
  bool get isStepsGoalMet => steps >= 8000;

  /// Kiểm tra có đạt mục tiêu nước uống không
  bool get isWaterGoalMet => waterIntake >= 2.0;

  /// Kiểm tra có đạt mục tiêu giấc ngủ không
  bool get isSleepGoalMet => sleepHours >= 7.0;

  /// Số mục tiêu đã đạt được
  int get goalsAchieved {
    int count = 0;
    if (isStepsGoalMet) count++;
    if (isWaterGoalMet) count++;
    if (isSleepGoalMet) count++;
    return count;
  }

  /// Tỷ lệ hoàn thành mục tiêu (%)
  double get goalCompletionRate => (goalsAchieved / 3.0 * 100);

  /// Chuyển đổi sang Map để lưu trữ
  Map<String, dynamic> toMap() {
    return {
      'date': date.millisecondsSinceEpoch,
      'steps': steps,
      'waterIntake': waterIntake,
      'sleepHours': sleepHours,
      'weight': weight,
      'mood': mood?.index,
      'notes': notes,
      'additionalData': additionalData,
    };
  }

  /// Tạo từ Map
  factory DailyRecord.fromMap(Map<String, dynamic> map) {
    return DailyRecord(
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] ?? 0),
      steps: (map['steps'] ?? 0).toDouble(),
      waterIntake: (map['waterIntake'] ?? 0).toDouble(),
      sleepHours: (map['sleepHours'] ?? 0).toDouble(),
      weight: map['weight']?.toDouble(),
      mood: map['mood'] != null ? MoodLevel.values[map['mood']] : null,
      notes: List<String>.from(map['notes'] ?? []),
      additionalData: Map<String, dynamic>.from(map['additionalData'] ?? {}),
    );
  }

  /// Tạo bản sao với các thay đổi
  DailyRecord copyWith({
    DateTime? date,
    double? steps,
    double? waterIntake,
    double? sleepHours,
    double? weight,
    MoodLevel? mood,
    List<String>? notes,
    Map<String, dynamic>? additionalData,
  }) {
    return DailyRecord(
      date: date ?? this.date,
      steps: steps ?? this.steps,
      waterIntake: waterIntake ?? this.waterIntake,
      sleepHours: sleepHours ?? this.sleepHours,
      weight: weight ?? this.weight,
      mood: mood ?? this.mood,
      notes: notes ?? this.notes,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  /// So sánh hai record
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DailyRecord &&
        other.date.day == date.day &&
        other.date.month == date.month &&
        other.date.year == date.year;
  }

  @override
  int get hashCode => date.hashCode;

  @override
  String toString() {
    return 'DailyRecord(date: ${date.toString().split(' ')[0]}, '
           'steps: $steps, water: ${waterIntake}L, sleep: ${sleepHours}h, '
           'score: ${activityScore.toStringAsFixed(1)})';
  }
}

/// Enum cho tâm trạng
enum MoodLevel {
  veryBad,    // Rất tệ
  bad,        // Tệ
  neutral,    // Bình thường
  good,       // Tốt
  veryGood,   // Rất tốt
}

extension MoodLevelExtension on MoodLevel {
  String get name {
    switch (this) {
      case MoodLevel.veryBad:
        return 'Rất tệ';
      case MoodLevel.bad:
        return 'Tệ';
      case MoodLevel.neutral:
        return 'Bình thường';
      case MoodLevel.good:
        return 'Tốt';
      case MoodLevel.veryGood:
        return 'Rất tốt';
    }
  }

  String get emoji {
    switch (this) {
      case MoodLevel.veryBad:
        return '😢';
      case MoodLevel.bad:
        return '😞';
      case MoodLevel.neutral:
        return '😐';
      case MoodLevel.good:
        return '😊';
      case MoodLevel.veryGood:
        return '😄';
    }
  }

  /// Màu sắc tương ứng
  int get colorValue {
    switch (this) {
      case MoodLevel.veryBad:
        return 0xFFE74C3C; // Đỏ
      case MoodLevel.bad:
        return 0xFFE67E22; // Cam đậm
      case MoodLevel.neutral:
        return 0xFFF39C12; // Cam
      case MoodLevel.good:
        return 0xFF27AE60; // Xanh lá
      case MoodLevel.veryGood:
        return 0xFF2ECC71; // Xanh lá sáng
    }
  }
}

/// Utility class cho DailyRecord
class DailyRecordUtils {
  /// Tạo record mặc định cho ngày hôm nay
  static DailyRecord createTodayRecord() {
    return DailyRecord(
      date: DateTime.now(),
      steps: 0,
      waterIntake: 0,
      sleepHours: 0,
    );
  }

  /// Tính trung bình từ danh sách records
  static Map<String, double> calculateAverages(List<DailyRecord> records) {
    if (records.isEmpty) {
      return {
        'steps': 0,
        'waterIntake': 0,
        'sleepHours': 0,
        'activityScore': 0,
      };
    }

    final totalSteps = records.fold<double>(0, (sum, record) => sum + record.steps);
    final totalWater = records.fold<double>(0, (sum, record) => sum + record.waterIntake);
    final totalSleep = records.fold<double>(0, (sum, record) => sum + record.sleepHours);
    final totalScore = records.fold<double>(0, (sum, record) => sum + record.activityScore);

    final count = records.length;

    return {
      'steps': totalSteps / count,
      'waterIntake': totalWater / count,
      'sleepHours': totalSleep / count,
      'activityScore': totalScore / count,
    };
  }

  /// Lọc records theo khoảng thời gian
  static List<DailyRecord> filterByDateRange(
    List<DailyRecord> records,
    DateTime startDate,
    DateTime endDate,
  ) {
    return records.where((record) {
      return record.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
             record.date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  /// Lấy records của tuần hiện tại
  static List<DailyRecord> getThisWeekRecords(List<DailyRecord> records) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    return filterByDateRange(records, startOfWeek, endOfWeek);
  }

  /// Lấy records của tháng hiện tại
  static List<DailyRecord> getThisMonthRecords(List<DailyRecord> records) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    
    return filterByDateRange(records, startOfMonth, endOfMonth);
  }
}
