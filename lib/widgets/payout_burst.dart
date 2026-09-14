import 'package:flutter/material.dart';

import '../game/task_value.dart';
import '../theme.dart';

/// Compact gold / silver / XP chip that pops in on the task that just paid out.
class PayoutBurst extends StatefulWidget {
  final TaskPayout payout;

  const PayoutBurst({super.key, required this.payout});

  @override
  State<PayoutBurst> createState() => _PayoutBurstState();
}

class _PayoutBurstState extends State<PayoutBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.55,
          end: 1.14,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.14,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 45,
      ),
    ]).animate(_controller);
    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.4, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(PayoutBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.payout.token != widget.payout.token) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Material(
          key: const ValueKey('task-payout'),
          color: AppTheme.surfaceDark,
          elevation: 6,
          shadowColor: const Color(0xFFFFC107).withValues(alpha: 0.45),
          borderRadius: AppTheme.borderRadius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _bit(const Color(0xFFFFC107), '+${widget.payout.gold}g'),
                  const SizedBox(width: 6),
                  _bit(const Color(0xFFB0BEC5), '+${widget.payout.silver}s'),
                  const SizedBox(width: 6),
                  _bit(const Color(0xFF81C784), '+${widget.payout.xp} XP'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bit(Color color, String text) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
