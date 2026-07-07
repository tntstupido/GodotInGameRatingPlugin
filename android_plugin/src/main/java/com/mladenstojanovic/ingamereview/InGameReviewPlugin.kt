package com.mladenstojanovic.ingamereview

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import com.google.android.play.core.review.ReviewManagerFactory
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.SignalInfo
import org.godotengine.godot.plugin.UsedByGodot

class InGameReviewPlugin(godot: Godot) : GodotPlugin(godot) {

    private var isRunning = false
    private var lastErrorCode: String = ""
    private var lastErrorMessage: String = ""

    override fun getPluginName(): String = "InGameReview"

    override fun getPluginSignals(): MutableSet<SignalInfo> {
        return mutableSetOf(
            SignalInfo("review_flow_started", String::class.java),
            SignalInfo("review_flow_finished", String::class.java, Map::class.java),
            SignalInfo("review_flow_failed", String::class.java, Map::class.java)
        )
    }

    @UsedByGodot
    fun is_available(): Boolean {
        return activity != null
    }

    @UsedByGodot
    fun get_platform(): String = "android"

    @UsedByGodot
    fun request_review(): Map<String, Any> {
        val currentActivity = activity
        if (currentActivity == null) {
            return errorMap("unavailable", "NO_ACTIVITY", "Android activity is unavailable.")
        }

        if (isRunning) {
            return mapOf(
                "ok" to false,
                "platform" to "android",
                "status" to "already_running",
                "message" to "Review flow is already running."
            )
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
                        )
                    )
                }
            } else {
                isRunning = false
                lastErrorCode = "REQUEST_REVIEW_FLOW_FAILED"
                lastErrorMessage = task.exception?.message ?: "requestReviewFlow failed."
                emitSignal(
                    "review_flow_failed",
                    "android",
                    mapOf("code" to lastErrorCode, "message" to lastErrorMessage)
                )
            }
        }

        return mapOf(
            "ok" to true,
            "platform" to "android",
            "status" to "started",
            "message" to "Review flow requested."
        )
    }

    @UsedByGodot
    fun open_store_review_page(packageName: String): Map<String, Any> {
        val currentActivity = activity
        if (currentActivity == null) {
            return errorMap("unavailable", "NO_ACTIVITY", "Android activity is unavailable.")
        }

        try {
            val marketIntent = Intent(Intent.ACTION_VIEW, Uri.parse("market://details?id=$packageName"))
            marketIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            currentActivity.startActivity(marketIntent)
            return mapOf(
                "ok" to true,
                "platform" to "android",
                "status" to "started",
                "message" to "Market page opened."
            )
        } catch (_: ActivityNotFoundException) {
        }

        return try {
            val webIntent = Intent(
                Intent.ACTION_VIEW,
                Uri.parse("https://play.google.com/store/apps/details?id=$packageName")
            )
            webIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            currentActivity.startActivity(webIntent)
            mapOf(
                "ok" to true,
                "platform" to "android",
                "status" to "started",
                "message" to "Play Store page opened."
            )
        } catch (_: ActivityNotFoundException) {
            errorMap("failed", "NO_BROWSER", "No browser found to open the Play Store page.")
        }
    }

    @UsedByGodot
    fun get_last_error(): Map<String, Any> {
        return mapOf("code" to lastErrorCode, "message" to lastErrorMessage)
    }

    private fun errorMap(status: String, code: String, message: String): Map<String, Any> {
        return mapOf(
            "ok" to false,
            "platform" to "android",
            "status" to status,
            "message" to message
        )
    }
}
