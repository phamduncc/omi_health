import 'package:flutter/material.dart';
import '../models/health_data.dart';
import '../services/storage_service.dart';
import '../services/daily_tracking_service.dart';
import '../services/ai_service.dart';

/// Service phân tích dữ liệu AI nâng cao
class AIAnalyticsService {
  static final AIAnalyticsService _instance = AIAnalyticsService._internal();
  factory AIAnalyticsService() => _instance;
  AIAnalyticsService._internal();

  /// Phân tích xu hướng sức khỏe
  static Future<HealthTrendAnalysis> analyzeHealthTrends() async {
    final history = await StorageService.getHistory();
    final trackingService = DailyTrackingService();
    await trackingService.initialize();
    
    if (history.length < 7) {
      return HealthTrendAnalysis(
        weightTrend: TrendDirection.stable,
        bmiTrend: TrendDirection.stable,
        activityTrend: TrendDirection.stable,
        overallHealth: HealthStatus.unknown,
        predictions: [],
        confidence: 0.0,
        analysisText: "Cần ít nhất 7 ngày dữ liệu để phân tích xu hướng.",
      );
    }

    // Phân tích xu hướng cân nặng
    final weightTrend = _analyzeWeightTrend(history);
    
    // Phân tích xu hướng BMI
    final bmiTrend = _analyzeBMITrend(history);
    
    // Phân tích xu hướng hoạt động
    final activityTrend = _analyzeActivityTrend(trackingService.records);
    
    // Đánh giá sức khỏe tổng thể
    final overallHealth = _assessOverallHealth(history.first, trackingService.getTodayRecord());
    
    // Tạo dự đoán
    final predictions = _generatePredictions(history, trackingService.records);
    
    // Tính độ tin cậy
    final confidence = _calculateConfidence(history.length, trackingService.records.length);
    
    // Tạo văn bản phân tích
    final analysisText = _generateAnalysisText(weightTrend, bmiTrend, activityTrend, overallHealth);

    return HealthTrendAnalysis(
      weightTrend: weightTrend,
      bmiTrend: bmiTrend,
      activityTrend: activityTrend,
      overallHealth: overallHealth,
      predictions: predictions,
      confidence: confidence,
      analysisText: analysisText,
    );
  }

  /// Phân tích xu hướng cân nặng
  static TrendDirection _analyzeWeightTrend(List<HealthData> history) {
    if (history.length < 3) return TrendDirection.stable;

    final recent = history.take(7).map((e) => e.weight).toList();
    final older = history.skip(7).take(7).map((e) => e.weight).toList();

    if (older.isEmpty) return TrendDirection.stable;

    final recentAvg = recent.reduce((a, b) => a + b) / recent.length;
    final olderAvg = older.reduce((a, b) => a + b) / older.length;
    final change = recentAvg - olderAvg;

    if (change > 0.5) return TrendDirection.increasing;
    if (change < -0.5) return TrendDirection.decreasing;
    return TrendDirection.stable;
  }

  /// Phân tích xu hướng BMI
  static TrendDirection _analyzeBMITrend(List<HealthData> history) {
    if (history.length < 3) return TrendDirection.stable;

    final recent = history.take(7).map((e) => e.bmi).toList();
    final older = history.skip(7).take(7).map((e) => e.bmi).toList();

    if (older.isEmpty) return TrendDirection.stable;

    final recentAvg = recent.reduce((a, b) => a + b) / recent.length;
    final olderAvg = older.reduce((a, b) => a + b) / older.length;
    final change = recentAvg - olderAvg;

    if (change > 0.2) return TrendDirection.increasing;
    if (change < -0.2) return TrendDirection.decreasing;
    return TrendDirection.stable;
  }

  /// Phân tích xu hướng hoạt động
  static TrendDirection _analyzeActivityTrend(List<DailyRecord> records) {
    if (records.length < 7) return TrendDirection.stable;

    final recent = records.take(7).toList();
    final older = records.skip(7).take(7).toList();

    if (older.isEmpty) return TrendDirection.stable;

    // Tính điểm hoạt động trung bình
    final recentScore = recent.map(_calculateDailyActivityScore).reduce((a, b) => a + b) / recent.length;
    final olderScore = older.map(_calculateDailyActivityScore).reduce((a, b) => a + b) / older.length;
    
    final change = recentScore - olderScore;

    if (change > 5) return TrendDirection.increasing;
    if (change < -5) return TrendDirection.decreasing;
    return TrendDirection.stable;
  }

