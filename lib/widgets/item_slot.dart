import 'package:flutter/material.dart';

import '../theme.dart';

/// One square on the paperdoll or in the bag, in the style of a classic
/// RPG inventory slot.
class ItemSlot extends StatelessWidget {
  final double? size;
  final IconData? icon;
  final Color? iconColor;
  final String? tooltip;
  final int count;
  final bool selected;
  final bool empty;
  final VoidCallback? onTap;

  const ItemSlot({
    super.key,
    this.size,
    this.icon,
    this.iconColor,
    this.tooltip,
    this.count = 0,
    this.selected = false,
    this.empty = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final slot = LayoutBuilder(
      builder: (context, constraints) {
        final side = size ??
            constraints.biggest.shortestSide.clamp(32.0, 72.0);
        return _slotBody(side);
      },
    );

    final boxed = size == null
        ? slot
        : SizedBox(width: size, height: size, child: slot);

    if (tooltip == null || tooltip!.isEmpty) {
      return boxed;
    }

    return Tooltip(message: tooltip!, child: boxed);
  }

  Widget _slotBody(double side) {
    final border = selected
        ? Colors.amber
        : empty
        ? AppTheme.border
        : Colors.amber.shade700;

    return Material(
      color: AppTheme.surfaceDark,
      borderRadius: AppTheme.borderRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppTheme.borderRadius,
        child: Container(
          width: side,
          height: side,
          decoration: BoxDecoration(
            borderRadius: AppTheme.borderRadius,
            border: Border.all(color: border, width: selected ? 2 : 1.4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                offset: const Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
          child: Stack(
            children: [
              if (icon != null)
                Center(
                  child: Icon(
                    icon,
                    size: side * 0.46,
                    color:
                        iconColor ??
                        (empty
                            ? Colors.white.withValues(alpha: 0.18)
                            : Colors.amber),
                  ),
                ),
              if (count > 1)
                Positioned(
                  right: 3,
                  bottom: 2,
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: side * 0.22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: const [
                        Shadow(color: Colors.black, blurRadius: 2),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
