/// BLE Manager implementation for NimBLE-Arduino.
///
/// Provides NimBLE server setup, characteristic management, and callbacks.
/// This implementation uses NimBLE for lower power consumption and smaller
/// memory footprint compared to default BLE implementation on ESP32-S3.

#include "ble_manager.h"
#include "config.h"
#include <NimBLEDevice.h>

static NimBLEServer* pServer = nullptr;
static NimBLECharacteristic* pConfigCharacteristic = nullptr;
static NimBLECharacteristic* pResponseCharacteristic = nullptr;
static void (*configCallback)(const std::string& config) = nullptr;
static bool clientConnected = false;
static std::string incomingConfigBuffer;
static bool receivingChunkedConfig = false;

class ServerCallbacks : public NimBLEServerCallbacks {
  void onConnect(NimBLEServer* pServer) {
    clientConnected = true;
    Serial.println("[BLE] Client connected");
  }

  void onDisconnect(NimBLEServer* pServer) {
    clientConnected = false;
    Serial.println("[BLE] Client disconnected");
    NimBLEDevice::startAdvertising();
    Serial.println("[BLE] Advertising restarted");
  }
};

class ConfigCharCallbacks : public NimBLECharacteristicCallbacks {
  void onWrite(NimBLECharacteristic* pCharacteristic) {
    std::string jsonConfig = pCharacteristic->getValue();
    if (jsonConfig.empty()) {
      return;
    }

    if (jsonConfig.rfind("CFG_BEGIN:", 0) == 0) {
      incomingConfigBuffer.clear();
      receivingChunkedConfig = true;
      Serial.print("[BLE] Chunked config begin: ");
      Serial.println(jsonConfig.c_str());
      return;
    }

    if (jsonConfig.rfind("CFG_CHUNK:", 0) == 0) {
      if (receivingChunkedConfig) {
        incomingConfigBuffer.append(jsonConfig.substr(10));
      }
      return;
    }

    if (jsonConfig == "CFG_END") {
      Serial.print("[BLE] Chunked config received, bytes=");
      Serial.println(incomingConfigBuffer.length());
      if (configCallback && receivingChunkedConfig && !incomingConfigBuffer.empty()) {
        configCallback(incomingConfigBuffer);
      }
      incomingConfigBuffer.clear();
      receivingChunkedConfig = false;
      return;
    }

    Serial.print("[BLE] Received config: ");
    Serial.println(jsonConfig.c_str());
    if (configCallback) {
      configCallback(jsonConfig);
    }
  }
};

void BleManager::setup() {
  Serial.println("[BLE] Initializing NimBLE device...");

  // Initialize NimBLE device
  NimBLEDevice::init(DEVICE_NAME);
  NimBLEDevice::setDeviceName(DEVICE_NAME);
  NimBLEDevice::setPower(ESP_PWR_LVL_P9, ESP_BLE_PWR_TYPE_DEFAULT);

  // Create server
  pServer = NimBLEDevice::createServer();
  if (!pServer) {
    Serial.println("[BLE] ERROR: Failed to create BLE server");
    return;
  }
  pServer->setCallbacks(new ServerCallbacks());

  // Create service
  NimBLEService* pService = pServer->createService(BLE_SERVICE_UUID);
  if (!pService) {
    Serial.println("[BLE] ERROR: Failed to create BLE service");
    return;
  }

  // Create config characteristic (write + notify)
  pConfigCharacteristic = pService->createCharacteristic(
    BLE_CONFIG_CHAR_UUID,
    NIMBLE_PROPERTY::WRITE | NIMBLE_PROPERTY::WRITE_NR
  );
  pConfigCharacteristic->setCallbacks(new ConfigCharCallbacks());

  // Create response characteristic (read + notify)
  pResponseCharacteristic = pService->createCharacteristic(
    BLE_RESPONSE_CHAR_UUID,
    NIMBLE_PROPERTY::READ | NIMBLE_PROPERTY::NOTIFY
  );
  if (!pConfigCharacteristic || !pResponseCharacteristic) {
    Serial.println("[BLE] ERROR: Failed to create BLE characteristics");
    return;
  }

  // Start service
  pService->start();

  // Start advertising
  NimBLEAdvertising* pAdvertising = NimBLEDevice::getAdvertising();
  if (!pAdvertising) {
    Serial.println("[BLE] ERROR: Failed to get BLE advertising handle");
    return;
  }

  pAdvertising->addServiceUUID(BLE_SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->setMaxPreferred(0x12);
  bool advStarted = pAdvertising->start(0);
  if (!advStarted) {
    Serial.println("[BLE] WARN: First advertising start failed, retrying...");
    NimBLEDevice::stopAdvertising();
    delay(200);
    advStarted = pAdvertising->start(0);
  }

  if (advStarted) {
    Serial.print("[BLE] Initialized and advertising as '");
    Serial.print(DEVICE_NAME);
    Serial.println("'");
  } else {
    Serial.println("[BLE] ERROR: Advertising did not start");
  }
}

void BleManager::setOnConfigReceived(void (*callback)(const std::string& config)) {
  configCallback = callback;
}

void BleManager::sendConfig(const std::string& jsonConfig) {
  if (pResponseCharacteristic && clientConnected) {
    pResponseCharacteristic->setValue(jsonConfig);
    pResponseCharacteristic->notify();
    Serial.print("[BLE] Sent config: ");
    Serial.println(jsonConfig.c_str());
  }
}

bool BleManager::isConnected() const {
  return clientConnected;
}

void BleManager::shutdown() {
  if (pServer) {
    pServer->getAdvertising()->stop();
    NimBLEDevice::deinit(true);
    Serial.println("[BLE] Shutdown complete");
  }
}

void BleManager::initializeService() {
  // Service initialization is handled in setup()
}

void BleManager::onConnect() {
  clientConnected = true;
}

void BleManager::onDisconnect() {
  clientConnected = false;
}

void BleManager::onConfigWrite(const std::string& data) {
  // Handled in ConfigCharCallbacks::onWrite()
}
