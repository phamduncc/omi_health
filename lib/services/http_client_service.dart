import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../config/ai_config.dart';

/// Service quản lý HTTP requests cho AI APIs
class HttpClientService {
  static final HttpClientService _instance = HttpClientService._internal();
  factory HttpClientService() => _instance;
  HttpClientService._internal();

  late final Dio _dio;

  /// Khởi tạo HTTP client
  void initialize() {
    _dio = Dio(BaseOptions(
      connectTimeout: AIConfig.requestTimeout,
      receiveTimeout: AIConfig.requestTimeout,
      sendTimeout: AIConfig.requestTimeout,
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // Thêm interceptor để log requests (chỉ trong development)
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) {
        // Chỉ log trong debug mode
        if (obj.toString().contains('error') || obj.toString().contains('Error')) {
          print('HTTP Error: $obj');
        }
      },
    ));
  }

  /// Gọi OpenAI API
  Future<String> callOpenAI(String message) async {
    try {
      final apiKey = await AIConfig.getApiKey(AIProvider.openai);
      final response = await _dio.post(
        AIConfig.openaiApiUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
          },
        ),
        data: {
          'model': AIConfig.openaiModel,
          'messages': [
            {
              'role': 'system',
              'content': AIConfig.healthSystemPrompt,
            },
            {
              'role': 'user',
              'content': message,
            },
          ],
          'max_tokens': AIConfig.maxTokens,
          'temperature': AIConfig.temperature,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return data['choices'][0]['message']['content'].toString().trim();
      } else {
        throw Exception('OpenAI API error: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('DioError') || e.toString().contains('DioException')) {
        throw _handleDioError(e, 'OpenAI');
      }
      throw Exception('Lỗi không xác định khi gọi OpenAI API: $e');
    }
  }

  /// Gọi Google Gemini API
  Future<String> callGemini(String message) async {
    try {
      final apiKey = await AIConfig.getApiKey(AIProvider.gemini);
      final response = await _dio.post(
        '${AIConfig.geminiApiUrl}?key=$apiKey',
        data: {
          'contents': [
            {
              'parts': [
                {
                  'text': '${AIConfig.healthSystemPrompt}\n\nCâu hỏi: $message'
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': AIConfig.temperature,
            'maxOutputTokens': AIConfig.maxTokens,
          }
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return data['candidates'][0]['content']['parts'][0]['text'].toString().trim();
      } else {
        throw Exception('Gemini API error: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('DioError') || e.toString().contains('DioException')) {
        throw _handleDioError(e, 'Gemini');
      }
      throw Exception('Lỗi không xác định khi gọi Gemini API: $e');
    }
  }

  /// Gọi Anthropic Claude API
  Future<String> callClaude(String message) async {
    try {
      final apiKey = await AIConfig.getApiKey(AIProvider.claude);
      final response = await _dio.post(
        AIConfig.claudeApiUrl,
        options: Options(
          headers: {
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
          },
        ),
        data: {
          'model': AIConfig.claudeModel,
          'max_tokens': AIConfig.maxTokens,
          'system': AIConfig.healthSystemPrompt,
          'messages': [
            {
              'role': 'user',
              'content': message,
            },
          ],
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return data['content'][0]['text'].toString().trim();
      } else {
        throw Exception('Claude API error: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('DioError') || e.toString().contains('DioException')) {
        throw _handleDioError(e, 'Claude');
      }
      throw Exception('Lỗi không xác định khi gọi Claude API: $e');
    }
  }

  /// Gọi Ollama API (local)
  Future<String> callOllama(String message) async {
    try {
      final response = await _dio.post(
        AIConfig.ollamaApiUrl,
        data: {
          'model': AIConfig.ollamaModel,
          'prompt': '${AIConfig.healthSystemPrompt}\n\nCâu hỏi: $message',
          'stream': false,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return data['response'].toString().trim();
      } else {
        throw Exception('Ollama API error: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('DioError') || e.toString().contains('DioException')) {
        throw _handleDioError(e, 'Ollama');
      }
      throw Exception('Lỗi không xác định khi gọi Ollama API: $e');
    }
  }

  /// Xử lý lỗi Dio
  Exception _handleDioError(dynamic e, String provider) {
    // Xử lý lỗi chung cho tất cả các trường hợp
    final errorMessage = e.toString();

    if (errorMessage.contains('timeout') || errorMessage.contains('Timeout')) {
      return Exception('Timeout khi kết nối đến $provider API. Vui lòng thử lại.');
    }

    if (errorMessage.contains('connection') || errorMessage.contains('Connection')) {
      return Exception('Không thể kết nối đến $provider API. Kiểm tra kết nối internet.');
    }

    if (errorMessage.contains('401')) {
      return Exception('API key không hợp lệ cho $provider.');
    }

    if (errorMessage.contains('429')) {
      return Exception('Đã vượt quá giới hạn requests cho $provider API.');
    }

    if (errorMessage.contains('500')) {
      return Exception('Lỗi server của $provider API.');
    }

    return Exception('Lỗi kết nối đến $provider API: $errorMessage');
  }
}
