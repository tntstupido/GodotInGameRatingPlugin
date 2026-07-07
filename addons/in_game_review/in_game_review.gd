class_name InGameReviewBridge
extends Node

signal review_flow_started(platform: String)
signal review_flow_finished(platform: String, result: Dictionary)
signal review_flow_failed(platform: String, error: Dictionary)

var _native: Variant = null


func _ready() -> void:
    if Engine.has_singleton("InGameReview"):
        _native = Engine.get_singleton("InGameReview")
        if _native.has_signal("review_flow_started"):
            _native.review_flow_started.connect(_on_review_flow_started)
        if _native.has_signal("review_flow_finished"):
            _native.review_flow_finished.connect(_on_review_flow_finished)
        if _native.has_signal("review_flow_failed"):
            _native.review_flow_failed.connect(_on_review_flow_failed)


func is_available() -> bool:
    return _native != null and _native.is_available()


func get_platform() -> String:
    if _native == null:
        return "unsupported"
    return _native.get_platform()


func request_review() -> Dictionary:
    if _native == null:
        return {
            "ok": false,
            "platform": "unsupported",
            "status": "unsupported",
            "message": "InGameReview native plugin is not available."
        }
    return _native.request_review()


func open_store_review_page(id: String) -> Dictionary:
    if _native != null:
        return _native.open_store_review_page(id)

    return {
        "ok": false,
        "platform": "unsupported",
        "status": "unsupported",
        "message": "No native plugin available."
    }


func get_last_error() -> Dictionary:
    if _native == null:
        return {}
    return _native.get_last_error()


func _on_review_flow_started(platform: String) -> void:
    review_flow_started.emit(platform)


func _on_review_flow_finished(platform: String, result: Dictionary) -> void:
    review_flow_finished.emit(platform, result)


func _on_review_flow_failed(platform: String, error: Dictionary) -> void:
    review_flow_failed.emit(platform, error)
