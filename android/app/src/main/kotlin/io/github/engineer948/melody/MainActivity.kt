package io.github.engineer948.melody

import android.content.Context
import android.content.Intent
import android.os.Bundle
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private val localMedia = LocalMedia(this)
    private val places = Places(this)
    private val nfc = Nfc(this)
    private var nfcChannel: MethodChannel? = null

    // A song letter link the app was opened with (NFC sticker), given to
    // Flutter once.
    private var initialLink: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        initialLink = Nfc.linkOf(intent)
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        Nfc.linkOf(intent)?.let { nfcChannel?.invokeMethod("link", it) }
    }

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
        nfcChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "melody/nfc").also {
            it.setMethodCallHandler { call, result ->
                when (call.method) {
                    "state" -> result.success(nfc.state())
                    "write" -> {
                        val uri = call.arguments as? String
                        if (uri == null) result.error("args", "uri is required", null)
                        else nfc.write(uri, result)
                    }
                    "cancel" -> {
                        nfc.cancel()
                        result.success(null)
                    }
                    "initialLink" -> {
                        result.success(initialLink)
                        initialLink = null
                    }
                    else -> result.notImplemented()
                }
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
                val discPath = call.argument<String>("disc")
                val discRect = call.argument<List<Number>>("discRect")?.map { it.toDouble() }
                val disc = if (discPath != null && discRect?.size == 4) {
                    StoryVideo.Disc(
                        discPath,
                        discRect,
                        call.argument<List<Number>>("pulse")?.map { it.toDouble() } ?: emptyList(),
                    )
                } else {
                    null
                }
                // Encoding takes seconds: off the main thread.
                Thread {
                    val made = runCatching { StoryVideo.make(images, times, audio, out, disc) }
                    android.os.Handler(android.os.Looper.getMainLooper()).post {
                        made.fold(
                            { result.success(out) },
                            { result.error("video", it.message ?: it.toString(), null) },
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
