enum GoalType {
  weightLoss,
  weightGain,
  maintain,
  bmiTarget,
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

  // Tính phần trăm hoàn thành
  double get progressPercentage {
    switch (type) {
      case GoalType.weightLoss:
        final startWeight = _getStartValue();
        final totalToLose = startWeight - targetValue;
        final currentLoss = startWeight - currentValue;
        if (totalToLose <= 0) return 100;
        return (currentLoss / totalToLose * 100).clamp(0, 100);

      case GoalType.weightGain:
        final startWeight = _getStartValue();
        final totalToGain = targetValue - startWeight;
        final currentGain = currentValue - startWeight;
        if (totalToGain <= 0) return 100;
        return (currentGain / totalToGain * 100).clamp(0, 100);

      case GoalType.maintain:
        final startWeight = _getStartValue();
        final tolerance = 2.0; // ±2kg tolerance
        final deviation = (currentValue - startWeight).abs();
        if (deviation <= tolerance) return 100;
        return ((tolerance - deviation + tolerance) / (tolerance * 2) * 100).clamp(0, 100);

      case GoalType.bmiTarget:
        final startBMI = _getStartValue();
        final totalChange = (targetValue - startBMI).abs();
        final currentChange = (startBMI - currentValue).abs();
        if (totalChange <= 0) return 100;

        // Kiểm tra hướng tiến triển
        final isMovingTowardsTarget = (startBMI > targetValue && currentValue < startBMI) ||
                                     (startBMI < targetValue && currentValue > startBMI) ||
                                     (startBMI == targetValue);

        if (!isMovingTowardsTarget) return 0;

        final progress = (currentChange / totalChange * 100).clamp(0, 100);

        // Nếu đã đạt hoặc vượt mục tiêu
        if ((startBMI > targetValue && currentValue <= targetValue) ||
            (startBMI < targetValue && currentValue >= targetValue)) {
          return 100;
        }

        return progress.toDouble();
    }
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
