import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service theo dõi hoạt động hàng ngày
class DailyTrackingService extends ChangeNotifier {
  static final DailyTrackingService _instance = DailyTrackingService._internal();
  factory DailyTrackingService() => _instance;
  DailyTrackingService._internal();

  static const String _dailyRecordsKey = 'daily_records';
  static const String _trackingSettingsKey = 'tracking_settings';

  List<DailyRecord> _records = [];
  TrackingSettings _settings = TrackingSettings();
  bool _isInitialized = false;

  List<DailyRecord> get records => _records;
  TrackingSettings get settings => _settings;
  bool get isInitialized => _isInitialized;

  /// Khởi tạo service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await _loadSettings();
    await _loadRecords();
    _isInitialized = true;
    notifyListeners();
  }

  /// Tải cài đặt theo dõi
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsString = prefs.getString(_trackingSettingsKey);
    
    if (settingsString != null) {
      try {
        final settingsMap = jsonDecode(settingsString) as Map<String, dynamic>;
        _settings = TrackingSettings.fromMap(settingsMap);
      } catch (e) {
        _settings = TrackingSettings();
      }
    }
  }

  /// Lưu cài đặt theo dõi
  Future<void> saveSettings(TrackingSettings settings) async {
    _settings = settings;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_trackingSettingsKey, jsonEncode(settings.toMap()));
    notifyListeners();
  }

  /// Tải danh sách bản ghi
  Future<void> _loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final recordsString = prefs.getString(_dailyRecordsKey) ?? '[]';
    
    try {
      final List<dynamic> recordsList = jsonDecode(recordsString);
      _records = recordsList
          .map((json) => DailyRecord.fromMap(json as Map<String, dynamic>))
          .toList();
      
      // Sắp xếp theo ngày giảm dần
      _records.sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      _records = [];
    }
  }

  /// Lưu danh sách bản ghi
  Future<void> _saveRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final recordsJson = _records.map((r) => r.toMap()).toList();
    await prefs.setString(_dailyRecordsKey, jsonEncode(recordsJson));
  }

  /// Lấy bản ghi của ngày hôm nay
  DailyRecord getTodayRecord() {
    final today = DateTime.now();
    final todayKey = _getDateKey(today);
    
    final existingRecord = _records.firstWhere(
      (record) => _getDateKey(record.date) == todayKey,
      orElse: () => DailyRecord(date: today),
    );
    
    return existingRecord;
  }

  /// Cập nhật bản ghi hàng ngày
  Future<void> updateDailyRecord(DailyRecord record) async {
    final dateKey = _getDateKey(record.date);
    final existingIndex = _records.indexWhere(
      (r) => _getDateKey(r.date) == dateKey,
    );
    
    if (existingIndex != -1) {
      _records[existingIndex] = record;
    } else {
      _records.add(record);
      _records.sort((a, b) => b.date.compareTo(a.date));
    }
    
    await _saveRecords();
    notifyListeners();
  }

  /// Cập nhật số bước chân
  Future<void> updateSteps(int steps) async {
    final today = getTodayRecord();
    final updated = today.copyWith(steps: steps);
    await updateDailyRecord(updated);
  }

  /// Cập nhật lượng nước
  Future<void> updateWaterIntake(double liters) async {
    final today = getTodayRecord();
    final updated = today.copyWith(waterIntake: liters);
    await updateDailyRecord(updated);
  }

  /// Thêm nước đã uống
  Future<void> addWater(double liters) async {
    final today = getTodayRecord();
    final newAmount = today.waterIntake + liters;
    await updateWaterIntake(newAmount);
  }

  /// Cập nhật giấc ngủ
  Future<void> updateSleep(double hours) async {
    final today = getTodayRecord();
    final updated = today.copyWith(sleepHours: hours);
    await updateDailyRecord(updated);
  }

  /// Cập nhật tâm trạng
  Future<void> updateMood(MoodLevel mood) async {
    final today = getTodayRecord();
    final updated = today.copyWith(mood: mood);
    await updateDailyRecord(updated);
  }

  /// Cập nhật ghi chú
  Future<void> updateNotes(String notes) async {
    final today = getTodayRecord();
    final updated = today.copyWith(notes: notes);
    await updateDailyRecord(updated);
  }

  /// Cập nhật cân nặng
  Future<void> updateWeight(double weight) async {
    final today = getTodayRecord();
    final updated = today.copyWith(weight: weight);
    await updateDailyRecord(updated);
  }

  /// Lấy thống kê tuần này
  Map<String, dynamic> getWeeklyStats() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekRecords = _records.where((record) {
      return record.date.isAfter(weekStart.subtract(const Duration(days: 1)));
    }).toList();

    if (weekRecords.isEmpty) {
      return {
        'averageSteps': 0,
        'totalWater': 0.0,
        'averageSleep': 0.0,
        'daysTracked': 0,
        'moodDistribution': <String, int>{},
      };
    }

    final totalSteps = weekRecords.fold<int>(0, (sum, r) => sum + r.steps);
    final totalWater = weekRecords.fold<double>(0, (sum, r) => sum + r.waterIntake);
    final totalSleep = weekRecords.fold<double>(0, (sum, r) => sum + r.sleepHours);
    
    final moodCounts = <MoodLevel, int>{};
    for (final record in weekRecords) {
      if (record.mood != null) {
        moodCounts[record.mood!] = (moodCounts[record.mood!] ?? 0) + 1;
      }
    }

    return {
      'averageSteps': (totalSteps / weekRecords.length).round(),
      'totalWater': totalWater,
      'averageSleep': totalSleep / weekRecords.length,
      'daysTracked': weekRecords.length,
      'moodDistribution': moodCounts.map((k, v) => MapEntry(k.name, v)),
    };
  }

  /// Lấy thống kê tháng này
  Map<String, dynamic> getMonthlyStats() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthRecords = _records.where((record) {
      return record.date.isAfter(monthStart.subtract(const Duration(days: 1)));
    }).toList();

    if (monthRecords.isEmpty) {
      return {
        'averageSteps': 0,
        'totalWater': 0.0,
        'averageSleep': 0.0,
        'daysTracked': 0,
        'bestDay': null,
        'trends': <String, String>{},
      };
    }

    final totalSteps = monthRecords.fold<int>(0, (sum, r) => sum + r.steps);
    final totalWater = monthRecords.fold<double>(0, (sum, r) => sum + r.waterIntake);
    final totalSleep = monthRecords.fold<double>(0, (sum, r) => sum + r.sleepHours);
    
    // Tìm ngày tốt nhất (nhiều bước nhất)
    final bestDay = monthRecords.reduce((a, b) => a.steps > b.steps ? a : b);

    return {
      'averageSteps': (totalSteps / monthRecords.length).round(),
      'totalWater': totalWater,
      'averageSleep': totalSleep / monthRecords.length,
      'daysTracked': monthRecords.length,
      'bestDay': bestDay,
      'trends': _calculateTrends(monthRecords),
    };
  }

  /// Tính xu hướng
  Map<String, String> _calculateTrends(List<DailyRecord> records) {
    if (records.length < 7) return {};

    final firstWeek = records.sublist(records.length - 7);
    final lastWeek = records.sublist(0, 7);

    final firstWeekSteps = firstWeek.fold<int>(0, (sum, r) => sum + r.steps) / 7;
    final lastWeekSteps = lastWeek.fold<int>(0, (sum, r) => sum + r.steps) / 7;

    final stepsTrend = lastWeekSteps > firstWeekSteps ? 'Tăng' : 'Giảm';

    return {
      'steps': stepsTrend,
    };
  }

  /// Lấy key ngày
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Xóa bản ghi cũ (giữ lại 90 ngày)
  Future<void> cleanOldRecords() async {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 90));
    _records.removeWhere((record) => record.date.isBefore(cutoffDate));
    await _saveRecords();
    notifyListeners();
  }
}

