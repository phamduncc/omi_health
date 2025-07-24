import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service quản lý nhắc nhở thông minh
class ReminderService extends ChangeNotifier {
  static final ReminderService _instance = ReminderService._internal();
  factory ReminderService() => _instance;
  ReminderService._internal();

  static const String _remindersKey = 'app_reminders';
  static const String _reminderSettingsKey = 'reminder_settings';

  List<AppReminder> _reminders = [];
  ReminderSettings _settings = ReminderSettings();
  Timer? _checkTimer;
  bool _isInitialized = false;

  List<AppReminder> get reminders => _reminders;
  ReminderSettings get settings => _settings;
  bool get isInitialized => _isInitialized;

  /// Khởi tạo service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await _loadSettings();
    await _loadReminders();
    _startPeriodicCheck();
    _isInitialized = true;
    notifyListeners();
  }

  /// Tải cài đặt nhắc nhở
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsString = prefs.getString(_reminderSettingsKey);
    
    if (settingsString != null) {
      try {
        final settingsMap = jsonDecode(settingsString) as Map<String, dynamic>;
        _settings = ReminderSettings.fromMap(settingsMap);
      } catch (e) {
        _settings = ReminderSettings(); // Default settings
      }
    }
  }

  /// Lưu cài đặt nhắc nhở
  Future<void> saveSettings(ReminderSettings settings) async {
    _settings = settings;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_reminderSettingsKey, jsonEncode(settings.toMap()));
    notifyListeners();
  }

  /// Tải danh sách nhắc nhở
  Future<void> _loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final remindersString = prefs.getString(_remindersKey) ?? '[]';
    
    try {
      final List<dynamic> remindersList = jsonDecode(remindersString);
      _reminders = remindersList
          .map((json) => AppReminder.fromMap(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _reminders = [];
    }
  }

  /// Lưu danh sách nhắc nhở
  Future<void> _saveReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final remindersJson = _reminders.map((r) => r.toMap()).toList();
    await prefs.setString(_remindersKey, jsonEncode(remindersJson));
  }

  /// Thêm nhắc nhở mới
  Future<void> addReminder(AppReminder reminder) async {
    _reminders.add(reminder);
    await _saveReminders();
    notifyListeners();
  }

  /// Cập nhật nhắc nhở
  Future<void> updateReminder(AppReminder reminder) async {
    final index = _reminders.indexWhere((r) => r.id == reminder.id);
    if (index != -1) {
      _reminders[index] = reminder;
      await _saveReminders();
      notifyListeners();
    }
  }

  /// Xóa nhắc nhở
  Future<void> removeReminder(String id) async {
    _reminders.removeWhere((r) => r.id == id);
    await _saveReminders();
    notifyListeners();
  }

  /// Bật/tắt nhắc nhở
  Future<void> toggleReminder(String id, bool enabled) async {
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index != -1) {
      _reminders[index] = _reminders[index].copyWith(isEnabled: enabled);
      await _saveReminders();
      notifyListeners();
    }
  }

  /// Đánh dấu nhắc nhở đã hoàn thành
  Future<void> markReminderCompleted(String id) async {
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index != -1) {
      final reminder = _reminders[index];
      final now = DateTime.now();
      
      // Cập nhật lần hoàn thành cuối
      _reminders[index] = reminder.copyWith(
        lastCompleted: now,
        completionCount: reminder.completionCount + 1,
      );
      
      // Tính toán lần nhắc nhở tiếp theo
      _calculateNextReminder(_reminders[index]);
      
      await _saveReminders();
      notifyListeners();
    }
  }

  /// Tính toán lần nhắc nhở tiếp theo
  void _calculateNextReminder(AppReminder reminder) {
    final now = DateTime.now();
    DateTime nextTime;
    
    switch (reminder.frequency) {
      case ReminderFrequency.hourly:
        nextTime = now.add(const Duration(hours: 1));
        break;
      case ReminderFrequency.daily:
        nextTime = DateTime(now.year, now.month, now.day + 1, 
                           reminder.scheduledTime.hour, reminder.scheduledTime.minute);
        break;
      case ReminderFrequency.weekly:
        nextTime = now.add(const Duration(days: 7));
        break;
      case ReminderFrequency.custom:
        nextTime = now.add(Duration(minutes: reminder.customIntervalMinutes));
        break;
    }
    
    final index = _reminders.indexWhere((r) => r.id == reminder.id);
    if (index != -1) {
      _reminders[index] = _reminders[index].copyWith(nextScheduled: nextTime);
    }
  }

  /// Bắt đầu kiểm tra định kỳ
  void _startPeriodicCheck() {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkDueReminders();
    });
  }

  /// Kiểm tra nhắc nhở đến hạn
  void _checkDueReminders() {
    if (!_settings.enableReminders) return;
    
    final now = DateTime.now();
    final dueReminders = _reminders.where((reminder) {
      return reminder.isEnabled && 
             reminder.nextScheduled != null &&
             reminder.nextScheduled!.isBefore(now);
    }).toList();
    
    for (final reminder in dueReminders) {
      _showReminderNotification(reminder);
      _calculateNextReminder(reminder);
    }
    
    if (dueReminders.isNotEmpty) {
      _saveReminders();
      notifyListeners();
    }
  }

  /// Hiển thị thông báo nhắc nhở
  void _showReminderNotification(AppReminder reminder) {
    // Trong thực tế, có thể sử dụng local notifications
    // Hiện tại chỉ log để demo
    debugPrint('Reminder: ${reminder.title} - ${reminder.message}');
  }

  /// Tạo nhắc nhở mặc định
  Future<void> createDefaultReminders() async {
    final defaultReminders = [
      AppReminder(
        id: 'water_reminder',
        type: ReminderType.water,
        title: 'Uống nước',
        message: 'Đã đến giờ uống nước! Hãy bổ sung 200ml nước.',
        frequency: ReminderFrequency.hourly,
        scheduledTime: DateTime.now(),
        isEnabled: true,
      ),
      AppReminder(
        id: 'weight_reminder',
        type: ReminderType.weight,
        title: 'Cân nặng',
        message: 'Hãy cân nặng và cập nhật chỉ số của bạn.',
        frequency: ReminderFrequency.daily,
        scheduledTime: DateTime(2024, 1, 1, 7, 0), // 7:00 AM
        isEnabled: false,
      ),
      AppReminder(
        id: 'exercise_reminder',
        type: ReminderType.exercise,
        title: 'Tập thể dục',
        message: 'Đã đến giờ tập thể dục! Hãy vận động 30 phút.',
        frequency: ReminderFrequency.daily,
        scheduledTime: DateTime(2024, 1, 1, 18, 0), // 6:00 PM
        isEnabled: false,
      ),
    ];
    
    for (final reminder in defaultReminders) {
      if (!_reminders.any((r) => r.id == reminder.id)) {
        await addReminder(reminder);
      }
    }
  }

  /// Lấy thống kê nhắc nhở
  Map<String, dynamic> getReminderStats() {
    final totalReminders = _reminders.length;
    final enabledReminders = _reminders.where((r) => r.isEnabled).length;
    final completedToday = _reminders.where((r) {
      final today = DateTime.now();
      final lastCompleted = r.lastCompleted;
      return lastCompleted != null &&
             lastCompleted.year == today.year &&
             lastCompleted.month == today.month &&
             lastCompleted.day == today.day;
    }).length;
    
    return {
      'total': totalReminders,
      'enabled': enabledReminders,
      'completedToday': completedToday,
      'completionRate': enabledReminders > 0 ? (completedToday / enabledReminders * 100) : 0.0,
    };
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }
}

