package com.mdfitsrq.mdfit

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.media.AudioAttributes
import android.net.Uri

class MDfitApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        // One channel for everything (visits, messages, streak reminders), with the app's own chime
        val nm = getSystemService(NotificationManager::class.java)
        val channel = NotificationChannel(CHANNEL, getString(R.string.channel_name), NotificationManager.IMPORTANCE_HIGH).apply {
            description = getString(R.string.channel_desc)
            enableVibration(true)
            setSound(
                Uri.parse("android.resource://$packageName/${R.raw.notify}"),
                AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_NOTIFICATION).setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION).build()
            )
        }
        nm.createNotificationChannel(channel)
    }

    companion object { const val CHANNEL = "mdfit" }
}
