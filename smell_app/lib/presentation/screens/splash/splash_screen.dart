import 'package:flutter/material.dart';
import '../../../core/utils/logger.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
  with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _initializeApp();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      Logger.info('Koku Cihazi uygulamasi baslatiliyor...');

      // TODO: Request BLE permissions
      // TODO: Initialize BLE service
      // TODO: Load cached device config
      // TODO: Initialize providers

      await Future.delayed(const Duration(milliseconds: 1800));

      Logger.info('Uygulama baslatma tamamlandi');

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
          SnackBar(content: Text('Baslatma hatasi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([_pulseController, _floatController]),
          builder: (context, _) {
            final pulseScale = 1 + (_pulseController.value * 0.07);
            final bubbleDrift = (_floatController.value * 2 - 1) * 10;

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 180,
                  height: 180,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 170,
                        height: 170,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(
                            colors: [Color(0xFFE2FBEF), Color(0xFFC7F9DD)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withValues(alpha: 0.22),
                              blurRadius: 40,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                      ),
                      Transform.translate(
                        offset: Offset(-42, -40 + bubbleDrift),
                        child: _bubble(16, 0.28),
                      ),
                      Transform.translate(
                        offset: Offset(48, -20 - bubbleDrift * 0.7),
                        child: _bubble(10, 0.22),
                      ),
                      Transform.translate(
                        offset: Offset(52, 34 + bubbleDrift * 0.5),
                        child: _bubble(8, 0.18),
                      ),
                      Transform.scale(
                        scale: pulseScale,
                        child: Container(
                          width: 108,
                          height: 108,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            size: 42,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Koku Cihazi',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 28,
                        letterSpacing: -0.4,
                        color: const Color(0xFF0F172A),
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Akilli koku deneyimi hazirlaniyor...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF475569),
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 26),
                SizedBox(
                  width: 170,
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    borderRadius: const BorderRadius.all(Radius.circular(999)),
                    color: const Color(0xFF10B981),
                    backgroundColor: const Color(0xFFD1FAE5),
                    value: (_floatController.value * 0.85) + 0.15,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _bubble(double size, double alpha) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF10B981).withValues(alpha: alpha),
      ),
    );
  }
}
