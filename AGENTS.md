# Repository Guidelines

Godot 4.5.1 plugin for in-app review via Google Play (Android) and StoreKit (iOS).

## Architecture

- **Two singletons**: `Engine.get_singleton("InGameReview")` is the native C++/Kotlin plugin; `InGameReviewBridge` (autoload `in_game_review.gd`) is the GDScript wrapper proxying to it.
- **Unsupported platforms** (editor, desktop, web): safe no-ops returning `status: "unsupported"`.
- **`ok: true` from `request_review()`** means request was *started*, not that dialog appeared.
- **Result dicts** use keys: `ok`, `platform`, `status`, `message`. Error codes are uppercase `snake_case`.
- **Signals**: `review_flow_started(platform)`, `review_flow_finished(platform, result)`, `review_flow_failed(platform, error)`.
- **No custom rating UI** or analytics that infer rating value.

## Current Status

- **iOS**: Implemented — ObjC++ via GDCLASS, `SKStoreReviewController requestReviewInScene:`, deployment target **15.0** (not 14.0). Registered as `"InGameReview"` singleton via `register_ingamereview_plugin()`/`unregister_ingamereview_plugin()` bootstrap.
- **Android**: Implemented — Kotlin via Godot v2 plugin, `ReviewManagerFactory.create()` / `requestReviewFlow()` / `launchReviewFlow()`, registered as `"InGameReview"` singleton via `GodotPlugin` base class. Source in `android_plugin/`, AAR goes in `addons/in_game_review/android/`.
- Missing per spec: `README.md`, `CHANGELOG.md`, `LICENSE`.

## iOS Plugin Build

Requires Xcode + Godot source headers:
```
export GODOT_HEADERS_DIR=/path/to/godot-4.5.1-stable
bash ios_plugin/build.sh
```
Output: `addons/in_game_review/ios/InGameReviewPlugin.xcframework/`. The `.gdip` sets `use_swift_runtime=false` (ObjC++ only), links `StoreKit.framework` + `UIKit.framework`.

## Android Plugin Build

Requires Android SDK + Java 17:
```
export ANDROID_HOME=/path/to/android-sdk
bash android_plugin/build.sh
```
Output: `addons/in_game_review/android/in_game_review-release.aar`. Export plugin's `_get_android_dependencies()` declares `com.google.android.play:review-ktx:2.0.2` for Gradle resolution at project export time.

## Export Plugin

`export_plugin.gd` supports iOS and Android — adds `in_game_review/apple_app_id` (String) for iOS export. For Android v2, uses `_get_android_libraries()`, `_get_android_dependencies()`, `_get_android_dependencies_maven_repos()`.

## Key Methods

- `request_review()` — starts native review flow (returns immediately with `ok: true`).
- `open_store_review_page(id)` — opens `market://details?id=<ID>` (fallback `https://play.google.com/store/apps/details?id=<ID>`) on Android; `https://apps.apple.com/app/id<ID>?action=write-review` on iOS.

## Conventions

- 4-space indent in GDScript, Kotlin, Swift, Markdown.
- `snake_case` methods, `PascalCase` classes.
- Android internal test track recommended for testing review flow (quota not enforced).
