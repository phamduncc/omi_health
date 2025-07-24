import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'storage_service.dart';
import 'goal_service.dart';
import 'goal_progress_service.dart';

/// Service chuyên dụng để quản lý việc xóa dữ liệu toàn bộ của app
class DataClearService {
  // Danh sách tất cả các key được sử dụng trong app
  static const List<String> _allDataKeys = [
    // StorageService keys
    'health_history',
    'latest_health_data',
    
    // GoalService keys
    'health_goals',
    'goal_progress',
    
    // Notification keys (nếu có)
    'notification_settings',
    'last_notification_time',
    
    // User preferences
    'user_preferences',
    'app_settings',
    'first_launch',
    'tutorial_completed',
    
    // Cache keys
    'cached_data',
    'temp_data',
  ];

  /// Xóa toàn bộ dữ liệu của app với xác thực bảo mật
  static Future<DataClearResult> clearAllData({
    bool includeSettings = true,
    bool includeTutorialProgress = false,
    String? securityToken,
  }) async {
    final result = DataClearResult();

    try {
      result.startTime = DateTime.now();

      // 0. Kiểm tra bảo mật (nếu có token)
      if (securityToken != null && !_validateSecurityToken(securityToken)) {
        result.success = false;
        result.message = 'Token bảo mật không hợp lệ';
        return result;
      }

      // 1. Tạo backup trước khi xóa (để có thể khôi phục nếu cần)
      await _createEmergencyBackup(result);

      // 2. Dừng tất cả các service đang chạy
      await _stopAllServices(result);

      // 3. Xóa dữ liệu từ các service
      await _clearServiceData(result);

      // 4. Xóa dữ liệu từ SharedPreferences
      await _clearSharedPreferences(result, includeSettings, includeTutorialProgress);

      // 5. Xóa các key động (goal progress với ID cụ thể)
      await _clearDynamicKeys(result);

      // 6. Verify việc xóa
      await _verifyDataCleared(result);

      // 7. Log hoạt động xóa dữ liệu
      await _logDataClearActivity(result);

      result.endTime = DateTime.now();
      result.success = true;
      result.message = 'Đã xóa thành công toàn bộ dữ liệu';

    } catch (e) {
      result.endTime = DateTime.now();
      result.success = false;
      result.error = e.toString();
      result.message = 'Lỗi khi xóa dữ liệu: ${e.toString()}';
    }

    return result;
  }

  /// Validate security token
  static bool _validateSecurityToken(String token) {
    // Có thể implement logic phức tạp hơn
    final expectedToken = _generateSecurityToken();
    return token == expectedToken;
  }

  /// Generate security token dựa trên thời gian và device
  static String _generateSecurityToken() {
    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    return 'CLEAR_$dateStr';
  }

