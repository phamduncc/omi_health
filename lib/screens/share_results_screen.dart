import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/health_data.dart';
import '../models/daily_record.dart' as daily_model;
import '../services/storage_service.dart';
import '../services/daily_tracking_service.dart';

class ShareResultsScreen extends StatefulWidget {
  const ShareResultsScreen({super.key});

  @override
  State<ShareResultsScreen> createState() => _ShareResultsScreenState();
}

class _ShareResultsScreenState extends State<ShareResultsScreen> {
  HealthData? _latestData;
  daily_model.DailyRecord? _todayRecord;
  bool _isLoading = true;
  String _selectedShareType = 'achievement'; // achievement, progress, stats

  final Map<String, String> _shareTypes = {
    'achievement': 'Thành tích',
    'progress': 'Tiến độ',
    'stats': 'Thống kê',
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final latestData = await StorageService.getLatestData();
      
      final trackingService = DailyTrackingService();
      await trackingService.initialize();
      final todayRecord = trackingService.getTodayRecord();

      setState(() {
        _latestData = latestData;
        _todayRecord = todayRecord as daily_model.DailyRecord?;
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
        title: const Text('Chia sẻ kết quả'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _latestData == null
              ? _buildNoDataWidget()
              : _buildShareContent(),
    );
  }

  Widget _buildNoDataWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.share_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có dữ liệu để chia sẻ',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vui lòng nhập thông tin sức khỏe để chia sẻ',
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

  Widget _buildShareContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShareTypeSelector(),
          const SizedBox(height: 16),
          _buildPreviewCard(),
          const SizedBox(height: 16),
          _buildShareOptions(),
        ],
      ),
    );
  }

  Widget _buildShareTypeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.category, color: Colors.purple[600]),
                const SizedBox(width: 8),
                const Text(
                  'Chọn loại chia sẻ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _shareTypes.entries.map((entry) {
                return _buildShareTypeChip(entry.key, entry.value);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareTypeChip(String value, String label) {
    final isSelected = _selectedShareType == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedShareType = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple[600] : Colors.grey[200],
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

  Widget _buildPreviewCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.preview, color: Colors.blue[600]),
                const SizedBox(width: 8),
                const Text(
                  'Xem trước nội dung',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPreviewContent(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewContent() {
    switch (_selectedShareType) {
      case 'achievement':
        return _buildAchievementPreview();
      case 'progress':
        return _buildProgressPreview();
      case 'stats':
        return _buildStatsPreview();
      default:
        return const SizedBox();
    }
  }

  Widget _buildAchievementPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.amber[600], size: 24),
            const SizedBox(width: 8),
            const Text(
              'Thành tích hôm nay! 🎉',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_todayRecord != null) ...[
          _buildAchievementItem(
            '👟 Bước chân',
            '${_todayRecord!.steps.toStringAsFixed(0)} bước',
            _todayRecord!.steps >= 8000,
          ),
          _buildAchievementItem(
            '💧 Nước uống',
            '${_todayRecord!.waterIntake.toStringAsFixed(1)} lít',
            _todayRecord!.waterIntake >= 2.0,
          ),
          _buildAchievementItem(
            '😴 Giấc ngủ',
            '${_todayRecord!.sleepHours.toStringAsFixed(1)} giờ',
            _todayRecord!.sleepHours >= 7.0,
          ),
        ],
        const SizedBox(height: 8),
        Text(
          'BMI: ${_latestData!.bmi.toStringAsFixed(1)} (${_latestData!.bmiCategory})',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '#OmiHealth #SứcKhỏe #LốiSốngLànhMạnh',
          style: TextStyle(
            fontSize: 12,
            color: Colors.blue,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementItem(String label, String value, bool isAchieved) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isAchieved ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: isAchieved ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 14,
              color: isAchieved ? Colors.green[700] : Colors.grey[600],
              fontWeight: isAchieved ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.trending_up, color: Colors.green[600], size: 24),
            const SizedBox(width: 8),
            const Text(
              'Tiến độ sức khỏe của tôi 📈',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Cân nặng hiện tại: ${_latestData!.weight.toStringAsFixed(1)} kg',
          style: const TextStyle(fontSize: 14),
        ),
        Text(
          'BMI: ${_latestData!.bmi.toStringAsFixed(1)} (${_latestData!.bmiCategory})',
          style: const TextStyle(fontSize: 14),
        ),
        Text(
          'Cân nặng lý tưởng: ${_latestData!.idealWeight.toStringAsFixed(1)} kg',
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 8),
        Text(
          'Đang nỗ lực để đạt được mục tiêu sức khỏe! 💪',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '#OmiHealth #TiếnĐộ #MụcTiêu',
          style: TextStyle(
            fontSize: 12,
            color: Colors.blue,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.analytics, color: Colors.indigo[600], size: 24),
            const SizedBox(width: 8),
            const Text(
              'Thống kê sức khỏe 📊',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildStatItem('Tuổi', '${_latestData!.age}'),
        _buildStatItem('Chiều cao', '${_latestData!.height.toStringAsFixed(0)} cm'),
        _buildStatItem('Cân nặng', '${_latestData!.weight.toStringAsFixed(1)} kg'),
        _buildStatItem('BMI', '${_latestData!.bmi.toStringAsFixed(1)}'),
        _buildStatItem('BMR', '${_latestData!.bmr.toStringAsFixed(0)} cal/ngày'),
        _buildStatItem('TDEE', '${_latestData!.tdee.toStringAsFixed(0)} cal/ngày'),
        const SizedBox(height: 8),
        const Text(
          '#OmiHealth #ThốngKê #SứcKhỏe',
          style: TextStyle(
            fontSize: 12,
            color: Colors.blue,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareOptions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.share, color: Colors.pink[600]),
                const SizedBox(width: 8),
                const Text(
                  'Chia sẻ qua',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildShareButton(
                    'Chia sẻ',
                    Icons.share,
                    Colors.blue,
                    _shareContent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildShareButton(
                    'Sao chép',
                    Icons.copy,
                    Colors.green,
                    _copyContent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Future<void> _shareContent() async {
    final content = _generateShareContent();
    await Share.share(
      content,
      subject: 'Kết quả sức khỏe từ Omi Health',
    );
  }

  Future<void> _copyContent() async {
    final content = _generateShareContent();
    await Clipboard.setData(ClipboardData(text: content));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã sao chép vào clipboard'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  String _generateShareContent() {
    switch (_selectedShareType) {
      case 'achievement':
        return _generateAchievementContent();
      case 'progress':
        return _generateProgressContent();
      case 'stats':
        return _generateStatsContent();
      default:
        return '';
    }
  }

  String _generateAchievementContent() {
    final buffer = StringBuffer();
    buffer.writeln('🎉 Thành tích hôm nay!');
    buffer.writeln('');
    
    if (_todayRecord != null) {
      buffer.writeln('👟 Bước chân: ${_todayRecord!.steps.toStringAsFixed(0)} bước ${_todayRecord!.steps >= 8000 ? '✅' : ''}');
      buffer.writeln('💧 Nước uống: ${_todayRecord!.waterIntake.toStringAsFixed(1)} lít ${_todayRecord!.waterIntake >= 2.0 ? '✅' : ''}');
      buffer.writeln('😴 Giấc ngủ: ${_todayRecord!.sleepHours.toStringAsFixed(1)} giờ ${_todayRecord!.sleepHours >= 7.0 ? '✅' : ''}');
    }
    
    buffer.writeln('');
    buffer.writeln('BMI: ${_latestData!.bmi.toStringAsFixed(1)} (${_latestData!.bmiCategory})');
    buffer.writeln('');
    buffer.writeln('#OmiHealth #SứcKhỏe #LốiSốngLànhMạnh');
    
    return buffer.toString();
  }

  String _generateProgressContent() {
    final buffer = StringBuffer();
    buffer.writeln('📈 Tiến độ sức khỏe của tôi');
    buffer.writeln('');
    buffer.writeln('Cân nặng hiện tại: ${_latestData!.weight.toStringAsFixed(1)} kg');
    buffer.writeln('BMI: ${_latestData!.bmi.toStringAsFixed(1)} (${_latestData!.bmiCategory})');
    buffer.writeln('Cân nặng lý tưởng: ${_latestData!.idealWeight.toStringAsFixed(1)} kg');
    buffer.writeln('');
    buffer.writeln('Đang nỗ lực để đạt được mục tiêu sức khỏe! 💪');
    buffer.writeln('');
    buffer.writeln('#OmiHealth #TiếnĐộ #MụcTiêu');
    
    return buffer.toString();
  }

  String _generateStatsContent() {
    final buffer = StringBuffer();
    buffer.writeln('📊 Thống kê sức khỏe');
    buffer.writeln('');
    buffer.writeln('Tuổi: ${_latestData!.age}');
    buffer.writeln('Chiều cao: ${_latestData!.height.toStringAsFixed(0)} cm');
    buffer.writeln('Cân nặng: ${_latestData!.weight.toStringAsFixed(1)} kg');
    buffer.writeln('BMI: ${_latestData!.bmi.toStringAsFixed(1)}');
    buffer.writeln('BMR: ${_latestData!.bmr.toStringAsFixed(0)} cal/ngày');
    buffer.writeln('TDEE: ${_latestData!.tdee.toStringAsFixed(0)} cal/ngày');
    buffer.writeln('');
    buffer.writeln('#OmiHealth #ThốngKê #SứcKhỏe');
    
    return buffer.toString();
  }
}
