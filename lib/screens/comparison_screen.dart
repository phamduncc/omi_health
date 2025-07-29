import 'package:flutter/material.dart';
import '../models/health_data.dart';
import '../services/storage_service.dart';
import '../services/calculator_service.dart';

class ComparisonScreen extends StatefulWidget {
  const ComparisonScreen({super.key});

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  HealthData? _latestData;
  bool _isLoading = true;
  Map<String, dynamic> _comparisonData = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await StorageService.getLatestData();
      if (data != null) {
        final comparison = _generateComparisonData(data);
        setState(() {
          _latestData = data;
          _comparisonData = comparison;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _generateComparisonData(HealthData data) {
    return {
      'bmi': _getBMIComparison(data),
      'weight': _getWeightComparison(data),
      'bodyFat': _getBodyFatComparison(data),
      'whr': _getWHRComparison(data),
      'calories': _getCalorieComparison(data),
      'water': _getWaterComparison(data),
    };
  }

  Map<String, dynamic> _getBMIComparison(HealthData data) {
    final bmi = data.bmi;
    return {
      'value': bmi,
      'category': data.bmiCategory,
      'color': _getColorFromHex(data.bmiCategoryColor),
      'standards': {
        'WHO': {
          'underweight': '< 18.5',
          'normal': '18.5 - 24.9',
          'overweight': '25.0 - 29.9',
          'obese': '≥ 30.0',
        },
        'Asian': {
          'underweight': '< 18.5',
          'normal': '18.5 - 22.9',
          'overweight': '23.0 - 27.4',
          'obese': '≥ 27.5',
        }
      },
      'recommendation': _getBMIRecommendation(bmi),
    };
  }

  Map<String, dynamic> _getWeightComparison(HealthData data) {
    final idealRange = data.idealWeightRange;
    final currentWeight = data.weight;
    final idealWeight = data.idealWeight;
    
    return {
      'current': currentWeight,
      'ideal': idealWeight,
      'idealRange': idealRange,
      'difference': currentWeight - idealWeight,
      'status': _getWeightStatus(currentWeight, idealRange),
      'recommendation': _getWeightRecommendation(currentWeight, idealRange),
    };
  }

  Map<String, dynamic> _getBodyFatComparison(HealthData data) {
    final bodyFat = data.bodyFatPercentage;
    if (bodyFat == null) return {};
    
    return {
      'value': bodyFat,
      'category': data.bodyFatCategory,
      'color': _getColorFromHex(data.bodyFatCategoryColor ?? '#95a5a6'),
      'standards': _getBodyFatStandards(data.gender),
      'recommendation': _getBodyFatRecommendation(bodyFat, data.gender),
    };
  }

  Map<String, dynamic> _getWHRComparison(HealthData data) {
    final whr = data.whr;
    if (whr == null) return {};
    
    return {
      'value': whr,
      'category': data.whrCategory,
      'standards': _getWHRStandards(data.gender),
      'recommendation': _getWHRRecommendation(whr, data.gender),
    };
  }

  Map<String, dynamic> _getCalorieComparison(HealthData data) {
    final bmr = data.bmr;
    final tdee = data.tdee;
    
    return {
      'bmr': bmr,
      'tdee': tdee,
      'recommendation': _getCalorieRecommendation(data),
    };
  }

  Map<String, dynamic> _getWaterComparison(HealthData data) {
    final recommendedWater = CalculatorService.calculateDailyWaterIntake(
      weight: data.weight,
      activityLevel: data.activityLevel,
    );
    
    return {
      'recommended': recommendedWater / 1000, // Convert to liters
      'recommendation': 'Nên uống ${(recommendedWater / 1000).toStringAsFixed(1)} lít nước mỗi ngày',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('So sánh với chuẩn'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _latestData == null
              ? _buildNoDataWidget()
              : _buildComparisonContent(),
    );
  }

  Widget _buildNoDataWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.data_usage_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có dữ liệu sức khỏe',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vui lòng nhập thông tin sức khỏe để xem so sánh',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Quay lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserInfoCard(),
          const SizedBox(height: 16),
          _buildBMIComparison(),
          const SizedBox(height: 16),
          _buildWeightComparison(),
          const SizedBox(height: 16),
          if (_comparisonData['bodyFat'].isNotEmpty) ...[
            _buildBodyFatComparison(),
            const SizedBox(height: 16),
          ],
          if (_comparisonData['whr'].isNotEmpty) ...[
            _buildWHRComparison(),
            const SizedBox(height: 16),
          ],
          _buildCalorieComparison(),
          const SizedBox(height: 16),
          _buildWaterComparison(),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: Colors.blue[600]),
                const SizedBox(width: 8),
                const Text(
                  'Thông tin cá nhân',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem('Tuổi', '${_latestData!.age}'),
                ),
                Expanded(
                  child: _buildInfoItem('Giới tính', _latestData!.gender),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem('Chiều cao', '${_latestData!.height.toStringAsFixed(0)} cm'),
                ),
                Expanded(
                  child: _buildInfoItem('Cân nặng', '${_latestData!.weight.toStringAsFixed(1)} kg'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildInfoItem('Mức độ hoạt động', _latestData!.activityLevel),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBMIComparison() {
    final bmiData = _comparisonData['bmi'];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.monitor_weight, color: Colors.green[600]),
                const SizedBox(width: 8),
                const Text(
                  'Chỉ số BMI',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '${bmiData['value'].toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: bmiData['color'],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bmiData['category'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: bmiData['color'],
                        ),
                      ),
                      Text(
                        bmiData['recommendation'],
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
            const SizedBox(height: 16),
            _buildStandardsTable('Chuẩn WHO', bmiData['standards']['WHO']),
            const SizedBox(height: 8),
            _buildStandardsTable('Chuẩn châu Á', bmiData['standards']['Asian']),
          ],
        ),
      ),
    );
  }

