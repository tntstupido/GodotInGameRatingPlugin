extends Control

@onready var status_label: Label = $StatusLabel
@onready var request_button: Button = $RequestButton
@onready var store_button: Button = $StoreButton
@onready var availability_label: Label = $AvailabilityLabel


func _ready() -> void:
    InGameReviewBridge.review_flow_started.connect(_on_review_flow_started)
    InGameReviewBridge.review_flow_finished.connect(_on_review_flow_finished)
    InGameReviewBridge.review_flow_failed.connect(_on_review_flow_failed)

    _update_availability()


func _update_availability() -> void:
    if InGameReviewBridge.is_available():
        availability_label.text = "InGameReview: available (%s)" % InGameReviewBridge.get_platform()
    else:
        availability_label.text = "InGameReview: not available (%s)" % InGameReviewBridge.get_platform()


func _on_request_button_pressed() -> void:
    var result = InGameReviewBridge.request_review()
    status_label.text = "request_review() -> %s" % JSON.stringify(result)


func _on_store_button_pressed() -> void:
    var result = InGameReviewBridge.open_store_review_page("%APP_ID%")
    status_label.text = "open_store_review_page() -> %s" % JSON.stringify(result)


func _on_review_flow_started(platform: String) -> void:
    print("Signal: review_flow_started(%s)" % platform)


func _on_review_flow_finished(platform: String, result: Dictionary) -> void:
    print("Signal: review_flow_finished(%s, %s)" % [platform, JSON.stringify(result)])


func _on_review_flow_failed(platform: String, error: Dictionary) -> void:
    print("Signal: review_flow_failed(%s, %s)" % [platform, JSON.stringify(error)])
