import 'package:flutter/material.dart';

class DeviceTile extends StatefulWidget {
  final String name;
  final VoidCallback? onTap;
  final bool isSelected;

  const DeviceTile({
    required this.name,
    this.onTap,
    this.isSelected = false,
    super.key,
  });

  @override
  State<DeviceTile> createState() => _DeviceTileState();
}

class _DeviceTileState extends State<DeviceTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onTap == null;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectedCardColor = isDark ? const Color(0xFF374151) : const Color(0xFF111827);
    final selectedBorderColor = isDark ? const Color(0xFF4B5563) : const Color(0xFF111827);
    final unselectedCardColor = theme.cardColor;
    final unselectedBorderColor = theme.colorScheme.outlineVariant;
    final selectedTextColor = Colors.white;
    final unselectedTextColor = theme.colorScheme.onSurface;
    final selectedIconColor = Colors.white70;
    final unselectedIconColor = theme.colorScheme.outline;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: isDisabled ? null : _onTapDown,
        onTapUp: isDisabled ? null : _onTapUp,
        onTapCancel: isDisabled ? null : _onTapCancel,
        child: Opacity(
          opacity: isDisabled ? 0.5 : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            decoration: BoxDecoration(
              color: widget.isSelected ? selectedCardColor : unselectedCardColor,
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(
                color: widget.isSelected ? selectedBorderColor : unselectedBorderColor,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.22)
                      : Colors.black.withValues(alpha: 0.04),
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                ),
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.35)
                      : Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.name,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 15.0,
                      color: widget.isSelected ? selectedTextColor : unselectedTextColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12.0),
                Icon(
                  Icons.chevron_right,
                  color: widget.isSelected ? selectedIconColor : unselectedIconColor,
                  size: 20.0,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
