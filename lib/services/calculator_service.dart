import 'dart:math';
import '../models/health_data.dart';

/// Service tính toán nâng cao cho sức khỏe
class CalculatorService {
  /// Tính lượng nước cần uống hàng ngày (ml)
  static double calculateDailyWaterIntake({
    required double weight,
    required String activityLevel,
    double temperature = 25.0, // Nhiệt độ môi trường (°C)
    bool isPregnant = false,
    bool isBreastfeeding = false,
  }) {
    // Công thức cơ bản: 35ml/kg cân nặng
    double baseIntake = weight * 35;
    
    // Điều chỉnh theo mức độ hoạt động
    double activityMultiplier = _getActivityMultiplier(activityLevel);
    baseIntake *= activityMultiplier;
    
    // Điều chỉnh theo nhiệt độ
    if (temperature > 30) {
      baseIntake *= 1.2; // Tăng 20% khi nóng
    } else if (temperature < 10) {
      baseIntake *= 0.9; // Giảm 10% khi lạnh
    }
    
    // Điều chỉnh cho phụ nữ mang thai/cho con bú
    if (isPregnant) {
      baseIntake += 300; // Thêm 300ml
    } else if (isBreastfeeding) {
      baseIntake += 700; // Thêm 700ml
    }
    
    return baseIntake.clamp(1500, 4000); // Giới hạn 1.5-4L
  }

  /// Tính calories cần thiết để giảm/tăng cân
  static Map<String, dynamic> calculateCaloriesForWeightGoal({
    required HealthData currentData,
    required double targetWeight,
    required int daysToReach,
  }) {
    final currentWeight = currentData.weight;
    final weightDifference = targetWeight - currentWeight;
    final isWeightLoss = weightDifference < 0;
    
    // 1kg mỡ = ~7700 calories
    final totalCaloriesNeeded = weightDifference.abs() * 7700;
    final dailyCalorieAdjustment = totalCaloriesNeeded / daysToReach;
    
    // Tính TDEE hiện tại
    final currentTDEE = currentData.tdee;
    
    // Tính calories mục tiêu hàng ngày
    final targetDailyCalories = isWeightLoss 
        ? currentTDEE - dailyCalorieAdjustment
        : currentTDEE + dailyCalorieAdjustment;
    
    // Kiểm tra an toàn
    final minCalories = currentData.bmr * 1.2; // Không dưới 120% BMR
    final maxCalories = currentTDEE * 1.5; // Không quá 150% TDEE
    
    final safeTargetCalories = targetDailyCalories.clamp(minCalories, maxCalories);
    final actualDailyDeficit = (currentTDEE - safeTargetCalories).abs();
    final actualWeightLossPerWeek = (actualDailyDeficit * 7) / 7700;
    final actualDaysToReach = (weightDifference.abs() / (actualWeightLossPerWeek * 7)).ceil();
    
    return {
      'targetDailyCalories': safeTargetCalories.round(),
      'dailyCalorieAdjustment': dailyCalorieAdjustment.round(),
      'actualDailyAdjustment': actualDailyDeficit.round(),
      'weightChangePerWeek': actualWeightLossPerWeek,
      'estimatedDays': actualDaysToReach,
      'isRealistic': actualDaysToReach <= daysToReach * 1.5,
      'recommendation': _getCalorieRecommendation(
        isWeightLoss, 
        dailyCalorieAdjustment, 
        actualDailyDeficit,
      ),
    };
  }

