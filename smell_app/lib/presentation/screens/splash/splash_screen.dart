import 'package:flutter/material.dart';
import '../../../core/utils/logger.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      Logger.info('Initializing SmellDevice app...');

      // TODO: Request BLE permissions
      // TODO: Initialize BLE service
      // TODO: Load cached device config
      // TODO: Initialize providers

      await Future.delayed(const Duration(milliseconds: 1500));

      Logger.info('App initialization complete');

      if (mounted) {
        Navigator.of(context).pushReplacementNamed(
          '/connection',
          result: true,
        );
      }
    } catch (e) {
      Logger.error('Initialization failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Initialization error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Minimal circular logo: black circle with a subtle center dot
            SizedBox(
              width: 120,
              height: 120,
              child: CustomPaint(
                painter: _MinimalLogoPainter(),
              ),
            ),
            const SizedBox(height: 32),
            // App name
            Text(
              'Smell Device',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 22,
                letterSpacing: -0.02,
                color: const Color(0xFF0A0A0A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MinimalLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.9;

    // Outer circle (thin stroke)
    final circlePaint = Paint()
      ..color = const Color(0xFF0A0A0A)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, circlePaint);

    // Inner dot (center)
    final dotPaint = Paint()
      ..color = const Color(0xFF0A0A0A)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 4, dotPaint);
  }

  @override
  bool shouldRepaint(_MinimalLogoPainter oldDelegate) => false;
}
