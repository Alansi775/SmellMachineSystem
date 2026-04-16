import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../../providers/ble_provider.dart';
import '../../../providers/smells_provider.dart';
import '../../../providers/schedules_provider.dart';
import '../../widgets/responsive_scaffold.dart';
import '../../widgets/custom_loader.dart';
import '../../widgets/section_label.dart';
import '../../widgets/device_tile.dart';
import '../../widgets/primary_button.dart';
import '../../../core/utils/logger.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  String? _errorMessage;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    )..repeat();

    if (kIsWeb) {
      _errorMessage = 'Bu uygulamada BLE web uzerinde desteklenmiyor. Android veya iOS kullanin.';
      return;
    }

    // Start scanning on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BleProvider>().startScan();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleDeviceSelect(String deviceId, BleProvider bleProvider) async {
    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    try {
      final success = await bleProvider.connectToDevice(deviceId);
      if (success && mounted) {
        Logger.info('Successfully connected to device');
        final config = bleProvider.lastDeviceConfig;
        if (config != null) {
          context.read<SmellsProvider>().replaceAll(config.smells);
          context.read<SchedulesProvider>().replaceAll(config.schedules);
        }
        // Navigate to next screen
        Navigator.of(context).pushReplacementNamed('/smells');
      } else if (mounted) {
        setState(() {
          _errorMessage = 'Cihaza baglanilamadi';
          _isConnecting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Baglanti hatasi: $e';
          _isConnecting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: '',
      centerTitle: true,
      body: Consumer<BleProvider>(
        builder: (context, bleProvider, _) {
          return SingleChildScrollView(
            child: Column(
              children: [
                // STEP label
                const SizedBox(height: 16),
                const SectionLabel(text: 'ADIM 1 / 3'),
                const SizedBox(height: 24),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF111827), Color(0xFF374151)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, _) {
                          final pulse = _pulseController.value;
                          final scale = 1.0 + (pulse < 0.5 ? pulse * 2 : (1 - pulse) * 2) * 0.09;
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              width: 132,
                              height: 132,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                              ),
                              child: const Icon(
                                Icons.bluetooth_rounded,
                                size: 72,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Cihaziniz araniyor',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Smell Device acik olsun ve yakinda tutun',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          bleProvider.isScanning ? 'Tarama suruyor...' : 'Yenilemek icin tekrar tara',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (_isConnecting) ...[
                        const SizedBox(height: 14),
                        const LinearProgressIndicator(
                          minHeight: 6,
                          borderRadius: BorderRadius.all(Radius.circular(999)),
                          color: Color(0xFF10B981),
                          backgroundColor: Colors.white24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Eslestirme yapiliyor, lutfen bekleyin...',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // Error message
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: const Color(0xFFEF4444)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFFEF4444),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Loader or device list
                if (bleProvider.isScanning && bleProvider.devices.isEmpty)
                  const CustomLoader(
                    color: Color(0xFF0A0A0A),
                    dotSize: 8.0,
                    gap: 6.0,
                  )
                else if (bleProvider.devices.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionLabel(text: 'DEVICES NEARBY'),
                      const SizedBox(height: 12),
                      ...bleProvider.devices.map((device) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: DeviceTile(
                            name: device.name ?? 'Bilinmeyen cihaz',
                            onTap: _isConnecting
                                ? null
                                : () => _handleDeviceSelect(device.id, bleProvider),
                            isSelected: false,
                          ),
                        );
                      }),
                    ],
                  )
                else if (!bleProvider.isScanning)
                  Column(
                    children: [
                      Text(
                        'Cihaz bulunamadi',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),

                const SizedBox(height: 48),

                // Scan again button
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    label: 'Tekrar Tara',
                    leadingIcon: const Icon(Icons.refresh),
                    isLoading: bleProvider.isScanning,
                    isEnabled: !_isConnecting && bleProvider.isBleSupported,
                    onPressed: () {
                      context.read<BleProvider>().startScan();
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
