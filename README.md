# InGameReview

Godot 4.5+ plugin for in-app review prompts via Google Play (Android) and Apple StoreKit (iOS).

**No custom rating UI.** This plugin only invokes the official platform review APIs — it never implements star ratings, sentiment gates, overlays, or incentivized reviews.

## Installation

1. Copy `addons/in_game_review/` into your project's `addons/` directory.
2. Enable the plugin in **Project → Project Settings → Plugins**.
3. The autoload `InGameReviewBridge` is registered automatically (the GDScript wrapper). Access the native singleton via `Engine.get_singleton("InGameReview")`.

### Android

- Build your project with **Gradle Build** enabled in the Android export preset.
- The export plugin declares `com.google.android.play:review-ktx:2.0.2` as a dependency — Gradle resolves it at export time.
- Requires Play Store on device (API level 21+).

### iOS

- Set the **in_game_review/apple_app_id** export option to your App Store ID.
- Minimum deployment target: **15.0**.
- Links `StoreKit.framework` and `UIKit.framework`.

## Usage

```gdscript
# Basic review request
var result = InGameReviewBridge.request_review()
if result.ok:
    print("Review flow started on ", result.platform)
else:
    print("Failed: ", result.message)

# Open store review page (manual fallback)
InGameReviewBridge.open_store_review_page("com.yourcompany.yourapp")

# Signal connection
InGameReviewBridge.review_flow_finished.connect(func(platform, r):
    print("Review flow finished on ", platform, ": ", r)
)

InGameReviewBridge.review_flow_failed.connect(func(platform, err):
    print("Review flow failed on ", platform, ": ", err)
)
```

`ok: true` from `request_review()` means the request was *started*, not that the dialog appeared or a review was submitted. The system decides whether to show the prompt (quotas, frequency, etc.).

## Signals

- `review_flow_started(platform: String)`
- `review_flow_finished(platform: String, result: Dictionary)`
- `review_flow_failed(platform: String, error: Dictionary)`

Result/error dictionaries use keys: `ok`, `platform`, `status`, `message`. Error codes are uppercase `snake_case`.

## Supported platforms

| Platform | Status |
|----------|--------|
| Android  | Supported (Play In-App Review API) |
| iOS      | Supported (StoreKit) |
| Editor   | No-op, returns `status: "unsupported"` |
| Desktop  | No-op, returns `status: "unsupported"` |
| Web      | No-op, returns `status: "unsupported"` |

## Testing

- **Android**: Use an internal test track — quota limits are not enforced, and the review dialog appears reliably.
- **iOS**: Use TestFlight or a production App Store build. The prompt does not appear in debug builds.

## Known limitations

- Native APIs do not reveal whether the prompt appeared or whether a review was submitted.
- Google Play and Apple may suppress prompts due to quotas, frequency, or other heuristics.
- Manual "Rate Game" buttons should use `open_store_review_page()` (external link) rather than `request_review()` to avoid quota issues on repeated calls.

## License

MIT — see [LICENSE](./LICENSE).