  /// Tính thời gian dự kiến đạt mục tiêu
  static Map<String, dynamic> calculateTimeToGoal({
    required HealthData currentData,
    required double targetWeight,
    double weeklyWeightChangeKg = 0.5, // Mặc định 0.5kg/tuần
  }) {
    final weightDifference = (targetWeight - currentData.weight).abs();
    final weeksNeeded = weightDifference / weeklyWeightChangeKg;
    final daysNeeded = (weeksNeeded * 7).ceil();
    
    final targetDate = DateTime.now().add(Duration(days: daysNeeded));
    
    // Tính milestone
    final milestones = <Map<String, dynamic>>[];
    final totalSteps = 10;
    for (int i = 1; i <= totalSteps; i++) {
      final progress = i / totalSteps;
      final milestoneWeight = currentData.weight + 
          (targetWeight - currentData.weight) * progress;
      final milestoneDate = DateTime.now().add(
        Duration(days: (daysNeeded * progress).round()),
      );
      
      milestones.add({
        'weight': milestoneWeight,
        'date': milestoneDate,
        'progress': progress * 100,
      });
    }
    
    return {
      'daysNeeded': daysNeeded,
      'weeksNeeded': weeksNeeded,
      'targetDate': targetDate,
      'milestones': milestones,
      'weeklyChange': weeklyWeightChangeKg,
      'difficulty': _getDifficultyLevel(weeksNeeded),
    };
  }

  /// Tính chỉ số cơ thể khác
  static Map<String, dynamic> calculateBodyComposition({
    required HealthData data,
    double? neckCircumference,
  }) {
    final results = <String, dynamic>{};
    
    // Lean Body Mass (LBM) - Khối lượng cơ nạc
    final lbm = _calculateLeanBodyMass(data);
    results['leanBodyMass'] = lbm;
    
    // Fat Mass - Khối lượng mỡ
    final fatMass = data.weight - lbm;
    results['fatMass'] = fatMass;
    
    // Muscle Mass Estimate - Ước tính khối lượng cơ
    final muscleMass = lbm * 0.45; // Cơ chiếm ~45% LBM
    results['muscleMass'] = muscleMass;
    
    // Bone Mass Estimate - Ước tính khối lượng xương
    final boneMass = data.gender.toLowerCase() == 'nam' 
        ? data.weight * 0.15 
        : data.weight * 0.12;
    results['boneMass'] = boneMass;
    
    // Body Surface Area (BSA) - Diện tích bề mặt cơ thể
    final bsa = _calculateBodySurfaceArea(data.weight, data.height);
    results['bodySurfaceArea'] = bsa;
    
    // Ponderal Index - Chỉ số Ponderal
    final pi = data.weight / pow(data.height / 100, 3);
    results['ponderalIndex'] = pi;
    
    return results;
  }

  /// Tính calories đốt cháy cho các hoạt động
  static Map<String, double> calculateCaloriesBurned({
    required double weight,
    required int durationMinutes,
  }) {
    // MET values cho các hoạt động khác nhau
    final activities = {
      'Đi bộ chậm': 3.0,
      'Đi bộ nhanh': 4.5,
      'Chạy bộ': 8.0,
      'Đạp xe': 6.0,
      'Bơi lội': 7.0,
      'Yoga': 3.0,
      'Tập gym': 5.0,
      'Nhảy dây': 10.0,
      'Leo cầu thang': 8.0,
      'Dọn nhà': 3.5,
      'Làm vườn': 4.0,
      'Nấu ăn': 2.5,
    };
    
    final results = <String, double>{};
    
    for (final entry in activities.entries) {
      final met = entry.value;
      // Calories = MET × weight(kg) × time(hours)
      final calories = met * weight * (durationMinutes / 60);
      results[entry.key] = calories;
    }
    
    return results;
  }