  Widget _buildStandardsTable(String title, Map<String, String> standards) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: standards.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      entry.value,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // Helper methods
  Color _getColorFromHex(String hexColor) {
    return Color(int.parse(hexColor.substring(1, 7), radix: 16) + 0xFF000000);
  }

  String _getBMIRecommendation(double bmi) {
    if (bmi < 18.5) return 'Nên tăng cân lành mạnh';
    if (bmi < 25) return 'Duy trì cân nặng hiện tại';
    if (bmi < 30) return 'Nên giảm cân nhẹ';
    return 'Cần giảm cân nghiêm túc';
  }

  String _getWeightStatus(double current, Map<String, double> range) {
    if (current < range['min']!) return 'Dưới mức lý tưởng';
    if (current > range['max']!) return 'Trên mức lý tưởng';
    return 'Trong khoảng lý tưởng';
  }

  String _getWeightRecommendation(double current, Map<String, double> range) {
    if (current < range['min']!) {
      return 'Tăng ${(range['min']! - current).toStringAsFixed(1)} kg';
    }
    if (current > range['max']!) {
      return 'Giảm ${(current - range['max']!).toStringAsFixed(1)} kg';
    }
    return 'Duy trì cân nặng hiện tại';
  }

  Map<String, String> _getBodyFatStandards(String gender) {
    if (gender.toLowerCase() == 'nam') {
      return {
        'Thiết yếu': '< 6%',
        'Vận động viên': '6-13%',
        'Khỏe mạnh': '14-17%',
        'Chấp nhận được': '18-24%',
        'Béo phì': '≥ 25%',
      };
    } else {
      return {
        'Thiết yếu': '< 16%',
        'Vận động viên': '16-20%',
        'Khỏe mạnh': '21-24%',
        'Chấp nhận được': '25-31%',
        'Béo phì': '≥ 32%',
      };
    }
  }

  String _getBodyFatRecommendation(double bodyFat, String gender) {
    final isHealthy = gender.toLowerCase() == 'nam' 
        ? (bodyFat >= 14 && bodyFat <= 17)
        : (bodyFat >= 21 && bodyFat <= 24);
    
    if (isHealthy) return 'Tỷ lệ mỡ cơ thể lý tưởng';
    if (bodyFat < (gender.toLowerCase() == 'nam' ? 14 : 21)) {
      return 'Tỷ lệ mỡ thấp, cần tăng';
    }
    return 'Tỷ lệ mỡ cao, cần giảm';
  }

  Map<String, String> _getWHRStandards(String gender) {
    if (gender.toLowerCase() == 'nam') {
      return {
        'Thấp': '< 0.9',
        'Trung bình': '0.9 - 1.0',
        'Cao': '> 1.0',
      };
    } else {
      return {
        'Thấp': '< 0.8',
        'Trung bình': '0.8 - 0.85',
        'Cao': '> 0.85',
      };
    }
  }

  String _getWHRRecommendation(double whr, String gender) {
    final isHealthy = gender.toLowerCase() == 'nam' 
        ? (whr < 0.9)
        : (whr < 0.8);
    
    if (isHealthy) return 'Tỷ lệ vòng eo/mông tốt';
    return 'Cần giảm vòng eo để cải thiện sức khỏe';
  }

