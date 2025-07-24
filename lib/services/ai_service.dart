import 'dart:math';
import 'package:flutter/material.dart';
import '../models/health_data.dart';
import '../config/ai_config.dart';
import 'storage_service.dart';
import 'daily_tracking_service.dart';
import 'http_client_service.dart';

/// Service quản lý các tính năng AI
class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  // HTTP client service để gọi AI APIs
  final HttpClientService _httpClient = HttpClientService();

  // AI provider hiện tại
  AIProvider _currentProvider = AIConfig.defaultProvider;

  /// Khởi tạo AI service
  void initialize() {
    _httpClient.initialize();
  }

  /// Thay đổi AI provider
  void setProvider(AIProvider provider) {
    _currentProvider = provider;
  }

  /// Lấy provider hiện tại
  AIProvider get currentProvider => _currentProvider;

  // Simulated AI responses - trong thực tế sẽ gọi API AI thật
  static const List<String> _healthTips = [
    "Uống đủ nước là chìa khóa cho sức khỏe tốt. Hãy uống ít nhất 8 ly nước mỗi ngày.",
    "Tập thể dục đều đặn 30 phút mỗi ngày giúp cải thiện sức khỏe tim mạch.",
    "Ngủ đủ 7-8 tiếng mỗi đêm giúp cơ thể phục hồi và tăng cường miễn dịch.",
    "Ăn nhiều rau xanh và trái cây cung cấp vitamin và khoáng chất cần thiết.",
    "Giảm stress bằng cách thiền định hoặc yoga 10-15 phút mỗi ngày.",
  ];

  static const List<String> _motivationalQuotes = [
    "Sức khỏe là tài sản quý giá nhất. Hãy đầu tư vào nó mỗi ngày!",
    "Mỗi bước nhỏ đều quan trọng trên hành trình đến sức khỏe tốt hơn.",
    "Bạn mạnh mẽ hơn bạn nghĩ. Hãy tiếp tục cố gắng!",
    "Thành công không đến từ việc hoàn hảo, mà từ việc kiên trì.",
    "Hôm nay là cơ hội mới để chăm sóc bản thân tốt hơn.",
  ];

  /// Phân tích dữ liệu sức khỏe và đưa ra insights
  static Future<AIHealthInsight> analyzeHealthData() async {
    final latestData = await StorageService.getLatestData();
    final history = await StorageService.getHistory();
    final trackingService = DailyTrackingService();
    await trackingService.initialize();
    final todayRecord = trackingService.getTodayRecord();

    if (latestData == null) {
      return AIHealthInsight(
        summary: "Chưa có dữ liệu sức khỏe để phân tích.",
        recommendations: ["Hãy nhập thông tin sức khỏe cơ bản để bắt đầu."],
        riskLevel: RiskLevel.unknown,
        confidence: 0.0,
      );
    }

    // Phân tích BMI
    final bmiAnalysis = _analyzeBMI(latestData.bmi);
    
    // Phân tích xu hướng cân nặng
    final weightTrend = _analyzeWeightTrend(history);
    
    // Phân tích hoạt động hàng ngày
    final activityAnalysis = _analyzeActivity(todayRecord);
    
    // Tính toán risk level tổng thể
    final riskLevel = _calculateOverallRisk(latestData, history, todayRecord);
    
    // Tạo recommendations
    final recommendations = _generateRecommendations(
      latestData, 
      history, 
      todayRecord, 
      bmiAnalysis,
      weightTrend,
    );

    return AIHealthInsight(
      summary: _generateSummary(latestData, bmiAnalysis, weightTrend, activityAnalysis),
      recommendations: recommendations,
      riskLevel: riskLevel,
      confidence: 0.85, // Simulated confidence score
      bmiAnalysis: bmiAnalysis,
      weightTrend: weightTrend,
      activityScore: _calculateActivityScore(todayRecord),
    );
  }

  /// Phân tích BMI
  static String _analyzeBMI(double bmi) {
    if (bmi < 18.5) {
      return "BMI của bạn thấp hơn mức bình thường. Cần tăng cân một cách lành mạnh.";
    } else if (bmi < 25) {
      return "BMI của bạn trong mức bình thường. Hãy duy trì lối sống lành mạnh.";
    } else if (bmi < 30) {
      return "BMI của bạn hơi cao. Nên giảm cân để cải thiện sức khỏe.";
    } else {
      return "BMI của bạn ở mức cao. Cần có kế hoạch giảm cân nghiêm túc.";
    }
  }

  /// Phân tích xu hướng cân nặng
  static String _analyzeWeightTrend(List<HealthData> history) {
    if (history.length < 3) {
      return "Cần thêm dữ liệu để phân tích xu hướng cân nặng.";
    }

    final recent = history.take(7).toList();
    final older = history.skip(7).take(7).toList();

    if (older.isEmpty) {
      return "Dữ liệu chưa đủ để phân tích xu hướng dài hạn.";
    }

    final recentAvg = recent.fold<double>(0, (sum, data) => sum + data.weight) / recent.length;
    final olderAvg = older.fold<double>(0, (sum, data) => sum + data.weight) / older.length;
    final change = recentAvg - olderAvg;

    if (change.abs() < 0.5) {
      return "Cân nặng của bạn ổn định trong thời gian gần đây.";
    } else if (change > 0) {
      return "Cân nặng của bạn có xu hướng tăng ${change.toStringAsFixed(1)}kg gần đây.";
    } else {
      return "Cân nặng của bạn có xu hướng giảm ${change.abs().toStringAsFixed(1)}kg gần đây.";
    }
  }

  /// Phân tích hoạt động hàng ngày
  static String _analyzeActivity(DailyRecord todayRecord) {
    final steps = todayRecord.steps;
    final water = todayRecord.waterIntake;
    final sleep = todayRecord.sleepHours;

    if (steps >= 10000 && water >= 2.0 && sleep >= 7) {
      return "Hoạt động hôm nay rất tốt! Bạn đã đạt được các mục tiêu cơ bản.";
    } else if (steps >= 5000 || water >= 1.5 || sleep >= 6) {
      return "Hoạt động hôm nay ở mức trung bình. Có thể cải thiện thêm.";
    } else {
      return "Hoạt động hôm nay còn hạn chế. Hãy cố gắng vận động và chăm sóc bản thân nhiều hơn.";
    }
  }

  /// Tính toán risk level tổng thể
  static RiskLevel _calculateOverallRisk(
    HealthData latestData, 
    List<HealthData> history, 
    DailyRecord todayRecord,
  ) {
    int riskScore = 0;

    // BMI risk
    if (latestData.bmi < 18.5 || latestData.bmi > 30) riskScore += 2;
    else if (latestData.bmi > 25) riskScore += 1;

    // Activity risk
    if (todayRecord.steps < 5000) riskScore += 1;
    if (todayRecord.waterIntake < 1.5) riskScore += 1;
    if (todayRecord.sleepHours < 6) riskScore += 1;

    // Age risk
    if (latestData.age > 60) riskScore += 1;
    else if (latestData.age > 40) riskScore += 0;

    if (riskScore >= 4) return RiskLevel.high;
    if (riskScore >= 2) return RiskLevel.medium;
    return RiskLevel.low;
  }

  /// Tạo recommendations
  static List<String> _generateRecommendations(
    HealthData latestData,
    List<HealthData> history,
    DailyRecord todayRecord,
    String bmiAnalysis,
    String weightTrend,
  ) {
    final recommendations = <String>[];

    // BMI recommendations
    if (latestData.bmi > 25) {
      recommendations.add("Tập trung vào việc giảm cân thông qua chế độ ăn lành mạnh và tập thể dục.");
    } else if (latestData.bmi < 18.5) {
      recommendations.add("Tăng cân lành mạnh bằng cách ăn nhiều protein và carbs phức hợp.");
    }

    // Activity recommendations
    if (todayRecord.steps < 8000) {
      recommendations.add("Tăng số bước chân lên ít nhất 8000 bước mỗi ngày.");
    }

    if (todayRecord.waterIntake < 2.0) {
      recommendations.add("Uống thêm nước để đạt mục tiêu 2 lít mỗi ngày.");
    }

    if (todayRecord.sleepHours < 7) {
      recommendations.add("Cải thiện chất lượng giấc ngủ, ngủ ít nhất 7-8 tiếng mỗi đêm.");
    }

    // General recommendations
    recommendations.add("Duy trì chế độ ăn cân bằng với nhiều rau xanh và trái cây.");
    recommendations.add("Tập thể dục đều đặn ít nhất 150 phút mỗi tuần.");

    return recommendations.take(5).toList();
  }

  /// Tạo summary
  static String _generateSummary(
    HealthData latestData,
    String bmiAnalysis,
    String weightTrend,
    String activityAnalysis,
  ) {
    return "Dựa trên phân tích dữ liệu sức khỏe của bạn: $bmiAnalysis $weightTrend $activityAnalysis";
  }

  /// Tính điểm hoạt động
  static double _calculateActivityScore(DailyRecord todayRecord) {
    double score = 0;
    
    // Steps score (0-40 points)
    score += (todayRecord.steps / 10000 * 40).clamp(0, 40);
    
    // Water score (0-30 points)
    score += (todayRecord.waterIntake / 2.0 * 30).clamp(0, 30);
    
    // Sleep score (0-30 points)
    score += (todayRecord.sleepHours / 8.0 * 30).clamp(0, 30);

    return score.clamp(0, 100);
  }

  /// Lấy tip sức khỏe ngẫu nhiên
  static String getRandomHealthTip() {
    final random = Random();
    return _healthTips[random.nextInt(_healthTips.length)];
  }

  /// Lấy câu động viên ngẫu nhiên
  static String getRandomMotivationalQuote() {
    final random = Random();
    return _motivationalQuotes[random.nextInt(_motivationalQuotes.length)];
  }

  /// Trả lời câu hỏi sức khỏe bằng AI thực tế
  Future<String> askHealthQuestion(String question) async {
    try {
      // Kiểm tra API key nếu cần thiết
      if (_currentProvider.requiresApiKey) {
        final apiKey = await _currentProvider.getApiKey();
        if (apiKey.isEmpty) {
          return _getFallbackResponse(question);
        }
      }

      String response;

      switch (_currentProvider) {
        case AIProvider.openai:
          response = await _httpClient.callOpenAI(question);
          break;
        case AIProvider.gemini:
          response = await _httpClient.callGemini(question);
          break;
        case AIProvider.claude:
          response = await _httpClient.callClaude(question);
          break;
        case AIProvider.ollama:
          response = await _httpClient.callOllama(question);
          break;
      }

      return response.isNotEmpty ? response : _getFallbackResponse(question);

    } catch (e) {
      // Log error và trả về fallback response
      print('AI API Error: $e');
      return _getFallbackResponse(question);
    }
  }

  /// Phương thức static để tương thích với code cũ
  static Future<String> askHealthQuestionStatic(String question) async {
    final instance = AIService();
    return await instance.askHealthQuestion(question);
  }

  /// Trả về response dự phòng khi AI API không khả dụng
  String _getFallbackResponse(String question) {
    final lowerQuestion = question.toLowerCase();

    if (lowerQuestion.contains('bmi') || lowerQuestion.contains('chỉ số khối cơ thể')) {
      return "BMI (Body Mass Index) là chỉ số đánh giá tình trạng cân nặng dựa trên chiều cao và cân nặng. "
             "BMI bình thường là 18.5-24.9. Bạn có thể tính BMI bằng công thức: cân nặng (kg) / (chiều cao (m))².";
    }

    if (lowerQuestion.contains('nước') || lowerQuestion.contains('uống')) {
      return "Bạn nên uống ít nhất 2-3 lít nước mỗi ngày. Lượng nước cần thiết phụ thuộc vào cân nặng, "
             "hoạt động thể chất và thời tiết. Uống nước đều đặn giúp duy trì sức khỏe và cải thiện trao đổi chất.";
    }

    if (lowerQuestion.contains('tập') || lowerQuestion.contains('thể dục') || lowerQuestion.contains('vận động')) {
      return "Nên tập thể dục ít nhất 150 phút mỗi tuần với cường độ vừa phải, hoặc 75 phút với cường độ cao. "
             "Kết hợp cả cardio và tập tạ để có sức khỏe tổng thể tốt nhất.";
    }

    if (lowerQuestion.contains('ngủ') || lowerQuestion.contains('giấc ngủ')) {
      return "Người trưởng thành nên ngủ 7-9 tiếng mỗi đêm. Giấc ngủ chất lượng giúp cơ thể phục hồi, "
             "tăng cường miễn dịch và cải thiện trí nhớ. Hãy tạo thói quen ngủ đều đặn.";
    }

    if (lowerQuestion.contains('ăn') || lowerQuestion.contains('dinh dưỡng') || lowerQuestion.contains('thức ăn')) {
      return "Chế độ ăn cân bằng nên bao gồm: 50% rau củ quả, 25% protein nạc, 25% carbs phức hợp. "
             "Hạn chế đường, muối và thực phẩm chế biến sẵn. Ăn nhiều bữa nhỏ trong ngày.";
    }

    if (lowerQuestion.contains('giảm cân') || lowerQuestion.contains('giảm béo')) {
      return "Để giảm cân hiệu quả: tạo deficit calories 500-750 kcal/ngày, kết hợp chế độ ăn lành mạnh "
             "và tập thể dục đều đặn. Giảm 0.5-1kg/tuần là mức an toàn và bền vững.";
    }

    if (lowerQuestion.contains('tăng cân') || lowerQuestion.contains('tăng cơ')) {
      return "Để tăng cân lành mạnh: ăn thặng dư calories 300-500 kcal/ngày, tập tạ để xây dựng cơ bắp, "
             "ăn nhiều protein (1.6-2.2g/kg cân nặng) và nghỉ ngơi đầy đủ.";
    }

    // Default response
    return "Đây là một câu hỏi hay về sức khỏe! Tôi khuyên bạn nên tham khảo ý kiến bác sĩ chuyên khoa "
           "để có lời khuyên chính xác nhất. Trong khi đó, hãy duy trì lối sống lành mạnh với chế độ ăn "
           "cân bằng, tập thể dục đều đặn và ngủ đủ giấc.";
  }

  /// Tạo kế hoạch cá nhân hóa
  static Future<PersonalizedPlan> generatePersonalizedPlan(HealthData userData) async {
    // Simulate AI processing
    await Future.delayed(const Duration(seconds: 2));

    final plan = PersonalizedPlan();
    
    // Tạo mục tiêu dựa trên BMI
    if (userData.bmi > 25) {
      plan.weightGoal = "Giảm ${((userData.bmi - 23) * pow(userData.height / 100, 2)).toStringAsFixed(1)}kg trong 3 tháng";
      plan.calorieTarget = (userData.tdee - 500).round();
    } else if (userData.bmi < 18.5) {
      plan.weightGoal = "Tăng ${((20 - userData.bmi) * pow(userData.height / 100, 2)).toStringAsFixed(1)}kg trong 3 tháng";
      plan.calorieTarget = (userData.tdee + 300).round();
    } else {
      plan.weightGoal = "Duy trì cân nặng hiện tại";
      plan.calorieTarget = userData.tdee.round();
    }

    // Tạo kế hoạch tập luyện
    plan.exercisePlan = _generateExercisePlan(userData);
    
    // Tạo gợi ý dinh dưỡng
    plan.nutritionTips = _generateNutritionTips(userData);

    return plan;
  }

  static List<String> _generateExercisePlan(HealthData userData) {
    final exercises = <String>[];
    
    if (userData.bmi > 25) {
      exercises.addAll([
        "Cardio 30-45 phút, 5 ngày/tuần (đi bộ nhanh, chạy bộ, đạp xe)",
        "Tập tạ 3 ngày/tuần để duy trì cơ bắp",
        "Yoga hoặc stretching 2 ngày/tuần",
      ]);
    } else if (userData.bmi < 18.5) {
      exercises.addAll([
        "Tập tạ 4-5 ngày/tuần tập trung vào compound exercises",
        "Cardio nhẹ 2-3 ngày/tuần (20-30 phút)",
        "Nghỉ ngơi đầy đủ giữa các buổi tập",
      ]);
    } else {
      exercises.addAll([
        "Kết hợp cardio và tập tạ 4-5 ngày/tuần",
        "Tập HIIT 2 ngày/tuần",
        "Hoạt động thể chất nhẹ nhàng hàng ngày",
      ]);
    }

    return exercises;
  }

  static List<String> _generateNutritionTips(HealthData userData) {
    final tips = <String>[];
    
    if (userData.bmi > 25) {
      tips.addAll([
        "Giảm 500-750 calories/ngày so với TDEE",
        "Tăng protein lên 1.6-2.2g/kg cân nặng",
        "Ăn nhiều rau xanh và giảm carbs tinh chế",
        "Uống nước trước bữa ăn để tăng cảm giác no",
      ]);
    } else if (userData.bmi < 18.5) {
      tips.addAll([
        "Tăng 300-500 calories/ngày so với TDEE",
        "Ăn nhiều bữa nhỏ trong ngày (5-6 bữa)",
        "Tập trung vào thực phẩm giàu dinh dưỡng",
        "Thêm healthy fats như avocado, nuts, olive oil",
      ]);
    } else {
      tips.addAll([
        "Duy trì calories ở mức TDEE",
        "Chế độ ăn cân bằng 40% carbs, 30% protein, 30% fat",
        "Ăn nhiều rau củ quả và whole grains",
        "Hạn chế thực phẩm chế biến sẵn",
      ]);
    }

    return tips;
  }
}

/// Enum mức độ rủi ro
enum RiskLevel {
  low,
  medium,
  high,
  unknown,
}

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

/// Model AI Health Insight
class AIHealthInsight {
  final String summary;
  final List<String> recommendations;
  final RiskLevel riskLevel;
  final double confidence;
  final String? bmiAnalysis;
  final String? weightTrend;
  final double? activityScore;

  AIHealthInsight({
    required this.summary,
    required this.recommendations,
    required this.riskLevel,
    required this.confidence,
    this.bmiAnalysis,
    this.weightTrend,
    this.activityScore,
  });
}

/// Model kế hoạch cá nhân hóa
class PersonalizedPlan {
  String weightGoal = '';
  int calorieTarget = 0;
  List<String> exercisePlan = [];
  List<String> nutritionTips = [];
}
