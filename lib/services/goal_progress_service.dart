import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/health_goal.dart';
import '../models/health_data.dart';
import 'goal_service.dart';
import 'storage_service.dart';

class GoalProgressService extends ChangeNotifier {
  static final GoalProgressService _instance = GoalProgressService._internal();
  factory GoalProgressService() => _instance;
  GoalProgressService._internal();

  List<HealthGoal> _goals = [];
  HealthData? _currentHealthData;
  Timer? _progressUpdateTimer;
  bool _isUpdating = false;
  Map<String, dynamic>? _progressSummary;

  // Stream controllers for real-time updates
  final StreamController<List<HealthGoal>> _goalsStreamController =
      StreamController<List<HealthGoal>>.broadcast();
  final StreamController<Map<String, dynamic>> _progressStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<List<HealthGoal>> get goalsStream => _goalsStreamController.stream;
  Stream<Map<String, dynamic>> get progressStream => _progressStreamController.stream;

  List<HealthGoal> get goals => _goals;
  HealthData? get currentHealthData => _currentHealthData;
  bool get isUpdating => _isUpdating;

  // Khởi tạo service và bắt đầu cập nhật liên tục
  Future<void> initialize() async {
    await _loadInitialData();
    _startContinuousUpdate();
  }

  // Tải dữ liệu ban đầu
  Future<void> _loadInitialData() async {
    _goals = await GoalService.getGoals();
    _currentHealthData = await StorageService.getLatestData();
    notifyListeners();
  }

  // Bắt đầu cập nhật liên tục mỗi 5 giây
  void _startContinuousUpdate() {
    _progressUpdateTimer?.cancel();
    _progressUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _updateProgress();
    });
  }

  // Dừng cập nhật liên tục
  void stopContinuousUpdate() {
    _progressUpdateTimer?.cancel();
    _progressUpdateTimer = null;
  }

  // Cập nhật tiến độ
  Future<void> _updateProgress() async {
    if (_isUpdating) return;
    
    _isUpdating = true;
    notifyListeners();

    try {
      // Lấy dữ liệu mới nhất
      final latestData = await StorageService.getLatestData();
      final currentGoals = await GoalService.getGoals();

      bool hasChanges = false;

      // Kiểm tra thay đổi trong health data
      if (latestData != null && 
          (_currentHealthData == null || 
           latestData.weight != _currentHealthData!.weight ||
           latestData.bmi != _currentHealthData!.bmi)) {
        _currentHealthData = latestData;
        hasChanges = true;
      }

      // Kiểm tra thay đổi trong goals
      if (currentGoals.length != _goals.length ||
          _hasGoalChanges(currentGoals)) {
        _goals = currentGoals;
        hasChanges = true;
      }

      // Cập nhật current values nếu có dữ liệu mới
      if (_currentHealthData != null) {
        await GoalService.updateCurrentValues(_currentHealthData!);
        
        // Reload goals sau khi update
        _goals = await GoalService.getGoals();
        hasChanges = true;
      }

      if (hasChanges) {
        // Tính toán progress summary
        final progressSummary = _calculateProgressSummary(_goals);
        _progressSummary = progressSummary;

        notifyListeners();

        // Emit to streams
        _goalsStreamController.add(_goals);
        _progressStreamController.add(progressSummary);
      }

    } catch (e) {
      // Log error silently
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  // Kiểm tra xem có thay đổi trong goals không
  bool _hasGoalChanges(List<HealthGoal> newGoals) {
    if (newGoals.length != _goals.length) return true;
    
    for (int i = 0; i < newGoals.length; i++) {
      final newGoal = newGoals[i];
      final oldGoal = _goals[i];
      
      if (newGoal.id != oldGoal.id ||
          newGoal.currentValue != oldGoal.currentValue ||
          newGoal.isActive != oldGoal.isActive ||
          newGoal.progressPercentage != oldGoal.progressPercentage) {
        return true;
      }
    }
    
    return false;
  }

  // Force update ngay lập tức
  Future<void> forceUpdate() async {
    await _updateProgress();
  }

  // Cập nhật khi có dữ liệu sức khỏe mới
  Future<void> onHealthDataUpdated(HealthData newData) async {
    _currentHealthData = newData;
    await _updateProgress();
  }

  // Cập nhật khi có goal mới
  Future<void> onGoalUpdated() async {
    await _updateProgress();
  }

  // Lấy goals đang active
  List<HealthGoal> get activeGoals {
    return _goals.where((goal) => goal.isActive).toList();
  }

  // Lấy goals đã hoàn thành
  List<HealthGoal> get completedGoals {
    return _goals.where((goal) => !goal.isActive).toList();
  }

  // Lấy goal theo ID
  HealthGoal? getGoalById(String id) {
    try {
      return _goals.firstWhere((goal) => goal.id == id);
    } catch (e) {
      return null;
    }
  }

  // Lấy progress summary
  Map<String, dynamic> get progressSummary {
    final active = activeGoals;
    final completed = completedGoals;
    
    double totalProgress = 0;
    if (active.isNotEmpty) {
      totalProgress = active.map((g) => g.progressPercentage).reduce((a, b) => a + b) / active.length;
    }

    return {
      'totalGoals': _goals.length,
      'activeGoals': active.length,
      'completedGoals': completed.length,
      'averageProgress': totalProgress,
      'completionRate': _goals.isEmpty ? 0.0 : (completed.length / _goals.length * 100),
    };
  }

  // Tính toán tóm tắt tiến độ
  Map<String, dynamic> _calculateProgressSummary(List<HealthGoal> goals) {
    if (goals.isEmpty) {
      return {
        'totalGoals': 0,
        'activeGoals': 0,
        'completedGoals': 0,
        'averageProgress': 0.0,
        'onTrackGoals': 0,
        'behindScheduleGoals': 0,
      };
    }

    int totalGoals = goals.length;
    int activeGoals = goals.where((g) => g.isActive).length;
    int completedGoals = goals.where((g) => !g.isActive && g.completedDate != null).length;

    double totalProgress = 0.0;
    int onTrackGoals = 0;
    int behindScheduleGoals = 0;

    for (final goal in goals.where((g) => g.isActive)) {
      double progress = goal.progressPercentage;
      totalProgress += progress;

      // Tính toán xem có đúng tiến độ không (dựa trên thời gian)
      final totalDays = goal.targetDate.difference(goal.startDate).inDays;
      final elapsedDays = DateTime.now().difference(goal.startDate).inDays;
      final expectedProgress = totalDays > 0 ? (elapsedDays / totalDays * 100).clamp(0, 100) : 0.0;

      if (progress >= expectedProgress - 10) {
        onTrackGoals++;
      } else {
        behindScheduleGoals++;
      }
    }

    double averageProgress = activeGoals > 0 ? totalProgress / activeGoals : 0.0;

    return {
      'totalGoals': totalGoals,
      'activeGoals': activeGoals,
      'completedGoals': completedGoals,
      'averageProgress': averageProgress,
      'onTrackGoals': onTrackGoals,
      'behindScheduleGoals': behindScheduleGoals,
      'lastUpdated': DateTime.now().millisecondsSinceEpoch,
    };
  }

  @override
  void dispose() {
    stopContinuousUpdate();
    _goalsStreamController.close();
    _progressStreamController.close();
    super.dispose();
  }
}
