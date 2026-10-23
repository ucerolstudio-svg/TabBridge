// SPDX-License-Identifier: GPL-3.0-only
package app.opendisplay.android.net

import android.content.ContentProvider
import android.content.ContentValues
import android.database.Cursor
import android.net.Uri
import android.os.Binder
import android.os.Bundle
import android.os.Process

/** Only an explicitly authorized ADB shell can bootstrap a new trusted Mac. */
class PairingProvider : ContentProvider() {
    override fun onCreate() = true
    override fun call(method: String, arg: String?, extras: Bundle?): Bundle {
        val uid = Binder.getCallingUid()
        if (uid != 2000 && uid != Process.myUid()) throw SecurityException("Authorized ADB pairing only")
        if (method != "pair" || arg == null) throw IllegalArgumentException("Unsupported operation")
        val identity = Binder.clearCallingIdentity()
        try {
            val pairing = SecurePairing(requireNotNull(context)).pair(arg)
            return Bundle().apply { putString("pairing", SecurePairing.encode(pairing.toString().toByteArray(Charsets.UTF_8))) }
        } finally { Binder.restoreCallingIdentity(identity) }
    }
    override fun getType(uri: Uri): String? = null
    override fun query(uri: Uri, projection: Array<out String>?, selection: String?, args: Array<out String>?, order: String?): Cursor? = null
    override fun insert(uri: Uri, values: ContentValues?): Uri? = throw UnsupportedOperationException()
    override fun delete(uri: Uri, selection: String?, args: Array<out String>?) = throw UnsupportedOperationException()
    override fun update(uri: Uri, values: ContentValues?, selection: String?, args: Array<out String>?) = throw UnsupportedOperationException()
}
