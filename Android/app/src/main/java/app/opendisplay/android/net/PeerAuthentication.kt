// SPDX-License-Identifier: GPL-3.0-only
package app.opendisplay.android.net

import org.json.JSONObject
import java.io.DataInputStream
import java.io.IOException
import java.security.MessageDigest
import java.util.UUID

/** The only frame allowed before an authenticated session can be adopted. */
object PeerAuthentication {
    const val MAX_BYTES = 2048
    fun canonicalClientId(value: String): Boolean = try {
        UUID.fromString(value).toString() == value
    } catch (_: IllegalArgumentException) { false }

    fun verify(input: DataInputStream, expected: (String) -> String?): Boolean = try {
        val length = input.readInt()
        if (length !in 1..MAX_BYTES) false else {
            val bytes = ByteArray(length)
            input.readFully(bytes)
            val obj = JSONObject(String(bytes, Charsets.UTF_8))
            val client = obj.opt("clientId") as? String
            val token = obj.opt("token") as? String
            if (obj.opt("type") != "authenticate" || obj.opt("securityVersion") != 1 ||
                client == null || !canonicalClientId(client) || token == null ||
                !token.matches(Regex("[A-Za-z0-9_-]{43}"))) false
            else expected(client)?.let {
                MessageDigest.isEqual(it.toByteArray(Charsets.UTF_8), token.toByteArray(Charsets.UTF_8))
            } ?: false
        }
    } catch (_: IOException) { false } catch (_: org.json.JSONException) { false }
}
