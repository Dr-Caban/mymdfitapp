package com.mdfitsrq.mdfit

import android.content.Context
import android.content.Intent
import android.provider.CalendarContract
import java.text.SimpleDateFormat
import java.util.Locale
import java.util.TimeZone

/** Turns the site's "Add to calendar" .ics into the system's Add Event screen (no calendar permission needed). */
object CalendarAdder {
    fun present(ctx: Context, ics: String) {
        val f = parse(ics)
        val start = f["DTSTART"]?.let(::date) ?: return
        val end = f["DTEND"]?.let(::date) ?: (start + 3600_000L)
        val intent = Intent(Intent.ACTION_INSERT).setData(CalendarContract.Events.CONTENT_URI)
            .putExtra(CalendarContract.EXTRA_EVENT_BEGIN_TIME, start)
            .putExtra(CalendarContract.EXTRA_EVENT_END_TIME, end)
            .putExtra(CalendarContract.Events.TITLE, f["SUMMARY"]?.let(::unescape) ?: "MD Fit")
            .putExtra(CalendarContract.Events.EVENT_LOCATION, f["LOCATION"]?.let(::unescape) ?: "")
            .putExtra(CalendarContract.Events.DESCRIPTION, f["DESCRIPTION"]?.let(::unescape) ?: "")
        try { ctx.startActivity(intent) } catch (_: Exception) {}
    }

    private fun parse(ics: String): Map<String, String> {
        val out = HashMap<String, String>()
        var inEvent = false
        for (raw in ics.replace("\r\n ", "").replace("\n ", "").lines()) {
            val line = raw.trim()
            if (line == "BEGIN:VEVENT") { inEvent = true; continue }
            if (line == "END:VEVENT") break
            if (!inEvent) continue
            val colon = line.indexOf(':'); if (colon < 0) continue
            val key = line.substring(0, colon).substringBefore(';').uppercase()
            if (key !in out) out[key] = line.substring(colon + 1)
        }
        return out
    }

    private fun date(v: String): Long? {
        val f = when {
            v.endsWith("Z") -> SimpleDateFormat("yyyyMMdd'T'HHmmss'Z'", Locale.US).apply { timeZone = TimeZone.getTimeZone("UTC") }
            v.length == 8 -> SimpleDateFormat("yyyyMMdd", Locale.US).apply { timeZone = TimeZone.getTimeZone("America/New_York") }
            else -> SimpleDateFormat("yyyyMMdd'T'HHmmss", Locale.US).apply { timeZone = TimeZone.getTimeZone("America/New_York") }
        }
        return try { f.parse(v)?.time } catch (_: Exception) { null }
    }

    private fun unescape(s: String) = s.replace("\\n", "\n").replace("\\N", "\n").replace("\\,", ",").replace("\\;", ";").replace("\\\\", "\\")
}
