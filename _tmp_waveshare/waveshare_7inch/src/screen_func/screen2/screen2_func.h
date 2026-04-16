#ifndef SCREEN2_FUNC_H
#define SCREEN2_FUNC_H

#include "lvgl.h"
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    lv_obj_t *container;
    lv_obj_t *slider;
    lv_obj_t *value_label;
} Depo;

#define MAX_CELLS_WAT 3
extern Depo temizSuDepo[MAX_CELLS_WAT]; 
extern Depo kirliSuDepo[MAX_CELLS_WAT]; 

extern lv_obj_t *ui_temizsudeger;
extern lv_obj_t *ui_temizSuArc;
extern lv_obj_t *ui_temizSuMiktar;

void create_su_depo(Depo temizSuDepo[MAX_CELLS_WAT], lv_obj_t *parent, int index, int x_offset, int y_offset, int slider_value, const char *label_text, const char *value_text, lv_color_t label_color);
void create_multiple_temizsu_depo(lv_obj_t *parent, int adet);
void update_temizsu_depo(int index, int slider_value);

extern lv_obj_t *ui_kirliSuDeger;
extern lv_obj_t *ui_kirliSuArc;
extern lv_obj_t *ui_kirliSuMiktar;

void updateKirliSuTotalArc(int kirliSuArcValue, double kirliSuTotalValues);
void create_multiple_Kirlisu_depo(lv_obj_t *parent, int adet);
void update_Kirlisu_depo(int index, int slider_value);

#ifdef __cplusplus
}
#endif

#endif // SCREEN2_FUNC_H
