package io.github.engineer948.melody

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.view.KeyEvent
import android.widget.RemoteViews

/**
 * Home screen widget: cover, title, artist and previous / play / next.
 *
 * What is playing is written to preferences by the Flutter side (see
 * MainActivity); the buttons send ordinary media button events, which the
 * playback service handles like headset buttons.
 */
class NowPlayingWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        manager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (id in appWidgetIds) {
            manager.updateAppWidget(id, render(context))
        }
    }

    companion object {
        const val PREFS = "melody_widget"
        private const val MEDIA_BUTTON_RECEIVER =
            "com.ryanheise.audioservice.MediaButtonReceiver"

        /** Redraws every placed widget. */
        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, NowPlayingWidget::class.java),
            )
            if (ids.isEmpty()) return
            val views = render(context)
            for (id in ids) {
                manager.updateAppWidget(id, views)
            }
        }

        private fun mediaButton(context: Context, keyCode: Int): PendingIntent {
            val intent = Intent(Intent.ACTION_MEDIA_BUTTON)
                .setComponent(ComponentName(context, MEDIA_BUTTON_RECEIVER))
                .putExtra(
                    Intent.EXTRA_KEY_EVENT,
                    KeyEvent(KeyEvent.ACTION_DOWN, keyCode),
                )
            return PendingIntent.getBroadcast(
                context,
                keyCode,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        private fun render(context: Context): RemoteViews {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val views = RemoteViews(context.packageName, R.layout.now_playing_widget)
            val title = prefs.getString("title", null)
            views.setTextViewText(
                R.id.widget_title,
                if (title.isNullOrEmpty()) context.getString(R.string.widget_idle) else title,
            )
            views.setTextViewText(R.id.widget_artist, prefs.getString("artist", "") ?: "")
            views.setImageViewResource(
                R.id.widget_play,
                if (prefs.getBoolean("playing", false)) {
                    R.drawable.ic_widget_pause
                } else {
                    R.drawable.ic_widget_play
                },
            )
            val cover = prefs.getString("cover", null)?.let {
                // Small on purpose: widgets may only carry little bitmap data.
                val options = BitmapFactory.Options().apply { inSampleSize = 2 }
                runCatching { BitmapFactory.decodeFile(it, options) }.getOrNull()
            }
            if (cover != null) {
                views.setImageViewBitmap(R.id.widget_cover, cover)
            } else {
                views.setImageViewResource(R.id.widget_cover, R.mipmap.ic_launcher)
            }

            views.setOnClickPendingIntent(
                R.id.widget_previous,
                mediaButton(context, KeyEvent.KEYCODE_MEDIA_PREVIOUS),
            )
            views.setOnClickPendingIntent(
                R.id.widget_play,
                mediaButton(context, KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE),
            )
            views.setOnClickPendingIntent(
                R.id.widget_next,
                mediaButton(context, KeyEvent.KEYCODE_MEDIA_NEXT),
            )
            val open = context.packageManager.getLaunchIntentForPackage(context.packageName)
            if (open != null) {
                views.setOnClickPendingIntent(
                    R.id.widget_root,
                    PendingIntent.getActivity(
                        context,
                        0,
                        open,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                    ),
                )
            }
            return views
        }
    }
}
