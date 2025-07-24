import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/daily_tracking_service.dart';

class DailyTrackingScreen extends StatefulWidget {
  const DailyTrackingScreen({super.key});

  @override
  State<DailyTrackingScreen> createState() => _DailyTrackingScreenState();
}

class _DailyTrackingScreenState extends State<DailyTrackingScreen> {
  final DailyTrackingService _trackingService = DailyTrackingService();
  bool _isLoading = true;
  DailyRecord? _todayRecord;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    await _trackingService.initialize();
    setState(() {
      _todayRecord = _trackingService.getTodayRecord();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theo dõi hàng ngày'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showHistory,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListenableBuilder(
              listenable: _trackingService,
              builder: (context, child) {
                _todayRecord = _trackingService.getTodayRecord();
                return _buildTrackingContent();
              },
            ),
    );
  }

  Widget _buildTrackingContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header với ngày
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[400]!, Colors.blue[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.today, color: Colors.white, size: 32),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hôm nay',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _formatDate(DateTime.now()),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Tracking cards
          _buildStepsCard(),
          const SizedBox(height: 16),
          _buildWaterCard(),
          const SizedBox(height: 16),
          _buildSleepCard(),
          const SizedBox(height: 16),
          _buildMoodCard(),
          const SizedBox(height: 16),
          _buildNotesCard(),
          const SizedBox(height: 24),

          // Weekly stats
          _buildWeeklyStats(),
        ],
      ),
    );
  }

  Widget _buildStepsCard() {
    final steps = _todayRecord?.steps ?? 0;
    final goal = _trackingService.settings.dailyStepsGoal;
    final progress = (steps / goal).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.directions_walk, color: Colors.green[600]),
                const SizedBox(width: 8),
                const Text(
                  'Bước chân',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _editSteps(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '$steps',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '/ $goal bước',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
            ),
            const SizedBox(height: 8),
            Text(
              '${(progress * 100).toStringAsFixed(0)}% hoàn thành',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaterCard() {
    final water = _todayRecord?.waterIntake ?? 0.0;
    final goal = _trackingService.settings.dailyWaterGoal;
    final progress = (water / goal).clamp(0.0, 1.0);

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
                  'Nước uống',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: () => _addWater(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '${water.toStringAsFixed(1)}L',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '/ ${goal.toStringAsFixed(1)}L',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${(progress * 100).toStringAsFixed(0)}% hoàn thành',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _editWater(),
                  child: const Text('Chỉnh sửa'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSleepCard() {
    final sleep = _todayRecord?.sleepHours ?? 0.0;
    final goal = _trackingService.settings.dailySleepGoal;
    final progress = (sleep / goal).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bedtime, color: Colors.purple[600]),
                const SizedBox(width: 8),
                const Text(
                  'Giấc ngủ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _editSleep(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '${sleep.toStringAsFixed(1)}h',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '/ ${goal.toStringAsFixed(1)}h',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.purple[600]!),
            ),
            const SizedBox(height: 8),
            Text(
              '${(progress * 100).toStringAsFixed(0)}% hoàn thành',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodCard() {
    final mood = _todayRecord?.mood;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sentiment_satisfied, color: Colors.orange[600]),
                const SizedBox(width: 8),
                const Text(
                  'Tâm trạng',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: MoodLevel.values.map((moodLevel) {
                final isSelected = mood == moodLevel;
                return GestureDetector(
                  onTap: () => _updateMood(moodLevel),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? moodLevel.color.withValues(alpha: 0.2) : null,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected ? Border.all(color: moodLevel.color) : null,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          moodLevel.icon,
                          color: isSelected ? moodLevel.color : Colors.grey,
                          size: 32,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          moodLevel.name,
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected ? moodLevel.color : Colors.grey,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard() {
    final notes = _todayRecord?.notes ?? '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.note_alt, color: Colors.teal[600]),
                const SizedBox(width: 8),
                const Text(
                  'Ghi chú',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _editNotes(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                notes.isEmpty ? 'Chưa có ghi chú...' : notes,
                style: TextStyle(
                  fontSize: 14,
                  color: notes.isEmpty ? Colors.grey[500] : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyStats() {
    final stats = _trackingService.getWeeklyStats();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thống kê tuần này',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Bước TB',
                    '${stats['averageSteps']}',
                    Icons.directions_walk,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Nước',
                    '${stats['totalWater'].toStringAsFixed(1)}L',
                    Icons.water_drop,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Ngủ TB',
                    '${stats['averageSleep'].toStringAsFixed(1)}h',
                    Icons.bedtime,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
            fontSize: 16,
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

  String _formatDate(DateTime date) {
    const weekdays = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    return '${weekdays[date.weekday % 7]}, ${date.day}/${date.month}/${date.year}';
  }

  void _editSteps() {
    final controller = TextEditingController(text: (_todayRecord?.steps ?? 0).toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cập nhật bước chân'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Số bước',
            suffixText: 'bước',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              final steps = int.tryParse(controller.text) ?? 0;
              _trackingService.updateSteps(steps);
              Navigator.pop(context);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _addWater() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm nước'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('200ml'),
              onTap: () {
                _trackingService.addWater(0.2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('250ml'),
              onTap: () {
                _trackingService.addWater(0.25);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('500ml'),
              onTap: () {
                _trackingService.addWater(0.5);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _editWater() {
    final controller = TextEditingController(text: (_todayRecord?.waterIntake ?? 0.0).toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cập nhật lượng nước'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Lượng nước',
            suffixText: 'lít',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              final water = double.tryParse(controller.text) ?? 0.0;
              _trackingService.updateWaterIntake(water);
              Navigator.pop(context);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _editSleep() {
    final controller = TextEditingController(text: (_todayRecord?.sleepHours ?? 0.0).toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cập nhật giấc ngủ'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Số giờ ngủ',
            suffixText: 'giờ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              final sleep = double.tryParse(controller.text) ?? 0.0;
              _trackingService.updateSleep(sleep);
              Navigator.pop(context);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _updateMood(MoodLevel mood) {
    _trackingService.updateMood(mood);
  }

  void _editNotes() {
    final controller = TextEditingController(text: _todayRecord?.notes ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ghi chú hôm nay'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Ghi chú',
            hintText: 'Nhập ghi chú về sức khỏe hôm nay...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              _trackingService.updateNotes(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _showHistory() {
    // TODO: Implement history screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lịch sử theo dõi sẽ được thêm sau')),
    );
  }

  void _showSettings() {
    // TODO: Implement settings screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cài đặt theo dõi sẽ được thêm sau')),
    );
  }
}
