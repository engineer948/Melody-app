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
    /**
     * What is known about the previous run's crash: the Go report (if the
     * Go runtime wrote one) and this app's own recent error log lines
     * (apps may read their own log without any permission).
     */
    private fun crashReport(goReport: String?): String? {
        val log = runCatching {
            val process = ProcessBuilder("logcat", "-d", "-v", "time", "-t", "2000", "*:W")
                .redirectErrorStream(true)
                .start()
            val lines = process.inputStream.bufferedReader().readLines()
            process.waitFor()
            lines.filter { line ->
                KEYWORDS.any { line.contains(it, ignoreCase = true) }
            }.takeLast(80).joinToString("\n")
        }.getOrNull()
        val parts = listOfNotNull(
            goReport?.takeIf { it.isNotBlank() }?.let { "--- go ---\n$it" },
            log?.takeIf { it.isNotBlank() }?.let { "--- log ---\n$it" },
        )
        return parts.takeIf { it.isNotEmpty() }?.joinToString("\n")?.take(30_000)
    }

    private val KEYWORDS = listOf(
        "tailscale", "tsbridge", "gojni", "JNI", "AndroidRuntime", "FATAL",
        "Abort", "panic", "SIGSYS", "SIGSEGV", "SIGABRT", "go.Seq",
    )

    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    fun register(messenger: BinaryMessenger, context: Context) {
        val dir = File(context.noBackupFilesDir, "tailscale").absolutePath
        // A crash report left by the previous run (read without loading the
        // Go library), handed to Dart once and then deleted.
        val crashFile = TailscaleNode.crashFile(dir)
        var lastCrash: String? = runCatching {
            if (crashFile.exists()) crashFile.readText().take(16_000).also { crashFile.delete() } else null
        }.getOrNull()
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
                "lastCrash" -> {
                    val goReport = lastCrash
                    lastCrash = null
                    run { crashReport(goReport) }
                }
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
