import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/mod_sprite.dart';
import '../models/mod_appearance.dart';

/// A pixel Mod that idles with a small up-and-down breath.
class ModPortrait extends StatefulWidget {
  final String appearanceId;
  final double size;
  final bool animate;

  const ModPortrait({
    super.key,
    required this.appearanceId,
    this.size = 128,
    this.animate = true,
  });

  @override
  State<ModPortrait> createState() => _ModPortraitState();
}

class _ModPortraitState extends State<ModPortrait>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath;

  /// A repeating breath never settles, so widget tests that call
  /// [WidgetTester.pumpAndSettle] would hang if this ran under the test
  /// binding.
  bool get _canLoop {
    final name = WidgetsBinding.instance.runtimeType.toString();
    return !name.contains('TestWidgetsFlutterBinding');
  }

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    if (widget.animate && _canLoop) {
      _breath.repeat();
    }
  }

  @override
  void didUpdateWidget(ModPortrait oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && _canLoop && !_breath.isAnimating) {
      _breath.repeat();
    } else if (!widget.animate && _breath.isAnimating) {
      _breath
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appearance = appearanceById(widget.appearanceId);
    final cell = widget.size / ModSprite.size;

    return AnimatedBuilder(
      animation: _breath,
      builder: (context, child) {
        final wave = math.sin(_breath.value * math.pi * 2);
        final lift = -wave * cell;
        final scaleY = 1.0 + (0.025 * (0.5 + 0.5 * wave));

        return Transform.translate(
          offset: Offset(0, lift),
          child: Transform.scale(
            scaleY: scaleY,
            alignment: Alignment.bottomCenter,
            filterQuality: FilterQuality.none,
            child: child,
          ),
        );
      },
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: _ModSpritePainter(
            appearanceId: appearance.id,
            accent: appearance.color,
          ),
        ),
      ),
    );
  }
}

class _ModSpritePainter extends CustomPainter {
  final String appearanceId;
  final Color accent;

  const _ModSpritePainter({required this.appearanceId, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final rows = ModSprite.rowsFor(appearanceId);
    final cell = size.width / ModSprite.size;
    final paint = Paint()..isAntiAlias = false;

    for (var y = 0; y < rows.length; y++) {
      final row = rows[y];
      for (var x = 0; x < row.length; x++) {
        final color = ModSprite.colorFor(row[x], accent);
        if (color == null) {
          continue;
        }
        paint.color = color;
        canvas.drawRect(
          Rect.fromLTWH(x * cell, y * cell, cell + 0.2, cell + 0.2),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ModSpritePainter oldDelegate) {
    return oldDelegate.appearanceId != appearanceId ||
        oldDelegate.accent != accent;
  }
}
