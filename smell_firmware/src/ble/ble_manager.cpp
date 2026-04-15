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

class ServerCallbacks : public NimBLEServerCallbacks {
  void onConnect(NimBLEServer* pServer) {
    clientConnected = true;
    Serial.println("[BLE] Client connected");
  }

  void onDisconnect(NimBLEServer* pServer) {
    clientConnected = false;
    Serial.println("[BLE] Client disconnected");
  }
};

class ConfigCharCallbacks : public NimBLECharacteristicCallbacks {
  void onWrite(NimBLECharacteristic* pCharacteristic) {
    std::string jsonConfig = pCharacteristic->getValue();
    if (!jsonConfig.empty()) {
      Serial.print("[BLE] Received config: ");
      Serial.println(jsonConfig.c_str());
      if (configCallback) {
        configCallback(jsonConfig);
      }
    }
  }
};

void BleManager::setup() {
  Serial.println("[BLE] Initializing NimBLE device...");

  // Initialize NimBLE device
  NimBLEDevice::init(DEVICE_NAME);
  NimBLEDevice::setPower(ESP_PWR_LVL_P9, ESP_BLE_PWR_TYPE_DEFAULT);

  // Create server
  pServer = NimBLEDevice::createServer();
  pServer->setCallbacks(new ServerCallbacks());

  // Create service
  NimBLEService* pService = pServer->createService(BLE_SERVICE_UUID);

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

  // Start service
  pService->start();

  // Start advertising
  NimBLEAdvertising* pAdvertising = NimBLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(BLE_SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->setMaxPreferred(0x12);
  pAdvertising->start();

  Serial.print("[BLE] Initialized and advertising as '");
  Serial.print(DEVICE_NAME);
  Serial.println("'");
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
