package io.github.engineer948.melody

import io.github.engineer948.melody.go.tsbridge.InterfaceSource
import io.github.engineer948.melody.go.tsbridge.Tsbridge
import java.io.File
import java.net.NetworkInterface

/** Thin wrapper over the Go library (native/tailscale). */
object TailscaleNode {
    const val available = true

    /** Crash report of the Go library, next to (not inside) its state. */
    fun crashFile(dir: String) = File(File(dir).parentFile, "tailscale-crash.txt")

    @Volatile private var interfacesSet = false

    /**
     * Android 11+ blocks Go from reading the network interfaces itself, so
     * they are listed here (see native/tailscale/interfaces.go).
     */
    private object Interfaces : InterfaceSource {
        /**
         * Must never throw: an exception here would reach native code with a
         * pending JNI exception and abort the whole app. Interfaces that
         * cannot be read (Android throws SocketException for some) are
         * skipped.
         */
        override fun list(): String = try {
            buildString {
                val all = NetworkInterface.getNetworkInterfaces() ?: return@buildString
                for (nif in all) {
                    val line = runCatching { describe(nif) }.getOrNull() ?: continue
                    append(line).append('\n')
                }
            }
        } catch (t: Throwable) {
            ""
        }

        private fun describe(nif: NetworkInterface): String? {
            val name = nif.name ?: return null
            if (name.contains('\t') || name.contains('\n')) return null
            val flags = buildString {
                if (runCatching { nif.isUp }.getOrDefault(false)) append('u')
                if (runCatching { nif.isLoopback }.getOrDefault(false)) append('l')
                if (runCatching { nif.isPointToPoint }.getOrDefault(false)) append('p')
                if (runCatching { nif.supportsMulticast() }.getOrDefault(false)) append('m')
            }
            val addrs = runCatching {
                nif.interfaceAddresses.mapNotNull { a ->
                    // IPv6 addresses carry a "%scope" suffix that Go's CIDR
                    // parser does not accept.
                    val host = a?.address?.hostAddress?.substringBefore('%')
                        ?: return@mapNotNull null
                    "$host/${a.networkPrefixLength}"
                }
            }.getOrDefault(emptyList())
            val mtu = runCatching { nif.mtu }.getOrDefault(1500)
            return "$name\t${nif.index}\t$mtu\t$flags\t${addrs.joinToString(",")}"
        }
    }

    fun start(
        dir: String,
        authKey: String,
        hostname: String,
        target: String,
        secret: String,
        port: Int,
        stateKey: String,
    ): Int {
        if (!interfacesSet) {
            // Fatal Go errors are written here and shown on the next start.
            Tsbridge.setCrashFile(crashFile(dir).absolutePath)
            Tsbridge.setInterfaceSource(Interfaces)
            interfacesSet = true
        }
        return Tsbridge.start(dir, authKey, hostname, target, secret, port.toLong(), stateKey).toInt()
    }

    fun status(): String = Tsbridge.status()

    fun stop() = Tsbridge.stop()

    fun logout(dir: String) = Tsbridge.logout(dir)
}
