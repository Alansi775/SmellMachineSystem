/// Animated logo for splash screen and app identity.
///
/// Provides a fun, animated version of the Smell Device logo.
///
/// TODO: Implement animation (fade, scale, rotate)
/// TODO: Load from asset file
import 'package:flutter/material.dart';

class AnimatedLogo extends StatefulWidget {
  final double size;

  const AnimatedLogo({
    super.key,
    this.size = 100,
  });

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // TODO: Initialize animation controller
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    // TODO: Start animation
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Center(
            child: Icon(
              Icons.local_florist,
              size: widget.size,
              color: Colors.black,
            ),
          ),
        );
      },
    );
  }
}
