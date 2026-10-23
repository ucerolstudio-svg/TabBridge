// SPDX-License-Identifier: GPL-3.0-only
package app.opendisplay.android.net

import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.DataInputStream
import java.io.DataOutputStream

class PeerAuthenticationTest {
    private val client = "12345678-1234-1234-1234-123456789abc"
    private val token = "a".repeat(43)
    private fun auth() = JSONObject().put("type", "authenticate").put("securityVersion", 1).put("clientId", client).put("token", token)
    private fun framed(body: ByteArray, size: Int = body.size): DataInputStream {
        val out = ByteArrayOutputStream()
        DataOutputStream(out).apply { writeInt(size); write(body) }
        return DataInputStream(ByteArrayInputStream(out.toByteArray()))
    }
    private fun verify(obj: JSONObject, expected: String? = token) = PeerAuthentication.verify(framed(obj.toString().toByteArray())) { if (it == client) expected else null }
    @Test fun authorizedPeerAccepted() { assertTrue(verify(auth())) }
    @Test fun wrongTokenRejected() { assertFalse(verify(auth().put("token", "b".repeat(43)))) }
    @Test fun unknownPeerRejected() { assertFalse(verify(auth(), null)) }
    @Test fun missingAuthenticationRejected() { assertFalse(verify(JSONObject().put("type", "hello"))) }
    @Test fun wrongTypeRejected() { assertFalse(verify(auth().put("type", "input"))) }
    @Test fun wrongVersionRejected() { assertFalse(verify(auth().put("securityVersion", 2))) }
    @Test fun booleanVersionRejected() { assertFalse(verify(auth().put("securityVersion", true))) }
    @Test fun nonCanonicalIdentityRejected() { assertFalse(verify(auth().put("clientId", client.uppercase()))) }
    @Test fun abbreviatedIdentityRejected() { assertFalse(verify(auth().put("clientId", "1-1-1-1-1"))) }
    @Test fun invalidTokenRejected() { assertFalse(verify(auth().put("token", "!".repeat(43)))) }
    @Test fun paddedTokenRejected() { assertFalse(verify(auth().put("token", token + "="))) }
    @Test fun numericTokenRejected() { assertFalse(verify(auth().put("token", 123))) }
    @Test fun oversizeRejectedBeforeReadingBody() { assertFalse(PeerAuthentication.verify(framed(byteArrayOf(), 2049)) { token }) }
    @Test fun negativeSizeRejected() { assertFalse(PeerAuthentication.verify(framed(byteArrayOf(), -1)) { token }) }
    @Test fun zeroSizeRejected() { assertFalse(PeerAuthentication.verify(framed(byteArrayOf(), 0)) { token }) }
    @Test fun partialFrameRejected() { assertFalse(PeerAuthentication.verify(framed(byteArrayOf(1), 10)) { token }) }
    @Test fun invalidJsonRejected() { assertFalse(PeerAuthentication.verify(framed("[]".toByteArray())) { token }) }
    @Test fun legacyVideoRejected() { assertFalse(PeerAuthentication.verify(framed(byteArrayOf(0,0,0,1,3))) { token }) }
}
