# Changelog

## 1.0.0 (2026-07-07)

- Android implementation via Godot v2 plugin (`GodotPlugin` / `ReviewManagerFactory`)
- iOS implementation via ObjC++ GDCLASS (`SKStoreReviewController requestReviewInScene:`)
- GDScript wrapper (`InGameReviewBridge`) with unsupported-platform fallback
- Export plugin for iOS (`in_game_review/apple_app_id`) and Android (AAR, review-ktx dependency)
- Signals: `review_flow_started`, `review_flow_finished`, `review_flow_failed`
- Methods: `is_available`, `get_platform`, `request_review`, `open_store_review_page`, `get_last_error`
