import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/health_data.dart';
import 'storage_service.dart';
import 'daily_tracking_service.dart';
import 'ai_service.dart';

/// Service AI Chatbot thông minh
class AIChatbotService extends ChangeNotifier {
  static final AIChatbotService _instance = AIChatbotService._internal();
  factory AIChatbotService() => _instance;
  AIChatbotService._internal();

  static const String _conversationKey = 'ai_conversation_history';
  static const String _chatSettingsKey = 'ai_chat_settings';

  List<ChatMessage> _conversationHistory = [];
  ChatSettings _settings = ChatSettings();
  bool _isInitialized = false;

  List<ChatMessage> get conversationHistory => _conversationHistory;
  ChatSettings get settings => _settings;
  bool get isInitialized => _isInitialized;

  /// Khởi tạo service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await _loadSettings();
    await _loadConversationHistory();
    _isInitialized = true;
    notifyListeners();
  }

  /// Tải cài đặt chat
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsString = prefs.getString(_chatSettingsKey);
    
    if (settingsString != null) {
      try {
        final settingsMap = jsonDecode(settingsString) as Map<String, dynamic>;
        _settings = ChatSettings.fromMap(settingsMap);
      } catch (e) {
        _settings = ChatSettings();
      }
    }
  }

  /// Lưu cài đặt chat
  Future<void> saveSettings(ChatSettings settings) async {
    _settings = settings;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chatSettingsKey, jsonEncode(settings.toMap()));
    notifyListeners();
  }

  /// Tải lịch sử hội thoại
  Future<void> _loadConversationHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyString = prefs.getString(_conversationKey) ?? '[]';
    
    try {
      final List<dynamic> historyList = jsonDecode(historyString);
      _conversationHistory = historyList
          .map((json) => ChatMessage.fromMap(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _conversationHistory = [];
    }

    // Thêm tin nhắn chào mừng nếu chưa có
    if (_conversationHistory.isEmpty) {
      _addWelcomeMessage();
    }
  }

  /// Lưu lịch sử hội thoại
  Future<void> _saveConversationHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = _conversationHistory.map((msg) => msg.toMap()).toList();
    await prefs.setString(_conversationKey, jsonEncode(historyJson));
  }

  /// Thêm tin nhắn chào mừng
  void _addWelcomeMessage() {
    final welcomeMessage = ChatMessage(
      id: _generateMessageId(),
      text: "Xin chào! Tôi là AI Health Assistant của bạn. 🤖\n\n"
            "Tôi có thể giúp bạn:\n"
            "• Phân tích dữ liệu sức khỏe\n"
            "• Đưa ra lời khuyên cá nhân hóa\n"
            "• Trả lời câu hỏi về dinh dưỡng\n"
            "• Tạo kế hoạch tập luyện\n"
            "• Theo dõi tiến độ của bạn\n\n"
            "Hãy hỏi tôi bất cứ điều gì! 😊",
      isUser: false,
      timestamp: DateTime.now(),
      messageType: MessageType.welcome,
    );
    
    _conversationHistory.add(welcomeMessage);
  }

  /// Gửi tin nhắn và nhận phản hồi
  Future<ChatMessage> sendMessage(String userMessage) async {
    // Thêm tin nhắn của user
    final userChatMessage = ChatMessage(
      id: _generateMessageId(),
      text: userMessage,
      isUser: true,
      timestamp: DateTime.now(),
      messageType: MessageType.text,
    );
    
    _conversationHistory.add(userChatMessage);
    await _saveConversationHistory();
    notifyListeners();

    // Simulate typing delay
    await Future.delayed(Duration(milliseconds: 500 + Random().nextInt(1500)));

    // Tạo phản hồi AI
    final aiResponse = await _generateAIResponse(userMessage);
    
    _conversationHistory.add(aiResponse);
    await _saveConversationHistory();
    notifyListeners();

    return aiResponse;
  }

  /// Tạo phản hồi AI
  Future<ChatMessage> _generateAIResponse(String userMessage) async {
    final lowerMessage = userMessage.toLowerCase();
    
    // Phân loại intent
    final intent = _classifyIntent(lowerMessage);
    
    String responseText;
    MessageType messageType = MessageType.text;
    Map<String, dynamic>? actionData;

    switch (intent) {
      case ChatIntent.healthAnalysis:
        responseText = await _generateHealthAnalysisResponse();
        messageType = MessageType.healthAnalysis;
        break;
      
      case ChatIntent.nutritionAdvice:
        responseText = _generateNutritionAdvice(lowerMessage);
        messageType = MessageType.advice;
        break;
      
      case ChatIntent.exerciseAdvice:
        responseText = _generateExerciseAdvice(lowerMessage);
        messageType = MessageType.advice;
        break;
      
      case ChatIntent.goalSetting:
        responseText = await _generateGoalSettingResponse();
        messageType = MessageType.goalSetting;
        break;
      
      case ChatIntent.motivational:
        responseText = _generateMotivationalResponse();
        messageType = MessageType.motivational;
        break;
      
      case ChatIntent.dataQuery:
        responseText = await _generateDataQueryResponse(lowerMessage);
        messageType = MessageType.dataQuery;
        break;
      
      case ChatIntent.general:
        responseText = await _generateGeneralResponse(lowerMessage);
        break;
    }

    return ChatMessage(
      id: _generateMessageId(),
      text: responseText,
      isUser: false,
      timestamp: DateTime.now(),
      messageType: messageType,
      actionData: actionData,
    );
  }

  /// Phân loại intent của tin nhắn
  ChatIntent _classifyIntent(String message) {
    // Health analysis keywords
    if (message.contains('phân tích') || message.contains('đánh giá') || 
        message.contains('tình trạng') || message.contains('sức khỏe của tôi')) {
      return ChatIntent.healthAnalysis;
    }

    // Nutrition keywords
    if (message.contains('ăn') || message.contains('thức ăn') || 
        message.contains('dinh dưỡng') || message.contains('calories') ||
        message.contains('thực đơn') || message.contains('món ăn')) {
      return ChatIntent.nutritionAdvice;
    }

    // Exercise keywords
    if (message.contains('tập') || message.contains('thể dục') || 
        message.contains('vận động') || message.contains('gym') ||
        message.contains('cardio') || message.contains('yoga')) {
      return ChatIntent.exerciseAdvice;
    }

    // Goal setting keywords
    if (message.contains('mục tiêu') || message.contains('kế hoạch') || 
        message.contains('giảm cân') || message.contains('tăng cân') ||
        message.contains('cải thiện')) {
      return ChatIntent.goalSetting;
    }

    // Motivational keywords
    if (message.contains('động viên') || message.contains('khuyến khích') || 
        message.contains('cảm thấy') || message.contains('buồn') ||
        message.contains('stress') || message.contains('mệt mỏi')) {
      return ChatIntent.motivational;
    }

    // Data query keywords
    if (message.contains('bao nhiêu') || message.contains('thống kê') || 
        message.contains('số liệu') || message.contains('dữ liệu') ||
        message.contains('tiến độ') || message.contains('kết quả')) {
      return ChatIntent.dataQuery;
    }

    return ChatIntent.general;
  }

  /// Tạo phản hồi phân tích sức khỏe
  Future<String> _generateHealthAnalysisResponse() async {
    final latestData = await StorageService.getLatestData();
    final trackingService = DailyTrackingService();
    await trackingService.initialize();
    final todayRecord = trackingService.getTodayRecord();

    if (latestData == null) {
      return "Tôi chưa thấy dữ liệu sức khỏe của bạn. Hãy nhập thông tin cơ bản như chiều cao, cân nặng để tôi có thể phân tích nhé! 📊";
    }

    final bmi = latestData.bmi;
    final steps = todayRecord.steps;
    final water = todayRecord.waterIntake;

    String analysis = "📊 **Phân tích sức khỏe hiện tại:**\n\n";
    
    // BMI analysis
    if (bmi < 18.5) {
      analysis += "• BMI: ${bmi.toStringAsFixed(1)} - Hơi thấp, nên tăng cân lành mạnh\n";
    } else if (bmi < 25) {
      analysis += "• BMI: ${bmi.toStringAsFixed(1)} - Tuyệt vời! Trong mức bình thường\n";
    } else if (bmi < 30) {
      analysis += "• BMI: ${bmi.toStringAsFixed(1)} - Hơi cao, nên giảm cân nhẹ\n";
    } else {
      analysis += "• BMI: ${bmi.toStringAsFixed(1)} - Cần giảm cân để cải thiện sức khỏe\n";
    }

    // Activity analysis
    if (steps >= 10000) {
      analysis += "• Hoạt động: Xuất sắc! $steps bước hôm nay 🚶‍♂️\n";
    } else if (steps >= 5000) {
      analysis += "• Hoạt động: Tốt! $steps bước, cố gắng thêm nhé 💪\n";
    } else {
      analysis += "• Hoạt động: Cần cải thiện, chỉ $steps bước hôm nay 🏃‍♂️\n";
    }

    // Water analysis
    if (water >= 2.0) {
      analysis += "• Nước uống: Tuyệt vời! ${water.toStringAsFixed(1)}L hôm nay 💧\n";
    } else {
      analysis += "• Nước uống: Cần uống thêm, mới ${water.toStringAsFixed(1)}L 🥤\n";
    }

    analysis += "\nBạn có muốn tôi đưa ra gợi ý cải thiện không? 🤔";

    return analysis;
  }

  /// Tạo lời khuyên dinh dưỡng
  String _generateNutritionAdvice(String message) {
    final nutritionTips = [
      "🥗 **Lời khuyên dinh dưỡng:**\n\n• Ăn nhiều rau xanh và trái cây\n• Chọn protein nạc như cá, gà, đậu\n• Hạn chế đường và thực phẩm chế biến\n• Uống đủ nước mỗi ngày",
      "🍎 **Thực đơn lành mạnh:**\n\n• Sáng: Yến mạch + trái cây + sữa\n• Trưa: Cơm gạo lứt + thịt/cá + rau\n• Tối: Salad + protein + ít carbs\n• Snack: Hạt, sữa chua, trái cây",
      "⚖️ **Cân bằng dinh dưỡng:**\n\n• 50% rau củ quả\n• 25% protein\n• 25% carbs phức hợp\n• Healthy fats từ avocado, nuts",
    ];

    if (message.contains('giảm cân')) {
      return "🎯 **Dinh dưỡng giảm cân:**\n\n• Tạo deficit 300-500 calories/ngày\n• Tăng protein lên 1.6-2.2g/kg\n• Ăn nhiều chất xơ để no lâu\n• Uống nước trước bữa ăn\n• Ăn chậm và nhai kỹ";
    }

    if (message.contains('tăng cân')) {
      return "💪 **Dinh dưỡng tăng cân:**\n\n• Thặng dư 300-500 calories/ngày\n• Ăn nhiều bữa nhỏ (5-6 bữa)\n• Tập trung vào healthy fats\n• Protein shake sau tập\n• Thêm nuts, avocado vào món ăn";
    }

    return nutritionTips[Random().nextInt(nutritionTips.length)];
  }

  /// Tạo lời khuyên tập luyện
  String _generateExerciseAdvice(String message) {
    final exerciseTips = [
      "🏃‍♂️ **Kế hoạch tập luyện:**\n\n• 150 phút cardio/tuần\n• 2-3 ngày tập tạ\n• Yoga/stretching 2 ngày\n• Nghỉ ngơi 1-2 ngày",
      "💪 **Bài tập cơ bản:**\n\n• Squat: 3 sets x 15 reps\n• Push-up: 3 sets x 10 reps\n• Plank: 3 sets x 30s\n• Burpee: 3 sets x 8 reps",
      "🧘‍♀️ **Tập nhẹ nhàng:**\n\n• Đi bộ 30 phút\n• Yoga 20 phút\n• Stretching 15 phút\n• Thiền 10 phút",
    ];

    if (message.contains('giảm cân')) {
      return "🔥 **Tập luyện giảm cân:**\n\n• HIIT 3 ngày/tuần (20-30 phút)\n• Cardio 2 ngày/tuần (45 phút)\n• Tập tạ 2 ngày/tuần\n• Đi bộ hàng ngày\n• Tăng cường độ dần dần";
    }

    if (message.contains('tăng cơ')) {
      return "💪 **Tập luyện tăng cơ:**\n\n• Tập tạ 4-5 ngày/tuần\n• Compound exercises ưu tiên\n• Progressive overload\n• Nghỉ ngơi đầy đủ\n• Cardio nhẹ 2 ngày/tuần";
    }

    return exerciseTips[Random().nextInt(exerciseTips.length)];
  }

  /// Tạo phản hồi về mục tiêu
  Future<String> _generateGoalSettingResponse() async {
    return "🎯 **Đặt mục tiêu thông minh:**\n\n"
           "Hãy cho tôi biết:\n"
           "• Bạn muốn đạt được gì?\n"
           "• Trong bao lâu?\n"
           "• Tại sao mục tiêu này quan trọng?\n\n"
           "Tôi sẽ giúp bạn tạo kế hoạch chi tiết! 📋";
  }

  /// Tạo phản hồi động viên
  String _generateMotivationalResponse() {
    final motivationalMessages = [
      "💪 Bạn đang làm rất tốt! Mỗi bước nhỏ đều quan trọng trên hành trình sức khỏe.",
      "🌟 Hãy nhớ rằng: Tiến bộ không phải lúc nào cũng hoàn hảo, nhưng kiên trì sẽ đưa bạn đến đích!",
      "🎯 Thành công không đến từ việc không bao giờ thất bại, mà từ việc không bao giờ bỏ cuộc!",
      "🚀 Cơ thể bạn có thể làm được. Chỉ cần thuyết phục tâm trí thôi!",
      "⭐ Mỗi ngày là một cơ hội mới để trở thành phiên bản tốt hơn của chính mình!",
    ];

    return motivationalMessages[Random().nextInt(motivationalMessages.length)];
  }

  /// Tạo phản hồi truy vấn dữ liệu
  Future<String> _generateDataQueryResponse(String message) async {
    final trackingService = DailyTrackingService();
    await trackingService.initialize();
    final weeklyStats = trackingService.getWeeklyStats();

    return "📈 **Thống kê tuần này:**\n\n"
           "• Bước chân TB: ${weeklyStats['averageSteps']} bước/ngày\n"
           "• Tổng nước uống: ${weeklyStats['totalWater'].toStringAsFixed(1)}L\n"
           "• Giấc ngủ TB: ${weeklyStats['averageSleep'].toStringAsFixed(1)} giờ/đêm\n"
           "• Số ngày theo dõi: ${weeklyStats['daysTracked']}/7\n\n"
           "Bạn muốn xem thống kê nào khác không? 🤔";
  }

  /// Tạo phản hồi chung bằng AI API
  Future<String> _generateGeneralResponse(String message) async {
    try {
      // Thử sử dụng AI API thực tế
      final aiService = AIService();
      final aiResponse = await aiService.askHealthQuestion(message);

      // Nếu có response từ AI, sử dụng nó
      if (aiResponse.isNotEmpty && !aiResponse.contains('API key')) {
        return aiResponse;
      }
    } catch (e) {
      // Nếu AI API không khả dụng, sử dụng fallback responses
      print('AI API không khả dụng: $e');
    }

    // Fallback responses khi AI API không hoạt động
    final generalResponses = [
      "Tôi hiểu bạn đang quan tâm đến sức khỏe! Bạn có thể hỏi tôi về dinh dưỡng, tập luyện, hoặc phân tích dữ liệu sức khỏe. 😊",
      "Đó là một câu hỏi hay! Tôi có thể giúp bạn với các vấn đề về sức khỏe, dinh dưỡng và tập luyện. Bạn muốn biết gì cụ thể? 🤔",
      "Cảm ơn bạn đã chia sẻ! Tôi luôn sẵn sàng hỗ trợ bạn trên hành trình sức khỏe. Có điều gì tôi có thể giúp không? 💪",
      "Tôi đang học hỏi để trả lời tốt hơn! Hiện tại bạn có thể hỏi về BMI, dinh dưỡng, tập luyện hoặc giấc ngủ. 🤖",
    ];

    return generalResponses[Random().nextInt(generalResponses.length)];
  }

  /// Tạo ID tin nhắn
  String _generateMessageId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Xóa lịch sử hội thoại
  Future<void> clearConversationHistory() async {
    _conversationHistory.clear();
    _addWelcomeMessage();
    await _saveConversationHistory();
    notifyListeners();
  }

  /// Lấy gợi ý câu hỏi
  List<String> getQuestionSuggestions() {
    return [
      "Phân tích sức khỏe của tôi",
      "Tạo thực đơn giảm cân",
      "Kế hoạch tập luyện cho người mới",
      "Tôi nên uống bao nhiêu nước?",
      "Cách cải thiện giấc ngủ",
      "Thống kê tuần này của tôi",
    ];
  }
}

