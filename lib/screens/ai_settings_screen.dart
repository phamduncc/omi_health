import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/ai_config.dart';
import '../services/ai_service.dart';

class AISettingsScreen extends StatefulWidget {
  const AISettingsScreen({super.key});

  @override
  State<AISettingsScreen> createState() => _AISettingsScreenState();
}

class _AISettingsScreenState extends State<AISettingsScreen> {
  AIProvider _selectedProvider = AIConfig.defaultProvider;
  final Map<AIProvider, TextEditingController> _apiKeyControllers = {};
  bool _isLoading = false;
  bool _testingConnection = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadSettings();
  }

  void _initializeControllers() {
    for (final provider in AIProvider.values) {
      _apiKeyControllers[provider] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final controller in _apiKeyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load selected provider
      final providerIndex = prefs.getInt('ai_provider') ?? AIConfig.defaultProvider.index;
      _selectedProvider = AIProvider.values[providerIndex];
      
      // Load API keys
      for (final provider in AIProvider.values) {
        final key = prefs.getString('api_key_${provider.name}') ?? '';
        _apiKeyControllers[provider]?.text = key;
      }
      
    } catch (e) {
      _showSnackBar('Lỗi khi tải cài đặt: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save selected provider
      await prefs.setInt('ai_provider', _selectedProvider.index);
      
      // Save API keys
      for (final provider in AIProvider.values) {
        final key = _apiKeyControllers[provider]?.text ?? '';
        await prefs.setString('api_key_${provider.name}', key);
      }
      
      // Update AI service
      AIService().setProvider(_selectedProvider);
      
      _showSnackBar('Đã lưu cài đặt thành công!');
      
    } catch (e) {
      _showSnackBar('Lỗi khi lưu cài đặt: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _testingConnection = true;
      _testResult = null;
    });

    try {
      final aiService = AIService();
      aiService.setProvider(_selectedProvider);
      
      final response = await aiService.askHealthQuestion('Xin chào, bạn có thể giúp tôi về sức khỏe không?');
      
      setState(() {
        _testResult = 'Kết nối thành công! AI đã phản hồi: "${response.substring(0, response.length > 100 ? 100 : response.length)}..."';
      });
      
    } catch (e) {
      setState(() {
        _testResult = 'Kết nối thất bại: $e';
      });
    } finally {
      setState(() => _testingConnection = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt AI'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              onPressed: _saveSettings,
              icon: const Icon(Icons.save),
              tooltip: 'Lưu cài đặt',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProviderSelection(),
                  const SizedBox(height: 24),
                  _buildApiKeyInput(),
                  const SizedBox(height: 24),
                  _buildTestConnection(),
                  const SizedBox(height: 24),
                  _buildInstructions(),
                ],
              ),
            ),
    );
  }

  Widget _buildProviderSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chọn AI Provider',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...AIProvider.values.map((provider) => RadioListTile<AIProvider>(
              title: Text(provider.name),
              subtitle: Text(_getProviderDescription(provider)),
              value: provider,
              groupValue: _selectedProvider,
              onChanged: (value) {
                setState(() {
                  _selectedProvider = value!;
                });
              },
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildApiKeyInput() {
    if (!_selectedProvider.requiresApiKey) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.info, color: Colors.blue, size: 48),
              const SizedBox(height: 8),
              Text(
                '${_selectedProvider.name} không cần API key',
                style: const TextStyle(fontSize: 16),
              ),
              const Text(
                'Đảm bảo Ollama đang chạy trên localhost:11434',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'API Key cho ${_selectedProvider.name}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _apiKeyControllers[_selectedProvider],
              decoration: InputDecoration(
                labelText: 'Nhập API Key',
                hintText: 'sk-...',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.visibility),
                  onPressed: () {
                    // Toggle password visibility
                  },
                ),
              ),
              obscureText: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestConnection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kiểm tra kết nối',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _testingConnection ? null : _testConnection,
              icon: _testingConnection
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.wifi_tethering),
              label: Text(_testingConnection ? 'Đang kiểm tra...' : 'Kiểm tra kết nối'),
            ),
            if (_testResult != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _testResult!.contains('thành công') 
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _testResult!.contains('thành công') 
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
                child: Text(_testResult!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hướng dẫn',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('• OpenAI: Tạo API key tại platform.openai.com'),
            const Text('• Gemini: Tạo API key tại makersuite.google.com'),
            const Text('• Claude: Tạo API key tại console.anthropic.com'),
            const Text('• Ollama: Cài đặt và chạy Ollama locally'),
            const SizedBox(height: 8),
            const Text(
              'Lưu ý: API keys sẽ được lưu trữ cục bộ trên thiết bị của bạn.',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getProviderDescription(AIProvider provider) {
    switch (provider) {
      case AIProvider.openai:
        return 'GPT-3.5/4 - Mạnh mẽ và đa năng';
      case AIProvider.gemini:
        return 'Google AI - Miễn phí với giới hạn';
      case AIProvider.claude:
        return 'Anthropic - Tốt cho phân tích';
      case AIProvider.ollama:
        return 'Local AI - Chạy offline, miễn phí';
    }
  }
}
