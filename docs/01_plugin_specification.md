# Godot In-Game Review Plugin Specification
_For Android Google Play In-App Review and iOS App Store Review_

Version: 1.0  
Target project: Die Laughing  
Target engine: Godot 4.x, preferably Godot 4.5+ / 4.6+  
Audience: Implementation agent / developer building the plugin

---

## 1. Goal

Build a small, production-ready Godot plugin that exposes a single cross-platform API for requesting the official store review prompt:

- Android: Google Play In-App Review API.
- iOS: Apple StoreKit review prompt.
- Desktop/editor/unsupported platforms: safe no-op with a clear status result.

The plugin must **not** implement custom star rating UI. It must only invoke the official platform review flow or return a reason why it could not.

---

## 2. Important platform rules

### 2.1 Android

Use the official Google Play In-App Review API.

Relevant requirements and behavior:

- In-app reviews work on Android devices running Android 5.0 / API level 21 or higher with the Google Play Store installed.
- The app must use the Play Core review library.
- Google Play enforces quota limits. Calling the API does **not** guarantee that the review dialog appears.
- Do not ask the player pre-questions such as “Do you like the game?” or “Would you rate this 5 stars?” before showing the rating card.
- Do not modify, resize, overlay, obscure, or programmatically dismiss the review card.
- A manual “Rate Game” button should usually open the Play Store page instead of calling the in-app review API, because quota suppression may make the button appear broken.
- Internal test tracks are the recommended way to test the review flow. Quota limits are not enforced for internal test track testing.
- Internal app sharing can be used for rapid testing, but submitted reviews cannot be posted from that flow.

Primary references:

- Google Play In-App Reviews API: https://developer.android.com/guide/playcore/in-app-review
- Test in-app reviews: https://developer.android.com/guide/playcore/in-app-review/test
- Native Play In-App Review API reference: https://developer.android.com/reference/native/play/core/group/review
- Godot Android plugin documentation: https://docs.godotengine.org/en/stable/tutorials/platform/android/android_plugin.html

### 2.2 iOS

Use Apple StoreKit review prompt.

Relevant requirements and behavior:

- Use StoreKit to request a review prompt at a moment that makes sense in the app or game.
- The system decides whether the prompt is shown. The app must not assume the prompt appeared.
- Ask only after the player has shown meaningful engagement.
- Do not interrupt gameplay, combat, onboarding, purchasing, loading, or other important tasks.
- Avoid repeated/pestering review requests.
- Provide a manual fallback link to the App Store review page for “Rate Game” buttons.

Primary references:

- Requesting App Store reviews: https://developer.apple.com/documentation/storekit/requesting-app-store-reviews
- AppStore requestReview(in:): https://developer.apple.com/documentation/storekit/appstore/requestreview%28in%3A%29-1q8qs
- StoreKit SKStoreReviewController: https://developer.apple.com/documentation/storekit/skstorereviewcontroller
- Apple HIG Ratings and Reviews: https://developer.apple.com/design/human-interface-guidelines/ratings-and-reviews
- Godot iOS plugins: https://docs.godotengine.org/en/stable/tutorials/platform/ios/index.html

---

## 3. Plugin design principles

The plugin should be intentionally boring. No fireworks. No rating manipulation. No custom popup gremlins.

### 3.1 Responsibilities

The plugin is responsible for:

- Detecting whether native review functionality is available.
- Requesting the native review flow.
- Emitting completion/failure signals.
- Returning simple status codes.
- Opening the external store review page when explicitly requested.
- Never crashing on unsupported platforms.

The game is responsible for:

- Deciding **when** a review should be requested.
- Tracking cooldowns, run count, playtime, and version gating.
- Avoiding bad moments such as death frustration, tutorial, crashes, or ads.
- Deciding when to show separate “Send Feedback” UI.

### 3.2 Non-goals

Do not implement:

- Custom star rating UI.
- A “Do you like the game?” sentiment gate.
- Incentivized reviews.
- Review rewards.
- Any overlay around the native review card.
- Analytics events that infer what score the player gave. Native APIs do not expose rating content.

