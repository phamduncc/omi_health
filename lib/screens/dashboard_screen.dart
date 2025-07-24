import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/health_data.dart';
import '../models/health_goal.dart';
import '../services/storage_service.dart';
import '../services/goal_service.dart';
import '../services/notification_service.dart';
import '../widgets/result_card.dart';
import '../widgets/notification_banner.dart';
import '../widgets/real_time_progress_widget.dart';
import '../widgets/quick_utilities_widget.dart';
import 'history_screen.dart';
import 'charts_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  HealthData? _latestData;
  List<HealthData> _recentHistory = [];
  List<HealthGoal> _activeGoals = [];
  bool _isLoading = true;
  bool _showNotification = false;
  NotificationType? _notificationType;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final latest = await StorageService.getLatestData();
    final history = await StorageService.getHistory();

    // Cập nhật current values cho mục tiêu nếu có dữ liệu mới nhất
    if (latest != null) {
      await GoalService.updateCurrentValues(latest);
    }

    final activeGoals = await GoalService.getActiveGoals();

    // Kiểm tra notifications
    bool showNotification = false;
    NotificationType? notificationType;

    for (final type in NotificationType.values) {
      if (await NotificationService.shouldShowNotification(type)) {
        showNotification = true;
        notificationType = type;
        break;
      }
    }

    setState(() {
      _latestData = latest;
      _recentHistory = history.length > 7 ? history.sublist(history.length - 7) : history;
      _activeGoals = activeGoals;
      _showNotification = showNotification;
      _notificationType = notificationType;
      _isLoading = false;
    });
  }

  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) return const Color(0xFF3498DB);
    if (bmi < 25) return const Color(0xFF2ECC71);
    if (bmi < 30) return const Color(0xFFF39C12);
    return const Color(0xFFE74C3C);
  }

  Color _getColorFromHex(String hexColor) {
    final hex = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  List<FlSpot> _getWeightTrendData() {
    if (_recentHistory.length < 2) return [];
    return _recentHistory.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.weight);
    }).toList();
  }

  String _getHealthStatus() {
    if (_latestData == null) return 'Chưa có dữ liệu';
    
    final bmi = _latestData!.bmi;
    if (bmi < 18.5) return 'Cần tăng cân';
    if (bmi < 25) return 'Sức khỏe tốt';
    if (bmi < 30) return 'Cần giảm cân';
    return 'Cần chú ý sức khỏe';
  }

  IconData _getHealthStatusIcon() {
    if (_latestData == null) return Icons.help_outline;
    
    final bmi = _latestData!.bmi;
    if (bmi < 18.5) return Icons.trending_up;
    if (bmi < 25) return Icons.favorite;
    if (bmi < 30) return Icons.trending_down;
    return Icons.warning;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tổng quan sức khỏe'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Notification Banner
                    if (_showNotification && _notificationType != null)
                      NotificationBanner(
                        type: _notificationType!,
                        onDismiss: () {
                          setState(() {
                            _showNotification = false;
                          });
                        },
                      ),
                    // Welcome Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF3498DB), Color(0xFF2980B9)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3498DB).withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _getHealthStatusIcon(),
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Chào bạn!',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      _getHealthStatus(),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (_latestData != null) ...[
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildQuickStat(
                                    'BMI',
                                    _latestData!.bmi.toStringAsFixed(1),
                                    _latestData!.bmiCategory,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildQuickStat(
                                    'Cân nặng',
                                    '${_latestData!.weight.toStringAsFixed(1)} kg',
                                    'Hiện tại',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    if (_latestData == null) ...[
                      // No Data State
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.analytics_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Chưa có dữ liệu sức khỏe',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Hãy tính toán BMI để xem tổng quan sức khỏe của bạn',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Health Metrics
                      Row(
                        children: [
                          const Text(
                            'Chỉ số sức khỏe',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ChartsScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.bar_chart, size: 16),
                            label: const Text('Biểu đồ'),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const HistoryScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.history, size: 16),
                            label: const Text('Lịch sử'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // BMI Card
                      ResultCard(
                        title: 'Chỉ số BMI',
                        value: _latestData!.bmi.toStringAsFixed(1),
                        subtitle: _latestData!.bmiCategory,
                        color: _getBMIColor(_latestData!.bmi),
                        icon: Icons.monitor_weight,
                        description: 'Cập nhật: ${_latestData!.timestamp.day}/${_latestData!.timestamp.month}/${_latestData!.timestamp.year}',
                      ),

                      // Quick Stats Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              'BMR',
                              '${_latestData!.bmr.toStringAsFixed(0)} kcal',
                              'Trao đổi chất cơ bản',
                              Icons.local_fire_department,
                              const Color(0xFF9B59B6),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricCard(
                              'TDEE',
                              '${_latestData!.tdee.toStringAsFixed(0)} kcal',
                              'Năng lượng hàng ngày',
                              Icons.restaurant,
                              const Color(0xFFE67E22),
                            ),
                          ),
                        ],
                      ),

                      // Additional Health Metrics (if available)
                      if (_latestData!.whr != null || _latestData!.bodyFatPercentage != null) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            if (_latestData!.whr != null) ...[
                              Expanded(
                                child: _buildMetricCard(
                                  'WHR',
                                  _latestData!.whr!.toStringAsFixed(2),
                                  _latestData!.whrCategory ?? 'Không xác định',
                                  Icons.straighten,
                                  _getColorFromHex(_latestData!.whrCategoryColor ?? '#95a5a6'),
                                ),
                              ),
                              if (_latestData!.bodyFatPercentage != null) const SizedBox(width: 12),
                            ],
                            if (_latestData!.bodyFatPercentage != null) ...[
                              Expanded(
                                child: _buildMetricCard(
                                  'Mỡ cơ thể',
                                  '${_latestData!.bodyFatPercentage!.toStringAsFixed(1)}%',
                                  _latestData!.bodyFatCategory ?? 'Không xác định',
                                  Icons.pie_chart,
                                  _getColorFromHex(_latestData!.bodyFatCategoryColor ?? '#95a5a6'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Quick Utilities Widget
                      const QuickUtilitiesWidget(),

                      const SizedBox(height: 24),

                      // Real-time Progress Widget
                      const RealTimeProgressWidget(
                        showHeader: true,
                        showSummary: true,
                        maxGoalsToShow: 3,
                      ),

                      const SizedBox(height: 24),

                      // Active Goals Section
                      if (_activeGoals.isNotEmpty) ...[
                        Row(
                          children: [
                            const Text(
                              'Mục tiêu đang thực hiện',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${_activeGoals.length} mục tiêu',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _activeGoals.length,
                            itemBuilder: (context, index) {
                              final goal = _activeGoals[index];
                              return _buildGoalCard(goal);
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Weight Trend Chart
                      if (_recentHistory.length >= 2) ...[
                        const Text(
                          'Xu hướng cân nặng (7 ngày gần nhất)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 200,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: 5,
                                getDrawingHorizontalLine: (value) {
                                  return FlLine(
                                    color: Colors.grey[200]!,
                                    strokeWidth: 1,
                                  );
                                },
                              ),
                              titlesData: const FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: _getWeightTrendData(),
                                  isCurved: true,
                                  color: const Color(0xFF3498DB),
                                  barWidth: 3,
                                  dotData: FlDotData(
                                    show: true,
                                    getDotPainter: (spot, percent, barData, index) {
                                      return FlDotCirclePainter(
                                        radius: 4,
                                        color: const Color(0xFF3498DB),
                                        strokeWidth: 2,
                                        strokeColor: Colors.white,
                                      );
                                    },
                                  ),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: const Color(0xFF3498DB).withValues(alpha: 0.1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildQuickStat(String title, String value, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(HealthGoal goal) {
    final color = _getGoalColor(goal);
    final progress = goal.progressPercentage / 100;

    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getGoalIcon(goal),
                color: color,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  goal.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${goal.progressPercentage.toStringAsFixed(1)}% hoàn thành',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
          ),
          const SizedBox(height: 8),
          Text(
            '${goal.daysRemaining} ngày còn lại',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Color _getGoalColor(HealthGoal goal) {
    switch (goal.type) {
      case GoalType.weightLoss:
        return const Color(0xFFE74C3C);
      case GoalType.weightGain:
        return const Color(0xFF2ECC71);
      case GoalType.maintain:
        return const Color(0xFF3498DB);
      case GoalType.bmiTarget:
        return const Color(0xFF9B59B6);
    }
  }

  IconData _getGoalIcon(HealthGoal goal) {
    switch (goal.type) {
      case GoalType.weightLoss:
        return Icons.trending_down;
      case GoalType.weightGain:
        return Icons.trending_up;
      case GoalType.maintain:
        return Icons.trending_flat;
      case GoalType.bmiTarget:
        return Icons.flag;
    }
  }
}
