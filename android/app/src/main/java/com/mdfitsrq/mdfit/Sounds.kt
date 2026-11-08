package com.mdfitsrq.mdfit

import android.content.Context
import android.media.AudioAttributes
import android.media.SoundPool

/** Short reward chimes (gem, badge, goal, xp, notify) from res/raw: game-style effects that mix with the member's music. */
object Sounds {
    private var pool: SoundPool? = null
    private val ids = HashMap<String, Int>()
    private val loaded = HashSet<Int>()
    private val names = mapOf("gem" to R.raw.gem, "badge" to R.raw.badge, "goal" to R.raw.goal, "xp" to R.raw.xp, "notify" to R.raw.notify)

    fun play(ctx: Context, name: String) {
        val res = names[name] ?: return
        val p = pool ?: SoundPool.Builder().setMaxStreams(3)
            .setAudioAttributes(AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_GAME).setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION).build())
            .build().also { sp ->
                pool = sp
                sp.setOnLoadCompleteListener { _, id, status -> if (status == 0) { loaded.add(id); sp.play(id, 0.9f, 0.9f, 1, 0, 1f) } }
            }
        val id = ids[name]
        if (id != null && id in loaded) p.play(id, 0.9f, 0.9f, 1, 0, 1f)
        else if (id == null) ids[name] = p.load(ctx, res, 1)   // plays once loaded (listener above)
    }
}