---

## 4. Public Godot API

Expose one singleton called:

```gdscript
InGameReview
```

The game should be able to call:

```gdscript
var review = Engine.get_singleton("InGameReview")
```

### 4.1 Methods

#### `is_available() -> bool`

Returns `true` when the current platform has a native in-app review implementation available.

Expected behavior:

- Android release build with Google Play support: `true`, if plugin is loaded.
- iOS build with StoreKit support: `true`, if plugin is loaded.
- Editor, Windows, Linux, macOS desktop, web: `false`.

#### `get_platform() -> String`

Returns one of:

```text
android
ios
unsupported
```

#### `request_review() -> Dictionary`

Attempts to request the native review prompt.

Return shape:

```gdscript
{
    "ok": true,
    "platform": "android",
    "status": "started",
    "message": "Review flow requested."
}
```

Possible status values:

```text
started
unavailable
already_running
failed
unsupported
```

Important: `ok: true` means the request was started. It does **not** mean the player saw the dialog or left a review.

#### `open_store_review_page(package_or_app_id: String) -> Dictionary`

Opens the external store review page.

Android examples:

```text
market://details?id=com.yourcompany.dielaughing
https://play.google.com/store/apps/details?id=com.yourcompany.dielaughing
```

iOS example:

```text
https://apps.apple.com/app/idYOUR_APP_ID?action=write-review
```

Expected behavior:

- Prefer native store URL scheme first.
- Fall back to HTTPS if the native scheme fails.
- Return `ok: true` if an external intent / URL open was requested.

#### `get_last_error() -> Dictionary`

Returns the last plugin-level error.

Example:

```gdscript
{
    "code": "PLAY_STORE_NOT_FOUND",
    "message": "Google Play Store is missing or not official."
}
```

### 4.2 Signals

The singleton should emit:

```gdscript
signal review_flow_started(platform: String)
signal review_flow_finished(platform: String, result: Dictionary)
signal review_flow_failed(platform: String, error: Dictionary)
```

Completion does not mean review submission. On Android, the native API may report completion even if the user dismissed the dialog or if quota suppressed the dialog.

---

## 5. Android implementation

### 5.1 Recommended approach

Use a Godot Android v2 plugin for Godot 4.2+.

Godot’s Android v2 plugin architecture uses an Android library / AAR dependency, Gradle, a custom manifest, and an init class extending `GodotPlugin`. Methods callable from GDScript must be annotated with `@UsedByGodot`.

Minimum expected plugin structure:

```text
addons/in_game_review/
  plugin.cfg
  export_plugin.gd
  android/
    in_game_review-release.aar
  in_game_review.gd
android_plugin/
  build.gradle.kts
  src/main/AndroidManifest.xml
  src/main/java/com/yourcompany/ingamereview/InGameReviewPlugin.kt
```

### 5.2 Android dependencies

Use the current Google Play review dependency. The exact latest version should be confirmed at implementation time from official Google Maven / Android docs.

Common Gradle dependency pattern:

```kotlin
dependencies {
    implementation("com.google.android.play:review-ktx:<latest-version>")
    implementation("org.godotengine:godot:<godot-version>")
}
```

The implementation agent must check the latest compatible `review` / `review-ktx` version before coding.

### 5.3 Kotlin implementation outline

Pseudo-code:

