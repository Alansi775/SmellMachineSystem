#include "lvgl.h"
#include <ui.h>
#include "ui_events.h"
#include <Arduino.h>
#include <stdio.h>
#include "screen3_func.h" 

lv_obj_t *ui_fuelArc;
lv_obj_t *ui_fueldeger;
lv_obj_t *ui_fuelMiktar;

bool fuelTotalArcStatus = true;
int TotalArc;

void updatefuelTotalArc(int fuelTotalArcValue, double fuelTotalValues) {
    if (fuelTotalArcStatus) {
        // fuelTotalArcValue += 7; 
        if (fuelTotalArcValue >= 100) {
            fuelTotalArcStatus = false; 
        }
    } else {
        // fuelTotalArcValue -= 3; 
        if (fuelTotalArcValue <= 0) {
            fuelTotalArcStatus = true; 
        }
    }

    char buffer[20] = "";
    lv_arc_set_value(ui_fuelArc, fuelTotalArcValue); // ARC değeri
    lv_label_set_text_fmt(ui_fueldeger, "%d", fuelTotalArcValue); // ARC yüzde değeri
    lv_label_set_text_fmt(ui_fuelMiktar, "%.2f", fuelTotalValues);
}

FuelCell fuelCell[MAX_CELLS ];

void create_fuel_cell(FuelCell fuelCell[MAX_CELLS], lv_obj_t *parent, int index, int x_offset, int y_offset, int slider_value, const char *label_text, const char *value_text) {
    if (!parent) return;
    if (index < 0 || index >= MAX_CELLS) return;  // Maksimum sınır kontrolü

    fuelCell[index].container  = lv_obj_create(parent);
    lv_obj_remove_style_all(fuelCell[index].container );
    lv_obj_set_width(fuelCell[index].container , 400);
    lv_obj_set_height(fuelCell[index].container , 80);
    lv_obj_set_x(fuelCell[index].container , x_offset);   // x_offset parametresi ile x pozisyonu ayarlama
    lv_obj_set_y(fuelCell[index].container , y_offset);   // y_offset parametresi ile y pozisyonu ayarlama
    lv_obj_set_align(fuelCell[index].container , LV_ALIGN_CENTER);
    lv_obj_clear_flag(fuelCell[index].container , LV_OBJ_FLAG_CLICKABLE | LV_OBJ_FLAG_SCROLLABLE);

    lv_obj_t *ui_fuelCellName = lv_label_create(fuelCell[index].container);
    lv_obj_set_width(ui_fuelCellName, LV_SIZE_CONTENT);
    lv_obj_set_height(ui_fuelCellName, LV_SIZE_CONTENT);
    lv_obj_set_x(ui_fuelCellName, 25);
    lv_obj_set_y(ui_fuelCellName, -10);
    lv_obj_set_align(ui_fuelCellName, LV_ALIGN_LEFT_MID);
    lv_label_set_text(ui_fuelCellName, label_text);  // Label text'i parametreden alıyor
    lv_obj_set_style_text_color(ui_fuelCellName, lv_color_hex(0xFFFFFF), LV_PART_MAIN | LV_STATE_DEFAULT);
    lv_obj_set_style_text_opa(ui_fuelCellName, 255, LV_PART_MAIN | LV_STATE_DEFAULT);
    lv_obj_set_style_text_font(ui_fuelCellName, &lv_font_montserrat_24, LV_PART_MAIN | LV_STATE_DEFAULT);

    fuelCell[index].slider = lv_slider_create(fuelCell[index].container);
    lv_slider_set_value(fuelCell[index].slider, slider_value, LV_ANIM_OFF);  // Slider değeri parametreden alınıyor
    if(lv_slider_get_mode(fuelCell[index].slider) == LV_SLIDER_MODE_RANGE) 
        lv_slider_set_left_value(fuelCell[index].slider, slider_value, LV_ANIM_OFF);
    
    lv_obj_set_width(fuelCell[index].slider, 350);
    lv_obj_set_height(fuelCell[index].slider, 10);
    lv_obj_set_x(fuelCell[index].slider, 5);
    lv_obj_set_y(fuelCell[index].slider, 25);
    lv_obj_set_align(fuelCell[index].slider, LV_ALIGN_CENTER);
    lv_obj_set_style_bg_color(fuelCell[index].slider, lv_color_hex(0xFF8000), LV_PART_MAIN | LV_STATE_DEFAULT);
    lv_obj_set_style_bg_opa(fuelCell[index].slider, 0, LV_PART_MAIN | LV_STATE_DEFAULT);
    lv_obj_set_style_border_color(fuelCell[index].slider, lv_color_hex(0xFF8000), LV_PART_MAIN | LV_STATE_DEFAULT);
    lv_obj_set_style_border_opa(fuelCell[index].slider, 255, LV_PART_MAIN | LV_STATE_DEFAULT);
    lv_obj_set_style_border_width(fuelCell[index].slider, 2, LV_PART_MAIN | LV_STATE_DEFAULT);
    lv_obj_set_style_border_side(fuelCell[index].slider, LV_BORDER_SIDE_TOP, LV_PART_MAIN | LV_STATE_DEFAULT);

    lv_obj_set_style_bg_color(fuelCell[index].slider, lv_color_hex(0xFF8000), LV_PART_INDICATOR | LV_STATE_DEFAULT);
    lv_obj_set_style_bg_opa(fuelCell[index].slider, 255, LV_PART_INDICATOR | LV_STATE_DEFAULT);
    lv_obj_set_style_bg_grad_color(fuelCell[index].slider, lv_color_hex(0xFFFFFF), LV_PART_INDICATOR | LV_STATE_DEFAULT);

    lv_obj_set_style_bg_color(fuelCell[index].slider, lv_color_hex(0xFF8000), LV_PART_KNOB | LV_STATE_DEFAULT);
    lv_obj_set_style_bg_opa(fuelCell[index].slider, 0, LV_PART_KNOB | LV_STATE_DEFAULT);
    lv_obj_clear_flag(fuelCell[index].slider, LV_OBJ_FLAG_CLICKABLE);

    fuelCell[index].value_label = lv_label_create(fuelCell[index].container);
    lv_obj_set_width(fuelCell[index].value_label, LV_SIZE_CONTENT);
    lv_obj_set_height(fuelCell[index].value_label, LV_SIZE_CONTENT);
    lv_obj_set_x(fuelCell[index].value_label, 250);
    lv_obj_set_y(fuelCell[index].value_label, -10);
    lv_obj_set_align(fuelCell[index].value_label, LV_ALIGN_LEFT_MID);
    lv_label_set_text(fuelCell[index].value_label, value_text);  // Değer text'i parametreden alınıyor
    lv_obj_set_style_text_color(fuelCell[index].value_label, lv_color_hex(0xFFFFFF), LV_PART_MAIN | LV_STATE_DEFAULT);
    lv_obj_set_style_text_opa(fuelCell[index].value_label, 255, LV_PART_MAIN | LV_STATE_DEFAULT);
    lv_obj_set_style_text_font(fuelCell[index].value_label, &lv_font_montserrat_48, LV_PART_MAIN | LV_STATE_DEFAULT);
}

