# Repository Guidelines

## Project Structure & Module Organization

Repo is currently **docs-only** (pre-implementation). The single source of truth for plugin design is `docs/01_plugin_specification.md`. As code is built, organize by platform:

- `addons/in_game_review/` — Godot plugin entry point, `plugin.cfg`, GDScript wrapper, export plugin
- `android/` — Android Godot plugin (v2, Godot 4.2+), Gradle build, Play Core review integration
- `ios/` — iOS Godot plugin, Swift bridge, StoreKit integration
- `demo/` — minimal Godot project exercising `InGameReview`

Add new design notes as numbered files under `docs/`, e.g. `docs/02_android_notes.md`.

## Key Design Constraints (from spec)

- **No custom rating UI.** Never implement star ratings, sentiment gates (`"Do you like the game?"`), overlays, or incentivized reviews.
- **No analytics that infer rating value.** Native APIs do not expose rating content.
- **Singleton name:** `InGameReview` (access via `Engine.get_singleton("InGameReview")`).
- **All result dicts** use keys: `ok`, `platform`, `status`, `message`.
- **Error codes** are uppercase snake_case e.g. `PLAY_STORE_NOT_FOUND`, `NO_ACTIVE_SCENE`.
- **Unsupported platforms** (editor, desktop, web) must be safe no-ops returning `status: "unsupported"`.
- **`ok: true` from `request_review()`** means the request was *started*, not that the dialog appeared or a review was submitted. The system may suppress the prompt.
- Signals: `review_flow_started(platform)`, `review_flow_finished(platform, result)`, `review_flow_failed(platform, error)`.

## Build Commands (planned — files don't exist yet)

```
godot --editor demo/project.godot       # open example project
./gradlew assembleRelease                # build Android plugin
./gradlew lint                           # Android static checks
xcodebuild -project ios/InGameReview.xcodeproj -scheme InGameReview build
```

## Conventions

- 4-space indent in GDScript, Kotlin, Swift, Markdown.
- `snake_case` for methods (`request_review`), `PascalCase` for classes, `InGameReview` for singleton.
- Favor small bridge layers.
- Test scenes named by behavior: `test_request_review.gd`, `review_flow_demo.tscn`.
- Android internal test track is the recommended way to test the review flow.
