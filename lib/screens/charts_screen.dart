import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/health_data.dart';
import '../services/storage_service.dart';

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> with TickerProviderStateMixin {
  List<HealthData> _history = [];
  bool _isLoading = true;
  late TabController _tabController;
  
  final List<String> _chartTypes = [
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
    _tabController = TabController(length: _chartTypes.length, vsync: this);
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final history = await StorageService.getHistory();
    setState(() {
      _history = history.reversed.toList(); // Hiển thị mới nhất trước
      _isLoading = false;
    });
  }

  Color _getColorFromHex(String hexColor) {
    final hex = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  List<FlSpot> _getChartData(String type) {
    if (_history.length < 2) return [];
    
    final sortedHistory = List<HealthData>.from(_history.reversed);
    List<FlSpot> spots = [];
    
    for (int i = 0; i < sortedHistory.length; i++) {
      final data = sortedHistory[i];
      double? value;
      
      switch (type) {
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

  Color _getChartColor(String type) {
    switch (type) {
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

  String _getUnit(String type) {
    switch (type) {
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

  Widget _buildChart(String type) {
    final spots = _getChartData(type);
    
    if (spots.isEmpty) {
      return Container(
        height: 300,
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bar_chart,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Không có dữ liệu cho $type',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                type == 'WHR' || type == 'Mỡ cơ thể' 
                  ? 'Cần nhập vòng eo và vòng mông để hiển thị biểu đồ này'
                  : 'Cần ít nhất 2 lần đo để hiển thị biểu đồ',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
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
            horizontalInterval: _getInterval(type),
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey[200]!,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toStringAsFixed(0)}${_getUnit(type)}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < _history.length) {
                    final data = _history.reversed.toList()[index];
                    return Text(
                      '${data.timestamp.day}/${data.timestamp.month}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: _getChartColor(type),
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: _getChartColor(type),
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: _getChartColor(type).withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getInterval(String type) {
    switch (type) {
      case 'BMI':
        return 2;
      case 'Cân nặng':
        return 5;
      case 'BMR':
      case 'TDEE':
        return 100;
      case 'WHR':
        return 0.1;
      case 'Mỡ cơ thể':
        return 5;
      default:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biểu đồ theo dõi'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _chartTypes.map((type) => Tab(text: type)).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: _chartTypes.map((type) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Biểu đồ $type theo thời gian',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildChart(type),
                      const SizedBox(height: 24),
                      _buildStatistics(type),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildStatistics(String type) {
    if (_history.isEmpty) {
      return const SizedBox.shrink();
    }

    List<double> values = [];
    for (final data in _history) {
      double? value;
      switch (type) {
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
      if (value != null) values.add(value);
    }

    if (values.isEmpty) {
      return const SizedBox.shrink();
    }

    final latest = values.first;
    final oldest = values.last;
    final change = latest - oldest;
    final average = values.reduce((a, b) => a + b) / values.length;
    final max = values.reduce((a, b) => a > b ? a : b);
    final min = values.reduce((a, b) => a < b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
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
          Text(
            'Thống kê $type',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Hiện tại',
                  '${latest.toStringAsFixed(1)}${_getUnit(type)}',
                  Icons.timeline,
                  _getChartColor(type),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Thay đổi',
                  '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}${_getUnit(type)}',
                  change >= 0 ? Icons.trending_up : Icons.trending_down,
                  change >= 0 ? const Color(0xFF2ECC71) : const Color(0xFFE74C3C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Trung bình',
                  '${average.toStringAsFixed(1)}${_getUnit(type)}',
                  Icons.analytics,
                  const Color(0xFF9B59B6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Cao nhất',
                  '${max.toStringAsFixed(1)}${_getUnit(type)}',
                  Icons.keyboard_arrow_up,
                  const Color(0xFFE67E22),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
        ],
      ),
    );
  }
}
