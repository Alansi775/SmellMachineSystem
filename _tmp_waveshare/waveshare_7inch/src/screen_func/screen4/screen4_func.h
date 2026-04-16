#ifndef SCREEN4_FUNC_H
#define SCREEN4_FUNC_H

#include "lvgl.h"
#include <stdbool.h>

// Button yapısını burada tanımlayın
typedef struct Button {
    int id;
    char name[30];
    bool durum;
    char func[30];
};

#ifdef __cplusplus
extern "C" {
#endif

bool saveButtonToNVS(struct Button button); // struct ile belirtmek
int loadAllButtonsFromNVS(struct Button buttons[], int maxButtons); // struct ile belirtmek
void create_unique_buttons();
void create_input_panel(lv_obj_t * parent, const char * roller_options);
void displayDeleteConfirmationButton(int button_id, int x, int y);
void confirm_btn_event_handler(lv_event_t * e);
bool deleteButtonToNVS(int button_id);
static void mask_event_cb(lv_event_t * e);

extern const char *rol;
#ifdef __cplusplus
}
#endif

#endif // SCREEN4_FUNC_H