  /// Tạo backup khẩn cấp trước khi xóa
  static Future<void> _createEmergencyBackup(DataClearResult result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final backupData = <String, dynamic>{};

      // Backup các key quan trọng
      final importantKeys = ['health_history', 'latest_health_data', 'health_goals'];
      for (final key in importantKeys) {
        final value = prefs.getString(key);
        if (value != null) {
          backupData[key] = value;
        }
      }

      if (backupData.isNotEmpty) {
        backupData['backup_timestamp'] = DateTime.now().millisecondsSinceEpoch;
        await prefs.setString('emergency_backup', jsonEncode(backupData));
        result.warnings.add('Đã tạo backup khẩn cấp');
      }
    } catch (e) {
      result.warnings.add('Không thể tạo backup: $e');
    }
  }

  /// Log hoạt động xóa dữ liệu
  static Future<void> _logDataClearActivity(DataClearResult result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logEntry = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'success': result.success,
        'clearedKeysCount': result.clearedKeys.length,
        'duration': result.duration?.inMilliseconds,
        'warnings': result.warnings.length,
      };

      // Lưu log (giữ tối đa 10 entries)
      final existingLogs = prefs.getString('data_clear_logs') ?? '[]';
      final List<dynamic> logs = jsonDecode(existingLogs);
      logs.add(logEntry);

      if (logs.length > 10) {
        logs.removeAt(0);
      }

      await prefs.setString('data_clear_logs', jsonEncode(logs));
    } catch (e) {
      // Ignore logging errors
    }
  }

  /// Xóa chỉ dữ liệu sức khỏe (giữ lại settings)
  static Future<DataClearResult> clearHealthDataOnly() async {
    final result = DataClearResult();
    
    try {
      result.startTime = DateTime.now();
      
      // Dừng GoalProgressService
      GoalProgressService().stopContinuousUpdate();
      result.stoppedServices.add('GoalProgressService');
      
      // Xóa dữ liệu sức khỏe
      await StorageService.clearHistory();
      result.clearedKeys.add('health_history');
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('latest_health_data');
      result.clearedKeys.add('latest_health_data');
      
      // Xóa mục tiêu
      await GoalService.clearAllGoals();
      result.clearedKeys.addAll(['health_goals', 'goal_progress']);
      
      // Xóa goal progress keys động
      await _clearDynamicKeys(result);
      
      result.endTime = DateTime.now();
      result.success = true;
      result.message = 'Đã xóa thành công dữ liệu sức khỏe';
      
    } catch (e) {
      result.endTime = DateTime.now();
      result.success = false;
      result.error = e.toString();
      result.message = 'Lỗi khi xóa dữ liệu sức khỏe: ${e.toString()}';
    }
    
    return result;
  }

  /// Dừng tất cả các service đang chạy
  static Future<void> _stopAllServices(DataClearResult result) async {
    try {
      // Dừng GoalProgressService
      GoalProgressService().stopContinuousUpdate();
      result.stoppedServices.add('GoalProgressService');
      
      // Có thể thêm các service khác nếu có
      // NotificationService().stop();
      // result.stoppedServices.add('NotificationService');
      
    } catch (e) {
      result.warnings.add('Không thể dừng một số service: $e');
    }
  }

  /// Xóa dữ liệu từ các service
  static Future<void> _clearServiceData(DataClearResult result) async {
    try {
      // Xóa dữ liệu StorageService
      await StorageService.clearHistory();
      result.clearedKeys.add('health_history');
      
      // Xóa dữ liệu GoalService
      await GoalService.clearAllGoals();
      result.clearedKeys.addAll(['health_goals', 'goal_progress']);
      
    } catch (e) {
      result.warnings.add('Lỗi khi xóa dữ liệu service: $e');
    }
  }

  /// Xóa dữ liệu từ SharedPreferences
  static Future<void> _clearSharedPreferences(
    DataClearResult result, 
    bool includeSettings, 
    bool includeTutorialProgress
  ) async {
    final prefs = await SharedPreferences.getInstance();
    
    for (final key in _allDataKeys) {
      // Bỏ qua settings nếu không muốn xóa
      if (!includeSettings && _isSettingsKey(key)) {
        continue;
      }
      
      // Bỏ qua tutorial progress nếu không muốn xóa
      if (!includeTutorialProgress && _isTutorialKey(key)) {
        continue;
      }
      
      if (prefs.containsKey(key)) {
        await prefs.remove(key);
        result.clearedKeys.add(key);
      }
    }
  }

  /// Xóa các key động (goal progress với ID cụ thể)
  static Future<void> _clearDynamicKeys(DataClearResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    
    // Tìm và xóa tất cả goal progress keys
    final goalProgressKeys = allKeys.where((key) => key.startsWith('goal_progress_')).toList();
    
    for (final key in goalProgressKeys) {
      await prefs.remove(key);
      result.clearedKeys.add(key);
    }
    
    // Tìm và xóa các key cache khác
    final cacheKeys = allKeys.where((key) => 
      key.startsWith('cache_') || 
      key.startsWith('temp_') ||
      key.contains('_temp')
    ).toList();
    
    for (final key in cacheKeys) {
      await prefs.remove(key);
      result.clearedKeys.add(key);
    }
  }

  /// Verify việc xóa dữ liệu
  static Future<void> _verifyDataCleared(DataClearResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final remainingKeys = <String>[];
    
    // Kiểm tra các key chính
    for (final key in ['health_history', 'latest_health_data', 'health_goals']) {
      if (prefs.containsKey(key)) {
        remainingKeys.add(key);
      }
    }
    
    if (remainingKeys.isNotEmpty) {
      result.warnings.add('Một số dữ liệu chưa được xóa hoàn toàn: ${remainingKeys.join(', ')}');
    }
    
    result.verificationPassed = remainingKeys.isEmpty;
  }

  /// Kiểm tra xem key có phải là settings không
  static bool _isSettingsKey(String key) {
    return key.contains('settings') || 
           key.contains('preferences') ||
           key == 'app_theme' ||
           key == 'language';
  }

  /// Kiểm tra xem key có phải là tutorial progress không
  static bool _isTutorialKey(String key) {
    return key.contains('tutorial') || 
           key.contains('first_launch') ||
           key.contains('onboarding');
  }

  /// Lấy thống kê dữ liệu hiện tại
  static Future<DataStats> getDataStats() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    
    final stats = DataStats();
    stats.totalKeys = allKeys.length;
    
    // Phân loại keys
    for (final key in allKeys) {
      if (key.contains('health') || key.contains('goal')) {
        stats.healthDataKeys++;
      } else if (_isSettingsKey(key)) {
        stats.settingsKeys++;
      } else if (key.startsWith('cache_') || key.startsWith('temp_')) {
        stats.cacheKeys++;
      } else {
        stats.otherKeys++;
      }
    }
    
    // Tính kích thước dữ liệu (ước tính)
    for (final key in allKeys) {
      final value = prefs.get(key);
      if (value is String) {
        stats.estimatedSizeBytes += value.length * 2; // UTF-16
      } else {
        stats.estimatedSizeBytes += 8; // Primitive types
      }
    }
    
    return stats;
  }

  /// Khôi phục dữ liệu từ emergency backup
  static Future<DataClearResult> restoreFromEmergencyBackup() async {
    final result = DataClearResult();
    result.startTime = DateTime.now();

    try {
      final prefs = await SharedPreferences.getInstance();
      final backupString = prefs.getString('emergency_backup');

      if (backupString == null) {
        result.success = false;
        result.message = 'Không tìm thấy backup khẩn cấp';
        return result;
      }

      final backupData = jsonDecode(backupString) as Map<String, dynamic>;

      // Restore dữ liệu
      for (final entry in backupData.entries) {
        if (entry.key != 'backup_timestamp' && entry.value is String) {
          await prefs.setString(entry.key, entry.value);
          result.clearedKeys.add('Restored: ${entry.key}');
        }
      }

      // Xóa backup sau khi restore
      await prefs.remove('emergency_backup');

      result.endTime = DateTime.now();
      result.success = true;
      result.message = 'Đã khôi phục thành công từ backup khẩn cấp';

    } catch (e) {
      result.endTime = DateTime.now();
      result.success = false;
      result.error = e.toString();
      result.message = 'Lỗi khi khôi phục: ${e.toString()}';
    }

    return result;
  }

  /// Kiểm tra xem có emergency backup không
  static Future<bool> hasEmergencyBackup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('emergency_backup');
  }

  /// Lấy thông tin emergency backup
  static Future<Map<String, dynamic>?> getEmergencyBackupInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final backupString = prefs.getString('emergency_backup');

    if (backupString == null) return null;

    try {
      final backupData = jsonDecode(backupString) as Map<String, dynamic>;
      final timestamp = backupData['backup_timestamp'] as int?;

      return {
        'timestamp': timestamp,
        'date': timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null,
        'keysCount': backupData.length - 1, // Trừ backup_timestamp
        'hasHealthHistory': backupData.containsKey('health_history'),
        'hasLatestData': backupData.containsKey('latest_health_data'),
        'hasGoals': backupData.containsKey('health_goals'),
      };
    } catch (e) {
      return null;
    }
  }

  /// Reset app về trạng thái ban đầu
  static Future<void> resetAppState() async {
    // Có thể thêm logic reset state của các provider/bloc
    // Ví dụ: reset theme, language, navigation stack, etc.
  }

  /// Lấy security token hiện tại
  static String getCurrentSecurityToken() {
    return _generateSecurityToken();
  }

  /// Lấy logs hoạt động xóa dữ liệu
  static Future<List<Map<String, dynamic>>> getDataClearLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final logsString = prefs.getString('data_clear_logs') ?? '[]';

    try {
      final List<dynamic> logs = jsonDecode(logsString);
      return logs.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }
}

