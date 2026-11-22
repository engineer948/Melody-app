package io.github.engineer948.melody

import android.app.Activity
import android.content.Intent
import android.nfc.NdefMessage
import android.nfc.NdefRecord
import android.nfc.NfcAdapter
import android.nfc.Tag
import android.nfc.tech.Ndef
import android.nfc.tech.NdefFormatable
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodChannel

/** Writes song letters to NFC stickers; nothing leaves the phone. */
class Nfc(private val activity: Activity) {
    private val main = Handler(Looper.getMainLooper())
    private var pending: MethodChannel.Result? = null

    /** "none" without NFC, else "on" or "off". */
    fun state(): String {
        val adapter = NfcAdapter.getDefaultAdapter(activity) ?: return "none"
        return if (adapter.isEnabled) "on" else "off"
    }

    /** Waits for a sticker and writes [uri] to it; answers with the outcome. */
    fun write(uri: String, result: MethodChannel.Result) {
        val adapter = NfcAdapter.getDefaultAdapter(activity)
        if (adapter == null || !adapter.isEnabled) {
            result.success("failed")
            return
        }
        finish("cancelled")
        pending = result
        val link = NdefRecord.createUri(uri)
        // With an app record Android opens Melody even when another app
        // could take the link; left out when the sticker is too small.
        val messages = listOf(
            NdefMessage(arrayOf(link, NdefRecord.createApplicationRecord(activity.packageName))),
            NdefMessage(arrayOf(link)),
        )
        val flags = NfcAdapter.FLAG_READER_NFC_A or NfcAdapter.FLAG_READER_NFC_B or
            NfcAdapter.FLAG_READER_NFC_F or NfcAdapter.FLAG_READER_NFC_V
        adapter.enableReaderMode(activity, { tag ->
            val outcome = runCatching { writeTag(tag, messages) }.getOrDefault("failed")
            main.post {
                runCatching { adapter.disableReaderMode(activity) }
                finish(outcome)
            }
        }, flags, null)
    }

    /** Stops waiting for a sticker. */
    fun cancel() {
        NfcAdapter.getDefaultAdapter(activity)?.let {
            runCatching { it.disableReaderMode(activity) }
        }
        finish("cancelled")
    }

    private fun finish(outcome: String) {
        pending?.success(outcome)
        pending = null
    }

    private fun writeTag(tag: Tag, messages: List<NdefMessage>): String {
        val ndef = Ndef.get(tag)
        if (ndef != null) {
            ndef.connect()
            try {
                if (!ndef.isWritable) return "readOnly"
                val message = messages.firstOrNull { it.toByteArray().size <= ndef.maxSize }
                    ?: return "tooBig"
                ndef.writeNdefMessage(message)
                return "written"
            } finally {
                runCatching { ndef.close() }
            }
        }
        val blank = NdefFormatable.get(tag) ?: return "readOnly"
        blank.connect()
        try {
            for (message in messages) {
                if (runCatching { blank.format(message) }.isSuccess) return "written"
            }
            return "tooBig"
        } finally {
            runCatching { blank.close() }
        }
    }

    companion object {
        /** The song letter link [intent] carries, if any. */
        fun linkOf(intent: Intent?): String? {
            val data = intent?.data ?: return null
            return if (data.scheme == "melody" && data.host == "letter") data.toString() else null
        }
    }
}
