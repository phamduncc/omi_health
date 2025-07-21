import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/health_data.dart';

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

  // Lưu vào lịch sử
  static Future<void> saveToHistory(HealthData data) async {
    final prefs = await SharedPreferences.getInstance();
    final historyString = prefs.getString(_historyKey) ?? '[]';
    final List<dynamic> history = jsonDecode(historyString);
    
    history.add(data.toMap());
    
    // Giữ tối đa 50 bản ghi
    if (history.length > 50) {
      history.removeAt(0);
    }
    
    await prefs.setString(_historyKey, jsonEncode(history));
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
}
