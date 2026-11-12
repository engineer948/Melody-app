package io.github.engineer948.melody

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

/**
 * "melody/tailscale": the Tailscale node built into the app.
 *
 * Every call runs on one background thread, in order. The node's files live
 * in noBackupFilesDir, which Android never backs up or transfers.
 */
object TailscaleChannel {
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    fun register(messenger: BinaryMessenger, context: Context) {
        val dir = File(context.noBackupFilesDir, "tailscale").absolutePath
        MethodChannel(messenger, "melody/tailscale").setMethodCallHandler { call, result ->
            fun run(body: () -> Any?) = worker.execute {
                val outcome = runCatching(body)
                main.post {
                    outcome.fold(
                        { result.success(it) },
                        { result.error("tailscale", it.message, null) },
                    )
                }
            }
            when (call.method) {
                "available" -> result.success(TailscaleNode.available)
                "start" -> run {
                    TailscaleNode.start(
                        dir = dir,
                        authKey = call.argument<String>("authKey") ?: "",
                        hostname = call.argument<String>("hostname")!!,
                        target = call.argument<String>("target")!!,
                        secret = call.argument<String>("secret")!!,
                        port = call.argument<Int>("port") ?: 0,
                        stateKey = call.argument<String>("stateKey")!!,
                    )
                }
                "status" -> run { TailscaleNode.status() }
                "stop" -> run { TailscaleNode.stop() }
                "logout" -> run { TailscaleNode.logout(dir) }
                else -> result.notImplemented()
            }
        }
    }
}
