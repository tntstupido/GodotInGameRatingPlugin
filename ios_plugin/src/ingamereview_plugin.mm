#import "ingamereview_plugin.h"
#import <StoreKit/StoreKit.h>
#import <UIKit/UIKit.h>

InGameReviewPlugin *InGameReviewPlugin::singleton = nullptr;

InGameReviewPlugin *InGameReviewPlugin::get_singleton() {
    return singleton;
}

InGameReviewPlugin::InGameReviewPlugin() {
    singleton = this;
}

InGameReviewPlugin::~InGameReviewPlugin() {
    singleton = nullptr;
}

void InGameReviewPlugin::_bind_methods() {
    ClassDB::bind_method(D_METHOD("is_available"), &InGameReviewPlugin::is_available);
    ClassDB::bind_method(D_METHOD("get_platform"), &InGameReviewPlugin::get_platform);
    ClassDB::bind_method(D_METHOD("request_review"), &InGameReviewPlugin::request_review);
    ClassDB::bind_method(D_METHOD("open_store_review_page", "app_id"), &InGameReviewPlugin::open_store_review_page);
    ClassDB::bind_method(D_METHOD("get_last_error"), &InGameReviewPlugin::get_last_error);

    ADD_SIGNAL(MethodInfo("review_flow_started", PropertyInfo(Variant::STRING, "platform")));
    ADD_SIGNAL(MethodInfo("review_flow_finished", PropertyInfo(Variant::STRING, "platform"), PropertyInfo(Variant::DICTIONARY, "result")));
    ADD_SIGNAL(MethodInfo("review_flow_failed", PropertyInfo(Variant::STRING, "platform"), PropertyInfo(Variant::DICTIONARY, "error")));
}

bool InGameReviewPlugin::is_available() {
    return true;
}

String InGameReviewPlugin::get_platform() {
    return "ios";
}

Dictionary InGameReviewPlugin::request_review() {
    if (is_running) {
        Dictionary ret;
        ret["ok"] = false;
        ret["platform"] = "ios";
        ret["status"] = "already_running";
        ret["message"] = "Review flow is already running.";
        return ret;
    }

    is_running = true;
    emit_signal("review_flow_started", "ios");

    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindowScene *scene = nil;
        for (UIScene *connected in [UIApplication sharedApplication].connectedScenes) {
            if (connected.activationState == UISceneActivationStateForegroundActive) {
                scene = (UIWindowScene *)connected;
                break;
            }
        }

        if (scene) {
            [SKStoreReviewController requestReviewInScene:scene];
        }

        is_running = false;
        Dictionary result;
        result["ok"] = true;
        result["platform"] = "ios";
        result["status"] = "finished";
        if (scene) {
            result["message"] = "Review flow finished or was suppressed by the system.";
        } else {
            result["message"] = "No active foreground scene found.";
        }
        emit_signal("review_flow_finished", "ios", result);
    });

    Dictionary ret;
    ret["ok"] = true;
    ret["platform"] = "ios";
    ret["status"] = "started";
    ret["message"] = "Review request sent to StoreKit.";
    return ret;
}

Dictionary InGameReviewPlugin::open_store_review_page(const String &p_app_id) {
    String url_str = "https://apps.apple.com/app/id" + p_app_id + "?action=write-review";
    NSString *ns_url = [NSString stringWithUTF8String:url_str.utf8().get_data()];
    NSURL *url = [NSURL URLWithString:ns_url];

    if (!url) {
        Dictionary ret;
        ret["ok"] = false;
        ret["platform"] = "ios";
        ret["status"] = "failed";
        ret["message"] = "Failed to construct store URL.";
        return ret;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [UIApplication.sharedApplication openURL:url options:@{} completionHandler:nil];
    });

    Dictionary ret;
    ret["ok"] = true;
    ret["platform"] = "ios";
    ret["status"] = "started";
    ret["message"] = "Store review page URL opened.";
    return ret;
}

Dictionary InGameReviewPlugin::get_last_error() {
    return last_error;
}

void InGameReviewPlugin::notify_flow_started() {
    emit_signal("review_flow_started", "ios");
}

void InGameReviewPlugin::notify_flow_finished(bool p_success, const String &p_message) {
    is_running = false;
    Dictionary result;
    result["ok"] = p_success;
    result["platform"] = "ios";
    result["status"] = p_success ? "finished" : "failed";
    result["message"] = p_message;
    emit_signal("review_flow_finished", "ios", result);
}

void InGameReviewPlugin::notify_flow_failed(const String &p_code, const String &p_message) {
    is_running = false;
    Dictionary error;
    error["code"] = p_code;
    error["message"] = p_message;
    last_error = error;
    emit_signal("review_flow_failed", "ios", error);
}
