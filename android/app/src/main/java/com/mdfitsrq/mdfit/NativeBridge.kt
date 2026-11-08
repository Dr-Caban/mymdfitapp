package com.mdfitsrq.mdfit

import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.view.HapticFeedbackConstants
import android.webkit.JavascriptInterface
import android.webkit.WebView
import org.json.JSONObject

/** Receives `mdfitAndroid.postMessage(json)` from assets/bridge.js and runs the native side. */
class NativeBridge(private val activity: MainActivity, private val web: WebView) {
    private val main = Handler(Looper.getMainLooper())

    @JavascriptInterface
    fun postMessage(json: String) {
        val body = try { JSONObject(json) } catch (_: Exception) { return }
        main.post { handle(body) }
    }

    private fun handle(body: JSONObject) {
        // Only the member app itself may drive native features
        val host = web.url?.let { android.net.Uri.parse(it).host?.lowercase() }
        if (host !in MainActivity.SITE_HOSTS) return
        when (body.optString("action")) {
            "haptic" -> haptic(body.optString("style", "light"))
            "sound" -> Sounds.play(activity, body.optString("name"))
            "share" -> {
                val text = listOf(body.optString("title"), body.optString("text"), body.optString("url")).filter { it.isNotBlank() }.joinToString("\n")
                if (text.isNotBlank()) activity.startActivity(Intent.createChooser(Intent(Intent.ACTION_SEND).setType("text/plain").putExtra(Intent.EXTRA_TEXT, text), null))
            }
            "calendar" -> body.optString("ics").takeIf { it.isNotBlank() }?.let { CalendarAdder.present(activity, it) }
            "askNotifications" -> activity.requestNotificationPermission()
            "streak" -> Reminders.updateStreakReminder(activity, body.optBoolean("qualifying", true), body.optInt("remaining", 0), body.optInt("streak", 0))
            "open" -> body.optString("url").takeIf { it.startsWith("https://") }?.let {
                activity.startActivity(Intent(Intent.ACTION_VIEW, android.net.Uri.parse(it)))
            }
        }
    }

    private fun haptic(style: String) {
        val c = when (style) {
            "success", "warning", "error" -> HapticFeedbackConstants.CONFIRM
            "selection" -> HapticFeedbackConstants.CLOCK_TICK
            "medium", "heavy" -> HapticFeedbackConstants.LONG_PRESS
            else -> HapticFeedbackConstants.KEYBOARD_TAP
        }
        web.performHapticFeedback(c)
    }
}
