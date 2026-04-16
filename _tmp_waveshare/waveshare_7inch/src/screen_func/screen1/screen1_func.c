#include "lvgl.h"
#include <ui.h>
#include "ui_events.h"
#include <Arduino.h>
#include <stdio.h>
#include "screen1_func.h" 

lv_obj_t *ui_batteryArc;
lv_obj_t *ui_arcDeger;
lv_obj_t *ui_batteryTotalValue;

bool batteryTotalArcStatus = true;

void updateBatteryTotalArc(int batteryTotalArcValue, double batteryTotalValues) {
    if (batteryTotalArcStatus) {
        // batteryTotalArcValue += 7; 
        if (batteryTotalArcValue >= 100) {
            batteryTotalArcStatus = false; 
        }
    } else {
        // batteryTotalArcValue -= 3; 
        if (batteryTotalArcValue <= 0) {
            batteryTotalArcStatus = true; 
        }
    }

    char buffer[20] = "";
    lv_arc_set_value(ui_batteryArc, batteryTotalArcValue); // ARC değeri
    lv_label_set_text_fmt(ui_arcDeger, "%d", batteryTotalArcValue); // ARC yüzde değeri
    lv_label_set_text_fmt(ui_batteryTotalValue, "%.2f", batteryTotalValues);
}
BatteryCell battery_cells[MAX_CELLS_BAT ];

void create_battery_cell(lv_obj_t *parent, int index, int x_offset, int y_offset, int slider_value, const char *label_text, const char *value_text) {
    if (!parent) return;
    if (index < 1 || index >= MAX_CELLS_BAT) return;  // Maksimum sınır kontrolü

    battery_cells[index].container  = lv_obj_create(parent);
    lv_obj_remove_style_all(battery_cells[index].container );
    lv_obj_set_width(battery_cells[index].container , 310);
    lv_obj_set_height(battery_cells[index].container , 80);
    lv_obj_set_x(battery_cells[index].container , x_offset);   // x_offset parametresi ile x pozisyonu ayarlama
    lv_obj_set_y(battery_cells[index].container , y_offset);   // y_offset parametresi ile y pozisyonu ayarlama
    lv_obj_set_align(battery_cells[index].container , LV_ALIGN_CENTER);
    lv_obj_clear_flag(battery_cells[index].container , LV_OBJ_FLAG_CLICKABLE | LV_OBJ_FLAG_SCROLLABLE);

    lv_obj_t *ui_batteryCellName = lv_label_create(battery_cells[index].container);
    lv_obj_set_width(ui_batteryCellName, LV_SIZE_CONTENT);
    lv_obj_set_height(ui_batteryCellName, LV_SIZE_CONTENT);
    lv_obj_set_x(ui_batteryCellName, 1);
    lv_obj_set_y(ui_batteryCellName, -10);
    lv_obj_set_align(ui_batteryCellName, LV_ALIGN_LEFT_MID);
    lv_label_set_text(ui_batteryCellName, label_text);  // Label text'i parametreden alıyor
    lv_obj_set_style_text_color(ui_batteryCellName, lv_color_hex(0xFFFFFF), LV_PART_MAIN | LV_STATE_DEFAULT);
    lv_obj_set_style_text_opa(ui_batteryCellName, 255, LV_PART_MAIN | LV_STATE_DEFAULT);
    lv_obj_set_style_text_font(ui_batteryCellName, &lv_font_montserrat_24, LV_PART_MAIN | LV_STATE_DEFAULT);

    battery_cells[index].slider = lv_slider_create(battery_cells[index].container);
    lv_slider_set_value(battery_cells[index].slider, slider_value, LV_ANIM_OFF);  // Slider değeri parametreden alınıyor
    if(lv_slider_get_mode(battery_cells[index].slider) == LV_SLIDER_MODE_RANGE) 
        lv_slider_set_left_value(battery_cells[index].slider, slider_value, LV_ANIM_OFF);
    
    lv_obj_set_width(battery_cells[index].slider, 300);
    lv_obj_set_height(battery_cells[index].slider, 15);
    lv_obj_set_x(battery_cells[index].slider, 1);
    lv_obj_set_y(battery_cells[index].slider, 26);
    lv_obj_set_align(battery_cells[index].slider, LV_ALIGN_CENTER);
    lv_obj_set_style_bg_color(battery_cells[index].slider, lv_color_hex(0xFFFFFF), LV_PART_MAIN | LV_STATE_DEFAULT);
    lv_obj_set_style_bg_opa(battery_cells[index].slider, 0, LV_PART_MAIN | LV_STATE_DEFAULT);
    lv_obj_set_style_border_color(battery_cells[index].slider, lv_color_hex(0x00FF00), LV_PART_MAIN | LV_STATE_DEFAULT);
    lv_obj_set_style_border_opa(battery_cells[index].slider, 255, LV_PART_MAIN | LV_STATE_DEFAULT);
    lv_obj_set_style_border_width(battery_cells[index].slider, 1, LV_PART_MAIN | LV_STATE_DEFAULT);
    lv_obj_set_style_border_side(battery_cells[index].slider, LV_BORDER_SIDE_TOP, LV_PART_MAIN | LV_STATE_DEFAULT);

    lv_obj_set_style_bg_color(battery_cells[index].slider, lv_color_hex(0x00FF00), LV_PART_INDICATOR | LV_STATE_DEFAULT);
    lv_obj_set_style_bg_opa(battery_cells[index].slider, 255, LV_PART_INDICATOR | LV_STATE_DEFAULT);
    lv_obj_set_style_bg_grad_color(battery_cells[index].slider, lv_color_hex(0xFFFFFF), LV_PART_INDICATOR | LV_STATE_DEFAULT);

    lv_obj_set_style_bg_color(battery_cells[index].slider, lv_color_hex(0xFFFFFF), LV_PART_KNOB | LV_STATE_DEFAULT);
    lv_obj_set_style_bg_opa(battery_cells[index].slider, 0, LV_PART_KNOB | LV_STATE_DEFAULT);
    lv_obj_clear_flag(battery_cells[index].slider, LV_OBJ_FLAG_CLICKABLE);

    battery_cells[index].value_label = lv_label_create(battery_cells[index].container);
    lv_obj_set_width(battery_cells[index].value_label, LV_SIZE_CONTENT);
    lv_obj_set_height(battery_cells[index].value_label, LV_SIZE_CONTENT);
    lv_obj_set_x(battery_cells[index].value_label, 200);
    lv_obj_set_y(battery_cells[index].value_label, -10);
    lv_obj_set_align(battery_cells[index].value_label, LV_ALIGN_LEFT_MID);
    lv_label_set_text(battery_cells[index].value_label, value_text);  // Değer text'i parametreden alınıyor
    lv_obj_set_style_text_color(battery_cells[index].value_label, lv_color_hex(0xFFFFFF), LV_PART_MAIN | LV_STATE_DEFAULT);
    lv_obj_set_style_text_opa(battery_cells[index].value_label, 255, LV_PART_MAIN | LV_STATE_DEFAULT);
    lv_obj_set_style_text_font(battery_cells[index].value_label, &lv_font_montserrat_48, LV_PART_MAIN | LV_STATE_DEFAULT);
}