/// Enum mức độ tâm trạng
enum MoodLevel {
  veryBad,
  bad,
  neutral,
  good,
  veryGood,
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

  IconData get icon {
    switch (this) {
      case MoodLevel.veryBad:
        return Icons.sentiment_very_dissatisfied;
      case MoodLevel.bad:
        return Icons.sentiment_dissatisfied;
      case MoodLevel.neutral:
        return Icons.sentiment_neutral;
      case MoodLevel.good:
        return Icons.sentiment_satisfied;
      case MoodLevel.veryGood:
        return Icons.sentiment_very_satisfied;
    }
  }

  Color get color {
    switch (this) {
      case MoodLevel.veryBad:
        return Colors.red[700]!;
      case MoodLevel.bad:
        return Colors.orange[700]!;
      case MoodLevel.neutral:
        return Colors.grey[600]!;
      case MoodLevel.good:
        return Colors.lightGreen[700]!;
      case MoodLevel.veryGood:
        return Colors.green[700]!;
    }
  }
}

/// Model bản ghi hàng ngày
class DailyRecord {
  final DateTime date;
  final int steps;
  final double waterIntake; // Lít
  final double sleepHours;
  final MoodLevel? mood;
  final String notes;
  final double? weight;

  DailyRecord({
    required this.date,
    this.steps = 0,
    this.waterIntake = 0.0,
    this.sleepHours = 0.0,
    this.mood,
    this.notes = '',
    this.weight,
  });