  /// Tính chỉ số sức khỏe tim mạch
  static Map<String, dynamic> calculateCardiovascularHealth({
    required HealthData data,
    int? restingHeartRate,
    int? systolicBP,
    int? diastolicBP,
  }) {
    final results = <String, dynamic>{};
    
    // Maximum Heart Rate - Nhịp tim tối đa
    final maxHR = 220 - data.age;
    results['maxHeartRate'] = maxHR;
    
    // Target Heart Rate Zones - Vùng nhịp tim mục tiêu
    results['heartRateZones'] = {
      'fat_burn': {'min': (maxHR * 0.6).round(), 'max': (maxHR * 0.7).round()},
      'cardio': {'min': (maxHR * 0.7).round(), 'max': (maxHR * 0.85).round()},
      'peak': {'min': (maxHR * 0.85).round(), 'max': maxHR},
    };
    
    // Resting Heart Rate Assessment
    if (restingHeartRate != null) {
      results['restingHeartRate'] = restingHeartRate;
      results['heartRateCategory'] = _getHeartRateCategory(restingHeartRate, data.age);
    }
    
    // Blood Pressure Assessment
    if (systolicBP != null && diastolicBP != null) {
      results['bloodPressure'] = {
        'systolic': systolicBP,
        'diastolic': diastolicBP,
        'category': _getBloodPressureCategory(systolicBP, diastolicBP),
      };
    }
    
    return results;
  }

  // Helper methods
  static double _getActivityMultiplier(String activityLevel) {
    switch (activityLevel.toLowerCase()) {
      case 'ít vận động':
        return 1.0;
      case 'vận động nhẹ':
        return 1.1;
      case 'vận động vừa':
        return 1.2;
      case 'vận động nhiều':
        return 1.3;
      case 'vận động rất nhiều':
        return 1.4;
      default:
        return 1.0;
    }
  }

  static String _getCalorieRecommendation(
    bool isWeightLoss, 
    double targetDeficit, 
    double actualDeficit,
  ) {
    if (targetDeficit > 1000) {
      return 'Mục tiêu quá khắt khe. Nên giảm ${actualDeficit.round()} calories/ngày để an toàn.';
    } else if (targetDeficit < 200) {
      return 'Tiến độ sẽ chậm. Có thể tăng hoạt động thể chất để đạt mục tiêu nhanh hơn.';
    } else {
      return 'Mục tiêu hợp lý. Duy trì ${actualDeficit.round()} calories/ngày.';
    }
  }

  static String _getDifficultyLevel(double weeks) {
    if (weeks < 4) return 'Rất khó';
    if (weeks < 8) return 'Khó';
    if (weeks < 16) return 'Vừa phải';
    if (weeks < 24) return 'Dễ';
    return 'Rất dễ';
  }

  static double _calculateLeanBodyMass(HealthData data) {
    // Boer Formula
    if (data.gender.toLowerCase() == 'nam') {
      return (0.407 * data.weight) + (0.267 * data.height) - 19.2;
    } else {
      return (0.252 * data.weight) + (0.473 * data.height) - 48.3;
    }
  }

  static double _calculateBodySurfaceArea(double weight, double height) {
    // Du Bois formula
    return 0.007184 * pow(weight, 0.425) * pow(height, 0.725);
  }

  static String _getHeartRateCategory(int rhr, int age) {
    if (age < 30) {
      if (rhr < 60) return 'Rất tốt';
      if (rhr < 70) return 'Tốt';
      if (rhr < 80) return 'Bình thường';
      return 'Cần cải thiện';
    } else if (age < 50) {
      if (rhr < 65) return 'Rất tốt';
      if (rhr < 75) return 'Tốt';
      if (rhr < 85) return 'Bình thường';
      return 'Cần cải thiện';
    } else {
      if (rhr < 70) return 'Rất tốt';
      if (rhr < 80) return 'Tốt';
      if (rhr < 90) return 'Bình thường';
      return 'Cần cải thiện';
    }
  }

  static String _getBloodPressureCategory(int systolic, int diastolic) {
    if (systolic < 120 && diastolic < 80) return 'Bình thường';
    if (systolic < 130 && diastolic < 80) return 'Hơi cao';
    if (systolic < 140 || diastolic < 90) return 'Cao độ 1';
    if (systolic < 180 || diastolic < 120) return 'Cao độ 2';
    return 'Khủng hoảng';
  }
}
