package io.github.engineer948.melody

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.os.Build
import android.provider.MediaStore
import io.flutter.plugin.common.MethodChannel

/**
 * The `melody/local` channel: permission to read audio files and a scan of
 * MediaStore. Only used when the hidden "device files" source is enabled.
 */
class LocalMedia(private val activity: Activity) {
    private var pending: MethodChannel.Result? = null

    private val permission: String
        get() = if (Build.VERSION.SDK_INT >= 33) {
            Manifest.permission.READ_MEDIA_AUDIO
        } else {
            Manifest.permission.READ_EXTERNAL_STORAGE
        }

    fun hasPermission(): Boolean =
        activity.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED

    fun requestPermission(result: MethodChannel.Result) {
        if (hasPermission()) {
            result.success(true)
            return
        }
        pending?.success(false)
        pending = result
        activity.requestPermissions(arrayOf(permission), REQUEST_CODE)
    }

    /** Forwarded from the activity. */
    fun onPermissionResult(requestCode: Int, grantResults: IntArray): Boolean {
        if (requestCode != REQUEST_CODE) return false
        val granted = grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED
        pending?.success(granted)
        pending = null
        return true
    }

    fun scan(): List<Map<String, Any?>> {
        val columns = arrayOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.DISPLAY_NAME,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.ARTIST_ID,
            MediaStore.Audio.Media.ALBUM,
            MediaStore.Audio.Media.ALBUM_ID,
            MediaStore.Audio.Media.DURATION,
            MediaStore.Audio.Media.TRACK,
            MediaStore.Audio.Media.YEAR,
            MediaStore.Audio.Media.MIME_TYPE,
        )
        val rows = mutableListOf<Map<String, Any?>>()
        activity.contentResolver.query(
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
            columns,
            "${MediaStore.Audio.Media.IS_MUSIC} != 0",
            null,
            null,
        )?.use { c ->
            while (c.moveToNext()) {
                rows.add(
                    mapOf(
                        "id" to c.getLong(0),
                        "title" to c.getString(1),
                        "displayName" to c.getString(2),
                        "artist" to c.getString(3),
                        "artistId" to c.getLong(4).toString(),
                        "album" to c.getString(5),
                        "albumId" to c.getLong(6).toString(),
                        "duration" to c.getLong(7),
                        "track" to c.getInt(8),
                        "year" to c.getInt(9).takeIf { it > 0 },
                        "mime" to c.getString(10),
                    ),
                )
            }
        }
        return rows
    }

    companion object {
        private const val REQUEST_CODE = 4211
    }
}
