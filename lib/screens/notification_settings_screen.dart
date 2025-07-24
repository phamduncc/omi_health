import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  List<NotificationSettings> _settings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await NotificationService.getNotificationSettings();
    setState(() {
      _settings = settings;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    await NotificationService.saveNotificationSettings(_settings);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu cài đặt thông báo'),
          backgroundColor: Color(0xFF2ECC71),
        ),
      );
    }
  }

  void _updateSetting(int index, NotificationSettings newSetting) {
    setState(() {
      _settings[index] = newSetting;
    });
    _saveSettings();
  }

  String _getWeekdaysText(List<int> weekdays) {
    if (weekdays.length == 7) return 'Hàng ngày';
    if (weekdays.length == 5 && weekdays.every((day) => day <= 5)) return 'Thứ 2 - Thứ 6';
    if (weekdays.length == 2 && weekdays.contains(6) && weekdays.contains(7)) return 'Cuối tuần';
    
    final dayNames = ['', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return weekdays.map((day) => dayNames[day]).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt thông báo'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _settings.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildHeader();
                }
                
                final setting = _settings[index - 1];
                return _buildSettingCard(setting, index - 1);
              },
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
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
          Row(
            children: [
              Icon(
                Icons.notifications_active,
                color: Colors.white,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Thông báo thông minh',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Nhận nhắc nhở và cập nhật về sức khỏe của bạn vào đúng thời điểm phù hợp.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard(NotificationSettings setting, int index) {
    final color = NotificationService.getNotificationColor(setting.type);
    final icon = NotificationService.getNotificationIcon(setting.type);
    final title = NotificationService.getNotificationTitle(setting.type);
    final description = NotificationService.getNotificationContent(setting.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        children: [
          // Header with switch
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
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
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: setting.enabled,
                  onChanged: (value) {
                    _updateSetting(
                      index,
                      NotificationSettings(
                        enabled: value,
                        time: setting.time,
                        weekdays: setting.weekdays,
                        type: setting.type,
                      ),
                    );
                  },
                  activeColor: color,
                ),
              ],
            ),
          ),
          
          // Settings details (only show when enabled)
          if (setting.enabled) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Time setting
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Thời gian:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () => _selectTime(setting, index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${setting.time.hour.toString().padLeft(2, '0')}:${setting.time.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Weekdays setting
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Lặp lại:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () => _selectWeekdays(setting, index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _getWeekdaysText(setting.weekdays),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.chevron_right,
                                color: color,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _selectTime(NotificationSettings setting, int index) async {
    final time = await showTimePicker(
      context: context,
      initialTime: setting.time,
    );
    
    if (time != null) {
      _updateSetting(
        index,
        NotificationSettings(
          enabled: setting.enabled,
          time: time,
          weekdays: setting.weekdays,
          type: setting.type,
        ),
      );
    }
  }

  Future<void> _selectWeekdays(NotificationSettings setting, int index) async {
    final result = await showDialog<List<int>>(
      context: context,
      builder: (context) => _WeekdaySelector(
        selectedWeekdays: setting.weekdays,
      ),
    );
    
    if (result != null) {
      _updateSetting(
        index,
        NotificationSettings(
          enabled: setting.enabled,
          time: setting.time,
          weekdays: result,
          type: setting.type,
        ),
      );
    }
  }
}

class _WeekdaySelector extends StatefulWidget {
  final List<int> selectedWeekdays;

  const _WeekdaySelector({required this.selectedWeekdays});

  @override
  State<_WeekdaySelector> createState() => _WeekdaySelectorState();
}

class _WeekdaySelectorState extends State<_WeekdaySelector> {
  late List<int> _selected;

  final List<String> _dayNames = ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'Chủ nhật'];

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedWeekdays);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chọn ngày lặp lại'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(7, (index) {
          final dayValue = index + 1;
          final isSelected = _selected.contains(dayValue);
          
          return CheckboxListTile(
            title: Text(_dayNames[index]),
            value: isSelected,
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _selected.add(dayValue);
                } else {
                  _selected.remove(dayValue);
                }
                _selected.sort();
              });
            },
            activeColor: const Color(0xFF3498DB),
          );
        }),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _selected.isEmpty ? null : () => Navigator.pop(context, _selected),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3498DB),
            foregroundColor: Colors.white,
          ),
          child: const Text('Xong'),
        ),
      ],
    );
  }
}
