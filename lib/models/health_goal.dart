enum GoalType {
  weightLoss,
  weightGain,
  maintain,
  bmiTarget,
}

class GoalProgressUpdate {
  final HealthGoal goal;
  final double oldProgress;
  final double newProgress;
  final double progressChange;
  final bool isCompleted;
  final bool isNewMilestone;

  GoalProgressUpdate({
    required this.goal,
    required this.oldProgress,
    required this.newProgress,
    required this.progressChange,
    required this.isCompleted,
    this.isNewMilestone = false,
  });

  String get progressMessage {
    if (isCompleted) {
      return 'Chúc mừng! Bạn đã hoàn thành mục tiêu "${goal.title}"';
    }

    if (isNewMilestone) {
      final milestone = (newProgress / 25).floor() * 25;
      return 'Tuyệt vời! Bạn đã đạt $milestone% mục tiêu "${goal.title}"';
    }

    if (progressChange > 0) {
      if (progressChange >= 5) {
        return 'Tiến bộ tuyệt vời! Mục tiêu "${goal.title}" tăng ${progressChange.toStringAsFixed(1)}%';
      } else {
        return 'Tiến độ mục tiêu "${goal.title}" đã tăng ${progressChange.toStringAsFixed(1)}%';
      }
    } else if (progressChange < 0) {
      return 'Tiến độ mục tiêu "${goal.title}" đã giảm ${(-progressChange).toStringAsFixed(1)}%';
    }

    return 'Mục tiêu "${goal.title}" được cập nhật';
  }

  String get detailMessage {
    final current = goal.type == GoalType.bmiTarget
        ? goal.currentValue.toStringAsFixed(1)
        : '${goal.currentValue.toStringAsFixed(1)} kg';
    final target = goal.type == GoalType.bmiTarget
        ? goal.targetValue.toStringAsFixed(1)
        : '${goal.targetValue.toStringAsFixed(1)} kg';

    return 'Hiện tại: $current → Mục tiêu: $target (${newProgress.toStringAsFixed(1)}%)';
  }
}

class HealthGoal {
  final String id;
  final GoalType type;
  final double targetValue;
  final double currentValue;
  final double startValue; // Giá trị ban đầu khi tạo mục tiêu
  final DateTime startDate;
  final DateTime targetDate;
  final String title;
  final String description;
  final bool isActive;
  final DateTime? completedDate;
  final String? notes;

  HealthGoal({
    required this.id,
    required this.type,
    required this.targetValue,
    required this.currentValue,
    required this.startValue,
    required this.startDate,
    required this.targetDate,
    required this.title,
    required this.description,
    this.isActive = true,
    this.completedDate,
    this.notes,
  });

  // Tính phần trăm hoàn thành với logic cải thiện
  double get progressPercentage {
    // Kiểm tra dữ liệu hợp lệ
    if (startValue == 0 || targetValue == 0) return 0;

    switch (type) {
      case GoalType.weightLoss:
        return _calculateWeightLossProgress();

      case GoalType.weightGain:
        return _calculateWeightGainProgress();

      case GoalType.maintain:
        return _calculateMaintainProgress();

      case GoalType.bmiTarget:
        return _calculateBMITargetProgress();
    }
  }

  // Tính tiến độ giảm cân
  double _calculateWeightLossProgress() {
    final startWeight = startValue;
    final totalToLose = startWeight - targetValue;

    // Kiểm tra mục tiêu hợp lệ
    if (totalToLose <= 0) return 100;

    final currentLoss = startWeight - currentValue;

    // Nếu đã đạt hoặc vượt mục tiêu
    if (currentValue <= targetValue) return 100;

    // Nếu tăng cân thay vì giảm
    if (currentLoss < 0) return 0;

    final progress = (currentLoss / totalToLose * 100).clamp(0, 100);
    return progress.toDouble();
  }

  // Tính tiến độ tăng cân
  double _calculateWeightGainProgress() {
    final startWeight = startValue;
    final totalToGain = targetValue - startWeight;

    // Kiểm tra mục tiêu hợp lệ
    if (totalToGain <= 0) return 100;

    final currentGain = currentValue - startWeight;

    // Nếu đã đạt hoặc vượt mục tiêu
    if (currentValue >= targetValue) return 100;

    // Nếu giảm cân thay vì tăng
    if (currentGain < 0) return 0;

    final progress = (currentGain / totalToGain * 100).clamp(0, 100);
    return progress.toDouble();
  }