void create_multiple_battery_cells(lv_obj_t *parent, int adet) {
    if(adet >= 3 || adet == 3){
    adet = 2;
    }
    for (int i = 0; i <= adet; i++) {
        int x_offset = 180;
        int y_offset = -250 + (i * 90);
        int slider_value = (i + 1) * 10;
        char label_text[10];
        char value_text[10];
        
        sprintf(label_text, "Battery %d", i + 1);
        sprintf(value_text, "%% %d", slider_value);
        
        create_battery_cell(parent, i, x_offset, y_offset, slider_value, label_text, value_text);
    }
}

// Batarya hücresine dışarıdan değer atama örneği
void update_battery_cell(int index, int slider_value) {
    if (index < 0 || index >= MAX_CELLS_BAT) return;

    // Slider değeri ve etiket metnini güncelleme
    lv_slider_set_value(battery_cells[index].slider, slider_value, LV_ANIM_OFF);
    char buffer[50]; 
    sprintf(buffer, "%% %d", slider_value);
    lv_label_set_text(battery_cells[index].value_label, buffer);

    // Tüm slider değerlerinin ortalamasını hesapla
    int sum = 0;
    int count = 0;
    for (int i = 0; i < MAX_CELLS_BAT; i++) {
        if (battery_cells[i].slider) {  // Eğer slider mevcutsa
            sum += lv_slider_get_value(battery_cells[i].slider);
            count++;
        }
    }
    // Ortalama hesaplama ve güncelleme
    if (count > 0) {
        int average = sum / count;
        updateBatteryTotalArc(average, 202.15);  // Ortalama değeri fonksiyona gönder
    }
}