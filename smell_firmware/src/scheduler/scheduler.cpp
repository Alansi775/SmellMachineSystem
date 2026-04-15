/// Scheduler implementation for automatic fragrance dispensing.
///
/// Parses schedule JSON and checks against current time to trigger sprayers.

#include "scheduler.h"
#include "config.h"
#include "time_keeper.h"
#include "sprayer.h"
#include <ArduinoJson.h>

// External references (defined in main.cpp)
extern TimeKeeper timeKeeper;
extern Sprayer sprayer;

void Scheduler::setup() {
  Serial.println("[Scheduler] Initialized");
}

void Scheduler::updateSchedules(const std::string& jsonConfig) {
  Serial.print("[Scheduler] Parsing schedules from JSON...");

  // Allocate buffer for ArduinoJson
  StaticJsonDocument<JSON_BUFFER_SIZE> doc;
  DeserializationError error = deserializeJson(doc, jsonConfig.c_str());

  if (error) {
    Serial.print("ERROR: JSON parse failed: ");
    Serial.println(error.c_str());
    return;
  }

  // Clear existing schedules
  schedules.clear();

  // Parse schedules array
  if (doc.containsKey("schedules") && doc["schedules"].is<JsonArray>()) {
    JsonArray schedulesArray = doc["schedules"].as<JsonArray>();
    
    for (JsonObject schedObj : schedulesArray) {
      ScheduleEntry entry;
      entry.id = schedObj["id"].as<std::string>();
      entry.smellId = schedObj["smellId"].as<std::string>();
      entry.dayOfWeek = schedObj["dayOfWeek"] | 0;
      entry.startTime = timeStringToMinutes(schedObj["startTime"].as<std::string>());
      entry.endTime = timeStringToMinutes(schedObj["endTime"].as<std::string>());
      
      schedules.push_back(entry);
      
      Serial.print("  - Schedule: ");
      Serial.print(entry.id.c_str());
      Serial.print(" -> ");
      Serial.println(entry.smellId.c_str());
    }
  }

  Serial.print("[Scheduler] Loaded ");
  Serial.print(schedules.size());
  Serial.println(" schedules");
}

std::string Scheduler::check() {
  if (!timeKeeper.isTimeSynchronized()) {
    return ""; // Can't check schedules without time sync
  }

  uint8_t currentDay = timeKeeper.getDayOfWeek();
  uint16_t currentMinutes = timeKeeper.getMinutesSinceMidnight();

  for (const auto& schedule : schedules) {
    if (schedule.dayOfWeek == currentDay) {
      if (currentMinutes >= schedule.startTime && currentMinutes < schedule.endTime) {
        triggerSpray(schedule.smellId);
        return schedule.smellId;
      }
    }
  }

  return "";
}

std::vector<ScheduleEntry> Scheduler::getActiveSchedules() const {
  std::vector<ScheduleEntry> active;
  
  if (!timeKeeper.isTimeSynchronized()) {
    return active;
  }

  uint8_t currentDay = timeKeeper.getDayOfWeek();
  uint16_t currentMinutes = timeKeeper.getMinutesSinceMidnight();

  for (const auto& schedule : schedules) {
    if (schedule.dayOfWeek == currentDay &&
        currentMinutes >= schedule.startTime &&
        currentMinutes < schedule.endTime) {
      active.push_back(schedule);
    }
  }

  return active;
}

const std::vector<ScheduleEntry>& Scheduler::getAllSchedules() const {
  return schedules;
}

uint16_t Scheduler::timeStringToMinutes(const std::string& timeStr) const {
  // Parse "HH:mm" format
  if (timeStr.length() < 5) return 0;
  
  int hour = std::stoi(timeStr.substr(0, 2));
  int minute = std::stoi(timeStr.substr(3, 2));
  
  return hour * 60 + minute;
}

uint8_t Scheduler::getCurrentDayOfWeek() const {
  return timeKeeper.getDayOfWeek();
}

uint16_t Scheduler::getCurrentTimeInMinutes() const {
  return timeKeeper.getMinutesSinceMidnight();
}

void Scheduler::triggerSpray(const std::string& smellId) {
  Serial.print("[Scheduler] Triggering spray for smell: ");
  Serial.println(smellId.c_str());
  sprayer.spray(smellId, 500); // 500ms spray duration
}
