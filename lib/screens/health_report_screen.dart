import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/health_data.dart';
import '../services/storage_service.dart';
import '../services/daily_tracking_service.dart';
import '../services/ai_service.dart';

class HealthReportScreen extends StatefulWidget {
  const HealthReportScreen({super.key});

  @override
  State<HealthReportScreen> createState() => _HealthReportScreenState();
}

class _HealthReportScreenState extends State<HealthReportScreen> {
  HealthData? _latestData;
  List<HealthData> _history = [];
  List<DailyRecord> _dailyRecords = [];
  bool _isLoading = true;
  bool _isGenerating = false;
  String _selectedPeriod = '30'; // 7, 30, 90 days

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final latestData = await StorageService.getLatestData();
      final history = await StorageService.getHistory();
      
      final trackingService = DailyTrackingService();
      await trackingService.initialize();
      final dailyRecords = trackingService.records;

      setState(() {
        _latestData = latestData;
        _history = history;
        _dailyRecords = dailyRecords;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo sức khỏe'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_latestData != null)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: _isGenerating ? null : _generateReport,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _latestData == null
              ? _buildNoDataWidget()
              : _buildReportContent(),
    );
  }

  Widget _buildNoDataWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có dữ liệu để tạo báo cáo',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vui lòng nhập thông tin sức khỏe để tạo báo cáo',
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