  // Tính tiến độ duy trì cân nặng
  double _calculateMaintainProgress() {
    final targetWeight = targetValue;
    final tolerance = 1.0; // ±1kg tolerance (giảm từ 2kg để chặt chẽ hơn)
    final deviation = (currentValue - targetWeight).abs();

    // Nếu trong khoảng tolerance thì đã hoàn thành
    if (deviation <= tolerance) return 100;

    // Tính toán progress dựa trên khoảng cách từ tolerance
    final maxDeviation = tolerance * 4; // Tối đa 4kg deviation
    final progress = ((maxDeviation - deviation) / maxDeviation * 100).clamp(0, 100);
    return progress.toDouble();
  }

  // Tính tiến độ đạt BMI mục tiêu
  double _calculateBMITargetProgress() {
    final startBMI = startValue;
    final totalChange = (targetValue - startBMI).abs();

    // Kiểm tra mục tiêu hợp lệ
    if (totalChange <= 0.01) return 100;

    // Nếu đã đạt mục tiêu (trong khoảng ±0.1 BMI)
    if ((currentValue - targetValue).abs() <= 0.1) return 100;

    // Tính toán tiến độ dựa trên hướng di chuyển
    double currentChange;
    if (startBMI > targetValue) {
      // Cần giảm BMI
      currentChange = startBMI - currentValue;
      if (currentChange < 0) return 0; // Đang tăng BMI thay vì giảm
    } else {
      // Cần tăng BMI
      currentChange = currentValue - startBMI;
      if (currentChange < 0) return 0; // Đang giảm BMI thay vì tăng
    }

    final progress = (currentChange / totalChange * 100).clamp(0, 100);
    return progress.toDouble();
  }

  // Lấy giá trị ban đầu
  double _getStartValue() {
    return startValue;
  }

  // Số ngày còn lại
  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(targetDate)) return 0;
    return targetDate.difference(now).inDays;
  }

  // Trạng thái mục tiêu
  String get status {
    if (progressPercentage >= 100) return 'Hoàn thành';
    if (daysRemaining <= 0) return 'Quá hạn';
    if (progressPercentage >= 75) return 'Gần hoàn thành';
    if (progressPercentage >= 50) return 'Đang tiến triển tốt';
    if (progressPercentage >= 25) return 'Đang tiến triển';
    return 'Mới bắt đầu';
  }

  // Màu sắc cho trạng thái
  String get statusColor {
    if (progressPercentage >= 100) return '#2ECC71'; // Xanh lá
    if (daysRemaining <= 0) return '#E74C3C'; // Đỏ
    if (progressPercentage >= 75) return '#27AE60'; // Xanh lá đậm
    if (progressPercentage >= 50) return '#3498DB'; // Xanh dương
    if (progressPercentage >= 25) return '#F39C12'; // Cam
    return '#95A5A6'; // Xám
  }

  // Lấy cân nặng hiện tại (cần implement với storage)
  double getCurrentWeight() {
    // Placeholder - sẽ được implement với StorageService
    return currentValue;
  }

  // Chuyển đổi sang Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.index,
      'targetValue': targetValue,
      'currentValue': currentValue,
      'startValue': startValue,
      'startDate': startDate.millisecondsSinceEpoch,
      'targetDate': targetDate.millisecondsSinceEpoch,
      'title': title,
      'description': description,
      'isActive': isActive,
      'completedDate': completedDate?.millisecondsSinceEpoch,
      'notes': notes,
    };
  }

  // Tạo từ Map
  factory HealthGoal.fromMap(Map<String, dynamic> map) {
    return HealthGoal(
      id: map['id'] ?? '',
      type: GoalType.values[map['type'] ?? 0],
      targetValue: map['targetValue']?.toDouble() ?? 0.0,
      currentValue: map['currentValue']?.toDouble() ?? 0.0,
      startValue: map['startValue']?.toDouble() ?? map['currentValue']?.toDouble() ?? 0.0,
      startDate: DateTime.fromMillisecondsSinceEpoch(map['startDate'] ?? 0),
      targetDate: DateTime.fromMillisecondsSinceEpoch(map['targetDate'] ?? 0),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      isActive: map['isActive'] ?? true,
      completedDate: map['completedDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completedDate'])
          : null,
      notes: map['notes'],
    );
  }

  // Copy with
  HealthGoal copyWith({
    String? id,
    GoalType? type,
    double? targetValue,
    double? currentValue,
    double? startValue,
    DateTime? startDate,
    DateTime? targetDate,
    String? title,
    String? description,
    bool? isActive,
    DateTime? completedDate,
    String? notes,
  }) {
    return HealthGoal(
      id: id ?? this.id,
      type: type ?? this.type,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      startValue: startValue ?? this.startValue,
      startDate: startDate ?? this.startDate,
      targetDate: targetDate ?? this.targetDate,
      title: title ?? this.title,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      completedDate: completedDate ?? this.completedDate,
      notes: notes ?? this.notes,
    );
  }
}