  /// Tính điểm hoạt động hàng ngày
  static double _calculateDailyActivityScore(DailyRecord record) {
    double score = 0;
    score += (record.steps / 10000 * 40).clamp(0, 40);
    score += (record.waterIntake / 2.0 * 30).clamp(0, 30);
    score += (record.sleepHours / 8.0 * 30).clamp(0, 30);
    return score;
  }

  /// Đánh giá sức khỏe tổng thể
  static HealthStatus _assessOverallHealth(HealthData latestData, DailyRecord todayRecord) {
    int healthScore = 0;

    // BMI score
    if (latestData.bmi >= 18.5 && latestData.bmi < 25) {
      healthScore += 3;
    } else if (latestData.bmi < 30) {
      healthScore += 1;
    }

    // Activity score
    if (todayRecord.steps >= 8000) healthScore += 2;
    else if (todayRecord.steps >= 5000) healthScore += 1;

    if (todayRecord.waterIntake >= 2.0) healthScore += 2;
    else if (todayRecord.waterIntake >= 1.5) healthScore += 1;

    if (todayRecord.sleepHours >= 7) healthScore += 2;
    else if (todayRecord.sleepHours >= 6) healthScore += 1;

    // Age factor
    if (latestData.age < 30) healthScore += 1;
    else if (latestData.age > 60) healthScore -= 1;

    if (healthScore >= 8) return HealthStatus.excellent;
    if (healthScore >= 6) return HealthStatus.good;
    if (healthScore >= 4) return HealthStatus.fair;
    if (healthScore >= 2) return HealthStatus.poor;
    return HealthStatus.critical;
  }

  /// Tạo dự đoán
  static List<HealthPrediction> _generatePredictions(
    List<HealthData> history,
    List<DailyRecord> dailyRecords,
  ) {
    final predictions = <HealthPrediction>[];

    // Dự đoán cân nặng sau 30 ngày
    if (history.length >= 7) {
      final weightPrediction = _predictWeight(history, 30);
      predictions.add(weightPrediction);
    }

    // Dự đoán BMI sau 30 ngày
    if (history.length >= 7) {
      final bmiPrediction = _predictBMI(history, 30);
      predictions.add(bmiPrediction);
    }

    // Dự đoán mức độ hoạt động
    if (dailyRecords.length >= 7) {
      final activityPrediction = _predictActivity(dailyRecords);
      predictions.add(activityPrediction);
    }

    return predictions;
  }

  /// Dự đoán cân nặng
  static HealthPrediction _predictWeight(List<HealthData> history, int days) {
    final weights = history.take(14).map((e) => e.weight).toList();
    final trend = _calculateLinearTrend(weights);
    final predictedWeight = weights.first + (trend * days);
    
    return HealthPrediction(
      type: PredictionType.weight,
      value: predictedWeight,
      timeframe: days,
      confidence: _calculatePredictionConfidence(weights.length),
      description: "Dự đoán cân nặng sau $days ngày: ${predictedWeight.toStringAsFixed(1)}kg",
    );
  }

  /// Dự đoán BMI
  static HealthPrediction _predictBMI(List<HealthData> history, int days) {
    final bmis = history.take(14).map((e) => e.bmi).toList();
    final trend = _calculateLinearTrend(bmis);
    final predictedBMI = bmis.first + (trend * days);
    
    return HealthPrediction(
      type: PredictionType.bmi,
      value: predictedBMI,
      timeframe: days,
      confidence: _calculatePredictionConfidence(bmis.length),
      description: "Dự đoán BMI sau $days ngày: ${predictedBMI.toStringAsFixed(1)}",
    );
  }

