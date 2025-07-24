import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/health_data.dart';
import '../models/health_goal.dart';
import '../services/storage_service.dart';
import '../services/goal_service.dart';
import '../services/navigation_service.dart';
import '../services/goal_progress_service.dart';
import '../widgets/custom_input_field.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/result_card.dart';
import '../widgets/goal_progress_banner.dart';
import '../widgets/real_time_progress_widget.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _ageController = TextEditingController();
  final _waistController = TextEditingController();
  final _hipController = TextEditingController();

  String? _selectedGender;
  String? _selectedActivityLevel;
  HealthData? _currentData;
  bool _isLoading = false;
  List<GoalProgressUpdate> _goalUpdates = [];

  final List<String> _genders = ['Nam', 'Nữ'];
  final List<String> _activityLevels = [
    'Ít vận động',
    'Vận động nhẹ',
    'Vận động vừa',
    'Vận động nhiều',
    'Vận động rất nhiều',
  ];

  @override
  void initState() {
    super.initState();
    _loadLatestData();
  }

  Future<void> _loadLatestData() async {
    final latestData = await StorageService.getLatestData();
    if (latestData != null) {
      setState(() {
        _weightController.text = latestData.weight.toString();
        _heightController.text = latestData.height.toString();
        _ageController.text = latestData.age.toString();
        _waistController.text = latestData.waist?.toString() ?? '';
        _hipController.text = latestData.hip?.toString() ?? '';
        _selectedGender = latestData.gender;
        _selectedActivityLevel = latestData.activityLevel;
      });

      // Tạo mục tiêu mẫu nếu chưa có
      await _createSampleGoalsIfNeeded(latestData);
    }
  }

  Future<void> _createSampleGoalsIfNeeded(HealthData currentData) async {
    final existingGoals = await GoalService.getGoals();
    if (existingGoals.isEmpty) {
      final sampleGoals = await GoalService.generateSampleGoals(currentData);
      for (final goal in sampleGoals) {
        await GoalService.addGoal(goal);
      }

      // Hiển thị thông báo về mục tiêu mẫu được tạo
      if (sampleGoals.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
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
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đã tạo ${sampleGoals.length} mục tiêu phù hợp!',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Dựa trên chỉ số BMI của bạn',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF2ECC71),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Xem ngay',
              textColor: Colors.white,
              onPressed: _navigateToGoalsTab,
            ),
          ),
        );
      }
    }
  }

  Future<void> _calculateHealth() async {
    // Kiểm tra các field cơ bản trước
    if (_weightController.text.isEmpty ||
        _heightController.text.isEmpty ||
        _ageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đầy đủ cân nặng, chiều cao và tuổi'),
          backgroundColor: Color(0xFFE74C3C),
        ),
      );
      return;
    }

    if (_selectedGender == null || _selectedActivityLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn giới tính và mức độ vận động'),
          backgroundColor: Color(0xFFE74C3C),
        ),
      );
      return;
    }

    // Validate form sau khi kiểm tra cơ bản
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final healthData = HealthData(
      weight: double.parse(_weightController.text),
      height: double.parse(_heightController.text),
      age: int.parse(_ageController.text),
      gender: _selectedGender!,
      activityLevel: _selectedActivityLevel!,
      timestamp: DateTime.now(),
      waist: _waistController.text.isNotEmpty ? double.parse(_waistController.text) : null,
      hip: _hipController.text.isNotEmpty ? double.parse(_hipController.text) : null,
    );

    // Cập nhật cân nặng hiện tại cho tất cả mục tiêu ngay lập tức
    final updateResult = await GoalService.updateCurrentValues(healthData);

    // Force check goal completion
    final completedGoals = await GoalService.forceCheckGoalCompletion();

    // Hiển thị thông báo xác nhận cập nhật
    _showCurrentValueUpdateConfirmation(updateResult);

    // Hiển thị thông báo về mục tiêu hoàn thành
    if (completedGoals.isNotEmpty) {
      _showCompletedGoalsNotification(completedGoals);
    }

    // Notify GoalProgressService về dữ liệu mới
    GoalProgressService().onHealthDataUpdated(healthData);

    // Kiểm tra thay đổi đáng kể so với dữ liệu trước
    final previousData = await StorageService.getLatestData();
    if (previousData != null) {
      await GoalService.handleSignificantHealthChange(previousData, healthData);
    }

    await StorageService.saveLatestData(healthData);
    final goalUpdates = await StorageService.saveToHistory(healthData);

    setState(() {
      _currentData = healthData;
      _isLoading = false;
    });

    // Lưu trữ goal updates để hiển thị banner
    if (goalUpdates.isNotEmpty) {
      setState(() {
        _goalUpdates = goalUpdates.cast<GoalProgressUpdate>();
      });
    }

    // Hiển thị thông báo về cập nhật mục tiêu
    _showGoalUpdates(goalUpdates);

    // Kiểm tra và hiển thị thông báo về mục tiêu mới
    await _checkForNewGoals();
  }

  void _showGoalUpdates(List<dynamic> goalUpdates) {
    if (goalUpdates.isEmpty) return;

    // Sắp xếp updates theo độ ưu tiên: completed > milestone > significant progress
    final sortedUpdates = goalUpdates.cast<GoalProgressUpdate>()
      ..sort((a, b) {
        if (a.isCompleted && !b.isCompleted) return -1;
        if (!a.isCompleted && b.isCompleted) return 1;
        if (a.isNewMilestone && !b.isNewMilestone) return -1;
        if (!a.isNewMilestone && b.isNewMilestone) return 1;
        return b.progressChange.abs().compareTo(a.progressChange.abs());
      });

    for (final update in sortedUpdates) {
      if (update.isCompleted) {
        // Hiển thị dialog chúc mừng cho mục tiêu hoàn thành
        _showGoalCompletedDialog(update);
        break; // Chỉ hiển thị 1 dialog completion
      } else if (update.isNewMilestone) {
        // Hiển thị snackbar cho milestone
        _showMilestoneSnackBar(update);
      } else if (update.progressChange.abs() > 2) {
        // Hiển thị snackbar cho thay đổi tiến độ đáng kể (>2%)
        _showGoalProgressSnackBar(update);
      }
    }
  }

  void _showGoalCompletedDialog(GoalProgressUpdate update) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2ECC71).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.celebration,
                color: Color(0xFF2ECC71),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Chúc mừng!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2ECC71),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              update.progressMessage,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              update.detailMessage,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2ECC71).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.tips_and_updates,
                        color: Color(0xFF2ECC71),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Chúng tôi đã tự động tạo mục tiêu mới phù hợp!',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF2ECC71),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hãy kiểm tra tab "Mục tiêu" để xem mục tiêu tiếp theo của bạn.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to goals screen - find the main navigation and switch tab
              _navigateToGoalsTab();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2ECC71),
              foregroundColor: Colors.white,
            ),
            child: const Text('Xem mục tiêu'),
          ),
        ],
      ),
    );
  }

  void _showMilestoneSnackBar(GoalProgressUpdate update) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.celebration,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    update.progressMessage,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tiếp tục phát huy nhé! 💪',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF9B59B6),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Xem',
          textColor: Colors.white,
          onPressed: _navigateToGoalsTab,
        ),
      ),
    );
  }

  void _showGoalProgressSnackBar(GoalProgressUpdate update) {
    final color = update.progressChange > 0
        ? const Color(0xFF2ECC71)
        : const Color(0xFFF39C12);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              update.progressMessage,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              update.detailMessage,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Xem',
          textColor: Colors.white,
          onPressed: () {
            // Navigate to goals screen
            _navigateToGoalsTab();
          },
        ),
      ),
    );
  }

  Future<void> _checkForNewGoals() async {
    // Kiểm tra xem có mục tiêu mới được tạo trong 5 phút qua không
    final goals = await GoalService.getGoals();
    final now = DateTime.now();
    final recentGoals = goals.where((goal) {
      final timeDiff = now.difference(goal.startDate).inMinutes;
      return timeDiff <= 5 && goal.isActive;
    }).toList();

    if (recentGoals.isNotEmpty && mounted) {
      // Hiển thị snackbar về mục tiêu mới
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
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
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recentGoals.length == 1
                          ? 'Mục tiêu mới đã được tạo!'
                          : '${recentGoals.length} mục tiêu mới đã được tạo!',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      recentGoals.first.title,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF3498DB),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'Xem ngay',
            textColor: Colors.white,
            onPressed: _navigateToGoalsTab,
          ),
        ),
      );
    }
  }

  void _showCurrentValueUpdateConfirmation(Map<String, dynamic> updateResult) {
    if (mounted && updateResult['hasUpdates'] == true) {
      final updatedCount = updateResult['updatedCount'] as int;
      final updatedGoalTitles = updateResult['updatedGoalTitles'] as List<String>;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.sync,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đã cập nhật $updatedCount mục tiêu',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    if (updatedGoalTitles.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        updatedGoalTitles.length > 2
                            ? '${updatedGoalTitles.take(2).join(', ')} và ${updatedGoalTitles.length - 2} khác'
                            : updatedGoalTitles.join(', '),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2ECC71),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          action: SnackBarAction(
            label: 'Xem',
            textColor: Colors.white,
            onPressed: _navigateToGoalsTab,
          ),
        ),
      );
    }
  }

  void _showCompletedGoalsNotification(List<HealthGoal> completedGoals) {
    if (mounted) {
      final goalCount = completedGoals.length;
      final firstGoal = completedGoals.first;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.celebration,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goalCount == 1
                          ? 'Chúc mừng! Hoàn thành mục tiêu!'
                          : 'Chúc mừng! Hoàn thành $goalCount mục tiêu!',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      firstGoal.title,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2ECC71),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'Xem',
            textColor: Colors.white,
            onPressed: _navigateToGoalsTab,
          ),
        ),
      );
    }
  }

  Future<void> _createTestGoal() async {
    if (_currentData != null) {
      await GoalService.createTestGoal(_currentData!);

      // Ngay lập tức force check completion
      final completedGoals = await GoalService.forceCheckGoalCompletion();

      if (mounted) {
        if (completedGoals.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tạo và hoàn thành ${completedGoals.length} test goal!'),
              backgroundColor: const Color(0xFF2ECC71),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã tạo test goal nhưng chưa hoàn thành. Kiểm tra logic!'),
              backgroundColor: Color(0xFFF39C12),
            ),
          );
        }
      }
    }
  }

  Future<void> _debugGoals() async {
    final goals = await GoalService.getGoals();
    if (mounted) {
      String debugInfo = '=== DEBUG ALL GOALS ===\n';
      for (final goal in goals) {
        debugInfo += 'Goal: ${goal.title}\n';
        debugInfo += 'Type: ${goal.type}\n';
        debugInfo += 'Start: ${goal.startValue}\n';
        debugInfo += 'Current: ${goal.currentValue}\n';
        debugInfo += 'Target: ${goal.targetValue}\n';
        debugInfo += 'Progress: ${goal.progressPercentage}%\n';
        debugInfo += 'Is Active: ${goal.isActive}\n';
        debugInfo += 'Actually Completed: ${GoalService.isGoalActuallyCompleted(goal)}\n';
        debugInfo += '---\n';
      }
      debugInfo += '======================';

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Debug Goals'),
          content: SingleChildScrollView(
            child: Text(
              debugInfo,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  void _navigateToGoalsTab() {
    NavigationService().navigateToGoals();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Omi Health'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Goal Progress Banner
              if (_goalUpdates.isNotEmpty)
                GoalProgressBanner(
                  updates: _goalUpdates,
                  onDismiss: () {
                    setState(() {
                      _goalUpdates.clear();
                    });
                  },
                ),
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF3498DB), Color(0xFF2980B9)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tính toán chỉ số sức khỏe',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Nhập thông tin của bạn để tính BMI và các chỉ số sức khỏe khác',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Input Fields
              CustomInputField(
                label: 'Cân nặng',
                hint: 'Nhập cân nặng của bạn',
                controller: _weightController,
                suffix: 'kg',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.monitor_weight,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập cân nặng';
                  }
                  final weight = double.tryParse(value);
                  if (weight == null || weight <= 0 || weight > 300) {
                    return 'Cân nặng không hợp lệ (1-300 kg)';
                  }
                  return null;
                },
              ),

              CustomInputField(
                label: 'Chiều cao',
                hint: 'Nhập chiều cao của bạn',
                controller: _heightController,
                suffix: 'cm',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.height,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập chiều cao';
                  }
                  final height = double.tryParse(value);
                  if (height == null || height <= 0 || height > 250) {
                    return 'Chiều cao không hợp lệ (1-250 cm)';
                  }
                  return null;
                },
              ),

              CustomInputField(
                label: 'Tuổi',
                hint: 'Nhập tuổi của bạn',
                controller: _ageController,
                suffix: 'tuổi',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.cake,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập tuổi';
                  }
                  final age = int.tryParse(value);
                  if (age == null || age <= 0 || age > 120) {
                    return 'Tuổi không hợp lệ (1-120)';
                  }
                  return null;
                },
              ),

              // Thêm phần mở rộng cho các chỉ số khác
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.analytics, color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Chỉ số bổ sung (tùy chọn)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nhập để tính toán WHR và phần trăm mỡ cơ thể',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),

                    CustomInputField(
                      label: 'Vòng eo',
                      hint: 'Nhập vòng eo của bạn',
                      controller: _waistController,
                      suffix: 'cm',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: Icons.straighten,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
                      ],
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final waist = double.tryParse(value);
                          if (waist == null || waist <= 0 || waist > 200) {
                            return 'Vòng eo không hợp lệ (1-200 cm)';
                          }
                        }
                        return null;
                      },
                    ),

                    CustomInputField(
                      label: 'Vòng mông',
                      hint: 'Nhập vòng mông của bạn',
                      controller: _hipController,
                      suffix: 'cm',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: Icons.straighten,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
                      ],
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final hip = double.tryParse(value);
                          if (hip == null || hip <= 0 || hip > 200) {
                            return 'Vòng mông không hợp lệ (1-200 cm)';
                          }
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              CustomDropdown(
                label: 'Giới tính',
                value: _selectedGender,
                items: _genders,
                prefixIcon: Icons.person,
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value;
                  });
                },
              ),

              CustomDropdown(
                label: 'Mức độ vận động',
                value: _selectedActivityLevel,
                items: _activityLevels,
                prefixIcon: Icons.fitness_center,
                onChanged: (value) {
                  setState(() {
                    _selectedActivityLevel = value;
                  });
                },
              ),

              const SizedBox(height: 24),

              // Calculate Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _calculateHealth,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3498DB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Tính toán chỉ số sức khỏe',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              // Test buttons (chỉ để test, có thể xóa sau)
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _createTestGoal,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2ECC71),
                        side: const BorderSide(color: Color(0xFF2ECC71)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Tạo Test Goal',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _debugGoals,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFF39C12),
                        side: const BorderSide(color: Color(0xFFF39C12)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Debug Goals',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                ],
              ),

              if (_currentData != null) ...[
                const SizedBox(height: 32),
                const Text(
                  'Kết quả',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 16),

                ResultCard(
                  title: 'Chỉ số BMI',
                  value: _currentData!.bmi.toStringAsFixed(1),
                  subtitle: _currentData!.bmiCategory,
                  color: _getBMIColor(_currentData!.bmi),
                  icon: Icons.monitor_weight,
                  description: 'BMI là chỉ số khối cơ thể, giúp đánh giá tình trạng cân nặng.',
                ),

                ResultCard(
                  title: 'BMR (Tỷ lệ trao đổi chất cơ bản)',
                  value: '${_currentData!.bmr.toStringAsFixed(0)} kcal',
                  subtitle: 'Calories cần thiết khi nghỉ ngơi',
                  color: const Color(0xFF9B59B6),
                  icon: Icons.local_fire_department,
                  description: 'Lượng calories cơ thể cần để duy trì các chức năng cơ bản.',
                ),

                ResultCard(
                  title: 'TDEE (Tổng năng lượng tiêu thụ)',
                  value: '${_currentData!.tdee.toStringAsFixed(0)} kcal',
                  subtitle: 'Calories cần thiết mỗi ngày',
                  color: const Color(0xFFE67E22),
                  icon: Icons.restaurant,
                  description: 'Tổng lượng calories bạn cần tiêu thụ mỗi ngày dựa trên mức độ hoạt động.',
                ),

                ResultCard(
                  title: 'Cân nặng lý tưởng',
                  value: '${_currentData!.idealWeight.toStringAsFixed(1)} kg',
                  subtitle: 'Dựa trên chiều cao và giới tính',
                  color: const Color(0xFF1ABC9C),
                  icon: Icons.favorite,
                  description: 'Cân nặng lý tưởng được tính theo công thức Devine.',
                ),

                // Hiển thị khoảng cân nặng lý tưởng
                ResultCard(
                  title: 'Khoảng cân nặng khỏe mạnh',
                  value: '${_currentData!.idealWeightRange['min']!.toStringAsFixed(1)} - ${_currentData!.idealWeightRange['max']!.toStringAsFixed(1)} kg',
                  subtitle: 'BMI từ 18.5 đến 24.9',
                  color: const Color(0xFF27AE60),
                  icon: Icons.fitness_center,
                  description: 'Khoảng cân nặng tương ứng với BMI khỏe mạnh cho chiều cao của bạn.',
                ),

                // Hiển thị WHR nếu có dữ liệu
                if (_currentData!.whr != null) ...[
                  ResultCard(
                    title: 'Tỷ lệ vòng eo/mông (WHR)',
                    value: _currentData!.whr!.toStringAsFixed(2),
                    subtitle: _currentData!.whrCategory ?? 'Không xác định',
                    color: _getColorFromHex(_currentData!.whrCategoryColor ?? '#95a5a6'),
                    icon: Icons.straighten,
                    description: 'WHR đánh giá phân bố mỡ cơ thể và nguy cơ sức khỏe.',
                  ),
                ],

                // Hiển thị phần trăm mỡ cơ thể nếu có dữ liệu
                if (_currentData!.bodyFatPercentage != null) ...[
                  ResultCard(
                    title: 'Phần trăm mỡ cơ thể',
                    value: '${_currentData!.bodyFatPercentage!.toStringAsFixed(1)}%',
                    subtitle: _currentData!.bodyFatCategory ?? 'Không xác định',
                    color: _getColorFromHex(_currentData!.bodyFatCategoryColor ?? '#95a5a6'),
                    icon: Icons.pie_chart,
                    description: 'Ước tính phần trăm mỡ cơ thể dựa trên BMI, tuổi và giới tính.',
                  ),
                ],

                const SizedBox(height: 24),
                const RealTimeProgressWidget(
                  showHeader: false,
                  showSummary: false,
                  maxGoalsToShow: 2,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    super.dispose();
  }
}
