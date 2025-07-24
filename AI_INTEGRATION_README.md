# Tích hợp AI vào Omi Health

## Tổng quan

Đã thành công tích hợp AI thực tế vào ứng dụng Omi Health, thay thế các phản hồi giả lập bằng các AI model thật từ các nhà cung cấp hàng đầu.

## Các AI Provider được hỗ trợ

### 1. OpenAI GPT
- **Model**: GPT-3.5-turbo
- **Ưu điểm**: Mạnh mẽ, đa năng, phản hồi chất lượng cao
- **Yêu cầu**: API key từ platform.openai.com
- **Chi phí**: Trả phí theo usage

### 2. Google Gemini
- **Model**: Gemini Pro
- **Ưu điểm**: Miễn phí với giới hạn, tốc độ nhanh
- **Yêu cầu**: API key từ makersuite.google.com
- **Chi phí**: Miễn phí với quota hạn chế

### 3. Anthropic Claude
- **Model**: Claude-3-haiku
- **Ưu điểm**: Tốt cho phân tích, an toàn
- **Yêu cầu**: API key từ console.anthropic.com
- **Chi phí**: Trả phí theo usage

### 4. Ollama (Local AI)
- **Model**: Llama2 (có thể thay đổi)
- **Ưu điểm**: Chạy offline, miễn phí, riêng tư
- **Yêu cầu**: Cài đặt Ollama trên máy local
- **Chi phí**: Miễn phí

## Cách sử dụng

### 1. Cài đặt AI Provider

1. Mở ứng dụng Omi Health
2. Vào **Settings** > **AI Settings** (cần thêm vào menu)
3. Chọn AI provider muốn sử dụng
4. Nhập API key (nếu cần)
5. Kiểm tra kết nối
6. Lưu cài đặt

### 2. Sử dụng AI Chatbot

1. Vào tab **AI Assistant**
2. Chọn tab **Chat với AI**
3. Gõ câu hỏi về sức khỏe
4. AI sẽ phản hồi dựa trên model đã chọn

### 3. Fallback System

Nếu AI API không khả dụng:
- Hệ thống sẽ tự động chuyển sang phản hồi dự phòng
- Vẫn cung cấp thông tin cơ bản về sức khỏe
- Không làm gián đoạn trải nghiệm người dùng

## Cấu hình cho Developer

### 1. Thêm AI Settings vào Menu

Cần thêm link đến `AISettingsScreen` trong menu settings:

```dart
// Trong settings screen
ListTile(
  leading: Icon(Icons.smart_toy),
  title: Text('Cài đặt AI'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AISettingsScreen()),
    );
  },
),
```

### 2. Cấu hình API Keys

API keys được lưu trong SharedPreferences với format:
- `api_key_openai`: OpenAI API key
- `api_key_gemini`: Gemini API key  
- `api_key_claude`: Claude API key
- `ai_provider`: Index của provider được chọn

### 3. Tùy chỉnh System Prompt

Có thể chỉnh sửa system prompt trong `lib/config/ai_config.dart`:

```dart
static const String healthSystemPrompt = '''
Bạn là một trợ lý AI chuyên về sức khỏe...
''';
```

## Bảo mật

- API keys được lưu trữ cục bộ trên thiết bị
- Không gửi dữ liệu nhạy cảm lên server
- Hỗ trợ Ollama để chạy AI hoàn toàn offline

## Xử lý lỗi

- Timeout: Tự động retry hoặc fallback
- API key không hợp lệ: Thông báo và chuyển fallback
- Quota vượt quá: Thông báo và gợi ý thay đổi provider
- Mất kết nối: Sử dụng phản hồi dự phòng

## Tối ưu hóa

### 1. Caching
- Có thể thêm cache cho các câu hỏi thường gặp
- Giảm số lượng API calls

### 2. Rate Limiting
- Thêm giới hạn số requests per minute
- Tránh vượt quota

### 3. Streaming Response
- Có thể implement streaming cho phản hồi dài
- Cải thiện UX

## Troubleshooting

### Lỗi thường gặp:

1. **"API key không hợp lệ"**
   - Kiểm tra API key đã nhập đúng
   - Đảm bảo API key còn hiệu lực

2. **"Timeout khi kết nối"**
   - Kiểm tra kết nối internet
   - Thử lại sau vài phút

3. **"Vượt quá giới hạn requests"**
   - Đợi reset quota
   - Chuyển sang provider khác

4. **Ollama không hoạt động**
   - Đảm bảo Ollama đang chạy: `ollama serve`
   - Kiểm tra port 11434 có mở không

## Phát triển tiếp

### Tính năng có thể thêm:

1. **Voice Input/Output**
   - Speech-to-text cho input
   - Text-to-speech cho output

2. **Personalized AI**
   - Training trên dữ liệu cá nhân
   - Context awareness

3. **Multi-language Support**
   - Hỗ trợ nhiều ngôn ngữ
   - Auto-detect language

4. **Advanced Analytics**
   - AI-powered health insights
   - Predictive analytics

## Kết luận

Việc tích hợp AI thực tế đã nâng cao đáng kể chất lượng phản hồi của chatbot, mang lại trải nghiệm tốt hơn cho người dùng trong việc tư vấn sức khỏe.
