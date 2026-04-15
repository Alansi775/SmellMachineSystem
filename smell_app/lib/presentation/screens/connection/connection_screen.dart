import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../../providers/ble_provider.dart';
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
      _errorMessage = 'BLE is not supported on Chrome in this app. Run on Android or iOS.';
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
        // Navigate to next screen
        Navigator.of(context).pushReplacementNamed('/smells');
      } else if (mounted) {
        setState(() {
          _errorMessage = 'Failed to connect to device';
          _isConnecting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Connection error: $e';
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
                const SectionLabel(text: 'STEP 1 OF 3'),
                const SizedBox(height: 48),

                // Pulsing Bluetooth icon container
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) {
                    final pulse = _pulseController.value;
                    final scale = 1.0 + (pulse < 0.5 ? pulse * 2 : (1 - pulse) * 2) * 0.08;
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F4F5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.bluetooth,
                          size: 80,
                          color: Color(0xFF0A0A0A),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Heading
                Text(
                  'Looking for your device',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.02,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'Make sure Smell Device is powered on',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 15,
                    color: const Color(0xFF71717A),
                  ),
                  textAlign: TextAlign.center,
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
                            name: device.name ?? 'Unknown',
                            onTap: _isConnecting
                                ? null
                                : () => _handleDeviceSelect(device.id, bleProvider),
                            isSelected: false,
                          ),
                        );
                      }).toList(),
                    ],
                  )
                else if (!bleProvider.isScanning)
                  Column(
                    children: [
                      Text(
                        'No devices found',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),

                const SizedBox(height: 48),

                // Scan again button
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    label: 'Scan Again',
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
