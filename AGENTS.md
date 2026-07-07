# Repository Guidelines

## Project Structure & Module Organization

Repo is a **Godot 4.5.1** plugin providing in-app review via Google Play (Android) and StoreKit (iOS).

```
addons/in_game_review/
  plugin.cfg                   # Addon metadata
  export_plugin.gd             # EditorExportPlugin (iOS export)
  in_game_review.gd            # GDScript wrapper / autoload
  ios/
    InGameReview.gdip          # iOS plugin descriptor
    InGameReviewPlugin.xcframework/  # Built iOS binary (device + simulator)
ios_plugin/
  src/
    ingamereview_plugin.h      # C++ Godot Object header
    ingamereview_plugin.mm     # ObjC++ impl (StoreKit calls)
    ingamereview_plugin_bootstrap.h/mm  # Singleton registration
  build.sh                     # Build script for xcframework
demo/
  project.godot                # Demo project pointing at addon
  demo.tscn / demo.gd          # Test scene with UI
docs/
  01_plugin_specification.md   # Design spec (single source of truth)
```

## Key Design Constraints (from spec)

- **No custom rating UI.** Never implement star ratings, sentiment gates, overlays, or incentivized reviews.
- **No analytics that infer rating value.** Native APIs do not expose rating content.
- **Singleton name:** `InGameReview` (access via `Engine.get_singleton("InGameReview")`).
- **All result dicts** use keys: `ok`, `platform`, `status`, `message`.
- **Error codes** are uppercase snake_case e.g. `NO_ACTIVE_SCENE`.
- **Unsupported platforms** (editor, desktop, web) must be safe no-ops returning `status: "unsupported"`.
- **`ok: true` from `request_review()`** means the request was *started*, not that the dialog appeared or a review was submitted.
- Signals: `review_flow_started(platform)`, `review_flow_finished(platform, result)`, `review_flow_failed(platform, error)`.

## iOS Plugin Build

Requires Godot source headers (point `GODOT_HEADERS_DIR` to a Godot source checkout):

```
export GODOT_HEADERS_DIR=/path/to/godot-4.5.1-stable
bash ios_plugin/build.sh
```

Output goes to `addons/in_game_review/ios/InGameReviewPlugin.xcframework`. The script compiles for both device (`ios-arm64`) and simulator (`ios-arm64-simulator`) and produces a valid `.xcframework`.

The C++ plugin class (`ingamereview_plugin.h/.mm`) extends `Object` via `GDCLASS`, uses `_bind_methods()` to register methods and signals, and calls StoreKit directly from `.mm` (ObjC++). Bootstrap functions (`register_ingamereview_plugin` / `unregister_ingamereview_plugin`) are declared in the `.gdip` file.

## Conventions

- 4-space indent in GDScript, Kotlin, Swift, Markdown.
- `snake_case` for methods (`request_review`), `PascalCase` for classes, `InGameReview` for singleton.
- Test scenes named by behavior: `test_request_review.gd`, `review_flow_demo.tscn`.
- Android internal test track is the recommended way to test the review flow.
- iOS plugin uses `@available(iOS 14.0, *)` for `SKStoreReviewController` — not `requestReview()` without scene.