void create_multiple_fuel_cells(lv_obj_t *parent, int adet) {
    if(adet >= 5 || adet == 5){
    adet = 4;
    }
    for (int i = 0; i <= adet; i++) {
        int x_offset = 150;
        int y_offset = -150 + (i * 90);
        int slider_value = (i + 1) * 10;
        char label_text[10];
        char value_text[10];
        
        sprintf(label_text, "Fuel %d", i + 1);
        sprintf(value_text, "%% %d", slider_value);
        
        create_fuel_cell(fuelCell, parent, i, x_offset, y_offset, slider_value, label_text, value_text);
    }
}

// Batarya hücresine dışarıdan değer atama örneği
void update_fuel_cell(int index, int slider_value) {
    if (index < 0 || index >= MAX_CELLS) return;

    // Slider değeri ve etiket metnini güncelleme
    lv_slider_set_value(fuelCell[index].slider, slider_value, LV_ANIM_OFF);
    char buffer[50]; 
    sprintf(buffer, "%% %d", slider_value);
    lv_label_set_text(fuelCell[index].value_label, buffer);

    // Tüm slider değerlerinin ortalamasını hesapla
    int sum = 0;
    int count = 0;
    for (int i = 0; i < MAX_CELLS; i++) {
        if (fuelCell[i].slider) {  // Eğer slider mevcutsa
            sum += lv_slider_get_value(fuelCell[i].slider);
            count++;
        }
    }
    // Ortalama hesaplama ve güncelleme
    if (count > 0) {
        int average = sum / count;
        updatefuelTotalArc(average, 202.15);  // Ortalama değeri fonksiyona gönder
    }
}