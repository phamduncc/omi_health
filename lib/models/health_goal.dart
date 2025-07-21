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
  final DateTime startDate;
  final DateTime targetDate;
  final String title;
  final String description;
  final bool isActive;

  HealthGoal({
    required this.id,
    required this.type,
    required this.targetValue,
    required this.currentValue,
    required this.startDate,
    required this.targetDate,
    required this.title,
    required this.description,
    this.isActive = true,
  });

  // Tính phần trăm hoàn thành
  double get progressPercentage {
    if (type == GoalType.weightLoss) {
      final totalToLose = currentValue - targetValue;
      final currentLoss = currentValue - getCurrentWeight();
      if (totalToLose <= 0) return 100;
      return (currentLoss / totalToLose * 100).clamp(0, 100);
    } else if (type == GoalType.weightGain) {
      final totalToGain = targetValue - currentValue;
      final currentGain = getCurrentWeight() - currentValue;
      if (totalToGain <= 0) return 100;
      return (currentGain / totalToGain * 100).clamp(0, 100);
    } else if (type == GoalType.bmiTarget) {
      // Tính dựa trên BMI hiện tại và mục tiêu
      return 0; // Cần implement logic phức tạp hơn
    }
    return 0;
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
      'startDate': startDate.millisecondsSinceEpoch,
      'targetDate': targetDate.millisecondsSinceEpoch,
      'title': title,
      'description': description,
      'isActive': isActive,
    };
  }

  // Tạo từ Map
  factory HealthGoal.fromMap(Map<String, dynamic> map) {
    return HealthGoal(
      id: map['id'] ?? '',
      type: GoalType.values[map['type'] ?? 0],
      targetValue: map['targetValue']?.toDouble() ?? 0.0,
      currentValue: map['currentValue']?.toDouble() ?? 0.0,
      startDate: DateTime.fromMillisecondsSinceEpoch(map['startDate'] ?? 0),
      targetDate: DateTime.fromMillisecondsSinceEpoch(map['targetDate'] ?? 0),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      isActive: map['isActive'] ?? true,
    );
  }

  // Copy with
  HealthGoal copyWith({
    String? id,
    GoalType? type,
    double? targetValue,
    double? currentValue,
    DateTime? startDate,
    DateTime? targetDate,
    String? title,
    String? description,
    bool? isActive,
  }) {
    return HealthGoal(
      id: id ?? this.id,
      type: type ?? this.type,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      startDate: startDate ?? this.startDate,
      targetDate: targetDate ?? this.targetDate,
      title: title ?? this.title,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }
}
