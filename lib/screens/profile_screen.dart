import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/health_data.dart';
import '../services/storage_service.dart';
import '../services/goal_service.dart';
import '../services/data_clear_service.dart';
import '../widgets/edit_profile_bottom_sheet.dart';
import 'history_screen.dart';
import 'notification_settings_screen.dart';
import 'ai_settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  HealthData? _currentData;
  bool _isLoading = true;
  String _selectedUnit = 'Metric';
  String _selectedLanguage = 'Tiếng Việt';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final currentData = await StorageService.getLatestData();
    setState(() {
      _currentData = currentData;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cá nhân'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _currentData != null ? _showEditProfile : null,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 24),
                  _buildHealthStats(),
                  const SizedBox(height: 24),
                  _buildSettingsSection(),
                  const SizedBox(height: 24),
                  _buildActionsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3498DB), Color(0xFF2980B9)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              _currentData?.gender.toLowerCase() == 'nam' 
                  ? Icons.person 
                  : Icons.person_outline,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Người dùng Omi Health',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_currentData != null) ...[
            const SizedBox(height: 8),
            Text(
              '${_currentData!.gender} • ${_currentData!.age} tuổi',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHealthStats() {
    if (_currentData == null) {
      return Container(
        padding: const EdgeInsets.all(24),
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
        child: Column(
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có dữ liệu sức khỏe',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy tính toán BMI để xem thông tin sức khỏe',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin sức khỏe',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Cân nặng',
                  '${_currentData!.weight.toStringAsFixed(1)} kg',
                  Icons.monitor_weight,
                  const Color(0xFF3498DB),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'Chiều cao',
                  '${_currentData!.height.toStringAsFixed(0)} cm',
                  Icons.height,
                  const Color(0xFF2ECC71),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'BMI',
                  _currentData!.bmi.toStringAsFixed(1),
                  Icons.favorite,
                  _getBMIColor(_currentData!.bmi),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'BMR',
                  '${_currentData!.bmr.toStringAsFixed(0)} kcal',
                  Icons.local_fire_department,
                  const Color(0xFFE67E22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getBMIColor(_currentData!.bmi).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: _getBMIColor(_currentData!.bmi),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tình trạng: ${_currentData!.bmiCategory}',
                  style: TextStyle(
                    color: _getBMIColor(_currentData!.bmi),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Cài đặt',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
          ),
          _buildSettingItem(
            'Thông báo',
            'Cài đặt nhắc nhở và thông báo',
            Icons.notifications_outlined,
            const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationSettingsScreen(),
                ),
              );
            },
          ),
          _buildDivider(),
          _buildSettingItem(
            'Cài đặt AI',
            'Cấu hình AI chatbot và API keys',
            Icons.smart_toy,
            const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AISettingsScreen(),
                ),
              );
            },
          ),
          _buildDivider(),
          _buildSettingItem(
            'Đơn vị đo lường',
            _selectedUnit,
            Icons.straighten,
            const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: _showUnitSelector,
          ),
          _buildDivider(),
          _buildSettingItem(
            'Ngôn ngữ',
            _selectedLanguage,
            Icons.language,
            const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: _showLanguageSelector,
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection() {
    return Container(
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
      child: Column(
        children: [
          _buildActionItem(
            'Lịch sử tính toán',
            'Xem tất cả dữ liệu đã lưu',
            Icons.history,
            const Color(0xFF3498DB),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
          ),
          _buildDivider(),
          _buildActionItem(
            'Xuất dữ liệu',
            'Sao lưu dữ liệu sức khỏe',
            Icons.download,
            const Color(0xFF2ECC71),
            onTap: _exportData,
          ),
          _buildDivider(),
          // Nút khôi phục dữ liệu khẩn cấp (chỉ hiện khi có backup)
          FutureBuilder<bool>(
            future: DataClearService.hasEmergencyBackup(),
            builder: (context, snapshot) {
              if (snapshot.data == true) {
                return Column(
                  children: [
                    _buildActionItem(
                      'Khôi phục dữ liệu khẩn cấp',
                      'Khôi phục từ backup tự động',
                      Icons.restore,
                      const Color(0xFF9B59B6),
                      onTap: _showRestoreConfirmation,
                    ),
                    _buildDivider(),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
          _buildActionItem(
            'Xóa tất cả dữ liệu',
            'Xóa toàn bộ lịch sử',
            Icons.delete_outline,
            const Color(0xFFE74C3C),
            onTap: _showDeleteConfirmation,
          ),
          _buildDivider(),
          _buildActionItem(
            'Về ứng dụng',
            'Thông tin phiên bản và nhà phát triển',
            Icons.info_outline,
            const Color(0xFF95A5A6),
            onTap: _showAboutDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(String title, String subtitle, IconData icon, Widget trailing, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF3498DB)),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF2C3E50),
        ),
      ),
      subtitle: Text(subtitle),
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildActionItem(String title, String subtitle, IconData icon, Color color, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF2C3E50),
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: Colors.grey[200],
      indent: 16,
      endIndent: 16,
    );
  }

  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) return const Color(0xFF3498DB);
    if (bmi < 25) return const Color(0xFF2ECC71);
    if (bmi < 30) return const Color(0xFFF39C12);
    return const Color(0xFFE74C3C);
  }

  void _showEditProfile() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditProfileBottomSheet(
        currentData: _currentData,
        onProfileUpdated: () {
          _loadData();
        },
      ),
    );
  }

  void _showUnitSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn đơn vị đo lường'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Metric (kg, cm)'),
              value: 'Metric',
              groupValue: _selectedUnit,
              onChanged: (value) {
                setState(() {
                  _selectedUnit = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Imperial (lbs, ft)'),
              value: 'Imperial',
              groupValue: _selectedUnit,
              onChanged: (value) {
                setState(() {
                  _selectedUnit = value!;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn ngôn ngữ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Tiếng Việt'),
              value: 'Tiếng Việt',
              groupValue: _selectedLanguage,
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('English'),
              value: 'English',
              groupValue: _selectedLanguage,
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value!;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _exportData() async {
    try {
      final healthHistory = await StorageService.getHistory();
      final goals = await GoalService.getGoals();

      final exportData = {
        'export_date': DateTime.now().toIso8601String(),
        'app_version': '1.0.0',
        'health_data': healthHistory.map((data) => data.toMap()).toList(),
        'goals': goals.map((goal) => goal.toMap()).toList(),
        'total_records': healthHistory.length,
        'total_goals': goals.length,
      };

      // Tạo nội dung JSON
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      // Hiển thị dialog với dữ liệu
      _showExportDialog(jsonString, exportData);

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Có lỗi xảy ra khi xuất dữ liệu'),
            backgroundColor: Color(0xFFE74C3C),
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DataClearDialog(),
    );
  }

  void _showRestoreConfirmation() async {
    final backupInfo = await DataClearService.getEmergencyBackupInfo();

    if (!mounted) return;

    if (backupInfo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy backup khẩn cấp'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.restore, color: Colors.blue[700]),
            const SizedBox(width: 8),
            const Text('Khôi phục dữ liệu'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tìm thấy backup khẩn cấp với thông tin sau:',
              style: TextStyle(fontWeight: FontWeight.w600),
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
                  Text('• Thời gian tạo: ${backupInfo['date']?.toString().split('.')[0] ?? 'Không xác định'}'),
                  Text('• Số lượng dữ liệu: ${backupInfo['keysCount']} mục'),
                  Text('• Lịch sử sức khỏe: ${backupInfo['hasHealthHistory'] ? 'Có' : 'Không'}'),
                  Text('• Dữ liệu mới nhất: ${backupInfo['hasLatestData'] ? 'Có' : 'Không'}'),
                  Text('• Mục tiêu: ${backupInfo['hasGoals'] ? 'Có' : 'Không'}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Việc khôi phục sẽ ghi đè lên dữ liệu hiện tại. Bạn có muốn tiếp tục?',
              style: TextStyle(color: Colors.orange),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performRestore();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Khôi phục'),
          ),
        ],
      ),
    );
  }

  Future<void> _performRestore() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Đang khôi phục dữ liệu...'),
          ],
        ),
      ),
    );

    try {
      final result = await DataClearService.restoreFromEmergencyBackup();

      if (mounted) {
        Navigator.pop(context); // Đóng progress dialog

        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          _loadData(); // Reload dữ liệu
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: ${result.message}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Đóng progress dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi không mong muốn: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Omi Health',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3498DB), Color(0xFF2980B9)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.favorite,
          color: Colors.white,
          size: 32,
        ),
      ),
      children: [
        const Text('Ứng dụng tính toán BMI và theo dõi sức khỏe toàn diện.'),
        const SizedBox(height: 16),
        const Text('Phát triển bởi: Omi Health Team'),
        const Text('Email: support@omihealth.com'),
      ],
    );
  }

  void _showExportDialog(String jsonString, Map<String, dynamic> exportData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.download, color: Color(0xFF2ECC71)),
            SizedBox(width: 8),
            Text('Xuất dữ liệu'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tổng cộng: ${exportData['total_records']} bản ghi sức khỏe và ${exportData['total_goals']} mục tiêu'),
              const SizedBox(height: 16),
              const Text('Dữ liệu JSON:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                height: 200,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    jsonString,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonString));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã sao chép dữ liệu vào clipboard'),
                  backgroundColor: Color(0xFF2ECC71),
                ),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('Sao chép'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2ECC71),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog xóa dữ liệu với nhiều tùy chọn