/// Kết quả của việc xóa dữ liệu
class DataClearResult {
  DateTime? startTime;
  DateTime? endTime;
  bool success = false;
  String message = '';
  String? error;
  List<String> clearedKeys = [];
  List<String> stoppedServices = [];
  List<String> warnings = [];
  bool verificationPassed = false;
  
  Duration? get duration => 
    startTime != null && endTime != null 
      ? endTime!.difference(startTime!) 
      : null;
      
  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'message': message,
      'error': error,
      'clearedKeysCount': clearedKeys.length,
      'clearedKeys': clearedKeys,
      'stoppedServices': stoppedServices,
      'warnings': warnings,
      'verificationPassed': verificationPassed,
      'durationMs': duration?.inMilliseconds,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }
}

/// Thống kê dữ liệu
class DataStats {
  int totalKeys = 0;
  int healthDataKeys = 0;
  int settingsKeys = 0;
  int cacheKeys = 0;
  int otherKeys = 0;
  int estimatedSizeBytes = 0;
  
  String get estimatedSizeFormatted {
    if (estimatedSizeBytes < 1024) {
      return '${estimatedSizeBytes}B';
    } else if (estimatedSizeBytes < 1024 * 1024) {
      return '${(estimatedSizeBytes / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(estimatedSizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }
}