  Widget _buildReportContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPeriodSelector(),
          const SizedBox(height: 16),
          _buildReportPreview(),
          const SizedBox(height: 16),
          _buildGenerateSection(),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.date_range, color: Colors.blue[600]),
                const SizedBox(width: 8),
                const Text(
                  'Chọn khoảng thời gian',
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
                _buildPeriodChip('7', '7 ngày'),
                const SizedBox(width: 8),
                _buildPeriodChip('30', '30 ngày'),
                const SizedBox(width: 8),
                _buildPeriodChip('90', '90 ngày'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodChip(String value, String label) {
    final isSelected = _selectedPeriod == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[600] : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildReportPreview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.preview, color: Colors.green[600]),
                const SizedBox(width: 8),
                const Text(
                  'Xem trước báo cáo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPreviewItem('Thông tin cá nhân', 'Tuổi, giới tính, chiều cao, cân nặng'),
            _buildPreviewItem('Chỉ số sức khỏe', 'BMI, WHR, tỷ lệ mỡ cơ thể'),
            _buildPreviewItem('Xu hướng cân nặng', 'Biểu đồ thay đổi cân nặng theo thời gian'),
            _buildPreviewItem('Hoạt động hàng ngày', 'Bước chân, nước uống, giấc ngủ'),
            _buildPreviewItem('Phân tích AI', 'Đánh giá tổng thể và khuyến nghị'),
            _buildPreviewItem('Mục tiêu và kế hoạch', 'Mục tiêu đã đặt và tiến độ'),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  description,
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
    );
  }

  Widget _buildGenerateSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.file_download, color: Colors.indigo[600]),
                const SizedBox(width: 8),
                const Text(
                  'Tạo và chia sẻ báo cáo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Báo cáo sẽ được tạo dưới dạng văn bản chi tiết và có thể chia sẻ qua email, tin nhắn hoặc lưu vào thiết bị.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateReport,
                icon: _isGenerating 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.picture_as_pdf),
                label: Text(_isGenerating ? 'Đang tạo báo cáo...' : 'Tạo báo cáo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateReport() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final reportContent = await _createReportContent();
      await _shareReport(reportContent);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tạo báo cáo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Future<String> _createReportContent() async {
    final period = int.parse(_selectedPeriod);
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: period));
    
    // Filter data by period
    final filteredHistory = _history.where((data) {
      return data.timestamp.isAfter(startDate) && data.timestamp.isBefore(endDate);
    }).toList();
    
    final filteredDailyRecords = _dailyRecords.where((record) {
      return record.date.isAfter(startDate) && record.date.isBefore(endDate);
    }).toList();

    // Get AI analysis
    final aiInsight = await AIService.analyzeHealthData();

    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('=== BÁO CÁO SỨC KHỎE ===');
    buffer.writeln('Thời gian: ${_formatDate(startDate)} - ${_formatDate(endDate)}');
    buffer.writeln('Tạo lúc: ${_formatDateTime(DateTime.now())}');
    buffer.writeln('');

    // Personal Info
    buffer.writeln('--- THÔNG TIN CÁ NHÂN ---');
    buffer.writeln('Tuổi: ${_latestData!.age}');
    buffer.writeln('Giới tính: ${_latestData!.gender}');
    buffer.writeln('Chiều cao: ${_latestData!.height.toStringAsFixed(0)} cm');
    buffer.writeln('Cân nặng hiện tại: ${_latestData!.weight.toStringAsFixed(1)} kg');
    buffer.writeln('Mức độ hoạt động: ${_latestData!.activityLevel}');
    buffer.writeln('');

    // Health Metrics
    buffer.writeln('--- CHỈ SỐ SỨC KHỎE ---');
    buffer.writeln('BMI: ${_latestData!.bmi.toStringAsFixed(1)} (${_latestData!.bmiCategory})');
    buffer.writeln('BMR: ${_latestData!.bmr.toStringAsFixed(0)} cal/ngày');
    buffer.writeln('TDEE: ${_latestData!.tdee.toStringAsFixed(0)} cal/ngày');
    buffer.writeln('Cân nặng lý tưởng: ${_latestData!.idealWeight.toStringAsFixed(1)} kg');
    
    if (_latestData!.whr != null) {
      buffer.writeln('WHR: ${_latestData!.whr!.toStringAsFixed(2)} (${_latestData!.whrCategory})');
    }
    
    if (_latestData!.bodyFatPercentage != null) {
      buffer.writeln('Tỷ lệ mỡ cơ thể: ${_latestData!.bodyFatPercentage!.toStringAsFixed(1)}% (${_latestData!.bodyFatCategory})');
    }
    buffer.writeln('');

    // Weight Trend
    if (filteredHistory.isNotEmpty) {
      buffer.writeln('--- XU HƯỚNG CÂN NẶNG ---');
      buffer.writeln('Số lần đo: ${filteredHistory.length}');
      if (filteredHistory.length >= 2) {
        final firstWeight = filteredHistory.first.weight;
        final lastWeight = filteredHistory.last.weight;
        final weightChange = lastWeight - firstWeight;
        buffer.writeln('Thay đổi cân nặng: ${weightChange > 0 ? '+' : ''}${weightChange.toStringAsFixed(1)} kg');

        if (weightChange > 0) {
          buffer.writeln('Xu hướng: Tăng cân');
        } else if (weightChange < 0) {
          buffer.writeln('Xu hướng: Giảm cân');
        } else {
          buffer.writeln('Xu hướng: Ổn định');
        }
      }
      buffer.writeln('');
    }

    // Daily Activity Summary
    if (filteredDailyRecords.isNotEmpty) {
      buffer.writeln('--- HOẠT ĐỘNG HÀNG NGÀY ---');
      final totalDays = filteredDailyRecords.length;
      final avgSteps = filteredDailyRecords.map((r) => r.steps).reduce((a, b) => a + b) / totalDays;
      final avgWater = filteredDailyRecords.map((r) => r.waterIntake).reduce((a, b) => a + b) / totalDays;
      final avgSleep = filteredDailyRecords.map((r) => r.sleepHours).reduce((a, b) => a + b) / totalDays;

      buffer.writeln('Số ngày theo dõi: $totalDays');
      buffer.writeln('Trung bình bước chân: ${avgSteps.toStringAsFixed(0)} bước/ngày');
      buffer.writeln('Trung bình nước uống: ${avgWater.toStringAsFixed(1)} lít/ngày');
      buffer.writeln('Trung bình giấc ngủ: ${avgSleep.toStringAsFixed(1)} giờ/ngày');
      buffer.writeln('');
    }

    // AI Analysis
    buffer.writeln('--- PHÂN TÍCH AI ---');
    buffer.writeln('Tóm tắt: ${aiInsight.summary}');
    buffer.writeln('');
    buffer.writeln('Khuyến nghị:');
    for (int i = 0; i < aiInsight.recommendations.length; i++) {
      buffer.writeln('${i + 1}. ${aiInsight.recommendations[i]}');
    }
    buffer.writeln('');
    buffer.writeln('Mức độ rủi ro: ${_getRiskLevelText(aiInsight.riskLevel)}');
    buffer.writeln('');

    // Footer
    buffer.writeln('--- KẾT THÚC BÁO CÁO ---');
    buffer.writeln('Được tạo bởi Omi Health');
    buffer.writeln('Lưu ý: Đây chỉ là thông tin tham khảo, không thay thế lời khuyên y tế chuyên nghiệp.');

    return buffer.toString();
  }

  String _getRiskLevelText(RiskLevel riskLevel) {
    switch (riskLevel) {
      case RiskLevel.low:
        return 'Thấp - Sức khỏe tốt';
      case RiskLevel.medium:
        return 'Trung bình - Cần chú ý';
      case RiskLevel.high:
        return 'Cao - Cần cải thiện';
      case RiskLevel.unknown:
        return 'Chưa xác định';
    }
  }

  Future<void> _shareReport(String content) async {
    try {
      // Copy to clipboard as fallback
      await Clipboard.setData(ClipboardData(text: content));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Báo cáo đã được sao chép vào clipboard'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tạo báo cáo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
