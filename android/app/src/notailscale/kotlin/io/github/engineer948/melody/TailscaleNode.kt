package io.github.engineer948.melody

/**
 * Stand-in used when the app is built without the Go library
 * (android/app/libs/tsbridge.aar missing); the feature is then hidden.
 */
object TailscaleNode {
    const val available = false

    fun crashFile(dir: String) = java.io.File(java.io.File(dir).parentFile, "tailscale-crash.txt")

    private fun missing(): Nothing =
        throw UnsupportedOperationException("built without Tailscale")

    @Suppress("UNUSED_PARAMETER")
    fun start(
        dir: String,
        authKey: String,
        hostname: String,
        target: String,
        secret: String,
        port: Int,
        stateKey: String,
    ): Int = missing()

    fun status(): String = """{"state":"stopped"}"""

    fun stop() {}

    @Suppress("UNUSED_PARAMETER")
    fun logout(dir: String) {}
}
