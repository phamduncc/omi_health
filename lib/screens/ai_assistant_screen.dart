import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../services/ai_chatbot_service.dart';
import '../services/storage_service.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  AIHealthInsight? _healthInsight;
  PersonalizedPlan? _personalizedPlan;
  bool _isLoadingInsight = false;
  bool _isLoadingPlan = false;
  
  final TextEditingController _questionController = TextEditingController();
  final AIChatbotService _chatbotService = AIChatbotService();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadHealthInsight();
    _initializeChatbot();
  }

  Future<void> _initializeChatbot() async {
    await _chatbotService.initialize();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _questionController.dispose();
    super.dispose();
  }



  Future<void> _loadHealthInsight() async {
    setState(() {
      _isLoadingInsight = true;
    });

    try {
      final insight = await AIService.analyzeHealthData();
      setState(() {
        _healthInsight = insight;
        _isLoadingInsight = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingInsight = false;
      });
    }
  }

  Future<void> _generatePersonalizedPlan() async {
    final userData = await StorageService.getLatestData();
    if (!mounted) return;

    if (userData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập dữ liệu sức khỏe trước')),
      );
      return;
    }

    setState(() {
      _isLoadingPlan = true;
    });

    try {
      final plan = await AIService.generatePersonalizedPlan(userData);
      setState(() {
        _personalizedPlan = plan;
        _isLoadingPlan = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingPlan = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.psychology, color: Colors.blue[700], size: 20),
            ),
            const SizedBox(width: 8),
            const Text('AI Health Assistant'),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Phân tích', icon: Icon(Icons.analytics, size: 16)),
            Tab(text: 'Kế hoạch', icon: Icon(Icons.assignment, size: 16)),
            Tab(text: 'Chat AI', icon: Icon(Icons.chat, size: 16)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAnalysisTab(),
          _buildPlanTab(),
          _buildChatTab(),
        ],
      ),
    );
  }

  Widget _buildAnalysisTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[400]!, Colors.purple[400]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.analytics, color: Colors.white, size: 24),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Phân tích AI thông minh',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Insights dựa trên dữ liệu sức khỏe của bạn',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          if (_isLoadingInsight)
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('AI đang phân tích dữ liệu...'),
                ],
              ),
            )
          else if (_healthInsight != null)
            _buildInsightContent()
          else
            _buildNoDataContent(),

          const SizedBox(height: 16),

          // Refresh button
          ElevatedButton.icon(
            onPressed: _loadHealthInsight,
            icon: const Icon(Icons.refresh),
            label: const Text('Phân tích lại'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightContent() {
    final insight = _healthInsight!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Risk Level Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: insight.riskLevel.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: insight.riskLevel.color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.health_and_safety,
                color: insight.riskLevel.color,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mức độ rủi ro: ${insight.riskLevel.name}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: insight.riskLevel.color,
                      ),
                    ),
                    Text(
                      'Độ tin cậy: ${(insight.confidence * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Summary
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.summarize, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Tóm tắt phân tích',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(insight.summary),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Activity Score
        if (insight.activityScore != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.score, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'Điểm hoạt động hôm nay',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: insight.activityScore! / 100,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            insight.activityScore! >= 70 ? Colors.green : 
                            insight.activityScore! >= 40 ? Colors.orange : Colors.red,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${insight.activityScore!.toStringAsFixed(0)}/100',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 16),

        // Recommendations
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lightbulb, color: Colors.orange),
                    SizedBox(width: 8),
                    Text(
                      'Gợi ý từ AI',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...insight.recommendations.map((rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(rec)),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoDataContent() {
    return const Center(
      child: Column(
        children: [
          Icon(Icons.data_usage, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Chưa có đủ dữ liệu để phân tích',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Hãy nhập thông tin sức khỏe để AI có thể phân tích',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPlanTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green[400]!, Colors.teal[400]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.assignment, color: Colors.white, size: 24),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kế hoạch cá nhân hóa',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'AI tạo kế hoạch phù hợp với bạn',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          if (_isLoadingPlan)
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('AI đang tạo kế hoạch...'),
                ],
              ),
            )
          else if (_personalizedPlan != null)
            _buildPlanContent()
          else
            _buildNoPlanContent(),

          const SizedBox(height: 16),

          // Generate plan button
          ElevatedButton.icon(
            onPressed: _generatePersonalizedPlan,
            icon: const Icon(Icons.auto_awesome),
            label: Text(_personalizedPlan == null ? 'Tạo kế hoạch AI' : 'Tạo lại kế hoạch'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanContent() {
    final plan = _personalizedPlan!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Weight Goal
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.flag, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Mục tiêu cân nặng',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(plan.weightGoal),
                const SizedBox(height: 8),
                Text(
                  'Calories mục tiêu: ${plan.calorieTarget} kcal/ngày',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Exercise Plan
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.fitness_center, color: Colors.orange),
                    SizedBox(width: 8),
                    Text(
                      'Kế hoạch tập luyện',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...plan.exercisePlan.map((exercise) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(exercise)),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Nutrition Tips
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.restaurant, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'Gợi ý dinh dưỡng',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...plan.nutritionTips.map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(tip)),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoPlanContent() {
    return const Center(
      child: Column(
        children: [
          Icon(Icons.assignment, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Chưa có kế hoạch cá nhân hóa',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Nhấn nút bên dưới để AI tạo kế hoạch cho bạn',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChatTab() {
    return Column(
      children: [
        // Chat messages
        Expanded(
          child: ListenableBuilder(
            listenable: _chatbotService,
            builder: (context, child) {
              final messages = _chatbotService.conversationHistory;
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  return _buildChatMessage(message);
                },
              );
            },
          ),
        ),

        // Typing indicator
        if (_isTyping)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('AI đang suy nghĩ...'),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Input field
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _questionController,
                  decoration: InputDecoration(
                    hintText: 'Hỏi AI về sức khỏe...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              FloatingActionButton(
                mini: true,
                onPressed: _sendMessage,
                child: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatMessage(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.psychology, color: Colors.blue[700], size: 20),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isUser ? Colors.blue[500] : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.person, color: Colors.blue[700], size: 20),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) return;

    setState(() {
      _isTyping = true;
    });

    _questionController.clear();

    try {
      await _chatbotService.sendMessage(question);
      setState(() {
        _isTyping = false;
      });
    } catch (e) {
      setState(() {
        _isTyping = false;
      });
    }
  }
}


