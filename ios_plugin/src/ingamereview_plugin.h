#ifndef IN_GAME_REVIEW_PLUGIN_H
#define IN_GAME_REVIEW_PLUGIN_H

#include "core/object/object.h"
#include "core/object/class_db.h"
#include "core/string/ustring.h"
#include "core/variant/dictionary.h"

class InGameReviewPlugin : public Object {
    GDCLASS(InGameReviewPlugin, Object);

private:
    static InGameReviewPlugin *singleton;
    bool is_running = false;
    Dictionary last_error;

    static void _bind_methods();

public:
    static InGameReviewPlugin *get_singleton();

    InGameReviewPlugin();
    ~InGameReviewPlugin();

    bool is_available();
    String get_platform();
    Dictionary request_review();
    Dictionary open_store_review_page(const String &p_app_id);
    Dictionary get_last_error();

    void notify_flow_started();
    void notify_flow_finished(bool p_success, const String &p_message);
    void notify_flow_failed(const String &p_code, const String &p_message);
};

#endif