class _DataClearDialog extends StatefulWidget {
  @override
  State<_DataClearDialog> createState() => _DataClearDialogState();
}

class _DataClearDialogState extends State<_DataClearDialog> {
  int _currentStep = 0;
  DataStats? _dataStats;
  String _selectedOption = 'health_only'; // 'health_only', 'all_data'

  @override
  void initState() {
    super.initState();
    _loadDataStats();
  }

  Future<void> _loadDataStats() async {
    final stats = await DataClearService.getDataStats();
    setState(() {
      _dataStats = stats;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange[700],
            size: 24,
          ),
          const SizedBox(width: 8),
          const Text('Xóa dữ liệu'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: _buildStepContent(),
      ),
      actions: _buildActions(),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildOptionsStep();
      case 1:
        return _buildConfirmationStep();
      case 2:
        return _buildProgressStep();
      default:
        return _buildResultStep();
    }
  }

  Widget _buildOptionsStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn loại dữ liệu muốn xóa:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),

        // Option 1: Chỉ xóa dữ liệu sức khỏe
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: _selectedOption == 'health_only' ? Colors.blue : Colors.grey[300]!,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: RadioListTile<String>(
            value: 'health_only',
            groupValue: _selectedOption,
            onChanged: (value) {
              setState(() {
                _selectedOption = value!;
              });
            },
            title: const Text(
              'Chỉ dữ liệu sức khỏe',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Xóa lịch sử cân nặng, mục tiêu và dữ liệu sức khỏe.\nGiữ lại cài đặt ứng dụng.',
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Option 2: Xóa toàn bộ
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: _selectedOption == 'all_data' ? Colors.red : Colors.grey[300]!,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: RadioListTile<String>(
            value: 'all_data',
            groupValue: _selectedOption,
            onChanged: (value) {
              setState(() {
                _selectedOption = value!;
              });
            },
            title: const Text(
              'Toàn bộ dữ liệu',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Xóa tất cả dữ liệu bao gồm cài đặt.\nỨng dụng sẽ trở về trạng thái ban đầu.',
            ),
          ),
        ),

        if (_dataStats != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thống kê dữ liệu hiện tại:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text('• Tổng số keys: ${_dataStats!.totalKeys}'),
                Text('• Dữ liệu sức khỏe: ${_dataStats!.healthDataKeys} keys'),
                Text('• Cài đặt: ${_dataStats!.settingsKeys} keys'),
                Text('• Kích thước ước tính: ${_dataStats!.estimatedSizeFormatted}'),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildConfirmationStep() {
    final isHealthOnly = _selectedOption == 'health_only';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning, color: Colors.red[700]),
                  const SizedBox(width: 8),
                  const Text(
                    'Cảnh báo quan trọng',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                isHealthOnly
                  ? 'Bạn sắp xóa toàn bộ dữ liệu sức khỏe bao gồm:\n'
                    '• Lịch sử cân nặng và BMI\n'
                    '• Tất cả mục tiêu đã tạo\n'
                    '• Tiến độ theo dõi\n\n'
                    'Cài đặt ứng dụng sẽ được giữ lại.'
                  : 'Bạn sắp xóa TOÀN BỘ dữ liệu ứng dụng bao gồm:\n'
                    '• Tất cả dữ liệu sức khỏe\n'
                    '• Cài đặt và tùy chọn\n'
                    '• Cache và dữ liệu tạm\n\n'
                    'Ứng dụng sẽ trở về trạng thái ban đầu.',
                style: TextStyle(color: Colors.red[700]),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        const Text(
          'Hành động này KHÔNG THỂ HOÀN TÁC!',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Để xác nhận, vui lòng gõ "XÓA DỮ LIỆU" vào ô bên dưới:',
          style: TextStyle(fontSize: 14),
        ),

        const SizedBox(height: 12),

        TextField(
          onChanged: (value) {
            setState(() {
              _confirmationText = value;
            });
          },
          decoration: const InputDecoration(
            hintText: 'Gõ "XÓA DỮ LIỆU" để xác nhận',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  String _confirmationText = '';

  Widget _buildProgressStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        const Text(
          'Đang xóa dữ liệu...',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 8),
        const Text(
          'Vui lòng không tắt ứng dụng',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildResultStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 48,
        ),
        const SizedBox(height: 16),
        const Text(
          'Xóa dữ liệu thành công!',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Ứng dụng sẽ khởi động lại để áp dụng thay đổi.',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  List<Widget> _buildActions() {
    switch (_currentStep) {
      case 0:
        return [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _currentStep = 1;
              });
            },
            child: const Text('Tiếp tục'),
          ),
        ];
      case 1:
        return [
          TextButton(
            onPressed: () {
              setState(() {
                _currentStep = 0;
                _confirmationText = '';
              });
            },
            child: const Text('Quay lại'),
          ),
          ElevatedButton(
            onPressed: _confirmationText == 'XÓA DỮ LIỆU' ? _performDataClear : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('XÓA DỮ LIỆU'),
          ),
        ];
      case 2:
        return [];
      default:
        return [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handlePostClearActions();
            },
            child: const Text('Hoàn tất'),
          ),
        ];
    }
  }

  Future<void> _performDataClear() async {
    setState(() {
      _currentStep = 2;
    });

    try {
      DataClearResult result;

      if (_selectedOption == 'health_only') {
        result = await DataClearService.clearHealthDataOnly();
      } else {
        result = await DataClearService.clearAllData();
      }

      if (result.success) {
        setState(() {
          _currentStep = 3;
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        // Show error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: ${result.message}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi không mong muốn: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
        Navigator.pop(context);
      }
    } finally {
      // Cleanup if needed
    }
  }

  void _handlePostClearActions() {
    // Reload dữ liệu trong ProfileScreen parent
    if (context.mounted) {
      // Tìm ProfileScreen parent và reload data
      final profileState = context.findAncestorStateOfType<_ProfileScreenState>();
      profileState?._loadData();

      // Có thể thêm logic khác như:
      // - Navigate về home screen
      // - Reset navigation stack
      // - Show welcome screen cho user mới

      // Hiển thị thông báo hướng dẫn
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Dữ liệu đã được xóa. Bạn có thể bắt đầu nhập dữ liệu mới.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }
}
