package com.mdfitsrq.mdfit

import android.content.Context
import com.google.firebase.FirebaseApp
import com.google.firebase.messaging.FirebaseMessaging
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

/** Firebase Cloud Messaging: the server sends visits, messages and admin alerts here (see backend lib/push.js). */
object Push {
    @Volatile var lastToken: String? = null
    private var activity: MainActivity? = null

    fun refreshToken(a: MainActivity) {
        activity = a
        if (!BuildConfig.HAS_FIREBASE || FirebaseApp.getApps(a).isEmpty()) return
        try {
            FirebaseMessaging.getInstance().token.addOnSuccessListener { t -> lastToken = t; activity?.deliverDeviceToken(t) }
        } catch (_: Exception) {}
    }
}

class PushService : FirebaseMessagingService() {
    override fun onNewToken(token: String) { Push.lastToken = token }

    // Data-only messages from the server are shown here, so the tap opens the right tab even in the foreground
    override fun onMessageReceived(message: RemoteMessage) {
        val d = message.data
        val title = message.notification?.title ?: d["title"] ?: "MD Fit"
        val body = message.notification?.body ?: d["body"] ?: ""
        val route = d["route"] ?: "home"
        Reminders.show(applicationContext, (d["collapse"] ?: route).hashCode(), title, body, route)   // the channel plays the chime
    }
}