  /// Dự đoán hoạt động
  static HealthPrediction _predictActivity(List<DailyRecord> records) {
    final scores = records.take(14).map(_calculateDailyActivityScore).toList();
    final avgScore = scores.reduce((a, b) => a + b) / scores.length;
    
    String description;
    if (avgScore >= 80) {
      description = "Xu hướng hoạt động rất tích cực. Tiếp tục duy trì!";
    } else if (avgScore >= 60) {
      description = "Hoạt động ở mức tốt. Có thể cải thiện thêm.";
    } else if (avgScore >= 40) {
      description = "Hoạt động trung bình. Nên tăng cường vận động.";
    } else {
      description = "Hoạt động thấp. Cần cải thiện đáng kể.";
    }
    
    return HealthPrediction(
      type: PredictionType.activity,
      value: avgScore,
      timeframe: 7,
      confidence: _calculatePredictionConfidence(scores.length),
      description: description,
    );
  }

  /// Tính xu hướng tuyến tính
  static double _calculateLinearTrend(List<double> values) {
    if (values.length < 2) return 0;

    final n = values.length;
    final x = List.generate(n, (i) => i.toDouble());
    final y = values;

    final sumX = x.reduce((a, b) => a + b);
    final sumY = y.reduce((a, b) => a + b);
    final sumXY = List.generate(n, (i) => x[i] * y[i]).reduce((a, b) => a + b);
    final sumX2 = x.map((e) => e * e).reduce((a, b) => a + b);

    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    return slope;
  }

  /// Tính độ tin cậy dự đoán
  static double _calculatePredictionConfidence(int dataPoints) {
    if (dataPoints >= 30) return 0.9;
    if (dataPoints >= 14) return 0.8;
    if (dataPoints >= 7) return 0.7;
    return 0.5;
  }

  /// Tính độ tin cậy tổng thể
  static double _calculateConfidence(int healthDataPoints, int dailyRecords) {
    final healthConfidence = (healthDataPoints / 30).clamp(0, 1);
    final dailyConfidence = (dailyRecords / 30).clamp(0, 1);
    return (healthConfidence + dailyConfidence) / 2;
  }

  /// Tạo văn bản phân tích
  static String _generateAnalysisText(
    TrendDirection weightTrend,
    TrendDirection bmiTrend,
    TrendDirection activityTrend,
    HealthStatus overallHealth,
  ) {
    final buffer = StringBuffer();
    
    buffer.write("Phân tích AI cho thấy: ");
    
    // Weight trend
    switch (weightTrend) {
      case TrendDirection.increasing:
        buffer.write("Cân nặng có xu hướng tăng. ");
        break;
      case TrendDirection.decreasing:
        buffer.write("Cân nặng có xu hướng giảm. ");
        break;
      case TrendDirection.stable:
        buffer.write("Cân nặng ổn định. ");
        break;
    }

    // Activity trend
    switch (activityTrend) {
      case TrendDirection.increasing:
        buffer.write("Mức độ hoạt động đang cải thiện. ");
        break;
      case TrendDirection.decreasing:
        buffer.write("Mức độ hoạt động đang giảm. ");
        break;
      case TrendDirection.stable:
        buffer.write("Mức độ hoạt động ổn định. ");
        break;
    }

    // Overall health
    switch (overallHealth) {
      case HealthStatus.excellent:
        buffer.write("Tình trạng sức khỏe tổng thể rất tốt!");
        break;
      case HealthStatus.good:
        buffer.write("Tình trạng sức khỏe tổng thể tốt.");
        break;
      case HealthStatus.fair:
        buffer.write("Tình trạng sức khỏe ở mức trung bình.");
        break;
      case HealthStatus.poor:
        buffer.write("Tình trạng sức khỏe cần cải thiện.");
        break;
      case HealthStatus.critical:
        buffer.write("Tình trạng sức khỏe cần được chú ý đặc biệt.");
        break;
      case HealthStatus.unknown:
        buffer.write("Cần thêm dữ liệu để đánh giá.");
        break;
    }

    return buffer.toString();
  }

