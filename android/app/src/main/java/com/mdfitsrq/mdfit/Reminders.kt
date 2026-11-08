package com.mdfitsrq.mdfit

import android.Manifest
import android.app.AlarmManager
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import java.util.Calendar

/** Local "keep your streak" reminder at 7 PM when today's goal isn't met yet; cancelled as soon as it is. */
object Reminders {
    private const val PREFS = "mdfit"
    private const val ASKED = "asked.notifications"
    private const val REQ = 7001

    fun askOnce(activity: MainActivity) {
        val p = activity.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (p.getBoolean(ASKED, false)) return
        p.edit().putBoolean(ASKED, true).apply()
        activity.requestNotificationPermission()
    }

    fun updateStreakReminder(ctx: Context, qualifying: Boolean, remaining: Int, streak: Int) {
        val am = ctx.getSystemService(AlarmManager::class.java)
        val pi = PendingIntent.getBroadcast(ctx, REQ, Intent(ctx, StreakReceiver::class.java), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        am.cancel(pi)
        if (qualifying) return
        val at = Calendar.getInstance().apply { set(Calendar.HOUR_OF_DAY, 19); set(Calendar.MINUTE, 0); set(Calendar.SECOND, 0) }
        if (at.timeInMillis <= System.currentTimeMillis()) return   // already past 7 PM
        val intent = Intent(ctx, StreakReceiver::class.java).putExtra("streak", streak).putExtra("remaining", remaining)
        val pi2 = PendingIntent.getBroadcast(ctx, REQ, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at.timeInMillis, pi2)
    }

    fun canNotify(ctx: Context) = Build.VERSION.SDK_INT < 33 ||
        ContextCompat.checkSelfPermission(ctx, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED

    fun show(ctx: Context, id: Int, title: String, body: String, route: String) {
        if (!canNotify(ctx)) return
        val open = Intent(ctx, MainActivity::class.java).putExtra("route", route).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        val pi = PendingIntent.getActivity(ctx, id, open, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val n = NotificationCompat.Builder(ctx, MDfitApplication.CHANNEL)
            .setSmallIcon(R.drawable.ic_notification).setColor(ContextCompat.getColor(ctx, R.color.mdfit_gold))
            .setContentTitle(title).setContentText(body).setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setAutoCancel(true).setContentIntent(pi).setPriority(NotificationCompat.PRIORITY_HIGH).build()
        ctx.getSystemService(NotificationManager::class.java).notify(id, n)
    }
}

class StreakReceiver : BroadcastReceiver() {
    override fun onReceive(ctx: Context, intent: Intent) {
        val streak = intent.getIntExtra("streak", 0)
        val remaining = intent.getIntExtra("remaining", 0)
        val title = if (streak > 0) "Keep your $streak-day streak going 🔥" else "Start a streak today"
        val body = when {
            streak > 0 && remaining > 0 -> "You're $remaining XP from today's goal. A quick workout or a few activities will do it."
            streak > 0 -> "Log today's workout or activities before midnight."
            else -> "A quick workout or a few daily activities hits today's goal."
        }
        Reminders.show(ctx, 7001, title, body, "home")
    }
}
