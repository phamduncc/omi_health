import 'package:flutter/material.dart';
import '../models/health_goal.dart';
import '../services/navigation_service.dart';

class GoalProgressBanner extends StatelessWidget {
  final List<GoalProgressUpdate> updates;
  final VoidCallback? onDismiss;

  const GoalProgressBanner({
    super.key,
    required this.updates,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (updates.isEmpty) return const SizedBox.shrink();

    final update = updates.first;
    final color = update.isCompleted 
        ? const Color(0xFF2ECC71)
        : update.progressChange > 0 
            ? const Color(0xFF3498DB)
            : const Color(0xFFF39C12);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => NavigationService().navigateToGoals(),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    update.isCompleted 
                        ? Icons.celebration
                        : update.progressChange > 0
                            ? Icons.trending_up
                            : Icons.info_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        update.isCompleted 
                            ? 'Mục tiêu hoàn thành!'
                            : 'Cập nhật mục tiêu',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        update.goal.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${update.newProgress.toStringAsFixed(1)}% hoàn thành',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onDismiss != null)
                      IconButton(
                        onPressed: onDismiss,
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white70,
                          size: 18,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 24,
                          minHeight: 24,
                        ),
                      ),
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
