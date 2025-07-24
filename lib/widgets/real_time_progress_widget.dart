import 'package:flutter/material.dart';
import '../services/goal_progress_service.dart';
import '../models/health_goal.dart';

class RealTimeProgressWidget extends StatefulWidget {
  final bool showHeader;
  final bool showSummary;
  final int maxGoalsToShow;

  const RealTimeProgressWidget({
    super.key,
    this.showHeader = true,
    this.showSummary = true,
    this.maxGoalsToShow = 3,
  });

  @override
  State<RealTimeProgressWidget> createState() => _RealTimeProgressWidgetState();
}

class _RealTimeProgressWidgetState extends State<RealTimeProgressWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: GoalProgressService(),
      builder: (context, child) {
        final service = GoalProgressService();
        final activeGoals = service.activeGoals;
        final summary = service.progressSummary;

        if (activeGoals.isEmpty && !widget.showSummary) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.all(16),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.showHeader) _buildHeader(service),
              if (widget.showSummary) _buildSummary(summary),
              if (activeGoals.isNotEmpty) _buildGoalsList(activeGoals),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(GoalProgressService service) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3498DB), Color(0xFF2980B9)],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: service.isUpdating ? _pulseAnimation.value : 1.0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    service.isUpdating ? Icons.sync : Icons.trending_up,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tiến độ mục tiêu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  service.isUpdating ? 'Đang cập nhật...' : 'Cập nhật liên tục',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (service.isUpdating)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummary(Map<String, dynamic> summary) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              'Tổng cộng',
              '${summary['totalGoals']}',
              Icons.flag,
              const Color(0xFF3498DB),
            ),
          ),
          Expanded(
            child: _buildSummaryItem(
              'Đang thực hiện',
              '${summary['activeGoals']}',
              Icons.play_arrow,
              const Color(0xFFF39C12),
            ),
          ),
          Expanded(
            child: _buildSummaryItem(
              'Hoàn thành',
              '${summary['completedGoals']}',
              Icons.check_circle,
              const Color(0xFF2ECC71),
            ),
          ),
          Expanded(
            child: _buildSummaryItem(
              'Tiến độ TB',
              '${summary['averageProgress'].toStringAsFixed(0)}%',
              Icons.trending_up,
              const Color(0xFF9B59B6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsList(List<HealthGoal> goals) {
    final goalsToShow = goals.take(widget.maxGoalsToShow).toList();
    
    return Column(
      children: [
        const Divider(height: 1),
        ...goalsToShow.map((goal) => _buildGoalItem(goal)),
        if (goals.length > widget.maxGoalsToShow)
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              'và ${goals.length - widget.maxGoalsToShow} mục tiêu khác...',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGoalItem(HealthGoal goal) {
    final color = _getGoalColor(goal);
    final progress = goal.progressPercentage / 100;
    final isOverdue = DateTime.now().isAfter(goal.targetDate) && goal.isActive;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: color,
            width: 3,
          ),
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
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isOverdue ? Colors.red[700] : const Color(0xFF2C3E50),
                  ),
                ),
              ),
              if (isOverdue)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Quá hạn',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.red[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${goal.progressPercentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Thông tin chi tiết về giá trị
          Row(
            children: [
              Expanded(
                child: Text(
                  _getGoalValueText(goal),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              Text(
                goal.daysRemaining > 0
                  ? '${goal.daysRemaining} ngày còn lại'
                  : 'Đã quá hạn ${-goal.daysRemaining} ngày',
                style: TextStyle(
                  fontSize: 11,
                  color: goal.daysRemaining > 0 ? Colors.grey[600] : Colors.red[600],
                  fontWeight: goal.daysRemaining <= 0 ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                ),
              ),
            ],
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

  String _getGoalValueText(HealthGoal goal) {
    switch (goal.type) {
      case GoalType.weightLoss:
        return 'Hiện tại: ${goal.currentValue.toStringAsFixed(1)}kg → Mục tiêu: ${goal.targetValue.toStringAsFixed(1)}kg';
      case GoalType.weightGain:
        return 'Hiện tại: ${goal.currentValue.toStringAsFixed(1)}kg → Mục tiêu: ${goal.targetValue.toStringAsFixed(1)}kg';
      case GoalType.maintain:
        return 'Duy trì: ${goal.targetValue.toStringAsFixed(1)}kg (±1kg) | Hiện tại: ${goal.currentValue.toStringAsFixed(1)}kg';
      case GoalType.bmiTarget:
        return 'BMI hiện tại: ${goal.currentValue.toStringAsFixed(1)} → Mục tiêu: ${goal.targetValue.toStringAsFixed(1)}';
    }
  }
}
