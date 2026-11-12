package io.github.engineer948.melody

import io.github.engineer948.melody.go.tsbridge.InterfaceSource
import io.github.engineer948.melody.go.tsbridge.Tsbridge
import java.net.NetworkInterface

/** Thin wrapper over the Go library (native/tailscale). */
object TailscaleNode {
    const val available = true

    @Volatile private var interfacesSet = false

    /**
     * Android 11+ blocks Go from reading the network interfaces itself, so
     * they are listed here (see native/tailscale/interfaces.go).
     */
    private object Interfaces : InterfaceSource {
        override fun list(): String = buildString {
            val all = NetworkInterface.getNetworkInterfaces() ?: return@buildString
            for (nif in all) {
                val flags = buildString {
                    if (nif.isUp) append('u')
                    if (nif.isLoopback) append('l')
                    if (nif.isPointToPoint) append('p')
                    if (nif.supportsMulticast()) append('m')
                }
                val addrs = nif.interfaceAddresses.mapNotNull { a ->
                    // IPv6 addresses carry a "%scope" suffix that Go's
                    // CIDR parser does not accept.
                    val host = a.address?.hostAddress?.substringBefore('%')
                        ?: return@mapNotNull null
                    "$host/${a.networkPrefixLength}"
                }
                append(nif.name).append('\t')
                    .append(nif.index).append('\t')
                    .append(runCatching { nif.mtu }.getOrDefault(1500)).append('\t')
                    .append(flags).append('\t')
                    .append(addrs.joinToString(","))
                    .append('\n')
            }
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
            Tsbridge.setInterfaceSource(Interfaces)
            interfacesSet = true
        }
        return Tsbridge.start(dir, authKey, hostname, target, secret, port.toLong(), stateKey).toInt()
    }

    fun status(): String = Tsbridge.status()

    fun stop() = Tsbridge.stop()

    fun logout(dir: String) = Tsbridge.logout(dir)
}
