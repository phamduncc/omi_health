import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/health_goal.dart';
import '../models/health_data.dart';
import '../services/goal_service.dart';
import '../services/storage_service.dart';

class GoalDetailScreen extends StatefulWidget {
  final HealthGoal goal;

  const GoalDetailScreen({super.key, required this.goal});

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  late HealthGoal _goal;
  List<Map<String, dynamic>> _progressHistory = [];
  List<HealthData> _healthHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _goal = widget.goal;
    _loadData();
  }

  Future<void> _loadData() async {
    final progressHistory = await GoalService.getGoalProgress(_goal.id);
    final healthHistory = await StorageService.getHistory();
    final updatedGoal = await GoalService.getGoalById(_goal.id);

    setState(() {
      _progressHistory = progressHistory;
      _healthHistory = healthHistory;
      if (updatedGoal != null) _goal = updatedGoal;
      _isLoading = false;
    });
  }

  Color _getGoalColor() {
    switch (_goal.type) {
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

  IconData _getGoalIcon() {
    switch (_goal.type) {
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

  List<FlSpot> _getProgressChartData() {
    if (_progressHistory.length < 2) return [];
    
    return _progressHistory.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value['progress']?.toDouble() ?? 0);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final color = _getGoalColor();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_goal.title),
        actions: [
          if (_goal.progressPercentage < 100)
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              onPressed: _markCompleted,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Goal Overview Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [color, color.withValues(alpha: 0.8)],
                      ),
                      borderRadius: BorderRadius.circular(20),
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
                                _getGoalIcon(),
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _goal.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    _goal.description,
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
                        const SizedBox(height: 24),
                        
                        // Progress
                        Text(
                          'Tiến độ: ${_goal.progressPercentage.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: _goal.progressPercentage / 100,
                          backgroundColor: Colors.white.withValues(alpha: 0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          minHeight: 8,
                        ),
                        const SizedBox(height: 16),
                        
                        // Stats Row
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Hiện tại',
                                _goal.type == GoalType.bmiTarget 
                                    ? _goal.currentValue.toStringAsFixed(1)
                                    : '${_goal.currentValue.toStringAsFixed(1)} kg',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(
                                'Mục tiêu',
                                _goal.type == GoalType.bmiTarget 
                                    ? _goal.targetValue.toStringAsFixed(1)
                                    : '${_goal.targetValue.toStringAsFixed(1)} kg',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(
                                'Còn lại',
                                '${_goal.daysRemaining} ngày',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Progress Chart
                  if (_progressHistory.length >= 2) ...[
                    const Text(
                      'Biểu đồ tiến độ',
                      style: TextStyle(
                        fontSize: 20,
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
                            horizontalInterval: 25,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: Colors.grey[200]!,
                                strokeWidth: 1,
                              );
                            },
                          ),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: _getProgressChartData(),
                              isCurved: true,
                              color: color,
                              barWidth: 3,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) {
                                  return FlDotCirclePainter(
                                    radius: 4,
                                    color: color,
                                    strokeWidth: 2,
                                    strokeColor: Colors.white,
                                  );
                                },
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                color: color.withValues(alpha: 0.1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Goal Details
                  const Text(
                    'Chi tiết mục tiêu',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Container(
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
                    child: Column(
                      children: [
                        _buildDetailRow('Ngày bắt đầu', 
                          '${_goal.startDate.day}/${_goal.startDate.month}/${_goal.startDate.year}'),
                        _buildDetailRow('Ngày kết thúc dự kiến', 
                          '${_goal.targetDate.day}/${_goal.targetDate.month}/${_goal.targetDate.year}'),
                        _buildDetailRow('Trạng thái', _goal.status),
                        if (_goal.completedDate != null)
                          _buildDetailRow('Ngày hoàn thành', 
                            '${_goal.completedDate!.day}/${_goal.completedDate!.month}/${_goal.completedDate!.year}'),
                        if (_goal.notes != null && _goal.notes!.isNotEmpty)
                          _buildDetailRow('Ghi chú', _goal.notes!),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Tips Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lightbulb, color: color),
                            const SizedBox(width: 8),
                            Text(
                              'Lời khuyên',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _getGoalTips(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getGoalTips() {
    switch (_goal.type) {
      case GoalType.weightLoss:
        return 'Để giảm cân hiệu quả:\n• Tạo thâm hụt calories 500-750 kcal/ngày\n• Ăn nhiều protein và chất xơ\n• Tập cardio 150 phút/tuần\n• Uống đủ nước và ngủ đủ giấc';
      case GoalType.weightGain:
        return 'Để tăng cân lành mạnh:\n• Tăng 300-500 calories/ngày\n• Ăn nhiều bữa nhỏ trong ngày\n• Tập tạ để tăng cơ bắp\n• Chọn thực phẩm giàu dinh dưỡng';
      case GoalType.maintain:
        return 'Để duy trì cân nặng:\n• Cân bằng calories vào và ra\n• Theo dõi cân nặng hàng tuần\n• Duy trì thói quen ăn uống lành mạnh\n• Tập thể dục đều đặn';
      case GoalType.bmiTarget:
        return 'Để đạt BMI mục tiêu:\n• Kết hợp chế độ ăn và vận động\n• Theo dõi tiến độ thường xuyên\n• Kiên nhẫn và nhất quán\n• Tham khảo ý kiến chuyên gia nếu cần';
    }
  }

  void _markCompleted() async {
    final completedGoal = _goal.copyWith(
      isActive: false,
      completedDate: DateTime.now(),
    );
    await GoalService.updateGoal(completedGoal);
    
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chúc mừng! Bạn đã hoàn thành mục tiêu'),
          backgroundColor: Color(0xFF2ECC71),
        ),
      );
    }
  }
}