// Enums và Models
enum ChatIntent {
  healthAnalysis,
  nutritionAdvice,
  exerciseAdvice,
  goalSetting,
  motivational,
  dataQuery,
  general,
}

enum MessageType {
  text,
  welcome,
  healthAnalysis,
  advice,
  goalSetting,
  motivational,
  dataQuery,
}

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final MessageType messageType;
  final Map<String, dynamic>? actionData;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.messageType = MessageType.text,
    this.actionData,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'messageType': messageType.index,
      'actionData': actionData,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      isUser: map['isUser'] ?? false,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      messageType: MessageType.values[map['messageType'] ?? 0],
      actionData: map['actionData'],
    );
  }
}

class ChatSettings {
  final bool enableNotifications;
  final bool enableSuggestions;
  final bool saveHistory;
  final String language;

  ChatSettings({
    this.enableNotifications = true,
    this.enableSuggestions = true,
    this.saveHistory = true,
    this.language = 'vi',
  });

  ChatSettings copyWith({
    bool? enableNotifications,
    bool? enableSuggestions,
    bool? saveHistory,
    String? language,
  }) {
    return ChatSettings(
      enableNotifications: enableNotifications ?? this.enableNotifications,
      enableSuggestions: enableSuggestions ?? this.enableSuggestions,
      saveHistory: saveHistory ?? this.saveHistory,
      language: language ?? this.language,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enableNotifications': enableNotifications,
      'enableSuggestions': enableSuggestions,
      'saveHistory': saveHistory,
      'language': language,
    };
  }

  factory ChatSettings.fromMap(Map<String, dynamic> map) {
    return ChatSettings(
      enableNotifications: map['enableNotifications'] ?? true,
      enableSuggestions: map['enableSuggestions'] ?? true,
      saveHistory: map['saveHistory'] ?? true,
      language: map['language'] ?? 'vi',
    );
  }
}
