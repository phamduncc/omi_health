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

  // Cập nhật tiến độ mục tiêu dựa trên dữ liệu sức khỏe mới
  static Future<void> updateGoalProgress() async {
    final goals = await getGoals();
    final latestData = await StorageService.getLatestData();
    
    if (latestData == null) return;

    bool hasUpdates = false;
    for (int i = 0; i < goals.length; i++) {
      final goal = goals[i];
      if (!goal.isActive) continue;

      HealthGoal updatedGoal = goal;
      
      switch (goal.type) {
        case GoalType.weightLoss:
        case GoalType.weightGain:
        case GoalType.maintain:
          updatedGoal = goal.copyWith(currentValue: latestData.weight);
          break;
        case GoalType.bmiTarget:
          updatedGoal = goal.copyWith(currentValue: latestData.bmi);
          break;
      }

      if (updatedGoal.currentValue != goal.currentValue) {
        goals[i] = updatedGoal;
        hasUpdates = true;
      }
    }

    if (hasUpdates) {
      await saveGoals(goals);
    }
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
}
