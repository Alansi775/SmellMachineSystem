#include <lvgl.h>
#include <ui.h>
#include "ui_events.h"
#include <Arduino.h>
#include <stdio.h>

#include "alert.h"

lv_obj_t *ui_arcDeger;
lv_obj_t *ui_batteryTotalValue;
boolean warn_battery_state = false;
lv_timer_t *battery_timer = NULL;

// Uyarı kutusu butonuna basıldığında çağrılacak işlev
static void event_cb(lv_event_t *e) {
    LV_LOG_USER("Button clicked");

    if (!battery_timer) {
        battery_timer = lv_timer_create(timer_cb, 10000, NULL);
    } else {
        lv_timer_resume(battery_timer);
    }

    lv_obj_del_async(lv_event_get_current_target(e));
    warn_battery_state = false;
}

// Batarya seviyesini kontrol eden işlev
void alert_battery_main() {
    if (warn_battery_state) return;

    char warning_msg[256]; // Uyarı mesajı için yeterli boyutta bir dizi
    snprintf(warning_msg, sizeof(warning_msg), "Battery too low!\n");

    bool low_battery_found = false; // Düşük batarya bulunup bulunmadığını kontrol et

    for (int i = 0; i < MAX_CELLS_BAT; i++) {
        if (battery_cells[i].value_label) {
            int value = lv_slider_get_value(battery_cells[i].slider);
            if (value <= 10) {
                // Düşük batarya durumu bulundu
                low_battery_found = true;

                // Düşük batarya hücresi bilgilerini uyarı mesajına ekle
                snprintf(warning_msg + strlen(warning_msg), sizeof(warning_msg) - strlen(warning_msg),
                         "Battery %d: %d%%\n", i + 1, value);
            }
        }
    }

    if (low_battery_found) {
        lv_obj_t *mbox_minimum = lv_msgbox_create(NULL, "WARNING", warning_msg, btns, true);
        lv_obj_add_event_cb(mbox_minimum, event_cb, LV_EVENT_VALUE_CHANGED, NULL);
        lv_obj_center(mbox_minimum);

        lv_obj_set_style_bg_color(mbox_minimum, lv_color_hex(0x2E2E2E), 0);  
        lv_obj_set_style_bg_opa(mbox_minimum, LV_OPA_COVER, 70);
        lv_obj_set_style_text_color(mbox_minimum, lv_color_hex(0xFFFFFF), LV_PART_MAIN); 
        lv_obj_set_style_text_font(mbox_minimum, &lv_font_montserrat_24, LV_PART_MAIN);
        // Style the message box close button
        lv_obj_t *close_btn = lv_msgbox_get_close_btn(mbox_minimum);
            if (close_btn) {
                lv_obj_set_style_bg_color(close_btn, lv_color_hex(0xE57373), 0);  // Light red background for close button
                lv_obj_set_style_text_color(close_btn, lv_color_hex(0xFFFFFF), 0); // White text/icon color
                lv_obj_set_style_border_color(close_btn, lv_color_hex(0xD32F2F), 0); // Darker red border color
                lv_obj_set_style_border_width(close_btn, 2, 0); // Border width
                lv_obj_set_style_radius(close_btn, 20, 0); // Rounded corners for close button
            }

        warn_battery_state = true;

        // Zamanlayıcıyı durdur
        if (battery_timer) {
            lv_timer_pause(battery_timer);
        }
    }
}

// Uyarıyı yeniden etkinleştiren zamanlayıcı işlevi
static void timer_cb(lv_timer_t *timer) {
    warn_battery_state = false;
    lv_timer_pause(timer);
}
