package io.github.engineer948.melody

import android.content.Context
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private val localMedia = LocalMedia(this)
    private val places = Places(this)

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        if (!localMedia.onPermissionResult(requestCode, grantResults) &&
            !places.onPermissionResult(requestCode, grantResults)
        ) {
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
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "melody/places")
            .setMethodCallHandler { call, result ->
                // Work that may wait (location fix, geocoder, thumbnails)
                // runs off the main thread.
                fun background(work: () -> Any?) = Thread {
                    val value = runCatching(work)
                    runOnUiThread {
                        value.fold(
                            { result.success(it) },
                            { result.error("places", it.message, null) },
                        )
                    }
                }.start()
                when (call.method) {
                    "hasLocation" -> result.success(places.hasLocation())
                    "requestLocation" -> places.requestLocation(result)
                    "hasPhotos" -> result.success(places.hasPhotos())
                    "requestPhotos" -> places.requestPhotos(result)
                    "location" -> background { places.location() }
                    "placeName" -> background {
                        places.placeName(
                            call.argument<Double>("latitude") ?: 0.0,
                            call.argument<Double>("longitude") ?: 0.0,
                            call.argument<String>("language") ?: "en",
                        )
                    }
                    "photos" -> background {
                        places.photos(
                            call.argument<Number>("from")?.toLong() ?: 0L,
                            call.argument<Number>("to")?.toLong() ?: 0L,
                            call.argument<Int>("limit") ?: 12,
                        )
                    }
                    "thumbnail" -> background {
                        places.thumbnail(
                            call.argument<Number>("id")?.toLong() ?: 0L,
                            call.argument<Int>("size") ?: 256,
                        )
                    }
                    else -> result.notImplemented()
                }
            }
        // The engine outlives the activity (background playback), so the
        // handlers only keep the application context.
        val app = applicationContext
        TailscaleChannel.register(flutterEngine.dartExecutor.binaryMessenger, app)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "melody/story_video")
            .setMethodCallHandler { call, result ->
                if (call.method != "make") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val images = call.argument<List<String>>("images")
                val times = call.argument<List<Number>>("times")?.map { it.toLong() }
                val audio = call.argument<String>("audio")
                val out = call.argument<String>("out")
                if (images == null || times == null || audio == null || out == null) {
                    result.error("args", "images, times, audio and out are required", null)
                    return@setMethodCallHandler
                }
                // Encoding takes seconds: off the main thread.
                Thread {
                    val made = runCatching { StoryVideo.make(images, times, audio, out) }
                    android.os.Handler(android.os.Looper.getMainLooper()).post {
                        made.fold(
                            { result.success(out) },
                            { result.error("video", it.message ?: it.toString(), null) },
                        )
                    }
                }.start()
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "melody/voice")
            .setMethodCallHandler { call, result ->
                if (call.method != "bands") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val path = call.argument<String>("path")
                if (path == null) {
                    result.error("args", "path is required", null)
                    return@setMethodCallHandler
                }
                val seconds = call.argument<Int>("seconds") ?: 60
                // Decoding takes a moment: off the main thread.
                Thread {
                    val bands = runCatching { VoiceBands.analyze(path, seconds) }
                    android.os.Handler(android.os.Looper.getMainLooper()).post {
                        bands.fold(
                            { result.success(it) },
                            { result.error("voice", it.message ?: it.toString(), null) },
                        )
                    }
                }.start()
            }
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
