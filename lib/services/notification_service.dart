import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

enum NotificationType {
  dailyReminder,
  goalProgress,
  healthTip,
  weeklyReport,
}

class NotificationSettings {
  final bool enabled;
  final TimeOfDay time;
  final List<int> weekdays; // 1-7, Monday to Sunday
  final NotificationType type;

  NotificationSettings({
    required this.enabled,
    required this.time,
    required this.weekdays,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'hour': time.hour,
      'minute': time.minute,
      'weekdays': weekdays,
      'type': type.index,
    };
  }

  factory NotificationSettings.fromMap(Map<String, dynamic> map) {
    return NotificationSettings(
      enabled: map['enabled'] ?? false,
      time: TimeOfDay(hour: map['hour'] ?? 9, minute: map['minute'] ?? 0),
      weekdays: List<int>.from(map['weekdays'] ?? [1, 2, 3, 4, 5, 6, 7]),
      type: NotificationType.values[map['type'] ?? 0],
    );
  }
}

class NotificationService {
  static const String _settingsKey = 'notification_settings';
  static const String _lastNotificationKey = 'last_notification_date';

  // Lưu cài đặt thông báo
  static Future<void> saveNotificationSettings(List<NotificationSettings> settings) async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = settings.map((s) => s.toMap()).toList();
    await prefs.setString(_settingsKey, jsonEncode(settingsJson));
  }

  // Lấy cài đặt thông báo
  static Future<List<NotificationSettings>> getNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsString = prefs.getString(_settingsKey);
    
    if (settingsString == null) {
      // Trả về cài đặt mặc định
      return _getDefaultSettings();
    }
    
    final List<dynamic> settingsJson = jsonDecode(settingsString);
    return settingsJson.map((json) => NotificationSettings.fromMap(json as Map<String, dynamic>)).toList();
  }

  // Cài đặt mặc định
  static List<NotificationSettings> _getDefaultSettings() {
    return [
      NotificationSettings(
        enabled: true,
        time: const TimeOfDay(hour: 9, minute: 0),
        weekdays: [1, 2, 3, 4, 5, 6, 7],
        type: NotificationType.dailyReminder,
      ),
      NotificationSettings(
        enabled: false,
        time: const TimeOfDay(hour: 18, minute: 0),
        weekdays: [1, 2, 3, 4, 5],
        type: NotificationType.healthTip,
      ),
      NotificationSettings(
        enabled: false,
        time: const TimeOfDay(hour: 10, minute: 0),
        weekdays: [7], // Sunday
        type: NotificationType.weeklyReport,
      ),
    ];
  }

  // Kiểm tra xem có nên hiển thị thông báo không
  static Future<bool> shouldShowNotification(NotificationType type) async {
    final settings = await getNotificationSettings();
    final setting = settings.firstWhere(
      (s) => s.type == type,
      orElse: () => NotificationSettings(
        enabled: false,
        time: const TimeOfDay(hour: 9, minute: 0),
        weekdays: [],
        type: type,
      ),
    );

    if (!setting.enabled) return false;

    final now = DateTime.now();
    final currentWeekday = now.weekday;
    
    if (!setting.weekdays.contains(currentWeekday)) return false;

    // Kiểm tra thời gian
    final currentTime = TimeOfDay.now();
    final notificationTime = setting.time;
    
    // Chỉ hiển thị trong khoảng 1 giờ sau thời gian đã đặt
    final currentMinutes = currentTime.hour * 60 + currentTime.minute;
    final notificationMinutes = notificationTime.hour * 60 + notificationTime.minute;
    
    if (currentMinutes < notificationMinutes || currentMinutes > notificationMinutes + 60) {
      return false;
    }

    // Kiểm tra xem đã hiển thị hôm nay chưa
    final prefs = await SharedPreferences.getInstance();
    final lastNotificationString = prefs.getString('${_lastNotificationKey}_${type.index}');
    
    if (lastNotificationString != null) {
      final lastNotification = DateTime.parse(lastNotificationString);
      if (lastNotification.day == now.day && 
          lastNotification.month == now.month && 
          lastNotification.year == now.year) {
        return false;
      }
    }

    return true;
  }

  // Đánh dấu đã hiển thị thông báo
  static Future<void> markNotificationShown(NotificationType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_lastNotificationKey}_${type.index}', DateTime.now().toIso8601String());
  }

  // Lấy nội dung thông báo
  static String getNotificationContent(NotificationType type) {
    switch (type) {
      case NotificationType.dailyReminder:
        return 'Đừng quên theo dõi sức khỏe hôm nay! Hãy cập nhật cân nặng và BMI của bạn.';
      case NotificationType.goalProgress:
        return 'Kiểm tra tiến độ mục tiêu sức khỏe của bạn và duy trì động lực!';
      case NotificationType.healthTip:
        return 'Khám phá mẹo sức khỏe mới để cải thiện lối sống của bạn!';
      case NotificationType.weeklyReport:
        return 'Xem báo cáo sức khỏe tuần này và lập kế hoạch cho tuần tới!';
    }
  }

  // Lấy tiêu đề thông báo
  static String getNotificationTitle(NotificationType type) {
    switch (type) {
      case NotificationType.dailyReminder:
        return 'Nhắc nhở hàng ngày';
      case NotificationType.goalProgress:
        return 'Tiến độ mục tiêu';
      case NotificationType.healthTip:
        return 'Mẹo sức khỏe';
      case NotificationType.weeklyReport:
        return 'Báo cáo tuần';
    }
  }

  // Lấy icon thông báo
  static IconData getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.dailyReminder:
        return Icons.notifications_active;
      case NotificationType.goalProgress:
        return Icons.flag;
      case NotificationType.healthTip:
        return Icons.lightbulb;
      case NotificationType.weeklyReport:
        return Icons.assessment;
    }
  }

  // Lấy màu thông báo
  static Color getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.dailyReminder:
        return const Color(0xFF3498DB);
      case NotificationType.goalProgress:
        return const Color(0xFF2ECC71);
      case NotificationType.healthTip:
        return const Color(0xFFF39C12);
      case NotificationType.weeklyReport:
        return const Color(0xFF9B59B6);
    }
  }
}
