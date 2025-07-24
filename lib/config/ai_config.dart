import 'package:shared_preferences/shared_preferences.dart';

/// Cấu hình cho các AI services
class AIConfig {
  // OpenAI Configuration
  static const String openaiApiUrl = 'https://api.openai.com/v1/chat/completions';
  static const String openaiModel = 'gpt-3.5-turbo';
  
  // Gemini Configuration (Google AI)
  static const String geminiApiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';
  
  // Claude Configuration (Anthropic)
  static const String claudeApiUrl = 'https://api.anthropic.com/v1/messages';
  static const String claudeModel = 'claude-3-haiku-20240307';
  
  // Ollama Configuration (Local AI)
  static const String ollamaApiUrl = 'http://localhost:11434/api/generate';
  static const String ollamaModel = 'llama2';
  
  // API Keys sẽ được đọc từ SharedPreferences
  static Future<String> getApiKey(AIProvider provider) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('api_key_${provider.name}') ?? '';
  }
  
  // Default AI Provider
  static const AIProvider defaultProvider = AIProvider.openai;
  
  // Request timeout
  static const Duration requestTimeout = Duration(seconds: 30);
  
  // Max tokens for response
  static const int maxTokens = 1000;
  
  // Temperature for creativity (0.0 - 1.0)
  static const double temperature = 0.7;
  
  // System prompt cho health chatbot
  static const String healthSystemPrompt = '''
Bạn là một trợ lý AI chuyên về sức khỏe và dinh dưỡng. Hãy trả lời các câu hỏi về sức khỏe một cách chính xác, hữu ích và dễ hiểu.

Nguyên tắc:
1. Luôn khuyến khích người dùng tham khảo ý kiến bác sĩ cho các vấn đề nghiêm trọng
2. Đưa ra thông tin dựa trên khoa học và y học hiện đại
3. Sử dụng tiếng Việt tự nhiên và dễ hiểu
4. Tập trung vào lời khuyên thực tế và có thể áp dụng
5. Không chẩn đoán bệnh hay thay thế ý kiến bác sĩ

Trả lời ngắn gọn, súc tích trong 2-3 câu.
''';
}

/// Enum các AI providers có sẵn
enum AIProvider {
  openai,
  gemini,
  claude,
  ollama,
}

extension AIProviderExtension on AIProvider {
  String get name {
    switch (this) {
      case AIProvider.openai:
        return 'OpenAI GPT';
      case AIProvider.gemini:
        return 'Google Gemini';
      case AIProvider.claude:
        return 'Anthropic Claude';
      case AIProvider.ollama:
        return 'Ollama (Local)';
    }
  }
  
  String get apiUrl {
    switch (this) {
      case AIProvider.openai:
        return AIConfig.openaiApiUrl;
      case AIProvider.gemini:
        return AIConfig.geminiApiUrl;
      case AIProvider.claude:
        return AIConfig.claudeApiUrl;
      case AIProvider.ollama:
        return AIConfig.ollamaApiUrl;
    }
  }
  
  Future<String> getApiKey() async {
    return await AIConfig.getApiKey(this);
  }
  
  bool get requiresApiKey {
    return this != AIProvider.ollama;
  }
}