```kotlin
class InGameReviewPlugin(godot: Godot) : GodotPlugin(godot) {
    private var isRunning = false
    private var lastError: Map<String, String> = emptyMap()

    override fun getPluginName(): String = "InGameReview"

    @UsedByGodot
    fun is_available(): Boolean {
        return activity != null
    }

    @UsedByGodot
    fun get_platform(): String = "android"

    @UsedByGodot
    fun request_review(): Dictionary {
        val currentActivity = activity
        if (currentActivity == null) {
            return failure("unavailable", "NO_ACTIVITY", "Android activity is unavailable.")
        }

        if (isRunning) {
            return mapOf(
                "ok" to false,
                "platform" to "android",
                "status" to "already_running",
                "message" to "Review flow is already running."
            ).toGodotDictionary()
        }

        isRunning = true
        emitSignal("review_flow_started", "android")

        val manager = ReviewManagerFactory.create(currentActivity)
        val request = manager.requestReviewFlow()

        request.addOnCompleteListener { task ->
            if (task.isSuccessful) {
                val reviewInfo = task.result
                val flow = manager.launchReviewFlow(currentActivity, reviewInfo)

                flow.addOnCompleteListener {
                    isRunning = false
                    emitSignal(
                        "review_flow_finished",
                        "android",
                        mapOf(
                            "ok" to true,
                            "platform" to "android",
                            "status" to "finished",
                            "message" to "Review flow finished or was dismissed/suppressed."
                        ).toGodotDictionary()
                    )
                }
            } else {
                isRunning = false
                val error = mapOf(
                    "code" to "REQUEST_REVIEW_FLOW_FAILED",
                    "message" to (task.exception?.message ?: "requestReviewFlow failed.")
                )
                lastError = error
                emitSignal("review_flow_failed", "android", error.toGodotDictionary())
            }
        }

        return mapOf(
            "ok" to true,
            "platform" to "android",
            "status" to "started",
            "message" to "Review flow requested."
        ).toGodotDictionary()
    }

    @UsedByGodot
    fun open_store_review_page(packageName: String): Dictionary {
        // Try market://details?id=<packageName>
        // Fall back to https://play.google.com/store/apps/details?id=<packageName>
    }

    @UsedByGodot
    fun get_last_error(): Dictionary {
        return lastError.toGodotDictionary()
    }
}
```

The actual code must use valid Godot Android plugin APIs for signal emission and Dictionary conversion for the targeted Godot version.

### 5.4 Android edge cases

Handle:

- Activity is null.
- Plugin called from unsupported build variant.
- Play Store missing.
- Play services / Play Store invalid.
- Review flow already running.
- `requestReviewFlow` failure.
- `launchReviewFlow` failure or completion.
- Quota suppression, which is not an error and may not be distinguishable.

### 5.5 Android testing checklist

Test with:

- Internal test track.
- Internal app sharing, understanding that review submission is disabled.
- Device with the app installed from Google Play.
- Device with multiple Google accounts.
- Device where the tester already reviewed the app.
- Device without Play Store if possible.
- Fresh install and update install.
- Repeated calls within a short time window.

Expected result:

- The plugin never crashes.
- `request_review()` returns immediately with a clear status.
- Signals fire once per request.
- Quota suppression is treated as normal completion, not a failure.

---

## 6. iOS implementation

### 6.1 Recommended approach

Create a Godot iOS plugin that exposes the same singleton name:

```text
InGameReview
```

Use StoreKit.

For modern iOS versions, prefer the current Apple-recommended review request API. For compatibility, the implementation can use `SKStoreReviewController.requestReview(in:)` when a valid foreground `UIWindowScene` is available.

### 6.2 Minimum plugin structure

Expected exported addon shape:

```text
addons/in_game_review/
  plugin.cfg
  export_plugin.gd
  ios/
    InGameReview.gdip
    InGameReview.xcframework or static library
  in_game_review.gd
ios_plugin/
  InGameReviewPlugin.swift
  InGameReviewPlugin.h / bridge files if needed
```

The exact Godot iOS plugin packaging should follow the current Godot iOS plugin documentation and the project’s existing iOS export setup.

### 6.3 Swift implementation outline

Pseudo-code:

```swift
import StoreKit
import UIKit

@objc(InGameReviewPlugin)
class InGameReviewPlugin: NSObject {
    @objc func is_available() -> Bool {
        return true
    }

    @objc func get_platform() -> String {
        return "ios"
    }

    @objc func request_review() -> Dictionary {
        DispatchQueue.main.async {
            if let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                SKStoreReviewController.requestReview(in: scene)
                // Emit finished signal. Apple does not tell us whether UI appeared.
            } else {
                // Emit failed signal: NO_ACTIVE_SCENE
            }
        }

        return [
            "ok": true,
            "platform": "ios",
            "status": "started",
            "message": "Review request sent to StoreKit."
        ]
    }

    @objc func open_store_review_page(_ appId: String) -> Dictionary {
        // Open https://apps.apple.com/app/id<APP_ID>?action=write-review
    }

    @objc func get_last_error() -> Dictionary {
        // Return last stored error.
    }
}
```

