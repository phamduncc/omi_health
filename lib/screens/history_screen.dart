import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/health_data.dart';
import '../services/storage_service.dart';
import 'charts_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<HealthData> _history = [];
  bool _isLoading = true;
  String _selectedMetric = 'BMI';

  final List<String> _metrics = [
    'BMI',
    'Cân nặng',
    'BMR',
    'TDEE',
    'WHR',
    'Mỡ cơ thể',
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await StorageService.getHistory();
    setState(() {
      _history = history.reversed.toList(); // Hiển thị mới nhất trước
      _isLoading = false;
    });
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa lịch sử'),
        content: const Text('Bạn có chắc chắn muốn xóa toàn bộ lịch sử?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await StorageService.clearHistory();
      _loadHistory();
    }
  }

  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) return const Color(0xFF3498DB);
    if (bmi < 25) return const Color(0xFF2ECC71);
    if (bmi < 30) return const Color(0xFFF39C12);
    return const Color(0xFFE74C3C);
  }

  List<FlSpot> _getChartData(String metric) {
    if (_history.length < 2) return [];

    final sortedHistory = List<HealthData>.from(_history.reversed);
    List<FlSpot> spots = [];

    for (int i = 0; i < sortedHistory.length; i++) {
      final data = sortedHistory[i];
      double? value;

      switch (metric) {
        case 'BMI':
          value = data.bmi;
          break;
        case 'Cân nặng':
          value = data.weight;
          break;
        case 'BMR':
          value = data.bmr;
          break;
        case 'TDEE':
          value = data.tdee;
          break;
        case 'WHR':
          value = data.whr;
          break;
        case 'Mỡ cơ thể':
          value = data.bodyFatPercentage;
          break;
      }

      if (value != null) {
        spots.add(FlSpot(i.toDouble(), value));
      }
    }

    return spots;
  }

  Color _getMetricColor(String metric) {
    switch (metric) {
      case 'BMI':
        return const Color(0xFF3498DB);
      case 'Cân nặng':
        return const Color(0xFF2ECC71);
      case 'BMR':
        return const Color(0xFF9B59B6);
      case 'TDEE':
        return const Color(0xFFE67E22);
      case 'WHR':
        return const Color(0xFFE74C3C);
      case 'Mỡ cơ thể':
        return const Color(0xFFF39C12);
      default:
        return const Color(0xFF95A5A6);
    }
  }

  String _getMetricUnit(String metric) {
    switch (metric) {
      case 'BMI':
        return '';
      case 'Cân nặng':
        return 'kg';
      case 'BMR':
      case 'TDEE':
        return 'kcal';
      case 'WHR':
        return '';
      case 'Mỡ cơ thể':
        return '%';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử'),
        actions: [
          // Dropdown để chọn metric
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: _selectedMetric,
              underline: const SizedBox.shrink(),
              dropdownColor: Colors.white,
              style: const TextStyle(color: Color(0xFF2C3E50)),
              items: _metrics.map((metric) {
                return DropdownMenuItem(
                  value: metric,
                  child: Text(metric),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedMetric = value;
                  });
                }
              },
            ),
          ),
          if (_history.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.bar_chart),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChartsScreen(),
                  ),
                );
              },
              tooltip: 'Xem biểu đồ chi tiết',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearHistory,
              tooltip: 'Xóa lịch sử',
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Chưa có dữ liệu lịch sử',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Chart for selected metric
                      if (_getChartData(_selectedMetric).isNotEmpty) ...[
                        Text(
                          'Biểu đồ $_selectedMetric theo thời gian',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 200,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.1),
                                spreadRadius: 1,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: LineChart(
                            LineChartData(
                              gridData: const FlGridData(show: false),
                              titlesData: const FlTitlesData(show: false),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: _getChartData(_selectedMetric),
                                  isCurved: true,
                                  color: _getMetricColor(_selectedMetric),
                                  barWidth: 3,
                                  dotData: const FlDotData(show: true),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: _getMetricColor(_selectedMetric).withValues(alpha: 0.1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ] else if (_history.length >= 2) ...[
                        Container(
                          height: 150,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.bar_chart,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Không có dữ liệu cho $_selectedMetric',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _selectedMetric == 'WHR' || _selectedMetric == 'Mỡ cơ thể'
                                      ? 'Cần nhập vòng eo và vòng mông'
                                      : 'Dữ liệu không khả dụng',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // History List
                      const Text(
                        'Lịch sử tính toán',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 16),

                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _history.length,
                        itemBuilder: (context, index) {
                          final data = _history[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: _getBMIColor(data.bmi).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: Icon(
                                  Icons.monitor_weight,
                                  color: _getBMIColor(data.bmi),
                                ),
                              ),
                              title: Text(
                                'BMI: ${data.bmi.toStringAsFixed(1)} - ${data.bmiCategory}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    '${data.weight}kg • ${data.height}cm • ${data.age} tuổi • ${data.gender}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  // Hiển thị các chỉ số bổ sung nếu có
                                  if (data.whr != null || data.bodyFatPercentage != null) ...[
                                    Row(
                                      children: [
                                        if (data.whr != null) ...[
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: _getMetricColor('WHR').withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'WHR: ${data.whr!.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                color: _getMetricColor('WHR'),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                        ],
                                        if (data.bodyFatPercentage != null) ...[
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: _getMetricColor('Mỡ cơ thể').withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Mỡ: ${data.bodyFatPercentage!.toStringAsFixed(1)}%',
                                              style: TextStyle(
                                                color: _getMetricColor('Mỡ cơ thể'),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                  ],
                                  Text(
                                    '${data.timestamp.day}/${data.timestamp.month}/${data.timestamp.year} ${data.timestamp.hour}:${data.timestamp.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'BMR',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '${data.bmr.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
    );
  }
}
