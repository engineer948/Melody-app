package io.github.engineer948.melody

import android.content.Context
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // The engine outlives the activity (background playback), so the
        // handler only keeps the application context.
        val app = applicationContext
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "melody/widget")
            .setMethodCallHandler { call, result ->
                if (call.method == "update") {
                    app.getSharedPreferences(NowPlayingWidget.PREFS, Context.MODE_PRIVATE)
                        .edit()
                        .putString("title", call.argument<String>("title"))
                        .putString("artist", call.argument<String>("artist"))
                        .putString("cover", call.argument<String>("cover"))
                        .putBoolean("playing", call.argument<Boolean>("playing") ?: false)
                        .apply()
                    NowPlayingWidget.updateAll(app)
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }
}
