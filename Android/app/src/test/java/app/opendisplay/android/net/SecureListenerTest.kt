// SPDX-License-Identifier: GPL-3.0-only
package app.opendisplay.android.net

import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import java.io.DataInputStream
import java.io.DataOutputStream
import java.net.Socket
import java.nio.file.Files
import java.security.KeyStore
import java.util.concurrent.CopyOnWriteArrayList
import javax.net.ssl.KeyManagerFactory
import javax.net.ssl.SSLContext
import javax.net.ssl.TrustManagerFactory
import javax.net.ssl.SSLSocket

/** Exercises the production admission gate with real TLS sockets, not mocked socket callbacks. */
class SecureListenerTest {
    private val id = "12345678-1234-1234-1234-123456789abc"
    private val secret = "a".repeat(43)
    private fun waitUntil(test: () -> Boolean) {
        val until = System.nanoTime() + 4_000_000_000L
        while (!test() && System.nanoTime() < until) Thread.sleep(10)
        assertTrue(test())
    }
    private fun context(): SSLContext {
        val dir = Files.createTempDirectory("tabbridge-tls-test-")
        val file = dir.resolve("fixture.p12")
        try {
            val process = ProcessBuilder(System.getProperty("java.home") + "/bin/keytool", "-genkeypair", "-alias", "test", "-keystore", file.toString(), "-storetype", "PKCS12", "-storepass", "fixture-only", "-keypass", "fixture-only", "-dname", "CN=localhost", "-keyalg", "EC", "-groupname", "secp256r1", "-validity", "1").redirectErrorStream(true).start()
            process.inputStream.readBytes(); check(process.waitFor() == 0)
            val store = KeyStore.getInstance("PKCS12").apply { Files.newInputStream(file).use { load(it, "fixture-only".toCharArray()) } }
            val keys = KeyManagerFactory.getInstance(KeyManagerFactory.getDefaultAlgorithm()).apply { init(store, "fixture-only".toCharArray()) }
            val trust = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm()).apply { init(store) }
            return SSLContext.getInstance("TLS").apply { init(keys.keyManagers, trust.trustManagers, null) }
        } finally { Files.deleteIfExists(file); Files.deleteIfExists(dir) }
    }
    private fun auth(socket: Socket, token: String = secret) {
        val body = JSONObject().put("type", "authenticate").put("securityVersion", 1).put("clientId", id).put("token", token).toString().toByteArray()
        DataOutputStream(socket.getOutputStream()).apply { writeInt(body.size); write(body); flush() }
    }
    @Test fun realTlsGateRejectsInvalidPeersAndPreservesAuthenticatedSession() {
        val context = context()
        val adopted = CopyOnWriteArrayList<Socket>()
        val server = SecureListener({ context }, { if (it == id) secret else null }, 0) { adopted.add(it) }
        server.start()
        try {
            waitUntil { server.boundPort != null }
            val port = server.boundPort!!
            // A legacy plaintext hello cannot pass TLS or change the active peer.
            Socket("127.0.0.1", port).use { it.soTimeout = 2000; auth(it); try { it.inputStream.read() } catch (_: Exception) {} }
            assertEquals(0, adopted.size)
            fun tls(): SSLSocket = (context.socketFactory.createSocket("127.0.0.1", port) as SSLSocket).apply { soTimeout = 2000; startHandshake() }
            tls().use { auth(it, "b".repeat(43)); assertEquals(-1, it.inputStream.read()) }
            assertEquals(0, adopted.size)
            val good = tls()
            auth(good)
            val input = DataInputStream(good.inputStream)
            val ackSize = input.readInt(); assertTrue(ackSize in 1..512)
            val ack = ByteArray(ackSize); input.readFully(ack)
            assertEquals("authenticated", JSONObject(String(ack)).getString("type"))
            waitUntil { adopted.size == 1 }
            tls().use { DataOutputStream(it.outputStream).apply { writeInt(2049); flush() }; assertEquals(-1, it.inputStream.read()) }
            assertEquals(1, adopted.size)
            assertFalse(good.isClosed)
            // A fresh authenticated dial (reconnect) must pass the same gate.
            tls().use { auth(it); val reply = DataInputStream(it.inputStream); assertTrue(reply.readInt() in 1..512) }
            waitUntil { adopted.size == 2 }
            good.close()
        } finally { server.stop(); adopted.forEach { it.close() } }
    }
    @Test fun removedCredentialCannotAuthenticateAgain() {
        val context = context()
        val tokens = java.util.concurrent.atomic.AtomicReference<String?>(secret)
        val adopted = CopyOnWriteArrayList<Socket>()
        val server = SecureListener({ context }, { tokens.get() }, 0) { adopted.add(it) }
        server.start()
        try {
            waitUntil { server.boundPort != null }
            tokens.set(null)
            (context.socketFactory.createSocket("127.0.0.1", server.boundPort!!) as SSLSocket).use {
                it.soTimeout = 2000; it.startHandshake(); auth(it); assertEquals(-1, it.inputStream.read())
            }
            assertTrue(adopted.isEmpty())
        } finally { server.stop(); adopted.forEach { it.close() } }
    }
    @Test fun listenerCannotBindBeforePublicationAndStopAllowsImmediateRestart() {
        val context = context()
        val port = java.net.ServerSocket(0).use { it.localPort }
        val initialized = java.util.concurrent.CountDownLatch(1)
        val first = SecureListener({ initialized.countDown(); context }, { null }, port) { it.close() }
        try {
            synchronized(first) {
                first.start()
                assertTrue(initialized.await(2, java.util.concurrent.TimeUnit.SECONDS))
                // Force the old bind/publication window: the listener thread
                // cannot publish while we hold its monitor. It must not bind either.
                val until = System.nanoTime() + 300_000_000L
                var connected = false
                while (System.nanoTime() < until) {
                    try { Socket().use { it.connect(java.net.InetSocketAddress("127.0.0.1", port), 20); connected = true } }
                    catch (_: java.io.IOException) { Thread.sleep(5) }
                }
                assertFalse("unpublished listener exposed a port", connected)
            }
            waitUntil { first.boundPort == port }
            first.stop()
            val second = SecureListener({ context }, { null }, port) { it.close() }
            try { second.start(); waitUntil { second.boundPort == port } }
            finally { second.stop() }
        } finally { first.stop() }
    }

}
