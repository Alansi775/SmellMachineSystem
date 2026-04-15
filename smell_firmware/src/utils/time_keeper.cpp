/// TimeKeeper implementation for clock management.
///
/// Tracks time using system milliseconds and periodic sync from app.

#include "time_keeper.h"
#include <time.h>

void TimeKeeper::setup() {
  Serial.println("[TimeKeeper] Initialized");
  // Wait for sync from app before running schedules
}

void TimeKeeper::syncTime(time_t unixTimestamp) {
  lastSyncTimestamp = unixTimestamp;
  lastSyncMillis = millis();
  synchronized = true;
  Serial.print("[TimeKeeper] Synced to Unix timestamp: ");
  Serial.println(unixTimestamp);
}

time_t TimeKeeper::getUnixTimestamp() const {
  if (!synchronized) {
    Serial.println("[TimeKeeper] WARNING: Time not synchronized");
    return 0;
  }
  unsigned long elapsedMs = millis() - lastSyncMillis;
  return lastSyncTimestamp + (elapsedMs / 1000);
}

struct tm TimeKeeper::getCurrentTime() const {
  time_t timestamp = getUnixTimestamp();
  struct tm timeinfo;
  gmtime_r(&timestamp, &timeinfo);
  return timeinfo;
}

uint8_t TimeKeeper::getCurrentHour() const {
  struct tm timeinfo = getCurrentTime();
  return timeinfo.tm_hour;
}

uint8_t TimeKeeper::getCurrentMinute() const {
  struct tm timeinfo = getCurrentTime();
  return timeinfo.tm_min;
}

uint8_t TimeKeeper::getDayOfWeek() const {
  struct tm timeinfo = getCurrentTime();
  // struct tm uses 0=Sunday, we use 0=Monday
  // So convert: 0->6, 1->0, 2->1, ..., 6->5
  return (timeinfo.tm_wday + 6) % 7;
}

uint16_t TimeKeeper::getMinutesSinceMidnight() const {
  struct tm timeinfo = getCurrentTime();
  return timeinfo.tm_hour * 60 + timeinfo.tm_min;
}

bool TimeKeeper::isTimeSynchronized() const {
  return synchronized;
}

time_t TimeKeeper::calculateCurrentTimestamp() const {
  // TODO: Add elapsed time since last sync to lastSyncTimestamp
  unsigned long elapsedMs = millis() - lastSyncMillis;
  unsigned long elapsedSeconds = elapsedMs / 1000;
  return lastSyncTimestamp + elapsedSeconds; // Placeholder
}
