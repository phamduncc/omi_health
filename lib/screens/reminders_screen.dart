import 'package:flutter/material.dart';
import '../services/reminder_service.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final ReminderService _reminderService = ReminderService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    await _reminderService.initialize();
    await _reminderService.createDefaultReminders();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhắc nhở thông minh'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showReminderSettings,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddReminderDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListenableBuilder(
              listenable: _reminderService,
              builder: (context, child) {
                return _buildRemindersList();
              },
            ),
    );
  }

  Widget _buildRemindersList() {
    final reminders = _reminderService.reminders;
    final stats = _reminderService.getReminderStats();

    return Column(
      children: [
        // Thống kê nhắc nhở
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Tổng số',
                  '${stats['total']}',
                  Icons.notifications,
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Đang bật',
                  '${stats['enabled']}',
                  Icons.notifications_active,
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Hôm nay',
                  '${stats['completedToday']}',
                  Icons.check_circle,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ),

        // Danh sách nhắc nhở
        Expanded(
          child: reminders.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_off,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Chưa có nhắc nhở nào',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: reminders.length,
                  itemBuilder: (context, index) {
                    final reminder = reminders[index];
                    return _buildReminderCard(reminder);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildReminderCard(AppReminder reminder) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getReminderColor(reminder.type).withValues(alpha: 0.1),
          child: Icon(
            _getReminderIcon(reminder.type),
            color: _getReminderColor(reminder.type),
          ),
        ),
        title: Text(
          reminder.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(reminder.message),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  _getFrequencyText(reminder.frequency),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (reminder.lastCompleted != null) ...[
                  const SizedBox(width: 12),
                  Icon(
                    Icons.check_circle,
                    size: 14,
                    color: Colors.green[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Hoàn thành: ${reminder.completionCount} lần',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[600],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: reminder.isEnabled,
              onChanged: (value) {
                _reminderService.toggleReminder(reminder.id, value);
              },
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _showEditReminderDialog(reminder);
                    break;
                  case 'complete':
                    _reminderService.markReminderCompleted(reminder.id);
                    _showCompletionSnackBar(reminder.title);
                    break;
                  case 'delete':
                    _showDeleteConfirmation(reminder);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16),
                      SizedBox(width: 8),
                      Text('Chỉnh sửa'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'complete',
                  child: Row(
                    children: [
                      Icon(Icons.check, size: 16),
                      SizedBox(width: 8),
                      Text('Đánh dấu hoàn thành'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Xóa', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getReminderColor(ReminderType type) {
    switch (type) {
      case ReminderType.water:
        return Colors.blue;
      case ReminderType.weight:
        return Colors.green;
      case ReminderType.exercise:
        return Colors.orange;
      case ReminderType.measurement:
        return Colors.purple;
      case ReminderType.medication:
        return Colors.red;
      case ReminderType.custom:
        return Colors.grey;
    }
  }

  IconData _getReminderIcon(ReminderType type) {
    switch (type) {
      case ReminderType.water:
        return Icons.water_drop;
      case ReminderType.weight:
        return Icons.monitor_weight;
      case ReminderType.exercise:
        return Icons.fitness_center;
      case ReminderType.measurement:
        return Icons.straighten;
      case ReminderType.medication:
        return Icons.medication;
      case ReminderType.custom:
        return Icons.notifications;
    }
  }

  String _getFrequencyText(ReminderFrequency frequency) {
    switch (frequency) {
      case ReminderFrequency.hourly:
        return 'Mỗi giờ';
      case ReminderFrequency.daily:
        return 'Hàng ngày';
      case ReminderFrequency.weekly:
        return 'Hàng tuần';
      case ReminderFrequency.custom:
        return 'Tùy chỉnh';
    }
  }

  void _showReminderSettings() {
    // TODO: Implement settings dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cài đặt nhắc nhở sẽ được thêm sau')),
    );
  }

  void _showAddReminderDialog() {
    // TODO: Implement add reminder dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thêm nhắc nhở sẽ được thêm sau')),
    );
  }

  void _showEditReminderDialog(AppReminder reminder) {
    // TODO: Implement edit reminder dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chỉnh sửa nhắc nhở sẽ được thêm sau')),
    );
  }

  void _showDeleteConfirmation(AppReminder reminder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa nhắc nhở'),
        content: Text('Bạn có chắc chắn muốn xóa nhắc nhở "${reminder.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _reminderService.removeReminder(reminder.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đã xóa nhắc nhở "${reminder.title}"')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _showCompletionSnackBar(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã hoàn thành: $title'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'Tuyệt vời!',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }
}