  String _getCalorieRecommendation(HealthData data) {
    return 'BMR: ${data.bmr.toStringAsFixed(0)} cal/ngày\n'
           'TDEE: ${data.tdee.toStringAsFixed(0)} cal/ngày';
  }

  Widget _buildWeightComparison() {
    final weightData = _comparisonData['weight'];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.scale, color: Colors.orange[600]),
                const SizedBox(width: 8),
                const Text(
                  'Cân nặng lý tưởng',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildWeightItem(
                    'Hiện tại',
                    '${weightData['current'].toStringAsFixed(1)} kg',
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildWeightItem(
                    'Lý tưởng',
                    '${weightData['ideal'].toStringAsFixed(1)} kg',
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Khoảng cân nặng lý tưởng (BMI 18.5-24.9)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${weightData['idealRange']['min'].toStringAsFixed(1)} - ${weightData['idealRange']['max'].toStringAsFixed(1)} kg',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        _getWeightStatusIcon(weightData['status']),
                        size: 16,
                        color: _getWeightStatusColor(weightData['status']),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        weightData['status'],
                        style: TextStyle(
                          fontSize: 14,
                          color: _getWeightStatusColor(weightData['status']),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    weightData['recommendation'],
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
    );
  }

  Widget _buildWeightItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildBodyFatComparison() {
    final bodyFatData = _comparisonData['bodyFat'];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.fitness_center, color: Colors.purple[600]),
                const SizedBox(width: 8),
                const Text(
                  'Tỷ lệ mỡ cơ thể',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '${bodyFatData['value'].toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: bodyFatData['color'],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bodyFatData['category'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: bodyFatData['color'],
                        ),
                      ),
                      Text(
                        bodyFatData['recommendation'],
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
            const SizedBox(height: 16),
            _buildStandardsTable('Chuẩn quốc tế', bodyFatData['standards']),
          ],
        ),
      ),
    );
  }

  Widget _buildWHRComparison() {
    final whrData = _comparisonData['whr'];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.straighten, color: Colors.teal[600]),
                const SizedBox(width: 8),
                const Text(
                  'Tỷ lệ vòng eo/mông (WHR)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  whrData['value'].toStringAsFixed(2),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        whrData['category'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        whrData['recommendation'],
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
            const SizedBox(height: 16),
            _buildStandardsTable('Chuẩn quốc tế', whrData['standards']),
          ],
        ),
      ),
    );
  }

  Widget _buildCalorieComparison() {
    final calorieData = _comparisonData['calories'];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_fire_department, color: Colors.red[600]),
                const SizedBox(width: 8),
                const Text(
                  'Nhu cầu calo hàng ngày',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildCalorieItem(
                    'BMR',
                    '${calorieData['bmr'].toStringAsFixed(0)} cal',
                    'Trao đổi chất cơ bản',
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildCalorieItem(
                    'TDEE',
                    '${calorieData['tdee'].toStringAsFixed(0)} cal',
                    'Tổng năng lượng tiêu thụ',
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.orange[700]),
                      const SizedBox(width: 4),
                      Text(
                        'Hướng dẫn',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• BMR: Số calo cần thiết để duy trì các chức năng cơ bản\n'
                    '• TDEE: Tổng calo cần thiết bao gồm hoạt động hàng ngày\n'
                    '• Để giảm cân: Ăn ít hơn TDEE 300-500 cal\n'
                    '• Để tăng cân: Ăn nhiều hơn TDEE 300-500 cal',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[700],
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

  Widget _buildCalorieItem(String label, String value, String description, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          description,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildWaterComparison() {
    final waterData = _comparisonData['water'];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.water_drop, color: Colors.blue[600]),
                const SizedBox(width: 8),
                const Text(
                  'Nhu cầu nước hàng ngày',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '${waterData['recommended'].toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[600],
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'lít',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue[600],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    waterData['recommendation'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 4),
                      Text(
                        'Lưu ý',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Nhu cầu nước được tính dựa trên cân nặng và mức độ hoạt động. '
                    'Uống nhiều nước hơn khi trời nóng hoặc tập thể dục.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
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

  IconData _getWeightStatusIcon(String status) {
    switch (status) {
      case 'Trong khoảng lý tưởng':
        return Icons.check_circle;
      case 'Dưới mức lý tưởng':
        return Icons.trending_up;
      case 'Trên mức lý tưởng':
        return Icons.trending_down;
      default:
        return Icons.help_outline;
    }
  }

  Color _getWeightStatusColor(String status) {
    switch (status) {
      case 'Trong khoảng lý tưởng':
        return Colors.green;
      case 'Dưới mức lý tưởng':
        return Colors.blue;
      case 'Trên mức lý tưởng':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
