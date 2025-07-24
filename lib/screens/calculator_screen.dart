import 'package:flutter/material.dart';
import '../models/health_data.dart';
import '../services/storage_service.dart';
import '../services/calculator_service.dart';
import '../widgets/custom_input_field.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  HealthData? _currentData;
  bool _isLoading = true;

  // Controllers cho các tab
  final _waterWeightController = TextEditingController();
  final _calorieTargetWeightController = TextEditingController();
  final _calorieDaysController = TextEditingController();
  final _timeTargetWeightController = TextEditingController();
  final _activityDurationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _waterWeightController.dispose();
    _calorieTargetWeightController.dispose();
    _calorieDaysController.dispose();
    _timeTargetWeightController.dispose();
    _activityDurationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final data = await StorageService.getLatestData();
    setState(() {
      _currentData = data;
      _isLoading = false;
      if (data != null) {
        _waterWeightController.text = data.weight.toString();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Máy tính sức khỏe'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Nước', icon: Icon(Icons.water_drop, size: 16)),
            Tab(text: 'Calories', icon: Icon(Icons.restaurant, size: 16)),
            Tab(text: 'Thời gian', icon: Icon(Icons.schedule, size: 16)),
            Tab(text: 'Hoạt động', icon: Icon(Icons.fitness_center, size: 16)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildWaterCalculator(),
                _buildCalorieCalculator(),
                _buildTimeCalculator(),
                _buildActivityCalculator(),
              ],
            ),
    );
  }

  Widget _buildWaterCalculator() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tính lượng nước cần uống',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 16),
          
          CustomInputField(
            label: 'Cân nặng',
            hint: 'Nhập cân nặng',
            controller: _waterWeightController,
            suffix: 'kg',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixIcon: Icons.monitor_weight,
          ),
          
          const SizedBox(height: 16),
          
          ElevatedButton.icon(
            onPressed: _calculateWaterIntake,
            icon: const Icon(Icons.calculate),
            label: const Text('Tính toán'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          
          const SizedBox(height: 24),
          
          _buildWaterResults(),
        ],
      ),
    );
  }

  Widget _buildCalorieCalculator() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tính calories cho mục tiêu',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 16),
          
          if (_currentData != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cân nặng hiện tại: ${_currentData!.weight}kg'),
                  Text('TDEE hiện tại: ${_currentData!.tdee.toStringAsFixed(0)} kcal/ngày'),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          CustomInputField(
            label: 'Cân nặng mục tiêu',
            hint: 'Nhập cân nặng mục tiêu',
            controller: _calorieTargetWeightController,
            suffix: 'kg',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixIcon: Icons.flag,
          ),
          
          CustomInputField(
            label: 'Thời gian đạt mục tiêu',
            hint: 'Số ngày để đạt mục tiêu',
            controller: _calorieDaysController,
            suffix: 'ngày',
            keyboardType: TextInputType.number,
            prefixIcon: Icons.calendar_today,
          ),
          
          const SizedBox(height: 16),
          
          ElevatedButton.icon(
            onPressed: _calculateCalories,
            icon: const Icon(Icons.calculate),
            label: const Text('Tính toán'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          
          const SizedBox(height: 24),
          
          _buildCalorieResults(),
        ],
      ),
    );
  }

  Widget _buildTimeCalculator() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tính thời gian đạt mục tiêu',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 16),
          
          if (_currentData != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Cân nặng hiện tại: ${_currentData!.weight}kg'),
            ),
            const SizedBox(height: 16),
          ],
          
          CustomInputField(
            label: 'Cân nặng mục tiêu',
            hint: 'Nhập cân nặng mục tiêu',
            controller: _timeTargetWeightController,
            suffix: 'kg',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixIcon: Icons.flag,
          ),
          
          const SizedBox(height: 16),
          
          ElevatedButton.icon(
            onPressed: _calculateTimeToGoal,
            icon: const Icon(Icons.calculate),
            label: const Text('Tính toán'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          
          const SizedBox(height: 24),
          
          _buildTimeResults(),
        ],
      ),
    );
  }

  Widget _buildActivityCalculator() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tính calories đốt cháy',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 16),
          
          if (_currentData != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Cân nặng: ${_currentData!.weight}kg'),
            ),
            const SizedBox(height: 16),
          ],
          
          CustomInputField(
            label: 'Thời gian hoạt động',
            hint: 'Số phút hoạt động',
            controller: _activityDurationController,
            suffix: 'phút',
            keyboardType: TextInputType.number,
            prefixIcon: Icons.timer,
          ),
          
          const SizedBox(height: 16),
          
          ElevatedButton.icon(
            onPressed: _calculateActivityCalories,
            icon: const Icon(Icons.calculate),
            label: const Text('Tính toán'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          
          const SizedBox(height: 24),
          
          _buildActivityResults(),
        ],
      ),
    );
  }

  Widget _buildWaterResults() {
    // Placeholder for water calculation results
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: const Column(
        children: [
          Icon(Icons.water_drop, size: 48, color: Colors.blue),
          SizedBox(height: 8),
          Text(
            'Nhập cân nặng và nhấn "Tính toán" để xem kết quả',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.blue),
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieResults() {
    // Placeholder for calorie calculation results
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: const Column(
        children: [
          Icon(Icons.restaurant, size: 48, color: Colors.orange),
          SizedBox(height: 8),
          Text(
            'Nhập thông tin và nhấn "Tính toán" để xem kết quả',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.orange),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeResults() {
    // Placeholder for time calculation results
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: const Column(
        children: [
          Icon(Icons.schedule, size: 48, color: Colors.green),
          SizedBox(height: 8),
          Text(
            'Nhập cân nặng mục tiêu và nhấn "Tính toán" để xem kết quả',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.green),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityResults() {
    // Placeholder for activity calculation results
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: const Column(
        children: [
          Icon(Icons.fitness_center, size: 48, color: Colors.purple),
          SizedBox(height: 8),
          Text(
            'Nhập thời gian hoạt động và nhấn "Tính toán" để xem kết quả',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.purple),
          ),
        ],
      ),
    );
  }

  void _calculateWaterIntake() {
    final weight = double.tryParse(_waterWeightController.text);
    if (weight == null || weight <= 0) {
      _showErrorSnackBar('Vui lòng nhập cân nặng hợp lệ');
      return;
    }

    final waterIntake = CalculatorService.calculateDailyWaterIntake(
      weight: weight,
      activityLevel: _currentData?.activityLevel ?? 'Ít vận động',
    );

    _showResultDialog(
      'Lượng nước cần uống',
      'Bạn nên uống khoảng ${(waterIntake / 1000).toStringAsFixed(1)} lít (${waterIntake.toStringAsFixed(0)}ml) nước mỗi ngày.\n\n'
      'Chia thành 8-10 lần uống trong ngày để đạt hiệu quả tốt nhất.',
      Icons.water_drop,
      Colors.blue,
    );
  }

  void _calculateCalories() {
    if (_currentData == null) {
      _showErrorSnackBar('Vui lòng nhập dữ liệu sức khỏe trước');
      return;
    }

    final targetWeight = double.tryParse(_calorieTargetWeightController.text);
    final days = int.tryParse(_calorieDaysController.text);

    if (targetWeight == null || days == null || days <= 0) {
      _showErrorSnackBar('Vui lòng nhập thông tin hợp lệ');
      return;
    }

    final result = CalculatorService.calculateCaloriesForWeightGoal(
      currentData: _currentData!,
      targetWeight: targetWeight,
      daysToReach: days,
    );

    _showResultDialog(
      'Kế hoạch calories',
      'Calories mục tiêu: ${result['targetDailyCalories']} kcal/ngày\n'
      'Thay đổi: ${result['dailyCalorieAdjustment'] > 0 ? '+' : ''}${result['dailyCalorieAdjustment']} kcal/ngày\n'
      'Thời gian ước tính: ${result['estimatedDays']} ngày\n\n'
      '${result['recommendation']}',
      Icons.restaurant,
      Colors.orange,
    );
  }

  void _calculateTimeToGoal() {
    if (_currentData == null) {
      _showErrorSnackBar('Vui lòng nhập dữ liệu sức khỏe trước');
      return;
    }

    final targetWeight = double.tryParse(_timeTargetWeightController.text);
    if (targetWeight == null) {
      _showErrorSnackBar('Vui lòng nhập cân nặng mục tiêu hợp lệ');
      return;
    }

    final result = CalculatorService.calculateTimeToGoal(
      currentData: _currentData!,
      targetWeight: targetWeight,
    );

    _showResultDialog(
      'Thời gian đạt mục tiêu',
      'Thời gian cần thiết: ${result['weeksNeeded'].toStringAsFixed(1)} tuần (${result['daysNeeded']} ngày)\n'
      'Ngày dự kiến: ${_formatDate(result['targetDate'])}\n'
      'Mức độ: ${result['difficulty']}\n'
      'Thay đổi mỗi tuần: ${result['weeklyChange']}kg',
      Icons.schedule,
      Colors.green,
    );
  }

  void _calculateActivityCalories() {
    if (_currentData == null) {
      _showErrorSnackBar('Vui lòng nhập dữ liệu sức khỏe trước');
      return;
    }

    final duration = int.tryParse(_activityDurationController.text);
    if (duration == null || duration <= 0) {
      _showErrorSnackBar('Vui lòng nhập thời gian hợp lệ');
      return;
    }

    final results = CalculatorService.calculateCaloriesBurned(
      weight: _currentData!.weight,
      durationMinutes: duration,
    );

    String resultText = 'Calories đốt cháy trong $duration phút:\n\n';
    results.forEach((activity, calories) {
      resultText += '• $activity: ${calories.toStringAsFixed(0)} kcal\n';
    });

    _showResultDialog(
      'Calories đốt cháy',
      resultText,
      Icons.fitness_center,
      Colors.purple,
    );
  }

  void _showResultDialog(String title, String content, IconData icon, Color color) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
