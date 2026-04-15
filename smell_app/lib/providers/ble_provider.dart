import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../core/utils/logger.dart';

class BleScanResult {
  final String id;
  final String? name;
  final BluetoothDevice _device;

  BleScanResult({
    required this.id,
    this.name,
    required BluetoothDevice device,
  }) : _device = device;

  BluetoothDevice get device => _device;
}

class BleProvider extends ChangeNotifier {
  // BLE connection state
  bool _isConnected = false;
  String? _connectedDeviceId;
  String? _connectedDeviceName;
  List<BleScanResult> _devices = [];
  bool _isScanning = false;
  bool _webUnsupportedWarningShown = false;

  // BLE channel UUIDs (from ESP32 config)
  static const String serviceUuid = '12345678-1234-1234-1234-123456789abc';
  static const String configCharUuid = 'bbcc0001-e56f-504d-a6c5-6c2342e5672a';
  static const String responseCharUuid = 'bbcc0002-e56f-504d-a6c5-6c2342e5672a';

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _configChar;
  BluetoothCharacteristic? _responseChar;

  bool get isConnected => _isConnected;
  String? get connectedDeviceId => _connectedDeviceId;
  String? get connectedDeviceName => _connectedDeviceName;
  List<BleScanResult> get devices => List.unmodifiable(_devices);
  bool get isScanning => _isScanning;
  bool get isBleSupported => !kIsWeb;

  /// Starts scanning for BLE devices.
  Future<void> startScan() async {
    if (_isScanning) {
      return;
    }

    try {
      _isScanning = true;
      _devices.clear();
      notifyListeners();

      // Check if BLE is available (not on web)
      if (kIsWeb) {
        if (!_webUnsupportedWarningShown) {
          Logger.warning('BLE not available on web platform. Use Android or iOS build.');
          _webUnsupportedWarningShown = true;
        }
        _isScanning = false;
        notifyListeners();
        return;
      }

      Logger.info('Starting BLE scan...');

      // Start scanning
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
      );

      // Listen to scan results
      FlutterBluePlus.scanResults.listen((results) {
        _devices.clear();
        for (ScanResult r in results) {
          final name = r.device.name.isNotEmpty ? r.device.name : 'Unknown';
          Logger.info('Found device: $name (${r.device.remoteId})');
          _devices.add(
            BleScanResult(
              id: r.device.remoteId.toString(),
              name: name,
              device: r.device,
            ),
          );
        }
        notifyListeners();
      });

      // Wait a bit for results
      await Future.delayed(const Duration(seconds: 2));
      _isScanning = false;
      notifyListeners();
    } catch (e) {
      Logger.error('BLE scan error: $e');
      _isScanning = false;
      notifyListeners();
    }
  }

  /// Stops scanning for devices.
  Future<void> stopScan() async {
    try {
      _isScanning = false;
      await FlutterBluePlus.stopScan();
      notifyListeners();
      Logger.info('BLE scan stopped');
    } catch (e) {
      Logger.error('Error stopping scan: $e');
    }
  }

  /// Connects to a device by ID.
  Future<bool> connectToDevice(String deviceId) async {
    try {
      Logger.info('Connecting to device: $deviceId');

      final device = _devices.firstWhere((d) => d.id == deviceId).device;
      _connectedDevice = device;

      // Connect to the device
      await device.connect(timeout: const Duration(seconds: 10));
      Logger.info('Connected to ${device.name}');

      // Discover services
      List<BluetoothService> services = await device.discoverServices();
      Logger.info('Discovered ${services.length} services');

      // Find our service
      BluetoothService? targetService;
      BluetoothCharacteristic? configChar;
      BluetoothCharacteristic? responseChar;

      for (BluetoothService service in services) {
        if (service.uuid.toString().toLowerCase() == serviceUuid.toLowerCase()) {
          targetService = service;
          Logger.info('Found target service');

          // Find characteristics
          for (BluetoothCharacteristic char in service.characteristics) {
            final charUuid = char.uuid.toString().toLowerCase();
            if (charUuid == configCharUuid.toLowerCase()) {
              configChar = char;
              Logger.info('Found config characteristic');
            } else if (charUuid == responseCharUuid.toLowerCase()) {
              responseChar = char;
              Logger.info('Found response characteristic');
              // Listen for notifications
              await char.setNotifyValue(true);
              char.onValueReceived.listen((value) {
                Logger.info('Received from ESP32: ${String.fromCharCodes(value)}');
              });
            }
          }
          break;
        }
      }

      if (configChar != null && responseChar != null) {
        _configChar = configChar;
        _responseChar = responseChar;
        _isConnected = true;
        _connectedDeviceId = deviceId;
        _connectedDeviceName = device.name;
        notifyListeners();

        Logger.info('Successfully connected and characteristics found');
        
        // Send time sync immediately after connection
        await _syncTimeWithDevice();
        
        return true;
      } else {
        Logger.error('Required characteristics not found');
        await device.disconnect();
        return false;
      }
    } catch (e) {
      Logger.error('Connection error: $e');
      _isConnected = false;
      notifyListeners();
      return false;
    }
  }

  /// Syncs Unix timestamp with device for schedule matching.
  Future<void> _syncTimeWithDevice() async {
    try {
      final unixSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final json = '{"unixTime":$unixSeconds}';
      Logger.info('Syncing time to ESP32: $json');
      
      final success = await sendConfig(json);
      if (success) {
        Logger.info('Time sync successful');
      } else {
        Logger.error('Time sync failed');
      }
    } catch (e) {
      Logger.error('Error syncing time: $e');
    }
  }

  /// Sends JSON configuration to the device via BLE.
  Future<bool> sendConfig(String jsonConfig) async {
    try {
      if (!_isConnected || _configChar == null) {
        Logger.error('Not connected or characteristic not found');
        return false;
      }

      Logger.info('Sending config to ESP32: $jsonConfig');
      await _configChar!.write(jsonConfig.codeUnits, withoutResponse: false);
      Logger.info('Config sent successfully');
      return true;
    } catch (e) {
      Logger.error('Send config error: $e');
      return false;
    }
  }

  /// Disconnects from the current device.
  Future<void> disconnect() async {
    try {
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
        Logger.info('Disconnected from device');
      }
      _isConnected = false;
      _connectedDeviceId = null;
      _connectedDeviceName = null;
      _connectedDevice = null;
      _configChar = null;
      _responseChar = null;
      notifyListeners();
    } catch (e) {
      Logger.error('Disconnect error: $e');
    }
  }
}
