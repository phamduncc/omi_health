import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/health_data.dart';
import '../services/storage_service.dart';
import '../widgets/custom_input_field.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/result_card.dart';
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
  
  String? _selectedGender;
  String? _selectedActivityLevel;
  HealthData? _currentData;
  bool _isLoading = false;

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
        _selectedGender = latestData.gender;
        _selectedActivityLevel = latestData.activityLevel;
      });
    }
  }

  Future<void> _calculateHealth() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGender == null || _selectedActivityLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn đầy đủ thông tin'),
          backgroundColor: Color(0xFFE74C3C),
        ),
      );
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
    );

    await StorageService.saveLatestData(healthData);
    await StorageService.saveToHistory(healthData);

    setState(() {
      _currentData = healthData;
      _isLoading = false;
    });
  }

  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) return const Color(0xFF3498DB);
    if (bmi < 25) return const Color(0xFF2ECC71);
    if (bmi < 30) return const Color(0xFFF39C12);
    return const Color(0xFFE74C3C);
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
