#include "lvgl.h"
#include <ui.h>
#include "ui_events.h"
#include <Arduino.h>
#include <stdio.h>
#include "screen2_func.h" 

lv_obj_t *ui_temizsudeger;
lv_obj_t *ui_temizSuArc;
lv_obj_t *ui_temizSuMiktar;
// Kirli Depolar
lv_obj_t *ui_kirliSuDeger;
lv_obj_t *ui_kirliSuArc;
lv_obj_t *ui_kirliSuMiktar;
lv_obj_t *ui_kirlisudeger;

Depo temizSuDepo[MAX_CELLS_WAT];
Depo kirliSuDepo[MAX_CELLS_WAT];

bool kirliSuArcStatus = true;
bool TemizSuArcStatus = true;

void updateTemizSuTotalArc(int temizSuArcValue, double temizSuTotalValues) {
    if (TemizSuArcStatus) {
        // temizSuArcValue += 7; 
        if (temizSuArcValue >= 100) {
            TemizSuArcStatus = false; 
        }
    } else {
        // temizSuArcValue -= 3; 
        if (temizSuArcValue <= 0) {
            TemizSuArcStatus = true; 
        }
    }

    lv_arc_set_value(ui_temizSuArc, temizSuArcValue); // ARC değeri
    lv_label_set_text_fmt(ui_temizsudeger, "%d", temizSuArcValue); // ARC yüzde değeri
    lv_label_set_text_fmt(ui_temizSuMiktar, "%.2f", temizSuTotalValues); // Su Miktarı
}

void create_multiple_temizsu_depo(lv_obj_t *parent, int adet) {
    if(adet >= 2){
    adet = 2;
    }
    for (int i = 0; i <= adet; i++) {
        int x_offset = -270;
        int y_offset = -150 + (i * 70);
        int slider_value = (i + 1) * 10;
        char label_text[10];
        char value_text[10];
        
        sprintf(label_text, "Depo %d", i);
        sprintf(value_text, "%% %d", slider_value);
        
        create_su_depo(temizSuDepo, parent, i, x_offset, y_offset, slider_value, label_text, value_text, lv_color_hex(0x4040FF));
    }
}

void update_temizsu_depo(int index, int slider_value) {
    if (index < 0 || index >= MAX_CELLS_WAT) return;

    // Slider değeri ve etiket metnini güncelleme
    lv_slider_set_value(temizSuDepo[index].slider, slider_value, LV_ANIM_OFF);
    char buffer[50]; 
    sprintf(buffer, "%% %d", slider_value);
    lv_label_set_text(temizSuDepo[index].value_label, buffer);

    // Tüm slider değerlerinin ortalamasını hesapla
    int sum = 0;
    int count = 0;
    for (int i = 0; i < MAX_CELLS_WAT; i++) {
        if (temizSuDepo[i].slider) {  // Eğer slider mevcutsa
            sum += lv_slider_get_value(temizSuDepo[i].slider);
            count++;
        }
    }

    // Ortalama hesaplama ve güncelleme
    if (count > 0) {
        int average = sum / count;
        updateTemizSuTotalArc(average, 173.85);  // Ortalama değeri fonksiyona gönder
    }
}

void updateKirliSuTotalArc(int kirliSuArcValue, double kirliSuTotalValues) {
    if (kirliSuArcStatus) {
        // kirliSuArcValue += 7; 
        if (kirliSuArcValue >= 100) {
            kirliSuArcStatus = false; 
        }
    } else {
        // kirliSuArcValue -= 3; 
        if (kirliSuArcValue <= 0) {
            kirliSuArcStatus = true; 
        }
    }

    lv_arc_set_value(ui_kirliSuArc, kirliSuArcValue); // ARC değeri
    lv_label_set_text_fmt(ui_kirliSuDeger, "%d", kirliSuArcValue); // ARC yüzde değeri
    lv_label_set_text_fmt(ui_kirliSuMiktar, "%.2f", kirliSuTotalValues);
}