/// Enum loại nhắc nhở
enum ReminderType {
  water,
  weight,
  exercise,
  measurement,
  medication,
  custom,
}

/// Enum tần suất nhắc nhở
enum ReminderFrequency {
  hourly,
  daily,
  weekly,
  custom,
}

/// Model nhắc nhở
class AppReminder {
  final String id;
  final ReminderType type;
  final String title;
  final String message;
  final ReminderFrequency frequency;
  final DateTime scheduledTime;
  final bool isEnabled;
  final DateTime? nextScheduled;
  final DateTime? lastCompleted;
  final int completionCount;
  final int customIntervalMinutes;

  AppReminder({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.frequency,
    required this.scheduledTime,
    this.isEnabled = true,
    this.nextScheduled,
    this.lastCompleted,
    this.completionCount = 0,
    this.customIntervalMinutes = 60,
  });

  AppReminder copyWith({
    String? id,
    ReminderType? type,
    String? title,
    String? message,
    ReminderFrequency? frequency,
    DateTime? scheduledTime,
    bool? isEnabled,
    DateTime? nextScheduled,
    DateTime? lastCompleted,
    int? completionCount,
    int? customIntervalMinutes,
  }) {
    return AppReminder(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      frequency: frequency ?? this.frequency,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      isEnabled: isEnabled ?? this.isEnabled,
      nextScheduled: nextScheduled ?? this.nextScheduled,
      lastCompleted: lastCompleted ?? this.lastCompleted,
      completionCount: completionCount ?? this.completionCount,
      customIntervalMinutes: customIntervalMinutes ?? this.customIntervalMinutes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.index,
      'title': title,
      'message': message,
      'frequency': frequency.index,
      'scheduledTime': scheduledTime.millisecondsSinceEpoch,
      'isEnabled': isEnabled,
      'nextScheduled': nextScheduled?.millisecondsSinceEpoch,
      'lastCompleted': lastCompleted?.millisecondsSinceEpoch,
      'completionCount': completionCount,
      'customIntervalMinutes': customIntervalMinutes,
    };
  }

