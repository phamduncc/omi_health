import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/health_goal.dart';
import '../models/health_data.dart';
import '../services/storage_service.dart';
import '../services/goal_service.dart';
import '../widgets/custom_input_field.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/real_time_progress_widget.dart';
import '../services/goal_progress_service.dart';
import 'goal_detail_screen.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  List<HealthGoal> _goals = [];
  HealthData? _currentData;
  bool _isLoading = true;
  List<HealthGoal> _newGoals = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Load current health data
    final currentData = await StorageService.getLatestData();

    // Load goals from storage
    final goals = await GoalService.getGoals();

    // Update current values and goal progress with latest health data
    if (currentData != null) {
      await GoalService.updateCurrentValues(currentData);
      await GoalService.updateGoalProgress();

      // Reload goals to get updated values
      final updatedGoals = await GoalService.getGoals();
      goals.clear();
      goals.addAll(updatedGoals);
    }

    // Tìm mục tiêu mới (được tạo trong 10 phút qua)
    final now = DateTime.now();
    final newGoals = goals.where((goal) {
      final timeDiff = now.difference(goal.startDate).inMinutes;
      return timeDiff <= 10 && goal.isActive;
    }).toList();

    setState(() {
      _currentData = currentData;
      _goals = goals;
      _newGoals = newGoals;
      _isLoading = false;
    });
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

  void _showCreateGoalDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreateGoalBottomSheet(
        currentData: _currentData,
        onGoalCreated: (goal) async {
          await GoalService.addGoal(goal);
          _loadData(); // Reload data to show new goal
        },
      ),
    );
  }

  void _showEditGoalDialog(HealthGoal goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditGoalBottomSheet(
        goal: goal,
        currentData: _currentData,
        onGoalUpdated: (updatedGoal) async {
          await GoalService.updateGoal(updatedGoal);
          _loadData();
        },
      ),
    );
  }

  void _showDeleteGoalDialog(HealthGoal goal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa mục tiêu'),
        content: Text('Bạn có chắc chắn muốn xóa mục tiêu "${goal.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await GoalService.deleteGoal(goal.id);
              _loadData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã xóa mục tiêu'),
                    backgroundColor: Color(0xFFE74C3C),
                  ),
                );
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Color(0xFFE74C3C))),
          ),
        ],
      ),
    );
  }

  void _markGoalCompleted(HealthGoal goal) async {
    final completedGoal = goal.copyWith(
      isActive: false,
      completedDate: DateTime.now(),
    );
    await GoalService.updateGoal(completedGoal);
    _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chúc mừng! Bạn đã hoàn thành mục tiêu'),
          backgroundColor: Color(0xFF2ECC71),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mục tiêu sức khỏe'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _currentData != null ? _showCreateGoalDialog : null,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentData == null
              ? _buildNoDataState()
              : _goals.isEmpty
                  ? _buildEmptyState()
                  : _buildGoalsList(),
      floatingActionButton: AnimatedBuilder(
        animation: GoalProgressService(),
        builder: (context, child) {
          final service = GoalProgressService();
          return FloatingActionButton(
            onPressed: service.isUpdating ? null : () async {
              await service.forceUpdate();
              _loadData();
            },
            backgroundColor: service.isUpdating
                ? Colors.grey[400]
                : const Color(0xFF3498DB),
            child: service.isUpdating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.refresh, color: Colors.white),
          );
        },
      ),
    );
  }

  Widget _buildNoDataState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flag_outlined,
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
              'Hãy tính toán BMI trước để đặt mục tiêu sức khỏe',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flag_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có mục tiêu nào',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy tạo mục tiêu đầu tiên để theo dõi tiến trình sức khỏe',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showCreateGoalDialog,
              icon: const Icon(Icons.add),
              label: const Text('Tạo mục tiêu'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3498DB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsList() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _goals.length + (_newGoals.isNotEmpty ? 3 : 2), // +1 for header, +1 for progress widget, +1 for new goals banner
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildHeader();
          }

          if (index == 1) {
            return const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: RealTimeProgressWidget(
                showHeader: true,
                showSummary: true,
                maxGoalsToShow: 5,
              ),
            );
          }

          if (_newGoals.isNotEmpty && index == 2) {
            return _buildNewGoalsBanner();
          }

          final goalIndex = _newGoals.isNotEmpty ? index - 3 : index - 2;
          final goal = _goals[goalIndex];
          return _buildGoalCard(goal);
        },
      ),
    );
  }

  Widget _buildHeader() {
    final activeGoals = _goals.where((g) => g.isActive).length;
    final completedGoals = _goals.where((g) => g.progressPercentage >= 100).length;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF9B59B6), Color(0xFF8E44AD)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tổng quan mục tiêu',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Đang thực hiện', activeGoals.toString()),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem('Đã hoàn thành', completedGoals.toString()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNewGoalsBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3498DB), Color(0xFF2980B9)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3498DB).withValues(alpha: 0.3),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _newGoals.length == 1
                          ? 'Mục tiêu mới đã được tạo!'
                          : '${_newGoals.length} mục tiêu mới đã được tạo!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Chúng tôi đã tự động tạo mục tiêu phù hợp dựa trên tiến độ của bạn',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _newGoals.clear();
                  });
                },
                icon: const Icon(
                  Icons.close,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...(_newGoals.take(2).map((goal) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _getGoalIcon(goal),
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    goal.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${goal.daysRemaining} ngày',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ))),
          if (_newGoals.length > 2)
            Container(
              padding: const EdgeInsets.all(8),
              child: Text(
                'và ${_newGoals.length - 2} mục tiêu khác...',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
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
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GoalDetailScreen(goal: goal),
            ),
          ).then((_) => _loadData()); // Reload when returning
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getGoalIcon(goal),
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      Text(
                        goal.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        goal.status,
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 20),
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _showEditGoalDialog(goal);
                            break;
                          case 'delete':
                            _showDeleteGoalDialog(goal);
                            break;
                          case 'complete':
                            _markGoalCompleted(goal);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 16),
                              SizedBox(width: 8),
                              Text('Chỉnh sửa'),
                            ],
                          ),
                        ),
                        if (goal.progressPercentage < 100)
                          const PopupMenuItem(
                            value: 'complete',
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, size: 16),
                                SizedBox(width: 8),
                                Text('Đánh dấu hoàn thành'),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 16, color: Color(0xFFE74C3C)),
                              SizedBox(width: 8),
                              Text('Xóa', style: TextStyle(color: Color(0xFFE74C3C))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tiến độ: ${goal.progressPercentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    Text(
                      'Còn ${goal.daysRemaining} ngày',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Goal Details
            Row(
              children: [
                Expanded(
                  child: _buildGoalDetailWithUpdate(
                    'Hiện tại',
                    goal.type == GoalType.bmiTarget
                        ? goal.currentValue.toStringAsFixed(1)
                        : '${goal.currentValue.toStringAsFixed(1)} kg',
                    showUpdateIndicator: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildGoalDetail(
                    'Mục tiêu',
                    goal.type == GoalType.bmiTarget 
                        ? goal.targetValue.toStringAsFixed(1)
                        : '${goal.targetValue.toStringAsFixed(1)} kg',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildGoalDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalDetailWithUpdate(String label, String value, {bool showUpdateIndicator = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
            if (showUpdateIndicator) ...[
              const SizedBox(width: 6),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF2ECC71),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            if (showUpdateIndicator) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF2ECC71).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Mới',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2ECC71),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _CreateGoalBottomSheet extends StatefulWidget {
  final HealthData? currentData;
  final Function(HealthGoal) onGoalCreated;

  const _CreateGoalBottomSheet({
    required this.currentData,
    required this.onGoalCreated,
  });

  @override
  State<_CreateGoalBottomSheet> createState() => _CreateGoalBottomSheetState();
}

class _CreateGoalBottomSheetState extends State<_CreateGoalBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  GoalType _selectedType = GoalType.weightLoss;
  final _targetController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _targetDate = DateTime.now().add(const Duration(days: 30));
  bool _isLoading = false;

  final List<String> _goalTypes = [
    'Giảm cân',
    'Tăng cân',
    'Duy trì cân nặng',
    'Đạt BMI mục tiêu',
  ];

  @override
  void initState() {
    super.initState();
    _updateGoalDefaults();
  }

  void _updateGoalDefaults() {
    if (widget.currentData == null) return;

    switch (_selectedType) {
      case GoalType.weightLoss:
        _titleController.text = 'Giảm cân lành mạnh';
        _descriptionController.text = 'Giảm cân an toàn và bền vững';
        _targetController.text = (widget.currentData!.weight - 5).toStringAsFixed(1);
        break;
      case GoalType.weightGain:
        _titleController.text = 'Tăng cân lành mạnh';
        _descriptionController.text = 'Tăng cân an toàn để đạt BMI bình thường';
        _targetController.text = (widget.currentData!.weight + 5).toStringAsFixed(1);
        break;
      case GoalType.maintain:
        _titleController.text = 'Duy trì cân nặng';
        _descriptionController.text = 'Duy trì cân nặng hiện tại';
        _targetController.text = widget.currentData!.weight.toStringAsFixed(1);
        break;
      case GoalType.bmiTarget:
        _titleController.text = 'BMI lý tưởng';
        _descriptionController.text = 'Đạt chỉ số BMI lý tưởng cho sức khỏe';
        _targetController.text = '22.0';
        break;
    }
  }

  String _getGoalTypeString(GoalType type) {
    switch (type) {
      case GoalType.weightLoss:
        return 'Giảm cân';
      case GoalType.weightGain:
        return 'Tăng cân';
      case GoalType.maintain:
        return 'Duy trì cân nặng';
      case GoalType.bmiTarget:
        return 'Đạt BMI mục tiêu';
    }
  }

  GoalType _getGoalTypeFromString(String typeString) {
    switch (typeString) {
      case 'Giảm cân':
        return GoalType.weightLoss;
      case 'Tăng cân':
        return GoalType.weightGain;
      case 'Duy trì cân nặng':
        return GoalType.maintain;
      case 'Đạt BMI mục tiêu':
        return GoalType.bmiTarget;
      default:
        return GoalType.weightLoss;
    }
  }

  String _getTargetUnit() {
    return _selectedType == GoalType.bmiTarget ? '' : 'kg';
  }

  String _getTargetHint() {
    switch (_selectedType) {
      case GoalType.weightLoss:
        return 'Cân nặng mục tiêu (kg)';
      case GoalType.weightGain:
        return 'Cân nặng mục tiêu (kg)';
      case GoalType.maintain:
        return 'Cân nặng duy trì (kg)';
      case GoalType.bmiTarget:
        return 'BMI mục tiêu (18.5-24.9)';
    }
  }

  Future<void> _createGoal() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.currentData == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final targetValue = double.parse(_targetController.text);
      final currentValue = _selectedType == GoalType.bmiTarget
          ? widget.currentData!.bmi
          : widget.currentData!.weight;

      final goal = HealthGoal(
        id: 'goal_${DateTime.now().millisecondsSinceEpoch}',
        type: _selectedType,
        targetValue: targetValue,
        currentValue: currentValue,
        startValue: currentValue,
        startDate: DateTime.now(),
        targetDate: _targetDate,
        title: _titleController.text,
        description: _descriptionController.text,
      );

      widget.onGoalCreated(goal);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Có lỗi xảy ra khi tạo mục tiêu'),
          backgroundColor: Color(0xFFE74C3C),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Tạo mục tiêu mới',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Goal Type Selection
                      CustomDropdown(
                        label: 'Loại mục tiêu',
                        value: _getGoalTypeString(_selectedType),
                        items: _goalTypes,
                        prefixIcon: Icons.flag,
                        onChanged: (value) {
                          setState(() {
                            _selectedType = _getGoalTypeFromString(value!);
                            _updateGoalDefaults();
                          });
                        },
                      ),

                      // Title
                      CustomInputField(
                        label: 'Tên mục tiêu',
                        hint: 'Nhập tên cho mục tiêu của bạn',
                        controller: _titleController,
                        prefixIcon: Icons.title,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập tên mục tiêu';
                          }
                          return null;
                        },
                      ),

                      // Target Value
                      CustomInputField(
                        label: 'Giá trị mục tiêu',
                        hint: _getTargetHint(),
                        controller: _targetController,
                        suffix: _getTargetUnit(),
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.track_changes,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập giá trị mục tiêu';
                          }
                          final target = double.tryParse(value);
                          if (target == null || target <= 0) {
                            return 'Giá trị không hợp lệ';
                          }

                          if (_selectedType == GoalType.bmiTarget) {
                            if (target < 15 || target > 35) {
                              return 'BMI phải trong khoảng 15-35';
                            }
                          } else {
                            if (target < 30 || target > 200) {
                              return 'Cân nặng phải trong khoảng 30-200kg';
                            }
                          }
                          return null;
                        },
                      ),

                      // Description
                      CustomInputField(
                        label: 'Mô tả',
                        hint: 'Mô tả chi tiết về mục tiêu',
                        controller: _descriptionController,
                        prefixIcon: Icons.description,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập mô tả';
                          }
                          return null;
                        },
                      ),

                      // Target Date
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ngày hoàn thành dự kiến',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _targetDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (date != null) {
                                  setState(() {
                                    _targetDate = date;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[200]!),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withValues(alpha: 0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today,
                                      color: Color(0xFF3498DB),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '${_targetDate.day}/${_targetDate.month}/${_targetDate.year}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF2C3E50),
                                      ),
                                    ),
                                    const Spacer(),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Create Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createGoal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3498DB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Tạo mục tiêu',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _targetController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

class _EditGoalBottomSheet extends StatefulWidget {
  final HealthGoal goal;
  final HealthData? currentData;
  final Function(HealthGoal) onGoalUpdated;

  const _EditGoalBottomSheet({
    required this.goal,
    required this.currentData,
    required this.onGoalUpdated,
  });

  @override
  State<_EditGoalBottomSheet> createState() => _EditGoalBottomSheetState();
}

class _EditGoalBottomSheetState extends State<_EditGoalBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late GoalType _selectedType;
  late final TextEditingController _targetController;
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late DateTime _targetDate;
  bool _isLoading = false;

  final List<String> _goalTypes = [
    'Giảm cân',
    'Tăng cân',
    'Duy trì cân nặng',
    'Đạt BMI mục tiêu',
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.goal.type;
    _targetController = TextEditingController(text: widget.goal.targetValue.toStringAsFixed(1));
    _titleController = TextEditingController(text: widget.goal.title);
    _descriptionController = TextEditingController(text: widget.goal.description);
    _targetDate = widget.goal.targetDate;
  }

  String _getGoalTypeString(GoalType type) {
    switch (type) {
      case GoalType.weightLoss:
        return 'Giảm cân';
      case GoalType.weightGain:
        return 'Tăng cân';
      case GoalType.maintain:
        return 'Duy trì cân nặng';
      case GoalType.bmiTarget:
        return 'Đạt BMI mục tiêu';
    }
  }

  GoalType _getGoalTypeFromString(String typeString) {
    switch (typeString) {
      case 'Giảm cân':
        return GoalType.weightLoss;
      case 'Tăng cân':
        return GoalType.weightGain;
      case 'Duy trì cân nặng':
        return GoalType.maintain;
      case 'Đạt BMI mục tiêu':
        return GoalType.bmiTarget;
      default:
        return GoalType.weightLoss;
    }
  }

  String _getTargetUnit() {
    return _selectedType == GoalType.bmiTarget ? '' : 'kg';
  }

  String _getTargetHint() {
    switch (_selectedType) {
      case GoalType.weightLoss:
        return 'Cân nặng mục tiêu (kg)';
      case GoalType.weightGain:
        return 'Cân nặng mục tiêu (kg)';
      case GoalType.maintain:
        return 'Cân nặng duy trì (kg)';
      case GoalType.bmiTarget:
        return 'BMI mục tiêu (18.5-24.9)';
    }
  }

  Future<void> _updateGoal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final targetValue = double.parse(_targetController.text);

      final updatedGoal = widget.goal.copyWith(
        type: _selectedType,
        targetValue: targetValue,
        targetDate: _targetDate,
        title: _titleController.text,
        description: _descriptionController.text,
      );

      widget.onGoalUpdated(updatedGoal);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Có lỗi xảy ra khi cập nhật mục tiêu'),
          backgroundColor: Color(0xFFE74C3C),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Chỉnh sửa mục tiêu',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Goal Type Selection
                      CustomDropdown(
                        label: 'Loại mục tiêu',
                        value: _getGoalTypeString(_selectedType),
                        items: _goalTypes,
                        prefixIcon: Icons.flag,
                        onChanged: (value) {
                          setState(() {
                            _selectedType = _getGoalTypeFromString(value!);
                          });
                        },
                      ),

                      // Title
                      CustomInputField(
                        label: 'Tên mục tiêu',
                        hint: 'Nhập tên cho mục tiêu của bạn',
                        controller: _titleController,
                        prefixIcon: Icons.title,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập tên mục tiêu';
                          }
                          return null;
                        },
                      ),

                      // Target Value
                      CustomInputField(
                        label: 'Giá trị mục tiêu',
                        hint: _getTargetHint(),
                        controller: _targetController,
                        suffix: _getTargetUnit(),
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.track_changes,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập giá trị mục tiêu';
                          }
                          final target = double.tryParse(value);
                          if (target == null || target <= 0) {
                            return 'Giá trị không hợp lệ';
                          }

                          if (_selectedType == GoalType.bmiTarget) {
                            if (target < 15 || target > 35) {
                              return 'BMI phải trong khoảng 15-35';
                            }
                          } else {
                            if (target < 30 || target > 200) {
                              return 'Cân nặng phải trong khoảng 30-200kg';
                            }
                          }
                          return null;
                        },
                      ),

                      // Description
                      CustomInputField(
                        label: 'Mô tả',
                        hint: 'Mô tả chi tiết về mục tiêu',
                        controller: _descriptionController,
                        prefixIcon: Icons.description,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập mô tả';
                          }
                          return null;
                        },
                      ),

                      // Target Date
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ngày hoàn thành dự kiến',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _targetDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (date != null) {
                                  setState(() {
                                    _targetDate = date;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[200]!),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withValues(alpha: 0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today,
                                      color: Color(0xFF3498DB),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '${_targetDate.day}/${_targetDate.month}/${_targetDate.year}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF2C3E50),
                                      ),
                                    ),
                                    const Spacer(),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Update Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateGoal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3498DB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Cập nhật mục tiêu',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _targetController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
