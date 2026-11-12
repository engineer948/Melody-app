package io.github.engineer948.melody

import android.content.Context
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private val localMedia = LocalMedia(this)

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        if (!localMedia.onPermissionResult(requestCode, grantResults)) {
            super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "melody/local")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasPermission" -> result.success(localMedia.hasPermission())
                    "requestPermission" -> localMedia.requestPermission(result)
                    "scan" -> Thread {
                        val rows = runCatching { localMedia.scan() }
                        runOnUiThread {
                            rows.fold(
                                { result.success(it) },
                                { result.error("scan", it.message, null) },
                            )
                        }
                    }.start()
                    else -> result.notImplemented()
                }
            }
        // The engine outlives the activity (background playback), so the
        // handlers only keep the application context.
        val app = applicationContext
        TailscaleChannel.register(flutterEngine.dartExecutor.binaryMessenger, app)
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
