// SPDX-License-Identifier: GPL-3.0-only
package app.opendisplay.android.net

import app.opendisplay.android.protocol.Framing
import org.json.JSONObject
import java.io.DataInputStream
import java.net.Socket
import java.util.concurrent.ArrayBlockingQueue
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.concurrent.ThreadPoolExecutor
import java.util.concurrent.TimeUnit
import javax.net.ssl.SSLServerSocket
import javax.net.ssl.SSLSocket

/** No video, control, or peer replacement is possible before TLS + token validation. */
class SecureListener(
    private val contextFactory: () -> javax.net.ssl.SSLContext,
    private val expectedToken: (String) -> String?,
    private val port: Int = 9443,
    private val adopt: (Socket) -> Unit,
) {
    @Volatile var boundPort: Int? = null
        private set
    private fun closeQuietly(socket: java.io.Closeable?) { try { socket?.close() } catch (_: Exception) {} }
    @Volatile private var running = false
    private var listener: SSLServerSocket? = null
    private val pending = java.util.Collections.newSetFromMap(ConcurrentHashMap<Socket, Boolean>())
    private val workers = ThreadPoolExecutor(2, 2, 0L, TimeUnit.SECONDS, ArrayBlockingQueue<Runnable>(4),
        { r -> Thread(r, "tb-auth").apply { isDaemon = true } })
    private val deadlines = Executors.newSingleThreadScheduledExecutor { r -> Thread(r, "tb-auth-deadline").apply { isDaemon = true } }
    fun start() {
        running = true
        Thread({
            val server = try { contextFactory().serverSocketFactory.createServerSocket() as SSLServerSocket }
                catch (_: Exception) { return@Thread }
            try {
                synchronized(this) {
                    if (!running) return@Thread
                    // Publish and bind under the same monitor as stop(). A stopped
                    // generation must not leave a bound but unrecorded socket behind.
                    listener = server
                    server.reuseAddress = true
                    server.enabledProtocols = server.supportedProtocols.filter { it == "TLSv1.3" || it == "TLSv1.2" }.toTypedArray()
                    server.bind(java.net.InetSocketAddress(port))
                    boundPort = server.localPort
                }
                while (running) {
                    val socket = server.accept() as SSLSocket
                    if (!running) { socket.close(); break }
                    pending.add(socket)
                    try {
                        val deadline = deadlines.schedule({ closeQuietly(socket) }, 5, TimeUnit.SECONDS)
                        workers.execute {
                            var accepted = false
                            try {
                                socket.soTimeout = 5000; socket.tcpNoDelay = true
                                socket.startHandshake()
                                if (PeerAuthentication.verify(DataInputStream(socket.inputStream), expectedToken) && running) {
                                    socket.outputStream.write(Framing.encode(JSONObject().put("type", "authenticated").put("securityVersion", 1).toString().toByteArray()))
                                    socket.outputStream.flush()
                                    socket.soTimeout = 0
                                    deadline.cancel(false); pending.remove(socket)
                                    if (running) { adopt(socket); accepted = true }
                                }
                            } catch (_: Exception) {
                                // Do not log auth frames, credentials, or detailed peer-validation errors.
                            } finally {
                                deadline.cancel(false); pending.remove(socket)
                                if (!accepted) closeQuietly(socket)
                            }
                        }
                    } catch (_: java.util.concurrent.RejectedExecutionException) {
                        pending.remove(socket); closeQuietly(socket)
                    }
                }
            } catch (_: Exception) {
                // Failure is closed: no plaintext listener is opened on the LAN.
            } finally {
                synchronized(this) {
                    closeQuietly(server)
                    if (listener === server) { listener = null; boundPort = null }
                }
            }
        }, "tb-tls-listener").apply { isDaemon = true }.start()
    }
    fun stop() {
        running = false
        synchronized(this) { closeQuietly(listener); listener = null; boundPort = null }
        pending.forEach { closeQuietly(it) }; pending.clear()
        workers.shutdownNow(); deadlines.shutdownNow()
    }
}
