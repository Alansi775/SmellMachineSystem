/// Storage Manager implementation using ESP32 Preferences (NVS wrapper).
///
/// Provides simple persistent storage for JSON device configuration.

#include "storage_manager.h"
#include "config.h"
#include <Preferences.h>
#include <vector>

static Preferences preferences;

void StorageManager::setup() {
  if (preferences.begin(NVS_NAMESPACE, false)) {
    Serial.print("[Storage] Initialized with namespace: ");
    Serial.println(NVS_NAMESPACE);
    preferences.end();
  } else {
    Serial.println("[Storage] ERROR: Failed to initialize Preferences");
  }
}

bool StorageManager::saveConfig(const std::string& jsonConfig) {
  if (!preferences.begin(NVS_NAMESPACE, false)) {
    Serial.println("[Storage] ERROR: Failed to open Preferences for writing");
    return false;
  }

  // Store as blob to avoid putString size limitations with larger JSON payloads.
  size_t bytesWritten = preferences.putBytes(
    NVS_CONFIG_KEY,
    jsonConfig.c_str(),
    jsonConfig.length() + 1
  );
  preferences.end();

  if (bytesWritten > 0) {
    Serial.print("[Storage] Config saved: ");
    Serial.println(jsonConfig.c_str());
    return true;
  } else {
    Serial.println("[Storage] ERROR: Failed to save config");
    return false;
  }
}

std::string StorageManager::loadConfig() const {
  if (!preferences.begin(NVS_NAMESPACE, true)) {
    Serial.println("[Storage] ERROR: Failed to open Preferences for reading");
    return "";
  }

  size_t bytesLen = preferences.getBytesLength(NVS_CONFIG_KEY);
  if (bytesLen == 0) {
    preferences.end();
    return "";
  }

  std::vector<char> buffer(bytesLen, '\0');
  size_t readLen = preferences.getBytes(NVS_CONFIG_KEY, buffer.data(), bytesLen);
  preferences.end();

  if (readLen == 0) {
    Serial.println("[Storage] ERROR: Failed to read config blob");
    return "";
  }

  return std::string(buffer.data());
}

bool StorageManager::hasConfig() const {
  if (!preferences.begin(NVS_NAMESPACE, true)) {
    return false;
  }

  bool exists = preferences.isKey(NVS_CONFIG_KEY);
  preferences.end();
  return exists;
}

bool StorageManager::eraseAll() {
  if (!preferences.begin(NVS_NAMESPACE, false)) {
    Serial.println("[Storage] ERROR: Failed to open Preferences for erasing");
    return false;
  }

  preferences.clear();
  preferences.end();

  Serial.println("[Storage] All data erased");
  return true;
}

size_t StorageManager::getConfigSize() const {
  std::string config = loadConfig();
  return config.length();
}

bool StorageManager::ensureInitialized() const {
  bool ok = preferences.begin(NVS_NAMESPACE, true);
  if (ok) {
    preferences.end();
  }
  return ok;
}
