import 'package:flutter/material.dart';
import 'dart:async';
import '../services/goal_progress_service.dart';
import '../models/health_goal.dart';

class LiveProgressIndicator extends StatefulWidget {
  final String? goalId;
  final bool showPercentage;
  final double height;
  final Color? color;

  const LiveProgressIndicator({
    super.key,
    this.goalId,
    this.showPercentage = true,
    this.height = 6,
    this.color,
  });

  @override
  State<LiveProgressIndicator> createState() => _LiveProgressIndicatorState();
}

class _LiveProgressIndicatorState extends State<LiveProgressIndicator>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  StreamSubscription<List<HealthGoal>>? _goalsSubscription;
  
  double _currentProgress = 0.0;
  double _targetProgress = 0.0;
  HealthGoal? _goal;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _loadInitialProgress();
    _subscribeToUpdates();
  }

  void _loadInitialProgress() {
    if (widget.goalId != null) {
      _goal = GoalProgressService().getGoalById(widget.goalId!);
      if (_goal != null) {
        _currentProgress = _goal!.progressPercentage / 100;
        _targetProgress = _currentProgress;
      }
    }
  }

  void _subscribeToUpdates() {
    _goalsSubscription = GoalProgressService().goalsStream.listen((goals) {
      if (widget.goalId != null) {
        final updatedGoal = goals.where((g) => g.id == widget.goalId).firstOrNull;
        if (updatedGoal != null && updatedGoal != _goal) {
          _updateProgress(updatedGoal);
        }
      }
    });
  }

  void _updateProgress(HealthGoal newGoal) {
    if (mounted) {
      setState(() {
        _goal = newGoal;
        _targetProgress = newGoal.progressPercentage / 100;
      });
      
      // Animate to new progress
      _animationController.reset();
      _animationController.forward().then((_) {
        if (mounted) {
          setState(() {
            _currentProgress = _targetProgress;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _goalsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_goal == null) {
      return const SizedBox.shrink();
    }

    final color = widget.color ?? _getGoalColor(_goal!);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showPercentage)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _goal!.title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    final displayProgress = _currentProgress + 
                        (_targetProgress - _currentProgress) * _progressAnimation.value;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${(displayProgress * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            final displayProgress = _currentProgress + 
                (_targetProgress - _currentProgress) * _progressAnimation.value;
            
            return Container(
              height: widget.height,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(widget.height / 2),
              ),
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: widget.height,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(widget.height / 2),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: displayProgress.clamp(0.0, 1.0),
                    child: Container(
                      height: widget.height,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withValues(alpha: 0.8),
                            color,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(widget.height / 2),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Shimmer effect when updating
                  if (GoalProgressService().isUpdating)
                    Container(
                      height: widget.height,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.0),
                            Colors.white.withValues(alpha: 0.3),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                        borderRadius: BorderRadius.circular(widget.height / 2),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Color _getGoalColor(HealthGoal goal) {
    switch (goal.type) {
      case GoalType.weightLoss:
        return const Color(0xFFE74C3C);
      case GoalType.weightGain:
        return const Color(0xFF2ECC71);
      case GoalType.maintain:
        return const Color(0xFF3498DB);
      case GoalType.bmiTarget:
        return const Color(0xFF9B59B6);
    }
  }
}
