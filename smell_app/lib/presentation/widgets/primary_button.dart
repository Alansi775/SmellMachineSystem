import 'package:flutter/material.dart';
import 'custom_loader.dart';

class PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final Widget? leadingIcon;
  final bool isEnabled;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.leadingIcon,
    this.isEnabled = true,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton>
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.isEnabled && !widget.isLoading) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    if (widget.isEnabled && !widget.isLoading) {
      widget.onPressed();
    }
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = !widget.isEnabled || widget.isLoading;
    const gradientStart = Color(0xFF059669);
    const gradientEnd = Color(0xFF10B981);
    final bgColor = isDisabled ? const Color(0xFFE4E4E7) : gradientEnd;
    final textColor = isDisabled ? const Color(0xFFA1A1AA) : Colors.white;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: Container(
          height: 56.0,
          decoration: BoxDecoration(
            color: isDisabled ? bgColor : null,
            gradient: isDisabled
                ? null
                : const LinearGradient(
                    colors: [gradientStart, gradientEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(14.0),
            boxShadow: [
              if (!isDisabled)
                BoxShadow(
                  color: gradientEnd.withValues(alpha: 0.26),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? CustomLoader(
                    color: textColor,
                    dotSize: 6.0,
                    gap: 4.0,
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.leadingIcon != null) ...[
                        IconTheme(
                          data: IconThemeData(color: textColor, size: 18.0),
                          child: widget.leadingIcon!,
                        ),
                        const SizedBox(width: 8.0),
                      ],
                      Text(
                        widget.label,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 15.0,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