  /// Phân tích rủi ro sức khỏe
  static Future<List<HealthRisk>> analyzeHealthRisks() async {
    final latestData = await StorageService.getLatestData();
    final trackingService = DailyTrackingService();
    await trackingService.initialize();
    final todayRecord = trackingService.getTodayRecord();

    if (latestData == null) return [];

    final risks = <HealthRisk>[];

    // BMI risks
    if (latestData.bmi > 30) {
      risks.add(HealthRisk(
        type: RiskType.obesity,
        level: RiskLevel.high,
        description: "BMI cao (${latestData.bmi.toStringAsFixed(1)}) tăng nguy cơ bệnh tim mạch, tiểu đường",
        recommendation: "Cần kế hoạch giảm cân nghiêm túc với sự hướng dẫn của chuyên gia",
      ));
    } else if (latestData.bmi > 25) {
      risks.add(HealthRisk(
        type: RiskType.overweight,
        level: RiskLevel.medium,
        description: "BMI hơi cao (${latestData.bmi.toStringAsFixed(1)}) có thể dẫn đến các vấn đề sức khỏe",
        recommendation: "Nên giảm cân nhẹ thông qua chế độ ăn và tập luyện",
      ));
    } else if (latestData.bmi < 18.5) {
      risks.add(HealthRisk(
        type: RiskType.underweight,
        level: RiskLevel.medium,
        description: "BMI thấp (${latestData.bmi.toStringAsFixed(1)}) có thể ảnh hưởng đến sức khỏe",
        recommendation: "Cần tăng cân lành mạnh với chế độ ăn giàu dinh dưỡng",
      ));
    }

    // Activity risks
    if (todayRecord.steps < 5000) {
      risks.add(HealthRisk(
        type: RiskType.sedentary,
        level: RiskLevel.medium,
        description: "Ít vận động (${todayRecord.steps} bước/ngày) tăng nguy cơ bệnh tật",
        recommendation: "Tăng hoạt động thể chất lên ít nhất 8000 bước/ngày",
      ));
    }

    // Sleep risks
    if (todayRecord.sleepHours < 6) {
      risks.add(HealthRisk(
        type: RiskType.sleepDeprivation,
        level: RiskLevel.high,
        description: "Thiếu ngủ (${todayRecord.sleepHours}h/đêm) ảnh hưởng nghiêm trọng đến sức khỏe",
        recommendation: "Cần cải thiện chất lượng giấc ngủ, ngủ ít nhất 7-8 tiếng/đêm",
      ));
    }

    // Hydration risks
    if (todayRecord.waterIntake < 1.5) {
      risks.add(HealthRisk(
        type: RiskType.dehydration,
        level: RiskLevel.low,
        description: "Uống ít nước (${todayRecord.waterIntake}L/ngày) có thể gây mệt mỏi",
        recommendation: "Tăng lượng nước uống lên ít nhất 2L/ngày",
      ));
    }

    return risks;
  }
}

// Enums và Models
enum TrendDirection { increasing, decreasing, stable }
enum HealthStatus { excellent, good, fair, poor, critical, unknown }
enum PredictionType { weight, bmi, activity }
enum RiskType { obesity, overweight, underweight, sedentary, sleepDeprivation, dehydration }

extension RiskLevelExtension on RiskLevel {
  String get name {
    switch (this) {
      case RiskLevel.low:
        return 'Thấp';
      case RiskLevel.medium:
        return 'Trung bình';
      case RiskLevel.high:
        return 'Cao';
      case RiskLevel.unknown:
        return 'Chưa xác định';
    }
  }

  Color get color {
    switch (this) {
      case RiskLevel.low:
        return Colors.green;
      case RiskLevel.medium:
        return Colors.orange;
      case RiskLevel.high:
        return Colors.red;
      case RiskLevel.unknown:
        return Colors.grey;
    }
  }
}

class HealthTrendAnalysis {
  final TrendDirection weightTrend;
  final TrendDirection bmiTrend;
  final TrendDirection activityTrend;
  final HealthStatus overallHealth;
  final List<HealthPrediction> predictions;
  final double confidence;
  final String analysisText;

  HealthTrendAnalysis({
    required this.weightTrend,
    required this.bmiTrend,
    required this.activityTrend,
    required this.overallHealth,
    required this.predictions,
    required this.confidence,
    required this.analysisText,
  });
}

class HealthPrediction {
  final PredictionType type;
  final double value;
  final int timeframe;
  final double confidence;
  final String description;

  HealthPrediction({
    required this.type,
    required this.value,
    required this.timeframe,
    required this.confidence,
    required this.description,
  });
}

class HealthRisk {
  final RiskType type;
  final RiskLevel level;
  final String description;
  final String recommendation;

  HealthRisk({
    required this.type,
    required this.level,
    required this.description,
    required this.recommendation,
  });
}
