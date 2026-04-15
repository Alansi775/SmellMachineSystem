import 'package:flutter/material.dart';

class CustomLoader extends StatefulWidget {
  final Color color;
  final double dotSize;
  final double gap;

  const CustomLoader({
    this.color = const Color(0xFF0A0A0A),
    this.dotSize = 8.0,
    this.gap = 6.0,
    super.key,
  });

  @override
  State<CustomLoader> createState() => _CustomLoaderState();
}

class _CustomLoaderState extends State<CustomLoader>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.dotSize * 3 + widget.gap * 2,
      height: widget.dotSize,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int index = 0; index < 3; index++) ...[
            _AnimatedDot(
              animation: _controller,
              index: index,
              dotSize: widget.dotSize,
              color: widget.color,
            ),
            if (index < 2) SizedBox(width: widget.gap),
          ],
        ],
      ),
    );
  }
}

class _AnimatedDot extends StatelessWidget {
  final AnimationController animation;
  final int index;
  final double dotSize;
  final Color color;

  const _AnimatedDot({
    required this.animation,
    required this.index,
    required this.dotSize,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final delay = index * 200; // 200ms stagger between dots
    final totalDuration = 1200;

    return ScaleTransition(
      scale: Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: Interval(
            delay / totalDuration,
            (delay + 400) / totalDuration,
            curve: Curves.easeInOutQuad,
          ),
        ),
      ),
      child: Container(
        width: dotSize,
        height: dotSize,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