  DailyRecord copyWith({
    DateTime? date,
    int? steps,
    double? waterIntake,
    double? sleepHours,
    MoodLevel? mood,
    String? notes,
    double? weight,
  }) {
    return DailyRecord(
      date: date ?? this.date,
      steps: steps ?? this.steps,
      waterIntake: waterIntake ?? this.waterIntake,
      sleepHours: sleepHours ?? this.sleepHours,
      mood: mood ?? this.mood,
      notes: notes ?? this.notes,
      weight: weight ?? this.weight,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date.millisecondsSinceEpoch,
      'steps': steps,
      'waterIntake': waterIntake,
      'sleepHours': sleepHours,
      'mood': mood?.index,
      'notes': notes,
      'weight': weight,
    };
  }

  factory DailyRecord.fromMap(Map<String, dynamic> map) {
    return DailyRecord(
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] ?? 0),
      steps: map['steps'] ?? 0,
      waterIntake: (map['waterIntake'] ?? 0.0).toDouble(),
      sleepHours: (map['sleepHours'] ?? 0.0).toDouble(),
      mood: map['mood'] != null ? MoodLevel.values[map['mood']] : null,
      notes: map['notes'] ?? '',
      weight: map['weight']?.toDouble(),
    );
  }
}

/// Cài đặt theo dõi
class TrackingSettings {
  final bool trackSteps;
  final bool trackWater;
  final bool trackSleep;
  final bool trackMood;
  final bool trackWeight;
  final int dailyStepsGoal;
  final double dailyWaterGoal; // Lít
  final double dailySleepGoal; // Giờ

  TrackingSettings({
    this.trackSteps = true,
    this.trackWater = true,
    this.trackSleep = true,
    this.trackMood = true,
    this.trackWeight = false,
    this.dailyStepsGoal = 10000,
    this.dailyWaterGoal = 2.0,
    this.dailySleepGoal = 8.0,
  });

  TrackingSettings copyWith({
    bool? trackSteps,
    bool? trackWater,
    bool? trackSleep,
    bool? trackMood,
    bool? trackWeight,
    int? dailyStepsGoal,
    double? dailyWaterGoal,
    double? dailySleepGoal,
  }) {
    return TrackingSettings(
      trackSteps: trackSteps ?? this.trackSteps,
      trackWater: trackWater ?? this.trackWater,
      trackSleep: trackSleep ?? this.trackSleep,
      trackMood: trackMood ?? this.trackMood,
      trackWeight: trackWeight ?? this.trackWeight,
      dailyStepsGoal: dailyStepsGoal ?? this.dailyStepsGoal,
      dailyWaterGoal: dailyWaterGoal ?? this.dailyWaterGoal,
      dailySleepGoal: dailySleepGoal ?? this.dailySleepGoal,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'trackSteps': trackSteps,
      'trackWater': trackWater,
      'trackSleep': trackSleep,
      'trackMood': trackMood,
      'trackWeight': trackWeight,
      'dailyStepsGoal': dailyStepsGoal,
      'dailyWaterGoal': dailyWaterGoal,
      'dailySleepGoal': dailySleepGoal,
    };
  }

  factory TrackingSettings.fromMap(Map<String, dynamic> map) {
    return TrackingSettings(
      trackSteps: map['trackSteps'] ?? true,
      trackWater: map['trackWater'] ?? true,
      trackSleep: map['trackSleep'] ?? true,
      trackMood: map['trackMood'] ?? true,
      trackWeight: map['trackWeight'] ?? false,
      dailyStepsGoal: map['dailyStepsGoal'] ?? 10000,
      dailyWaterGoal: (map['dailyWaterGoal'] ?? 2.0).toDouble(),
      dailySleepGoal: (map['dailySleepGoal'] ?? 8.0).toDouble(),
    );
  }
}
