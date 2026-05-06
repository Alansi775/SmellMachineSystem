
# SmellDevice

Project overview
----------------
SmellDevice is a two-part project: a Flutter mobile app (`smell_app/`) and ESP32 firmware (`smell_firmware/`). The system lets a phone discover the ESP32 over BLE, connect, and exchange device configuration (a list of "smells" and run schedules). The ESP32 has no physical display in the current setup — it logs events and received data to the serial console and stores configuration in non-volatile storage (NVS / Preferences).

Quick facts
-----------
- BLE device name: "Smell Device"
- BLE Service UUID: `12345678-1234-1234-1234-123456789abc`
- Config (write) Characteristic UUID: `bbcc0001-e56f-504d-a6c5-6c2342e5672a`
- Response (notify) Characteristic UUID: `bbcc0002-e56f-504d-a6c5-6c2342e5672a`
- Default JSON buffer size on the device: 2048 bytes

Repository layout
-----------------
- `smell_firmware/` — ESP32 firmware (PlatformIO / Arduino / NimBLE)
- `smell_app/` — Flutter application (UI + BLE client logic)

Current status
--------------
- The ESP32 advertises as "Smell Device" and accepts connections from the mobile app.
- The app discovers, connects, and interacts with the firmware's BLE service and characteristics.
- Large JSON configuration transfers are handled via an application-level chunking protocol implemented on both sides.
- Received configuration is printed to the serial console and persisted to NVS so it survives power cycles.

Prerequisites
-------------
- PlatformIO (for firmware builds) or VS Code + PlatformIO extension
- Python (used by PlatformIO)
- Flutter SDK (for the mobile app)
- USB/serial tools for monitoring (e.g. `pio device monitor`, `screen`)

Build & flash firmware (ESP32)
-------------------------------
1. Open the `smell_firmware` folder in VS Code (recommended) or use the CLI.
2. Identify the serial port on macOS:

```bash
ls /dev/cu.* | grep usbmodem
```

3. Build and upload via PlatformIO:

```bash
# Build
pio run

# Upload (specify port if needed)
pio run -t upload --upload-port /dev/cu.usbmodemXXXX

# Open serial monitor
pio device monitor --port /dev/cu.usbmodemXXXX --baud 115200
```

Notes: If you see "port busy" during upload, close any serial monitor or terminal holding the port, or replug the USB cable.

Build & run the Flutter app
---------------------------
1. Open `smell_app` in an editor that supports Flutter or use the CLI.
2. Get packages:

```bash
cd smell_app
flutter pub get
```

3. Run the app on a device/emulator:

```bash
flutter run
```

4. Android permissions: the app requests `bluetoothScan`, `bluetoothConnect` and may require `location` depending on Android version. Grant permissions when prompted or edit `AndroidManifest.xml` as appropriate.

BLE protocol (app ↔ firmware)
----------------------------
Service & characteristics

- Service: `12345678-1234-1234-1234-123456789abc`
- Write (config) characteristic: `bbcc0001-e56f-504d-a6c5-6c2342e5672a` — client writes commands and JSON payloads here.
- Notify (response) characteristic: `bbcc0002-e56f-504d-a6c5-6c2342e5672a` — firmware sends JSON responses and status notifications here.

Large-payload strategy (chunking)

BLE write size limits (MTU, library constraints) mean large JSON payloads cannot be reliably written in a single request. An application-level chunking protocol is used:

1. Client sends: `CFG_BEGIN:<total_bytes>` to indicate transfer start and expected size.
2. Client sends multiple chunks: each write begins with the ASCII prefix `CFG_CHUNK:` followed immediately by the raw UTF-8 bytes for that chunk. The client-side chunk size is kept small (example: 180 bytes).
3. Client sends `CFG_END` to mark completion.

On the firmware side the BLE write handler recognizes these prefixes, accumulates raw bytes into an `incomingConfigBuffer`, and on `CFG_END` it validates the assembled byte length and passes the completed JSON to the config handler.

Important: the firmware's `JSON_BUFFER_SIZE` (default 2048) limits the maximum supported config size. Increase that value in `include/config.h` if you need larger transfers.

What happens after firmware receives a configuration
-----------------------------------------------------
- The firmware parses the JSON, saves it to NVS (`NVS_NAMESPACE` / `NVS_CONFIG_KEY`), and updates internal schedules and spray logic.
- The firmware prints the received configuration and processing logs to the serial console.
- The firmware notifies the client with an `apply_result` JSON message over the response characteristic describing success/failure and the next scheduled smell if applicable.

Project file highlights
-----------------------
- `smell_firmware/`
  - `platformio.ini` — build configuration
  - `include/config.h` — device constants (device name, UUIDs, buffer sizes)
  - `src/main.cpp` — initialization and subsystem wiring (BLE, storage, scheduler)
  - `src/ble/ble_manager.cpp` — NimBLE server, chunk assembly, characteristic callbacks
  - `src/display/display_manager.cpp` — serial-only logging (no physical screen)

- `smell_app/`
  - `pubspec.yaml` — Flutter dependencies
  - `lib/providers/ble_provider.dart` — scanning, connection, chunked writes, notifications
  - `lib/presentation/screens/` — UI screens (connection, smells, schedules, settings)

Manual acceptance checklist
--------------------------
1. Flash firmware and open serial monitor:

```bash
pio run -t upload --upload-port /dev/cu.usbmodemXXXX
pio device monitor --port /dev/cu.usbmodemXXXX --baud 115200
```

2. Run the mobile app on a BLE-capable device.
3. In the app, scan for devices — "Smell Device" should appear.
4. Connect: after connecting the app typically requests time sync (`{"unixTime":...}`) and `{"type":"get_config"}` to fetch the stored configuration.
5. Test a large config (> ~220 bytes): ensure the client sends it using `CFG_BEGIN` / `CFG_CHUNK` / `CFG_END` and the firmware prints the reassembled JSON to the serial monitor.
6. Power-cycle the ESP32 and confirm the configuration persists and is reloaded at boot.

Troubleshooting
---------------
- USB port busy during upload: close other serial monitors or replug the device.
- App cannot discover device: confirm firmware shows "Initialized and advertising as 'Smell Device'" in serial logs, restart phone Bluetooth, and verify app permissions.
- PlatformException: data longer than allowed: use the updated app that implements chunking.
- Configuration not persisted: check serial logs for NVS write success messages and verify `include/config.h` NVS keys.

Developer notes
---------------
- Increase `JSON_BUFFER_SIZE` in `include/config.h` to support larger configurations, then rebuild firmware.
- Scheduler and spray logic live in `src/` — edit `scheduler` and `sprayer` modules to change timings or behavior.
- Alternative to chunking: negotiate a larger MTU or use Write Long if both client and server libraries support it — but application-level chunking is more portable.

Contributing & license
----------------------
Contributions are welcome. Please open issues for problems and create focused pull requests with clear descriptions of changes and motivations.

Contact / support
-----------------
If you encounter issues not covered by the troubleshooting section, include serial monitor logs and app logs when opening an issue.

Summary
-------
This repository connects a Flutter UI with an ESP32 BLE device to manage smell presets and schedules. The project uses an application-level chunking protocol to transfer large JSON configs reliably and stores them in NVS so they survive power cycles. Start by flashing the firmware and running the app, then use the checklist above to validate end-to-end behavior.
