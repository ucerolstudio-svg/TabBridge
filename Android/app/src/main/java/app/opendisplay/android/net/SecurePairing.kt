// SPDX-License-Identifier: GPL-3.0-only
package app.opendisplay.android.net

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import app.opendisplay.android.ui.DeviceIdentity
import org.json.JSONObject
import java.math.BigInteger
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.MessageDigest
import java.security.SecureRandom
import java.security.spec.ECGenParameterSpec
import java.util.Date
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec
import javax.net.ssl.KeyManagerFactory
import javax.net.ssl.SSLContext
import javax.security.auth.x500.X500Principal

/** Identity keys never leave Android Keystore. Peer secrets are wrapped at rest. */
class SecurePairing(private val context: Context) {
    private val prefs = context.getSharedPreferences("secure-peers-v1", Context.MODE_PRIVATE)
    private fun keyStore() = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
    private fun ensureKeys() = synchronized(LOCK) {
        val store = keyStore()
        if (!store.containsAlias(TLS_KEY)) {
            KeyPairGenerator.getInstance(KeyProperties.KEY_ALGORITHM_EC, "AndroidKeyStore").apply {
                initialize(KeyGenParameterSpec.Builder(TLS_KEY, KeyProperties.PURPOSE_SIGN or KeyProperties.PURPOSE_VERIFY)
                    .setAlgorithmParameterSpec(ECGenParameterSpec("secp256r1"))
                    .setDigests(KeyProperties.DIGEST_SHA256, KeyProperties.DIGEST_SHA512)
                    .setCertificateSubject(X500Principal("CN=TabBridge"))
                    .setCertificateSerialNumber(BigInteger(128, SecureRandom()).setBit(127))
                    .setCertificateNotBefore(Date(System.currentTimeMillis() - 86400000L))
                    .setCertificateNotAfter(Date(System.currentTimeMillis() + 10L * 365 * 86400000L)).build())
                generateKeyPair()
            }
        }
        if (!store.containsAlias(WRAP_KEY)) {
            KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore").apply {
                init(KeyGenParameterSpec.Builder(WRAP_KEY, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                    .setKeySize(256).setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                    .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE).build())
                generateKey()
            }
        }
    }
    fun sslContext(): SSLContext {
        ensureKeys()
        val managers = KeyManagerFactory.getInstance(KeyManagerFactory.getDefaultAlgorithm()).apply { init(keyStore(), null) }
        return SSLContext.getInstance("TLS").apply { init(managers.keyManagers, null, SecureRandom()) }
    }
    fun pair(client: String): JSONObject = synchronized(LOCK) {
        require(PeerAuthentication.canonicalClientId(client)) { "Invalid client identity" }
        ensureKeys()
        var token = expectedToken(client)
        if (token == null) {
            require(prefs.all.size < 8) { "Forget an old Mac before pairing another" }
            val bytes = ByteArray(32).also { SecureRandom().nextBytes(it) }
            token = encode(bytes)
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            cipher.init(Cipher.ENCRYPT_MODE, keyStore().getKey(WRAP_KEY, null) as SecretKey)
            val wrapped = cipher.iv + cipher.doFinal(bytes)
            check(prefs.edit().putString(client, encode(wrapped)).commit()) { "Could not save pairing" }
        }
        val cert = keyStore().getCertificate(TLS_KEY).encoded
        JSONObject().put("securityVersion", 1).put("id", DeviceIdentity.installId(context))
            .put("clientId", client).put("token", token)
            .put("certificateSHA256", encode(MessageDigest.getInstance("SHA-256").digest(cert)))
    }
    fun expectedToken(client: String): String? = synchronized(LOCK) {
        val saved = prefs.getString(client, null) ?: return@synchronized null
        try {
            val wrapped = Base64.decode(saved, FLAGS)
            if (wrapped.size != 60) return@synchronized null
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            cipher.init(Cipher.DECRYPT_MODE, keyStore().getKey(WRAP_KEY, null) as SecretKey,
                GCMParameterSpec(128, wrapped.copyOfRange(0, 12)))
            encode(cipher.doFinal(wrapped.copyOfRange(12, wrapped.size)))
        } catch (_: Exception) { null }
    }
    fun forgetAll() = synchronized(LOCK) { check(prefs.edit().clear().commit()) }
    fun pairedCount(): Int = synchronized(LOCK) { prefs.all.size }
    companion object {
        private val LOCK = Any()
        private const val TLS_KEY = "tabbridge-tls-v1"
        private const val WRAP_KEY = "tabbridge-peers-v1"
        const val FLAGS = Base64.URL_SAFE or Base64.NO_WRAP or Base64.NO_PADDING
        fun encode(data: ByteArray): String = Base64.encodeToString(data, FLAGS)
    }
}
