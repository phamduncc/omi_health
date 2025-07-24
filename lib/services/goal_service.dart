import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/health_goal.dart';
import '../models/health_data.dart';
import 'storage_service.dart';

class GoalService {
  static const String _goalsKey = 'health_goals';
  static const String _goalProgressKey = 'goal_progress';

  // Lưu danh sách mục tiêu
  static Future<void> saveGoals(List<HealthGoal> goals) async {
    final prefs = await SharedPreferences.getInstance();
    final goalsJson = goals.map((goal) => goal.toMap()).toList();
    await prefs.setString(_goalsKey, jsonEncode(goalsJson));
  }

  // Lấy danh sách mục tiêu
  static Future<List<HealthGoal>> getGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final goalsString = prefs.getString(_goalsKey) ?? '[]';
    final List<dynamic> goalsJson = jsonDecode(goalsString);
    
    return goalsJson.map((json) => HealthGoal.fromMap(json as Map<String, dynamic>)).toList();
  }

  // Thêm mục tiêu mới
  static Future<void> addGoal(HealthGoal goal) async {
    final goals = await getGoals();
    goals.add(goal);
    await saveGoals(goals);
  }

  // Cập nhật mục tiêu
  static Future<void> updateGoal(HealthGoal updatedGoal) async {
    final goals = await getGoals();
    final index = goals.indexWhere((goal) => goal.id == updatedGoal.id);
    if (index != -1) {
      goals[index] = updatedGoal;
      await saveGoals(goals);
    }
  }

  // Xóa mục tiêu
  static Future<void> deleteGoal(String goalId) async {
    final goals = await getGoals();
    goals.removeWhere((goal) => goal.id == goalId);
    await saveGoals(goals);
  }

  // Lấy mục tiêu theo ID
  static Future<HealthGoal?> getGoalById(String goalId) async {
    final goals = await getGoals();
    try {
      return goals.firstWhere((goal) => goal.id == goalId);
    } catch (e) {
      return null;
    }
  }

  // Cập nhật giá trị hiện tại cho tất cả mục tiêu với logic cải thiện
  static Future<Map<String, dynamic>> updateCurrentValues(HealthData newData) async {
    final goals = await getGoals();
    bool hasUpdates = false;
    int updatedCount = 0;
    List<String> updatedGoalTitles = [];
    List<HealthGoal> completedGoals = [];

    for (int i = 0; i < goals.length; i++) {
      final goal = goals[i];
      if (!goal.isActive) continue;

      double newValue = _getValueForGoalType(goal.type, newData);
      double oldValue = goal.currentValue;

      // Kiểm tra thay đổi có ý nghĩa dựa trên loại mục tiêu
      bool shouldUpdate = _shouldUpdateGoalValue(goal, oldValue, newValue);

      if (shouldUpdate) {
        // Tính toán tiến độ trước và sau khi cập nhật
        double oldProgress = goal.progressPercentage;

        HealthGoal updatedGoal = goal.copyWith(currentValue: newValue);
        double newProgress = updatedGoal.progressPercentage;

        // Kiểm tra xem mục tiêu có hoàn thành không
        bool isCompleted = _checkGoalCompletion(updatedGoal);
        if (isCompleted && goal.completedDate == null) {
          updatedGoal = updatedGoal.copyWith(
            isActive: false,
            completedDate: DateTime.now(),
          );
          completedGoals.add(updatedGoal);
        }

        // Lưu lịch sử tiến độ nếu có thay đổi đáng kể
        if ((newProgress - oldProgress).abs() > 0.5) {
          await saveGoalProgress(goal.id, newProgress, DateTime.now());
        }

        goals[i] = updatedGoal;
        hasUpdates = true;
        updatedCount++;
        updatedGoalTitles.add(goal.title);
      }
    }

    // Lưu tất cả thay đổi một lần
    if (hasUpdates) {
      await saveGoals(goals);
    }

    return {
      'hasUpdates': hasUpdates,
      'updatedCount': updatedCount,
      'updatedGoalTitles': updatedGoalTitles,
      'completedGoals': completedGoals,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  // Lấy giá trị tương ứng với loại mục tiêu
  static double _getValueForGoalType(GoalType type, HealthData data) {
    switch (type) {
      case GoalType.weightLoss:
      case GoalType.weightGain:
      case GoalType.maintain:
        return data.weight;
      case GoalType.bmiTarget:
        return data.bmi;
    }
  }

  // Kiểm tra xem có nên cập nhật giá trị mục tiêu không
  static bool _shouldUpdateGoalValue(HealthGoal goal, double oldValue, double newValue) {
    double threshold;

    switch (goal.type) {
      case GoalType.weightLoss:
      case GoalType.weightGain:
      case GoalType.maintain:
        threshold = 0.1; // 0.1kg
        break;
      case GoalType.bmiTarget:
        threshold = 0.01; // 0.01 BMI
        break;
    }

    return (oldValue - newValue).abs() >= threshold;
  }

  // Kiểm tra hoàn thành mục tiêu với logic cải thiện
  static bool _checkGoalCompletion(HealthGoal goal) {
    switch (goal.type) {
      case GoalType.weightLoss:
        return goal.currentValue <= goal.targetValue;
      case GoalType.weightGain:
        return goal.currentValue >= goal.targetValue;
      case GoalType.bmiTarget:
        return (goal.currentValue - goal.targetValue).abs() <= 0.1;
      case GoalType.maintain:
        // Duy trì trong khoảng ±1kg
        return (goal.currentValue - goal.targetValue).abs() <= 1.0;
    }
  }

  // Đồng bộ tất cả mục tiêu với dữ liệu sức khỏe mới nhất
  static Future<void> syncAllGoalsWithLatestData() async {
    final latestData = await StorageService.getLatestData();
    if (latestData != null) {
      await updateCurrentValues(latestData);
      await forceCheckGoalCompletion();
    }
  }

  // Force check tất cả mục tiêu và đánh dấu hoàn thành nếu cần
  static Future<List<HealthGoal>> forceCheckGoalCompletion() async {
    final goals = await getGoals();
    final completedGoals = <HealthGoal>[];
    bool hasUpdates = false;

    for (int i = 0; i < goals.length; i++) {
      final goal = goals[i];
      if (!goal.isActive) continue;

      // Kiểm tra nếu mục tiêu thực sự đã hoàn thành
      final actuallyCompleted = _isGoalActuallyCompleted(goal);
      final progressCompleted = goal.progressPercentage >= 100;

      print('=== FORCE CHECK ===');
      print('Goal: ${goal.title}');
      print('Progress: ${goal.progressPercentage}%');
      print('Actually Completed: $actuallyCompleted');
      print('Progress Completed: $progressCompleted');
      print('==================');

      if (actuallyCompleted || progressCompleted) {
        final completedGoal = goal.copyWith(
          isActive: false,
          completedDate: DateTime.now(),
        );
        goals[i] = completedGoal;
        completedGoals.add(completedGoal);
        hasUpdates = true;

        print('MARKED AS COMPLETED: ${goal.title}');
      }
    }

    if (hasUpdates) {
      await saveGoals(goals);
    }

    return completedGoals;
  }

  // Tạo mục tiêu test dễ hoàn thành (chỉ dùng để test)
  static Future<void> createTestGoal(HealthData currentData) async {
    // Tạo goal weight loss đơn giản: từ 80kg xuống 70kg, hiện tại 69kg (đã hoàn thành)
    final testGoal = HealthGoal(
      id: 'test_${DateTime.now().millisecondsSinceEpoch}',
      type: GoalType.weightLoss,
      startValue: 80.0,      // Bắt đầu từ 80kg
      targetValue: 70.0,     // Mục tiêu 70kg
      currentValue: 69.0,    // Hiện tại 69kg (đã hoàn thành)
      startDate: DateTime.now().subtract(const Duration(days: 1)),
      targetDate: DateTime.now().add(const Duration(days: 30)),
      title: 'Test Goal - Weight Loss',
      description: 'Test: 80kg -> 70kg, hiện tại 69kg',
    );

    print('Creating test goal:');
    print('Start: ${testGoal.startValue}kg');
    print('Target: ${testGoal.targetValue}kg');
    print('Current: ${testGoal.currentValue}kg');
    print('Expected: Should be completed (69 <= 70)');
    print('Progress: ${testGoal.progressPercentage}%');

    await addGoal(testGoal);
  }

  // Debug method để test logic hoàn thành
  static Future<void> debugGoalCompletion() async {
    final goals = await getGoals();
    print('=== DEBUG ALL GOALS ===');
    for (final goal in goals) {
      print('Goal: ${goal.title}');
      print('Type: ${goal.type}');
      print('Start: ${goal.startValue}');
      print('Current: ${goal.currentValue}');
      print('Target: ${goal.targetValue}');
      print('Progress: ${goal.progressPercentage}%');
      print('Is Active: ${goal.isActive}');
      print('Actually Completed: ${_isGoalActuallyCompleted(goal)}');
      print('---');
    }
    print('======================');
  }

  // Cập nhật tiến độ mục tiêu dựa trên dữ liệu sức khỏe mới
  static Future<List<GoalProgressUpdate>> updateGoalProgress() async {
    final goals = await getGoals();
    final latestData = await StorageService.getLatestData();

    if (latestData == null) return [];

    List<GoalProgressUpdate> updates = [];
    bool hasUpdates = false;

    for (int i = 0; i < goals.length; i++) {
      final goal = goals[i];
      if (!goal.isActive) continue;

      HealthGoal updatedGoal = goal;
      double oldProgress = goal.progressPercentage;
      double oldValue = goal.currentValue;

      // Đảm bảo giá trị hiện tại được cập nhật (double-check)
      switch (goal.type) {
        case GoalType.weightLoss:
        case GoalType.weightGain:
        case GoalType.maintain:
          if (goal.currentValue != latestData.weight) {
            updatedGoal = goal.copyWith(currentValue: latestData.weight);
          }
          break;
        case GoalType.bmiTarget:
          if (goal.currentValue != latestData.bmi) {
            updatedGoal = goal.copyWith(currentValue: latestData.bmi);
          }
          break;
      }

      // Xử lý nếu có thay đổi giá trị hoặc cần kiểm tra tiến độ
      if (updatedGoal.currentValue != oldValue || updatedGoal != goal) {
        double newProgress = updatedGoal.progressPercentage;
        bool isCompleted = false;
        bool isNewMilestone = false;

        // Debug logging
        print('=== GOAL DEBUG ===');
        print('Goal: ${goal.title}');
        print('Type: ${goal.type}');
        print('Start: ${goal.startValue}');
        print('Current: ${updatedGoal.currentValue}');
        print('Target: ${goal.targetValue}');
        print('Progress: $oldProgress% -> $newProgress%');
        print('Is Active: ${goal.isActive}');
        print('Actually Completed: ${_isGoalActuallyCompleted(updatedGoal)}');
        print('==================');

        // Lưu lịch sử tiến độ nếu có thay đổi đáng kể
        if ((newProgress - oldProgress).abs() > 0.1) {
          await saveGoalProgress(goal.id, newProgress, DateTime.now());
        }

        // Kiểm tra hoàn thành mục tiêu
        if (newProgress >= 100 && oldProgress < 100) {
          updatedGoal = updatedGoal.copyWith(
            isActive: false,
            completedDate: DateTime.now(),
          );
          isCompleted = true;
        }

        // Kiểm tra hoàn thành dựa trên giá trị thực tế (double-check)
        if (!isCompleted && _isGoalActuallyCompleted(updatedGoal)) {
          updatedGoal = updatedGoal.copyWith(
            isActive: false,
            completedDate: DateTime.now(),
          );
          isCompleted = true;
        }

        // Kiểm tra milestone (mỗi 25%)
        final oldMilestone = (oldProgress / 25).floor();
        final newMilestone = (newProgress / 25).floor();
        if (newMilestone > oldMilestone && newProgress < 100) {
          isNewMilestone = true;
        }

        // Xử lý các trường hợp edge case
        updatedGoal = _handleEdgeCases(updatedGoal, newProgress, isCompleted);

        goals[i] = updatedGoal;
        hasUpdates = true;

        // Chỉ tạo update nếu có thay đổi đáng kể trong tiến độ
        if ((newProgress - oldProgress).abs() > 0.1 || isCompleted || isNewMilestone) {
          updates.add(GoalProgressUpdate(
            goal: updatedGoal,
            oldProgress: oldProgress,
            newProgress: newProgress,
            isCompleted: isCompleted,
            progressChange: newProgress - oldProgress,
            isNewMilestone: isNewMilestone,
          ));
        }
      }
    }

    if (hasUpdates) {
      await saveGoals(goals);

      // Tạo mục tiêu mới tự động nếu có mục tiêu hoàn thành
      final completedGoals = updates.where((u) => u.isCompleted).toList();
      if (completedGoals.isNotEmpty) {
        await _suggestNewGoals(latestData, completedGoals);
      }
    }

    return updates;
  }

  // Kiểm tra xem mục tiêu có thực sự hoàn thành không dựa trên giá trị thực tế
  static bool _isGoalActuallyCompleted(HealthGoal goal) {
    switch (goal.type) {
      case GoalType.weightLoss:
        return goal.currentValue <= goal.targetValue;
      case GoalType.weightGain:
        return goal.currentValue >= goal.targetValue;
      case GoalType.maintain:
        final deviation = (goal.currentValue - goal.targetValue).abs();
        return deviation <= 2.0; // ±2kg tolerance
      case GoalType.bmiTarget:
        return (goal.currentValue - goal.targetValue).abs() <= 0.1;
    }
  }

  // Public method để debug
  static bool isGoalActuallyCompleted(HealthGoal goal) {
    return _isGoalActuallyCompleted(goal);
  }

  // Lấy mục tiêu đang hoạt động
  static Future<List<HealthGoal>> getActiveGoals() async {
    final goals = await getGoals();
    return goals.where((goal) => goal.isActive).toList();
  }

  // Lấy mục tiêu đã hoàn thành
  static Future<List<HealthGoal>> getCompletedGoals() async {
    final goals = await getGoals();
    return goals.where((goal) => goal.progressPercentage >= 100).toList();
  }

  // Đánh dấu mục tiêu hoàn thành
  static Future<void> markGoalCompleted(String goalId) async {
    final goal = await getGoalById(goalId);
    if (goal != null) {
      final completedGoal = goal.copyWith(isActive: false);
      await updateGoal(completedGoal);
    }
  }

  // Tạo mục tiêu mẫu dựa trên dữ liệu hiện tại
  static Future<List<HealthGoal>> generateSampleGoals(HealthData currentData) async {
    final goals = <HealthGoal>[];
    final now = DateTime.now();

    // Mục tiêu giảm cân (nếu BMI > 25)
    if (currentData.bmi > 25) {
      final targetWeight = currentData.weight - (currentData.bmi > 30 ? 10 : 5);
      goals.add(HealthGoal(
        id: 'sample_weight_loss_${now.millisecondsSinceEpoch}',
        type: GoalType.weightLoss,
        targetValue: targetWeight,
        currentValue: currentData.weight,
        startValue: currentData.weight,
        startDate: now,
        targetDate: now.add(const Duration(days: 90)),
        title: 'Giảm ${(currentData.weight - targetWeight).toStringAsFixed(1)}kg',
        description: 'Giảm cân an toàn để đạt BMI lý tưởng',
      ));
    }

    // Mục tiêu tăng cân (nếu BMI < 18.5)
    if (currentData.bmi < 18.5) {
      final targetWeight = currentData.weight + 5;
      goals.add(HealthGoal(
        id: 'sample_weight_gain_${now.millisecondsSinceEpoch}',
        type: GoalType.weightGain,
        targetValue: targetWeight,
        currentValue: currentData.weight,
        startValue: currentData.weight,
        startDate: now,
        targetDate: now.add(const Duration(days: 60)),
        title: 'Tăng ${(targetWeight - currentData.weight).toStringAsFixed(1)}kg',
        description: 'Tăng cân lành mạnh để đạt BMI bình thường',
      ));
    }

    // Mục tiêu BMI lý tưởng
    if (currentData.bmi < 22 || currentData.bmi > 23) {
      goals.add(HealthGoal(
        id: 'sample_bmi_target_${now.millisecondsSinceEpoch}',
        type: GoalType.bmiTarget,
        targetValue: 22.0,
        currentValue: currentData.bmi,
        startValue: currentData.bmi,
        startDate: now,
        targetDate: now.add(const Duration(days: 120)),
        title: 'BMI lý tưởng 22.0',
        description: 'Đạt chỉ số BMI lý tưởng cho sức khỏe tốt nhất',
      ));
    }

    return goals;
  }

  // Tính toán thống kê mục tiêu
  static Future<Map<String, int>> getGoalStats() async {
    final goals = await getGoals();
    
    return {
      'total': goals.length,
      'active': goals.where((g) => g.isActive).length,
      'completed': goals.where((g) => g.progressPercentage >= 100).length,
      'overdue': goals.where((g) => g.daysRemaining <= 0 && g.progressPercentage < 100).length,
    };
  }

  // Xóa tất cả mục tiêu
  static Future<void> clearAllGoals() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_goalsKey);
    await prefs.remove(_goalProgressKey);

    // Xóa tất cả goal progress keys động
    await _clearAllGoalProgressKeys();
  }

  // Xóa tất cả goal progress keys động
  static Future<void> _clearAllGoalProgressKeys() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();

    // Tìm tất cả keys bắt đầu với goal_progress_
    final goalProgressKeys = allKeys.where((key) => key.startsWith('${_goalProgressKey}_')).toList();

    for (final key in goalProgressKeys) {
      await prefs.remove(key);
    }
  }

  // Xóa toàn bộ dữ liệu của GoalService (alias cho clearAllGoals)
  static Future<void> clearAll() async {
    await clearAllGoals();
  }

  // Lấy thống kê dữ liệu mục tiêu
  static Future<Map<String, dynamic>> getGoalDataStats() async {
    final prefs = await SharedPreferences.getInstance();
    final goals = await getGoals();
    final allKeys = prefs.getKeys();

    // Đếm goal progress keys
    final goalProgressKeys = allKeys.where((key) => key.startsWith('${_goalProgressKey}_')).toList();

    // Tính kích thước dữ liệu
    final goalsString = prefs.getString(_goalsKey) ?? '[]';
    int totalProgressSize = 0;

    for (final key in goalProgressKeys) {
      final progressString = prefs.getString(key) ?? '[]';
      totalProgressSize += progressString.length * 2;
    }

    return {
      'totalGoals': goals.length,
      'activeGoals': goals.where((g) => g.isActive).length,
      'completedGoals': goals.where((g) => !g.isActive && g.completedDate != null).length,
      'goalProgressKeys': goalProgressKeys.length,
      'goalsSizeBytes': goalsString.length * 2,
      'progressSizeBytes': totalProgressSize,
      'totalSizeBytes': (goalsString.length * 2) + totalProgressSize,
      'oldestGoal': goals.isNotEmpty ? goals.map((g) => g.startDate.millisecondsSinceEpoch).reduce((a, b) => a < b ? a : b) : null,
      'newestGoal': goals.isNotEmpty ? goals.map((g) => g.startDate.millisecondsSinceEpoch).reduce((a, b) => a > b ? a : b) : null,
    };
  }

  // Backup dữ liệu mục tiêu
  static Future<Map<String, dynamic>> backupGoalData() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    final goalProgressKeys = allKeys.where((key) => key.startsWith('${_goalProgressKey}_')).toList();

    final backup = <String, dynamic>{};

    // Backup goals
    backup[_goalsKey] = prefs.getString(_goalsKey);

    // Backup all goal progress
    for (final key in goalProgressKeys) {
      backup[key] = prefs.getString(key);
    }

    backup['backupTimestamp'] = DateTime.now().millisecondsSinceEpoch;
    backup['version'] = '1.0';

    return backup;
  }

  // Restore dữ liệu mục tiêu từ backup
  static Future<bool> restoreGoalData(Map<String, dynamic> backup) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Xóa dữ liệu hiện tại trước
      await clearAllGoals();

      // Restore goals
      if (backup.containsKey(_goalsKey) && backup[_goalsKey] != null) {
        await prefs.setString(_goalsKey, backup[_goalsKey]);
      }

      // Restore goal progress
      for (final entry in backup.entries) {
        if (entry.key.startsWith('${_goalProgressKey}_') && entry.value != null) {
          await prefs.setString(entry.key, entry.value);
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // Lưu lịch sử tiến độ mục tiêu
  static Future<void> saveGoalProgress(String goalId, double progress, DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final progressKey = '${_goalProgressKey}_$goalId';
    final existingProgress = prefs.getString(progressKey) ?? '[]';
    final List<dynamic> progressList = jsonDecode(existingProgress);
    
    progressList.add({
      'progress': progress,
      'date': date.millisecondsSinceEpoch,
    });
    
    // Giữ tối đa 100 điểm dữ liệu
    if (progressList.length > 100) {
      progressList.removeAt(0);
    }
    
    await prefs.setString(progressKey, jsonEncode(progressList));
  }

  // Lấy lịch sử tiến độ mục tiêu
  static Future<List<Map<String, dynamic>>> getGoalProgress(String goalId) async {
    final prefs = await SharedPreferences.getInstance();
    final progressKey = '${_goalProgressKey}_$goalId';
    final progressString = prefs.getString(progressKey) ?? '[]';
    final List<dynamic> progressList = jsonDecode(progressString);
    
    return progressList.cast<Map<String, dynamic>>();
  }

  // Cập nhật mục tiêu khi có thay đổi lớn trong dữ liệu sức khỏe
  static Future<void> handleSignificantHealthChange(HealthData oldData, HealthData newData) async {
    final weightChange = (newData.weight - oldData.weight).abs();
    final bmiChange = (newData.bmi - oldData.bmi).abs();

    // Nếu có thay đổi đáng kể (>2kg hoặc BMI thay đổi >1.0)
    if (weightChange > 2.0 || bmiChange > 1.0) {
      final goals = await getGoals();
      bool hasUpdates = false;

      for (int i = 0; i < goals.length; i++) {
        final goal = goals[i];
        if (!goal.isActive) continue;

        HealthGoal? updatedGoal;

        // Điều chỉnh mục tiêu dựa trên thay đổi
        switch (goal.type) {
          case GoalType.weightLoss:
            if (newData.weight < goal.targetValue) {
              // Đã đạt mục tiêu trước hạn, tạo mục tiêu mới
              updatedGoal = goal.copyWith(
                isActive: false,
                completedDate: DateTime.now(),
              );
            } else if (weightChange > 3.0) {
              // Điều chỉnh target nếu có thay đổi lớn
              final newTarget = newData.weight - (goal.startValue - goal.targetValue);
              updatedGoal = goal.copyWith(targetValue: newTarget);
            }
            break;

          case GoalType.weightGain:
            if (newData.weight > goal.targetValue) {
              // Đã đạt mục tiêu trước hạn
              updatedGoal = goal.copyWith(
                isActive: false,
                completedDate: DateTime.now(),
              );
            } else if (weightChange > 3.0) {
              // Điều chỉnh target
              final newTarget = newData.weight + (goal.targetValue - goal.startValue);
              updatedGoal = goal.copyWith(targetValue: newTarget);
            }
            break;

          case GoalType.bmiTarget:
            if ((goal.targetValue - newData.bmi).abs() < 0.5) {
              // Gần đạt mục tiêu BMI
              updatedGoal = goal.copyWith(
                isActive: false,
                completedDate: DateTime.now(),
              );
            }
            break;

          case GoalType.maintain:
            // Kiểm tra xem có duy trì được không
            if (weightChange > 2.0) {
              // Cập nhật target range
              updatedGoal = goal.copyWith(targetValue: newData.weight);
            }
            break;
        }

        if (updatedGoal != null) {
          goals[i] = updatedGoal;
          hasUpdates = true;
        }
      }

      if (hasUpdates) {
        await saveGoals(goals);
      }
    }
  }

  // Gợi ý mục tiêu mới khi hoàn thành mục tiêu cũ
  static Future<void> _suggestNewGoals(HealthData currentData, List<GoalProgressUpdate> completedGoals) async {
    final existingGoals = await getGoals();
    final now = DateTime.now();

    for (final completedGoal in completedGoals) {
      final goal = completedGoal.goal;

      // Tránh tạo mục tiêu trùng lặp
      final hasSimilarGoal = existingGoals.any((g) =>
        g.type == goal.type &&
        g.isActive &&
        g.id != goal.id
      );

      if (hasSimilarGoal) continue;

      HealthGoal? newGoal;

      switch (goal.type) {
        case GoalType.weightLoss:
          // Nếu đã giảm cân thành công, gợi ý duy trì hoặc giảm thêm
          if (currentData.bmi >= 18.5 && currentData.bmi <= 24.9) {
            // BMI đã lý tưởng, gợi ý duy trì
            newGoal = HealthGoal(
              id: 'maintain_${now.millisecondsSinceEpoch}',
              type: GoalType.maintain,
              targetValue: currentData.weight,
              currentValue: currentData.weight,
              startValue: currentData.weight,
              startDate: now,
              targetDate: now.add(const Duration(days: 90)),
              title: 'Duy trì cân nặng lý tưởng',
              description: 'Duy trì cân nặng hiện tại trong 3 tháng tới',
            );
          } else if (currentData.bmi > 24.9) {
            // Vẫn có thể giảm thêm
            final additionalLoss = (currentData.bmi - 22) * (currentData.height / 100) * (currentData.height / 100);
            newGoal = HealthGoal(
              id: 'weight_loss_${now.millisecondsSinceEpoch}',
              type: GoalType.weightLoss,
              targetValue: currentData.weight - additionalLoss,
              currentValue: currentData.weight,
              startValue: currentData.weight,
              startDate: now,
              targetDate: now.add(const Duration(days: 120)),
              title: 'Tiếp tục giảm cân',
              description: 'Đạt BMI lý tưởng 22.0',
            );
          }
          break;

        case GoalType.weightGain:
          // Nếu đã tăng cân thành công, gợi ý duy trì
          if (currentData.bmi >= 18.5) {
            newGoal = HealthGoal(
              id: 'maintain_${now.millisecondsSinceEpoch}',
              type: GoalType.maintain,
              targetValue: currentData.weight,
              currentValue: currentData.weight,
              startValue: currentData.weight,
              startDate: now,
              targetDate: now.add(const Duration(days: 90)),
              title: 'Duy trì cân nặng khỏe mạnh',
              description: 'Duy trì cân nặng đã đạt được',
            );
          }
          break;

        case GoalType.bmiTarget:
          // Gợi ý mục tiêu duy trì BMI
          newGoal = HealthGoal(
            id: 'maintain_bmi_${now.millisecondsSinceEpoch}',
            type: GoalType.maintain,
            targetValue: currentData.weight,
            currentValue: currentData.weight,
            startValue: currentData.weight,
            startDate: now,
            targetDate: now.add(const Duration(days: 180)),
            title: 'Duy trì BMI lý tưởng',
            description: 'Duy trì BMI ${currentData.bmi.toStringAsFixed(1)} trong 6 tháng',
          );
          break;

        case GoalType.maintain:
          // Có thể gợi ý mục tiêu cải thiện thể lực hoặc BMI tối ưu hơn
          if (currentData.bmi < 22) {
            newGoal = HealthGoal(
              id: 'optimal_bmi_${now.millisecondsSinceEpoch}',
              type: GoalType.bmiTarget,
              targetValue: 22.0,
              currentValue: currentData.bmi,
              startValue: currentData.bmi,
              startDate: now,
              targetDate: now.add(const Duration(days: 90)),
              title: 'BMI tối ưu 22.0',
              description: 'Đạt BMI tối ưu cho sức khỏe',
            );
          }
          break;
      }

      // Thêm mục tiêu mới nếu có
      if (newGoal != null) {
        await addGoal(newGoal);
      }
    }
  }

  // Xử lý các trường hợp edge case
  static HealthGoal _handleEdgeCases(HealthGoal goal, double progress, bool isCompleted) {
    final now = DateTime.now();
    HealthGoal updatedGoal = goal;

    // 1. Xử lý mục tiêu quá hạn
    if (now.isAfter(goal.targetDate) && !isCompleted && goal.isActive) {
      if (progress > 75) {
        // Gia hạn thêm 30 ngày nếu tiến độ tốt
        updatedGoal = updatedGoal.copyWith(
          targetDate: goal.targetDate.add(const Duration(days: 30)),
        );
      } else if (progress < 25) {
        // Điều chỉnh mục tiêu nếu tiến độ quá chậm
        updatedGoal = _adjustGoalForSlowProgress(updatedGoal);
      }
    }

    // 2. Xử lý thay đổi đột ngột (tiến độ âm)
    if (progress < 0) {
      updatedGoal = _handleNegativeProgress(updatedGoal);
    }

    // 3. Xử lý mục tiêu không thực tế (quá xa so với thời gian còn lại)
    final daysRemaining = goal.targetDate.difference(now).inDays;
    if (daysRemaining > 0 && progress < 10 && daysRemaining < 30) {
      // Mục tiêu có thể không thực tế, điều chỉnh
      updatedGoal = _adjustUnrealisticGoal(updatedGoal, daysRemaining);
    }

    // 4. Xử lý mục tiêu duy trì với biến động lớn
    if (goal.type == GoalType.maintain) {
      final deviation = (goal.currentValue - goal.targetValue).abs();
      if (deviation > 3.0) {
        // Điều chỉnh target để phù hợp với thực tế
        updatedGoal = updatedGoal.copyWith(
          targetValue: goal.currentValue,
        );
      }
    }

    return updatedGoal;
  }

  // Điều chỉnh mục tiêu khi tiến độ chậm
  static HealthGoal _adjustGoalForSlowProgress(HealthGoal goal) {
    switch (goal.type) {
      case GoalType.weightLoss:
        // Giảm mục tiêu xuống 50% so với ban đầu
        final newTarget = goal.startValue - ((goal.startValue - goal.targetValue) * 0.5);
        return goal.copyWith(targetValue: newTarget);

      case GoalType.weightGain:
        // Giảm mục tiêu xuống 50% so với ban đầu
        final newTarget = goal.startValue + ((goal.targetValue - goal.startValue) * 0.5);
        return goal.copyWith(targetValue: newTarget);

      case GoalType.bmiTarget:
        // Điều chỉnh BMI target gần hơn với hiện tại
        final currentDiff = (goal.targetValue - goal.currentValue).abs();
        final newTarget = goal.currentValue + (goal.targetValue > goal.currentValue ? currentDiff * 0.5 : -currentDiff * 0.5);
        return goal.copyWith(targetValue: newTarget);

      case GoalType.maintain:
        return goal; // Không cần điều chỉnh
    }
  }

  // Xử lý tiến độ âm (đi ngược hướng)
  static HealthGoal _handleNegativeProgress(HealthGoal goal) {
    // Có thể tạo thông báo cảnh báo hoặc điều chỉnh chiến lược
    // Hiện tại chỉ reset lại target date
    return goal.copyWith(
      targetDate: DateTime.now().add(const Duration(days: 60)),
    );
  }

  // Điều chỉnh mục tiêu không thực tế
  static HealthGoal _adjustUnrealisticGoal(HealthGoal goal, int daysRemaining) {
    // Gia hạn thời gian hoặc điều chỉnh mục tiêu
    final newTargetDate = DateTime.now().add(Duration(days: daysRemaining + 60));
    return goal.copyWith(targetDate: newTargetDate);
  }
}
