#import "ingamereview_plugin.h"
#import "ingamereview_plugin_bootstrap.h"

#include "core/config/engine.h"

static InGameReviewPlugin *plugin = nullptr;

void register_ingamereview_plugin() {
    plugin = memnew(InGameReviewPlugin);
    Engine::get_singleton()->add_singleton(Engine::Singleton("InGameReview", plugin));
}

void unregister_ingamereview_plugin() {
    if (plugin != nullptr) {
        memdelete(plugin);
        plugin = nullptr;
    }
}
