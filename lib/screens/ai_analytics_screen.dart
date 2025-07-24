import 'package:flutter/material.dart';
import '../services/ai_analytics_service.dart';

class AIAnalyticsScreen extends StatefulWidget {
  const AIAnalyticsScreen({super.key});

  @override
  State<AIAnalyticsScreen> createState() => _AIAnalyticsScreenState();
}

class _AIAnalyticsScreenState extends State<AIAnalyticsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  HealthTrendAnalysis? _trendAnalysis;
  List<HealthRisk>? _healthRisks;
  bool _isLoadingTrends = false;
  bool _isLoadingRisks = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    await Future.wait([
      _loadTrendAnalysis(),
      _loadHealthRisks(),
    ]);
  }

  Future<void> _loadTrendAnalysis() async {
    setState(() {
      _isLoadingTrends = true;
    });

    try {
      final analysis = await AIAnalyticsService.analyzeHealthTrends();
      setState(() {
        _trendAnalysis = analysis;
        _isLoadingTrends = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingTrends = false;
      });
    }
  }

  Future<void> _loadHealthRisks() async {
    setState(() {
      _isLoadingRisks = true;
    });

    try {
      final risks = await AIAnalyticsService.analyzeHealthRisks();
      setState(() {
        _healthRisks = risks;
        _isLoadingRisks = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingRisks = false;
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
                color: Colors.purple[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.analytics, color: Colors.purple[700], size: 20),
            ),
            const SizedBox(width: 8),
            const Text('AI Analytics'),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Xu hướng', icon: Icon(Icons.trending_up, size: 16)),
            Tab(text: 'Rủi ro', icon: Icon(Icons.warning, size: 16)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTrendsTab(),
          _buildRisksTab(),
        ],
      ),
    );
  }

  Widget _buildTrendsTab() {
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
                colors: [Colors.purple[400]!, Colors.blue[400]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.trending_up, color: Colors.white, size: 24),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Phân tích xu hướng AI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Dự đoán và phân tích dựa trên dữ liệu lịch sử',
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

          if (_isLoadingTrends)
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('AI đang phân tích xu hướng...'),
                ],
              ),
            )
          else if (_trendAnalysis != null)
            _buildTrendContent()
          else
            _buildNoTrendData(),
        ],
      ),
    );
  }

  Widget _buildTrendContent() {
    final analysis = _trendAnalysis!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overall Health Status
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _getHealthStatusColor(analysis.overallHealth).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getHealthStatusColor(analysis.overallHealth).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _getHealthStatusIcon(analysis.overallHealth),
                color: _getHealthStatusColor(analysis.overallHealth),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tình trạng sức khỏe: ${_getHealthStatusText(analysis.overallHealth)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getHealthStatusColor(analysis.overallHealth),
                      ),
                    ),
                    Text(
                      'Độ tin cậy: ${(analysis.confidence * 100).toStringAsFixed(0)}%',
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

        // Analysis Summary
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.analytics, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Phân tích tổng quan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(analysis.analysisText),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Trend Cards
        Row(
          children: [
            Expanded(
              child: _buildTrendCard(
                'Cân nặng',
                analysis.weightTrend,
                Icons.monitor_weight,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTrendCard(
                'BMI',
                analysis.bmiTrend,
                Icons.straighten,
                Colors.green,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        _buildTrendCard(
          'Hoạt động',
          analysis.activityTrend,
          Icons.directions_run,
          Colors.orange,
          isFullWidth: true,
        ),

        const SizedBox(height: 16),

        // Predictions
        if (analysis.predictions.isNotEmpty) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.psychology, color: Colors.purple),
                      SizedBox(width: 8),
                      Text(
                        'Dự đoán AI',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...analysis.predictions.map((prediction) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.purple[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prediction.description,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Độ tin cậy: ${(prediction.confidence * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTrendCard(
    String title,
    TrendDirection trend,
    IconData icon,
    Color color, {
    bool isFullWidth = false,
  }) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getTrendIcon(trend),
                color: _getTrendColor(trend),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                _getTrendText(trend),
                style: TextStyle(
                  fontSize: 12,
                  color: _getTrendColor(trend),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoTrendData() {
    return const Center(
      child: Column(
        children: [
          Icon(Icons.trending_up, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Chưa có đủ dữ liệu để phân tích xu hướng',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Cần ít nhất 7 ngày dữ liệu để AI có thể phân tích',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRisksTab() {
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
                colors: [Colors.red[400]!, Colors.orange[400]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning, color: Colors.white, size: 24),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Phân tích rủi ro sức khỏe',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'AI đánh giá các yếu tố rủi ro tiềm ẩn',
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

          if (_isLoadingRisks)
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('AI đang phân tích rủi ro...'),
                ],
              ),
            )
          else if (_healthRisks != null)
            _buildRisksContent()
          else
            _buildNoRiskData(),
        ],
      ),
    );
  }

  Widget _buildRisksContent() {
    final risks = _healthRisks!;

    if (risks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green[200]!),
        ),
        child: const Column(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 48),
            SizedBox(height: 12),
            Text(
              'Tuyệt vời! Không phát hiện rủi ro nào',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Hãy tiếp tục duy trì lối sống lành mạnh',
              style: TextStyle(color: Colors.green),
            ),
          ],
        ),
      );
    }

    return Column(
      children: risks.map((risk) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: risk.level.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: risk.level.color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getRiskIcon(risk.type),
                  color: risk.level.color,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Rủi ro ${risk.level.name}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: risk.level.color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              risk.description,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb, color: Colors.blue[700], size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      risk.recommendation,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildNoRiskData() {
    return const Center(
      child: Column(
        children: [
          Icon(Icons.warning, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Chưa có đủ dữ liệu để phân tích rủi ro',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Hãy nhập thông tin sức khỏe để AI có thể đánh giá',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getHealthStatusColor(HealthStatus status) {
    switch (status) {
      case HealthStatus.excellent:
        return Colors.green;
      case HealthStatus.good:
        return Colors.lightGreen;
      case HealthStatus.fair:
        return Colors.orange;
      case HealthStatus.poor:
        return Colors.red;
      case HealthStatus.critical:
        return Colors.red[800]!;
      case HealthStatus.unknown:
        return Colors.grey;
    }
  }

  IconData _getHealthStatusIcon(HealthStatus status) {
    switch (status) {
      case HealthStatus.excellent:
        return Icons.favorite;
      case HealthStatus.good:
        return Icons.thumb_up;
      case HealthStatus.fair:
        return Icons.warning;
      case HealthStatus.poor:
        return Icons.error;
      case HealthStatus.critical:
        return Icons.dangerous;
      case HealthStatus.unknown:
        return Icons.help;
    }
  }

  String _getHealthStatusText(HealthStatus status) {
    switch (status) {
      case HealthStatus.excellent:
        return 'Xuất sắc';
      case HealthStatus.good:
        return 'Tốt';
      case HealthStatus.fair:
        return 'Trung bình';
      case HealthStatus.poor:
        return 'Kém';
      case HealthStatus.critical:
        return 'Nguy hiểm';
      case HealthStatus.unknown:
        return 'Chưa xác định';
    }
  }

  IconData _getTrendIcon(TrendDirection trend) {
    switch (trend) {
      case TrendDirection.increasing:
        return Icons.trending_up;
      case TrendDirection.decreasing:
        return Icons.trending_down;
      case TrendDirection.stable:
        return Icons.trending_flat;
    }
  }

  Color _getTrendColor(TrendDirection trend) {
    switch (trend) {
      case TrendDirection.increasing:
        return Colors.red;
      case TrendDirection.decreasing:
        return Colors.blue;
      case TrendDirection.stable:
        return Colors.green;
    }
  }

  String _getTrendText(TrendDirection trend) {
    switch (trend) {
      case TrendDirection.increasing:
        return 'Tăng';
      case TrendDirection.decreasing:
        return 'Giảm';
      case TrendDirection.stable:
        return 'Ổn định';
    }
  }

  IconData _getRiskIcon(RiskType type) {
    switch (type) {
      case RiskType.obesity:
        return Icons.warning;
      case RiskType.overweight:
        return Icons.scale;
      case RiskType.underweight:
        return Icons.trending_down;
      case RiskType.sedentary:
        return Icons.airline_seat_recline_extra;
      case RiskType.sleepDeprivation:
        return Icons.bedtime;
      case RiskType.dehydration:
        return Icons.water_drop;
    }
  }
}
