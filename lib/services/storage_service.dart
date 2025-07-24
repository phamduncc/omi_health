import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/health_data.dart';
import 'goal_service.dart';

class StorageService {
  static const String _historyKey = 'health_history';
  static const String _latestDataKey = 'latest_health_data';

  // Lưu dữ liệu mới nhất
  static Future<void> saveLatestData(HealthData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_latestDataKey, jsonEncode(data.toMap()));
  }

  // Lấy dữ liệu mới nhất
  static Future<HealthData?> getLatestData() async {
    final prefs = await SharedPreferences.getInstance();
    final dataString = prefs.getString(_latestDataKey);
    if (dataString != null) {
      final dataMap = jsonDecode(dataString) as Map<String, dynamic>;
      return HealthData.fromMap(dataMap);
    }
    return null;
  }

  // Lưu vào lịch sử và trả về thông tin cập nhật mục tiêu
  static Future<List<dynamic>> saveToHistory(HealthData data) async {
    final prefs = await SharedPreferences.getInstance();
    final historyString = prefs.getString(_historyKey) ?? '[]';
    final List<dynamic> history = jsonDecode(historyString);

    history.add(data.toMap());

    // Giữ tối đa 50 bản ghi
    if (history.length > 50) {
      history.removeAt(0);
    }

    await prefs.setString(_historyKey, jsonEncode(history));

    // Cập nhật tiến độ mục tiêu khi có dữ liệu mới
    try {
      // Đảm bảo current values đã được cập nhật trước khi tính toán tiến độ
      await GoalService.updateCurrentValues(data);
      final goalUpdates = await GoalService.updateGoalProgress();
      return goalUpdates;
    } catch (e) {
      // Ignore errors to avoid breaking the main flow
      // Log error silently
      return [];
    }
  }

  // Lấy lịch sử
  static Future<List<HealthData>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyString = prefs.getString(_historyKey) ?? '[]';
    final List<dynamic> history = jsonDecode(historyString);
    
    return history.map((item) => HealthData.fromMap(item as Map<String, dynamic>)).toList();
  }

  // Xóa lịch sử
  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  // Xóa dữ liệu mới nhất
  static Future<void> clearLatestData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_latestDataKey);
  }

  // Xóa toàn bộ dữ liệu của StorageService
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
    await prefs.remove(_latestDataKey);
  }

  // Lấy thống kê dữ liệu
  static Future<Map<String, dynamic>> getDataStats() async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();
    final latestData = await getLatestData();

    // Tính kích thước ước tính
    final historyString = prefs.getString(_historyKey) ?? '[]';
    final latestDataString = prefs.getString(_latestDataKey) ?? '';

    return {
      'historyCount': history.length,
      'hasLatestData': latestData != null,
      'historySizeBytes': historyString.length * 2, // UTF-16
      'latestDataSizeBytes': latestDataString.length * 2,
      'totalSizeBytes': (historyString.length + latestDataString.length) * 2,
      'oldestRecord': history.isNotEmpty ? history.last.timestamp.millisecondsSinceEpoch : null,
      'newestRecord': history.isNotEmpty ? history.first.timestamp.millisecondsSinceEpoch : null,
    };
  }

  // Kiểm tra tính toàn vẹn dữ liệu
  static Future<bool> verifyDataIntegrity() async {
    try {
      final history = await getHistory();
      final latestData = await getLatestData();

      // Kiểm tra dữ liệu có hợp lệ không
      for (final data in history) {
        if (data.weight <= 0 || data.height <= 0 || data.age <= 0) {
          return false;
        }
      }

      if (latestData != null) {
        if (latestData.weight <= 0 || latestData.height <= 0 || latestData.age <= 0) {
          return false;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}