  factory AppReminder.fromMap(Map<String, dynamic> map) {
    return AppReminder(
      id: map['id'] ?? '',
      type: ReminderType.values[map['type'] ?? 0],
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      frequency: ReminderFrequency.values[map['frequency'] ?? 0],
      scheduledTime: DateTime.fromMillisecondsSinceEpoch(map['scheduledTime'] ?? 0),
      isEnabled: map['isEnabled'] ?? true,
      nextScheduled: map['nextScheduled'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['nextScheduled'])
          : null,
      lastCompleted: map['lastCompleted'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastCompleted'])
          : null,
      completionCount: map['completionCount'] ?? 0,
      customIntervalMinutes: map['customIntervalMinutes'] ?? 60,
    );
  }
}

/// Cài đặt nhắc nhở
class ReminderSettings {
  final bool enableReminders;
  final bool enableSound;
  final bool enableVibration;
  final int quietHoursStart; // 22 = 10 PM
  final int quietHoursEnd;   // 7 = 7 AM

  ReminderSettings({
    this.enableReminders = true,
    this.enableSound = true,
    this.enableVibration = true,
    this.quietHoursStart = 22,
    this.quietHoursEnd = 7,
  });

  ReminderSettings copyWith({
    bool? enableReminders,
    bool? enableSound,
    bool? enableVibration,
    int? quietHoursStart,
    int? quietHoursEnd,
  }) {
    return ReminderSettings(
      enableReminders: enableReminders ?? this.enableReminders,
      enableSound: enableSound ?? this.enableSound,
      enableVibration: enableVibration ?? this.enableVibration,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enableReminders': enableReminders,
      'enableSound': enableSound,
      'enableVibration': enableVibration,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
    };
  }

  factory ReminderSettings.fromMap(Map<String, dynamic> map) {
    return ReminderSettings(
      enableReminders: map['enableReminders'] ?? true,
      enableSound: map['enableSound'] ?? true,
      enableVibration: map['enableVibration'] ?? true,
      quietHoursStart: map['quietHoursStart'] ?? 22,
      quietHoursEnd: map['quietHoursEnd'] ?? 7,
    );
  }
}
