#ifndef ALERT_H
#define ALERT_H

#include "lvgl.h"
#include "../screen1/screen1_func.h"
#include "../screen2/screen2_func.h"
#include "../screen3/screen3_func.h"
#ifdef __cplusplus
extern "C" {
#endif

// alert_battery.c içindeki işlevlerin bildirimleri
void alert_battery_main(void);
static void event_cb(lv_event_t *e);
static void timer_cb(lv_timer_t *timer);

// Uyarı durumunu izleyen değişkenin dışa açılması
extern boolean warn_battery_state;

// alert_water.c içindeki işlevlerin bildirimleri
void alert_water_main(void);
// Uyarı durumunu izleyen değişkenin dışa açılması
extern boolean warn_water_state;

// alert_water.c içindeki işlevlerin bildirimleri
void alert_fuel_main(void);
// Uyarı durumunu izleyen değişkenin dışa açılması
extern boolean warn_fuel_state;

// Define btns inline
static const char *btns[] = {"", ""};

#ifdef __cplusplus
}
#endif

#endif // ALERT_H