void create_su_depo(Depo depo[MAX_CELLS_WAT], lv_obj_t *parent, int index, int x_offset, int y_offset, int slider_value, const char *label_text, const char *value_text, lv_color_t label_color) {
    if (!parent) return;
    if (index < 1 || index >= MAX_CELLS_WAT) return;  // Maksimum sınır kontrolü

    depo[index].container  = lv_obj_create(parent);
    lv_obj_remove_style_all(depo[index].container );
    lv_obj_set_width(depo[index].container , 200);
    lv_obj_set_height(depo[index].container , 70);
    lv_obj_set_x(depo[index].container , x_offset);   // x_offset parametresi ile x pozisyonu ayarlama
    lv_obj_set_y(depo[index].container , y_offset);   // y_offset parametresi ile y pozisyonu ayarlama
    lv_obj_set_align(depo[index].container , LV_ALIGN_CENTER);
    lv_obj_clear_flag(depo[index].container , LV_OBJ_FLAG_CLICKABLE | LV_OBJ_FLAG_SCROLLABLE);

    lv_obj_t *ui_Name = lv_label_create(depo[index].container);
    lv_obj_set_width(ui_Name, LV_SIZE_CONTENT);
    lv_obj_set_height(ui_Name, LV_SIZE_CONTENT);
    lv_obj_set_x(ui_Name, -55);
    lv_obj_set_y(ui_Name, -15);
    lv_obj_set_align(ui_Name, LV_ALIGN_CENTER);
    lv_label_set_text(ui_Name, label_text);  // Label text'i parametreden alıyor
    lv_obj_set_style_text_color(ui_Name, lv_color_hex(0xB9B9B9), LV_PART_MAIN | LV_STATE_DEFAULT);
    lv_obj_set_style_text_opa(ui_Name, 255, LV_PART_MAIN | LV_STATE_DEFAULT);
    lv_obj_set_style_text_font(ui_Name, &lv_font_montserrat_24, LV_PART_MAIN | LV_STATE_DEFAULT);

    depo[index].slider = lv_slider_create(depo[index].container);
    lv_slider_set_value(depo[index].slider, slider_value, LV_ANIM_OFF);  // Slider değeri parametreden alınıyor
    if(lv_slider_get_mode(depo[index].slider) == LV_SLIDER_MODE_RANGE) 
        lv_slider_set_left_value(depo[index].slider, slider_value, LV_ANIM_OFF);
    
    lv_obj_set_width(depo[index].slider, 180);
    lv_obj_set_height(depo[index].slider, 10);
    lv_obj_set_x(depo[index].slider, -1);
    lv_obj_set_y(depo[index].slider, 10);
    lv_obj_set_align(depo[index].slider, LV_ALIGN_CENTER);
    lv_obj_set_style_bg_color(depo[index].slider, lv_color_hex(0xFFFFFF), LV_PART_MAIN | LV_STATE_DEFAULT);
    lv_obj_set_style_bg_opa(depo[index].slider, 0, LV_PART_MAIN | LV_STATE_DEFAULT);
    lv_obj_set_style_border_color(depo[index].slider, label_color, LV_PART_MAIN | LV_STATE_DEFAULT);
    lv_obj_set_style_border_opa(depo[index].slider, 255, LV_PART_MAIN | LV_STATE_DEFAULT);
    lv_obj_set_style_border_width(depo[index].slider, 1, LV_PART_MAIN | LV_STATE_DEFAULT);
    lv_obj_set_style_border_side(depo[index].slider, LV_BORDER_SIDE_TOP, LV_PART_MAIN | LV_STATE_DEFAULT);

    lv_obj_set_style_bg_color(depo[index].slider, label_color, LV_PART_INDICATOR | LV_STATE_DEFAULT);
    lv_obj_set_style_bg_opa(depo[index].slider, 255, LV_PART_INDICATOR | LV_STATE_DEFAULT);
    lv_obj_set_style_bg_grad_color(depo[index].slider, lv_color_hex(0xFFFFFF), LV_PART_INDICATOR | LV_STATE_DEFAULT);

    lv_obj_set_style_bg_color(depo[index].slider, lv_color_hex(0xFFFFFF), LV_PART_KNOB | LV_STATE_DEFAULT);
    lv_obj_set_style_bg_opa(depo[index].slider, 0, LV_PART_KNOB | LV_STATE_DEFAULT);
    lv_obj_clear_flag(depo[index].slider, LV_OBJ_FLAG_CLICKABLE);

    depo[index].value_label = lv_label_create(depo[index].container);
    lv_obj_set_width(depo[index].value_label, LV_SIZE_CONTENT);
    lv_obj_set_height(depo[index].value_label, LV_SIZE_CONTENT);
    lv_obj_set_x(depo[index].value_label, 48);
    lv_obj_set_y(depo[index].value_label, -19);
    lv_obj_set_align(depo[index].value_label, LV_ALIGN_CENTER);
    lv_label_set_text(depo[index].value_label, value_text);  // Değer text'i parametreden alınıyor
    lv_obj_set_style_text_color(depo[index].value_label, lv_color_hex(0xB9B9B9), LV_PART_MAIN | LV_STATE_DEFAULT);
    lv_obj_set_style_text_opa(depo[index].value_label, 255, LV_PART_MAIN | LV_STATE_DEFAULT);
    lv_obj_set_style_text_font(depo[index].value_label, &lv_font_montserrat_24, LV_PART_MAIN | LV_STATE_DEFAULT);

}

void create_multiple_Kirlisu_depo(lv_obj_t *parent, int adet) {
    if(adet >= 2){
    adet = 2;
    }
    for (int i = 0; i <= adet; i++) {
        int x_offset = 270;
        int y_offset = -150 + (i * 70);
        int slider_value = (i + 1) * 10;
        char label_text[10];
        char value_text[10];
        
        sprintf(label_text, "Depo %d", i);
        sprintf(value_text, "%% %d", slider_value);
        
        create_su_depo(kirliSuDepo, parent, i, x_offset, y_offset, slider_value, label_text, value_text, lv_color_hex(0xFF0000));
    }
}

// Batarya hücresine dışarıdan değer atama örneği
void update_Kirlisu_depo(int index, int slider_value) {
    if (index < 0 || index >= MAX_CELLS_WAT) return;

    // Slider değeri ve etiket metnini güncelleme
    lv_slider_set_value(kirliSuDepo[index].slider, slider_value, LV_ANIM_OFF);
    char buffer[50]; // Gerekli boyutu ayarlayın
    sprintf(buffer, "%% %d", slider_value);
    lv_label_set_text(kirliSuDepo[index].value_label, buffer);

    // Tüm slider değerlerinin ortalamasını hesapla
    int sum = 0;
    int count = 0;
    for (int i = 0; i < MAX_CELLS_WAT; i++) {
        if (kirliSuDepo[i].slider) {  // Eğer slider mevcutsa
            sum += lv_slider_get_value(kirliSuDepo[i].slider);
            count++;
        }
    }

    // Ortalama hesaplama ve güncelleme
    if (count > 0) {
        int average = sum / count;
        updateKirliSuTotalArc(average, 202.15);  // Ortalama değeri fonksiyona gönder
    }
}