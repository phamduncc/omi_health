import 'package:flutter/material.dart';
import '../screens/utilities_screen.dart';
import '../screens/reminders_screen.dart';
import '../screens/calculator_screen.dart';
import '../screens/daily_tracking_screen.dart';
import '../screens/ai_assistant_screen.dart';

class QuickUtilitiesWidget extends StatelessWidget {
  const QuickUtilitiesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.build,
                color: Colors.blue[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Tiện ích nhanh',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UtilitiesScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('Xem tất cả'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Quick utility cards
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildQuickUtilityCard(
                  context,
                  title: 'AI Assistant',
                  subtitle: 'Trợ lý AI thông minh',
                  icon: Icons.psychology,
                  color: Colors.blue,
                  onTap: () => _navigateToScreen(context, const AIAssistantScreen()),
                ),
                const SizedBox(width: 12),
                _buildQuickUtilityCard(
                  context,
                  title: 'Theo dõi hàng ngày',
                  subtitle: 'Bước chân, nước, giấc ngủ',
                  icon: Icons.today,
                  color: Colors.green,
                  onTap: () => _navigateToScreen(context, const DailyTrackingScreen()),
                ),
                const SizedBox(width: 12),
                _buildQuickUtilityCard(
                  context,
                  title: 'Nhắc nhở',
                  subtitle: 'Thông báo thông minh',
                  icon: Icons.notifications_active,
                  color: Colors.orange,
                  onTap: () => _navigateToScreen(context, const RemindersScreen()),
                ),
                const SizedBox(width: 12),
                _buildQuickUtilityCard(
                  context,
                  title: 'Máy tính',
                  subtitle: 'Calories, nước, thời gian',
                  icon: Icons.calculate,
                  color: Colors.teal,
                  onTap: () => _navigateToScreen(context, const CalculatorScreen()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickUtilityCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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


}
