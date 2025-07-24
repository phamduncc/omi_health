import 'package:flutter/material.dart';
import 'reminders_screen.dart';
import 'calculator_screen.dart';
import 'daily_tracking_screen.dart';
import 'charts_screen.dart';
import 'ai_assistant_screen.dart';
import 'ai_analytics_screen.dart';

class UtilitiesScreen extends StatelessWidget {
  const UtilitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tiện ích sức khỏe'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[400]!, Colors.purple[400]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.build, color: Colors.white, size: 32),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tiện ích thông minh',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Các công cụ hỗ trợ theo dõi sức khỏe',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Theo dõi hàng ngày
            const Text(
              'Theo dõi hàng ngày',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildUtilityCard(
                    context,
                    title: 'Theo dõi hàng ngày',
                    subtitle: 'Bước chân, nước, giấc ngủ',
                    icon: Icons.today,
                    color: Colors.green,
                    onTap: () => _navigateToScreen(context, const DailyTrackingScreen()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildUtilityCard(
                    context,
                    title: 'Nhắc nhở',
                    subtitle: 'Thông báo thông minh',
                    icon: Icons.notifications_active,
                    color: Colors.orange,
                    onTap: () => _navigateToScreen(context, const RemindersScreen()),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // AI & Phân tích thông minh
            const Text(
              'AI & Phân tích thông minh',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildUtilityCard(
                    context,
                    title: 'AI Assistant',
                    subtitle: 'Trợ lý AI sức khỏe',
                    icon: Icons.psychology,
                    color: Colors.blue,
                    onTap: () => _navigateToScreen(context, const AIAssistantScreen()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildUtilityCard(
                    context,
                    title: 'AI Analytics',
                    subtitle: 'Phân tích xu hướng AI',
                    icon: Icons.analytics,
                    color: Colors.purple,
                    onTap: () => _navigateToScreen(context, const AIAnalyticsScreen()),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Tính toán và phân tích
            const Text(
              'Tính toán & Phân tích',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildUtilityCard(
                    context,
                    title: 'Máy tính sức khỏe',
                    subtitle: 'Calories, nước, thời gian',
                    icon: Icons.calculate,
                    color: Colors.teal,
                    onTap: () => _navigateToScreen(context, const CalculatorScreen()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildUtilityCard(
                    context,
                    title: 'Biểu đồ chi tiết',
                    subtitle: 'Phân tích xu hướng',
                    icon: Icons.bar_chart,
                    color: Colors.indigo,
                    onTap: () => _navigateToScreen(context, const ChartsScreen()),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Tiện ích khác
            const Text(
              'Tiện ích khác',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 12),
            
            _buildUtilityCard(
              context,
              title: 'So sánh với chuẩn',
              subtitle: 'So sánh chỉ số với chuẩn quốc tế',
              icon: Icons.compare_arrows,
              color: Colors.teal,
              onTap: () => _showComingSoon(context, 'So sánh với chuẩn'),
              isFullWidth: true,
            ),

            const SizedBox(height: 12),

            _buildUtilityCard(
              context,
              title: 'Báo cáo sức khỏe',
              subtitle: 'Tạo báo cáo PDF chi tiết',
              icon: Icons.description,
              color: Colors.indigo,
              onTap: () => _showComingSoon(context, 'Báo cáo sức khỏe'),
              isFullWidth: true,
            ),

            const SizedBox(height: 12),

            _buildUtilityCard(
              context,
              title: 'Chia sẻ kết quả',
              subtitle: 'Chia sẻ thành tích với bạn bè',
              icon: Icons.share,
              color: Colors.pink,
              onTap: () => _showComingSoon(context, 'Chia sẻ kết quả'),
              isFullWidth: true,
            ),

            const SizedBox(height: 24),

            // Quick actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thao tác nhanh',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickAction(
                          context,
                          'Cân nặng hôm nay',
                          Icons.monitor_weight,
                          Colors.green,
                          () => _showComingSoon(context, 'Cân nặng nhanh'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildQuickAction(
                          context,
                          'Uống nước',
                          Icons.water_drop,
                          Colors.blue,
                          () => _showComingSoon(context, 'Uống nước nhanh'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildQuickAction(
                          context,
                          'Ghi chú',
                          Icons.note_add,
                          Colors.orange,
                          () => _showComingSoon(context, 'Ghi chú nhanh'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUtilityCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isFullWidth = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isFullWidth ? double.infinity : null,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
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
              subtitle,
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

  Widget _buildQuickAction(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.upcoming, color: Colors.blue[600]),
            const SizedBox(width: 8),
            const Text('Sắp ra mắt'),
          ],
        ),
        content: Text('Tính năng "$feature" sẽ được thêm trong phiên bản tiếp theo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}
