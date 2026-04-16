import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../data/models/device_config.dart';
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
  static const String targetDeviceName = 'Smell Device';

  // BLE connection state
  bool _isConnected = false;
  String? _connectedDeviceId;
  String? _connectedDeviceName;
  final List<BleScanResult> _devices = [];
  bool _isScanning = false;
  bool _webUnsupportedWarningShown = false;
  StreamSubscription<List<ScanResult>>? _scanResultsSubscription;
  final Set<String> _loggedDeviceIds = <String>{};
  DateTime? _lastScanRequestAt;

  // BLE channel UUIDs (from ESP32 config)
  static const String serviceUuid = '12345678-1234-1234-1234-123456789abc';
  static const String configCharUuid = 'bbcc0001-e56f-504d-a6c5-6c2342e5672a';
  static const String responseCharUuid = 'bbcc0002-e56f-504d-a6c5-6c2342e5672a';

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _configChar;
  static const int _bleChunkSize = 180;
  String? _lastDeviceMessage;
  String? _lastNextSmellName;
  bool _lastApplySuccess = false;
  DeviceConfig? _lastDeviceConfig;
  Completer<DeviceConfig?>? _pendingConfigCompleter;

  bool get isConnected => _isConnected;
  String? get connectedDeviceId => _connectedDeviceId;
  String? get connectedDeviceName => _connectedDeviceName;
  List<BleScanResult> get devices => List.unmodifiable(_devices);
  bool get isScanning => _isScanning;
  bool get isBleSupported => !kIsWeb;
  String? get lastDeviceMessage => _lastDeviceMessage;
  String? get lastNextSmellName => _lastNextSmellName;
  bool get lastApplySuccess => _lastApplySuccess;
  DeviceConfig? get lastDeviceConfig => _lastDeviceConfig;

  Future<bool> _ensureBlePermissions() async {
    if (kIsWeb) return false;

    final statuses = await <Permission>[
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    final scanOk = statuses[Permission.bluetoothScan]?.isGranted ?? false;
    final connectOk = statuses[Permission.bluetoothConnect]?.isGranted ?? false;
    final locationOk = statuses[Permission.locationWhenInUse]?.isGranted ?? false;

    if (!scanOk || !connectOk || !locationOk) {
      Logger.warning(
        'BLE permissions missing. scan=$scanOk connect=$connectOk location=$locationOk',
      );
      return false;
    }

    return true;
  }

  /// Starts scanning for BLE devices.
  Future<void> startScan() async {
    final now = DateTime.now();
    if (_lastScanRequestAt != null &&
        now.difference(_lastScanRequestAt!) < const Duration(seconds: 2)) {
      return;
    }
    _lastScanRequestAt = now;

    if (_isScanning) {
      return;
    }

    try {
      _isScanning = true;
      _devices.clear();
      _loggedDeviceIds.clear();
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

      final hasPermissions = await _ensureBlePermissions();
      if (!hasPermissions) {
        _isScanning = false;
        notifyListeners();
        return;
      }

      Logger.info('Starting BLE scan...');

      await _scanResultsSubscription?.cancel();

      // Start scanning without strict UUID filter. Some peripherals expose
      // service UUID in scan response, which can be missed by filtered scans.
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
      );

      // Listen to results and keep only devices that match target name or
      // contain the expected service UUID in advertised service data.
      _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
        final Map<String, BleScanResult> filtered = <String, BleScanResult>{};

        for (final ScanResult r in results) {
          final String id = r.device.remoteId.toString();
          final String advName = r.advertisementData.advName.trim();
          final String platformName = r.device.platformName.trim();
          final String rawDisplayName = advName.isNotEmpty
              ? advName
              : (platformName.isNotEmpty ? platformName : 'Unknown');
          final String displayName = rawDisplayName == 'Unknown'
              ? targetDeviceName
              : rawDisplayName;

          final bool nameMatches = rawDisplayName.toLowerCase() ==
              targetDeviceName.toLowerCase();
            final bool serviceMatches = r.advertisementData.serviceUuids
              .map((uuid) => uuid.toString().toLowerCase())
              .contains(serviceUuid.toLowerCase());

          if (!nameMatches && !serviceMatches) {
            continue;
          }

          if (_loggedDeviceIds.add(id)) {
            Logger.info('Found target device: $displayName ($id)');
          }

          filtered[id] = BleScanResult(
            id: id,
            name: displayName,
            device: r.device,
          );
        }

        _devices
          ..clear()
          ..addAll(filtered.values);
        notifyListeners();
      });

      // Keep scanning state while scan session is active.
      await Future.delayed(const Duration(seconds: 10));
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
      await _scanResultsSubscription?.cancel();
      _scanResultsSubscription = null;
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
      Logger.info('Connected to ${device.platformName}');

      // Discover services
      List<BluetoothService> services = await device.discoverServices();
      Logger.info('Discovered ${services.length} services');

      // Find our service
      BluetoothCharacteristic? configChar;
      BluetoothCharacteristic? responseChar;

      for (BluetoothService service in services) {
        if (service.uuid.toString().toLowerCase() == serviceUuid.toLowerCase()) {
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
                final payload = String.fromCharCodes(value);
                Logger.info('Received from ESP32: $payload');
                _handleDeviceNotification(payload);
              });
            }
          }
          break;
        }
      }

      if (configChar != null && responseChar != null) {
        _configChar = configChar;
        _isConnected = true;
        _connectedDeviceId = deviceId;
        _connectedDeviceName = device.platformName;
        notifyListeners();

        Logger.info('Successfully connected and characteristics found');
        
        // Send time sync immediately after connection
        await _syncTimeWithDevice();

        // Pull the current device configuration so the app mirrors the ESP32.
        await requestDeviceConfig();
        
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

  void _handleDeviceNotification(String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) {
        return;
      }

      final type = decoded['type']?.toString() ?? '';
      if (type == 'apply_result') {
        _lastApplySuccess = decoded['success'] == true;
        _lastDeviceMessage = decoded['message']?.toString();
        _lastNextSmellName = decoded['nextSmellName']?.toString();
        notifyListeners();
      } else if (type == 'device_config') {
        _lastDeviceConfig = DeviceConfig.fromJson(decoded);
        _pendingConfigCompleter?.complete(_lastDeviceConfig);
        _pendingConfigCompleter = null;
        notifyListeners();
      } else if (type == 'time_sync') {
        _lastDeviceMessage = 'Time synchronized';
        notifyListeners();
      }
    } catch (_) {
      // Non-JSON payloads are allowed; ignore silently.
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

  /// Requests the current full configuration from the ESP32.
  Future<DeviceConfig?> requestDeviceConfig() async {
    try {
      if (!_isConnected || _configChar == null) {
        Logger.error('Cannot request config while disconnected');
        return null;
      }

      _pendingConfigCompleter = Completer<DeviceConfig?>();
      const requestJson = '{"type":"get_config"}';
      Logger.info('Requesting config from ESP32');
      await _configChar!.write(requestJson.codeUnits, withoutResponse: false);

      final config = await _pendingConfigCompleter!.future.timeout(
        const Duration(seconds: 4),
        onTimeout: () {
          Logger.warning('Timed out waiting for device config');
          return null;
        },
      );

      _pendingConfigCompleter = null;
      return config;
    } catch (e) {
      Logger.error('Request config error: $e');
      _pendingConfigCompleter = null;
      return null;
    }
  }

  /// Sends a full configuration object to the device.
  Future<bool> syncDeviceConfig(DeviceConfig config) async {
    return sendConfig(jsonEncode(config.toJson()));
  }

  /// Sends JSON configuration to the device via BLE.
  Future<bool> sendConfig(String jsonConfig) async {
    try {
      if (!_isConnected || _configChar == null) {
        Logger.error('Not connected or characteristic not found');
        return false;
      }

      Logger.info('Sending config to ESP32: $jsonConfig');

      final data = utf8.encode(jsonConfig);
      if (data.length <= 220) {
        await _configChar!.write(data, withoutResponse: false);
        Logger.info('Config sent successfully');
        return true;
      }

      Logger.info('Config is large (${data.length} bytes), sending in BLE chunks');
      await _configChar!.write(
        utf8.encode('CFG_BEGIN:${data.length}'),
        withoutResponse: false,
      );

      for (int i = 0; i < data.length; i += _bleChunkSize) {
        final end = (i + _bleChunkSize < data.length) ? i + _bleChunkSize : data.length;
        final chunk = data.sublist(i, end);
        final packet = <int>[]..addAll(utf8.encode('CFG_CHUNK:'))..addAll(chunk);
        await _configChar!.write(packet, withoutResponse: false);
      }

      await _configChar!.write(utf8.encode('CFG_END'), withoutResponse: false);
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
      await _scanResultsSubscription?.cancel();
      _scanResultsSubscription = null;

      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
        Logger.info('Disconnected from device');
      }
      _isConnected = false;
      _connectedDeviceId = null;
      _connectedDeviceName = null;
      _connectedDevice = null;
      _configChar = null;
      _lastDeviceMessage = null;
      _lastNextSmellName = null;
      _lastApplySuccess = false;
      _lastDeviceConfig = null;
      _pendingConfigCompleter = null;
      notifyListeners();
    } catch (e) {
      Logger.error('Disconnect error: $e');
    }
  }
}