The implementation agent must adapt this outline to Godot’s iOS plugin bridge requirements.

### 6.4 iOS edge cases

Handle:

- No active foreground scene.
- App running in unsupported environment.
- App Store URL cannot be opened.
- Review prompt suppressed by the system.
- Repeated calls.
- Game paused/resumed around the prompt.

### 6.5 iOS testing checklist

Test with:

- Real iOS device.
- TestFlight build.
- App Store build if available.
- Repeated prompt requests.
- Prompt call during paused gameplay.
- Prompt call from post-run screen.
- Manual App Store review page link.

Expected result:

- The plugin never crashes.
- The game remains stable if the prompt is suppressed.
- The plugin does not claim that a review was submitted.
- The external review link opens correctly.

---

## 7. GDScript wrapper

Provide a wrapper script for clean use from the game.

`addons/in_game_review/in_game_review.gd`:

```gdscript
class_name InGameReviewBridge
extends Node

signal review_flow_started(platform: String)
signal review_flow_finished(platform: String, result: Dictionary)
signal review_flow_failed(platform: String, error: Dictionary)

var _native := null

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
```

---

## 8. Editor behavior

In editor/desktop builds, calls should be harmless.

Recommended desktop/editor return:

```gdscript
{
    "ok": false,
    "platform": "unsupported",
    "status": "unsupported",
    "message": "Native in-game review is only available on Android and iOS export builds."
}
```

Do not spam logs every frame. Log once per request at most.

---

## 9. Acceptance criteria

The plugin is done when:

- Godot can detect `Engine.has_singleton("InGameReview")` on Android/iOS builds.
- Android request flow calls Google Play In-App Review API.
- iOS request flow calls StoreKit review request.
- Unsupported platforms safely return `unsupported`.
- The plugin exposes all required methods.
- The plugin emits all required signals.
- Manual external store review page opening works.
- No custom rating UI exists.
- No code attempts to determine the rating value or review text.
- Sample Godot scene demonstrates:
  - availability check,
  - request review,
  - open store page,
  - signal handling,
  - unsupported fallback.

---

## 10. Deliverables

The implementation agent should deliver:

```text
addons/in_game_review/
android_plugin/ or android source project
ios_plugin/ or ios source project
sample/
README.md
CHANGELOG.md
LICENSE
```

`README.md` must include:

- Installation steps for Godot.
- Android export requirements.
- iOS export requirements.
- GDScript usage sample.
- Store policy notes.
- Testing instructions.
- Known limitations.

---

## 11. Known limitations to document

- Native APIs do not reveal whether the prompt appeared.
- Native APIs do not reveal whether a rating or review was submitted.
- Google Play and Apple may suppress prompts.
- Quotas are controlled by the platform and can change.
- Manual “Rate Game” buttons should use external store links.
- Testing behavior differs between internal, TestFlight, local, and production builds.

---

## 12. Recommended implementation order

1. Build the GDScript wrapper and unsupported-platform stub.
2. Implement Android plugin.
3. Add Android sample scene.
4. Test through internal test track.
5. Implement iOS plugin.
6. Add iOS sample scene.
7. Add manual store link opening.
8. Add README and troubleshooting.
9. Package addon.
10. Integrate into Die Laughing using the separate game integration document.

---

## 13. Questions the agent must resolve before coding

- Exact Godot version used by the project.
- Android package name for Die Laughing.
- iOS App Store ID for Die Laughing.
- Whether the project already uses custom Android Gradle builds.
- Whether the iOS export pipeline already includes native plugins.
- Final plugin namespace and author metadata.
- Whether analytics events are available for non-sensitive status tracking.

