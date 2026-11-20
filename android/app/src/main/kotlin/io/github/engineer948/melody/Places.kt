package io.github.engineer948.melody

import android.Manifest
import android.app.Activity
import android.content.ContentUris
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.location.Geocoder
import android.location.Location
import android.location.LocationManager
import android.os.Build
import android.os.CancellationSignal
import android.provider.MediaStore
import android.util.Size
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.Locale
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/**
 * The `melody/places` channel for "soundtrack of your life": a rough
 * location of the phone (platform LocationManager, no Google services), the
 * name of a place, and the photos taken on a day. Everything stays on the
 * phone.
 */
class Places(private val activity: Activity) {
    private val context: Context get() = activity.applicationContext
    private var pending: MethodChannel.Result? = null
    private var pendingCode = 0

    private val photoPermission: String
        get() = if (Build.VERSION.SDK_INT >= 33) {
            Manifest.permission.READ_MEDIA_IMAGES
        } else {
            Manifest.permission.READ_EXTERNAL_STORAGE
        }

    private fun granted(permission: String) =
        activity.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED

    fun hasLocation() = granted(Manifest.permission.ACCESS_COARSE_LOCATION)

    fun hasPhotos() = granted(photoPermission) ||
        (Build.VERSION.SDK_INT >= 34 &&
            granted(Manifest.permission.READ_MEDIA_VISUAL_USER_SELECTED))

    fun requestLocation(result: MethodChannel.Result) =
        request(arrayOf(Manifest.permission.ACCESS_COARSE_LOCATION), LOCATION_CODE, result)

    fun requestPhotos(result: MethodChannel.Result) {
        val wanted = if (Build.VERSION.SDK_INT >= 34) {
            arrayOf(photoPermission, Manifest.permission.READ_MEDIA_VISUAL_USER_SELECTED)
        } else {
            arrayOf(photoPermission)
        }
        request(wanted, PHOTOS_CODE, result)
    }

    private fun request(permissions: Array<String>, code: Int, result: MethodChannel.Result) {
        if (permissions.any { granted(it) }) {
            result.success(true)
            return
        }
        pending?.success(false)
        pending = result
        pendingCode = code
        activity.requestPermissions(permissions, code)
    }

    /** Forwarded from the activity. */
    fun onPermissionResult(requestCode: Int, grantResults: IntArray): Boolean {
        if (requestCode != LOCATION_CODE && requestCode != PHOTOS_CODE) return false
        if (requestCode != pendingCode) return true
        pending?.success(grantResults.any { it == PackageManager.PERMISSION_GRANTED })
        pending = null
        return true
    }

    /**
     * The newest known location; when it is older than a quarter of an hour
     * a fresh network fix is asked for (up to 5 s). Call off the main thread.
     */
    fun location(): Map<String, Any>? {
        if (!hasLocation()) return null
        val manager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        var best: Location? = null
        for (provider in listOf(
            LocationManager.NETWORK_PROVIDER,
            LocationManager.PASSIVE_PROVIDER,
            LocationManager.GPS_PROVIDER,
        )) {
            val known = try {
                manager.getLastKnownLocation(provider)
            } catch (_: SecurityException) {
                null
            } catch (_: IllegalArgumentException) {
                null
            }
            if (known != null && (best == null || known.time > best.time)) best = known
        }
        val stale = best == null || System.currentTimeMillis() - best.time > 15 * 60_000
        if (stale && Build.VERSION.SDK_INT >= 30 &&
            manager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
        ) {
            val latch = CountDownLatch(1)
            var fresh: Location? = null
            try {
                manager.getCurrentLocation(
                    LocationManager.NETWORK_PROVIDER,
                    CancellationSignal(),
                    context.mainExecutor,
                ) {
                    fresh = it
                    latch.countDown()
                }
                latch.await(5, TimeUnit.SECONDS)
            } catch (_: SecurityException) {
            }
            fresh?.let { best = it }
        }
        val found = best ?: return null
        return mapOf(
            "latitude" to found.latitude,
            "longitude" to found.longitude,
            "time" to found.time,
        )
    }

    /** "Neighbourhood, town" in [language], or null. Off the main thread. */
    @Suppress("DEPRECATION")
    fun placeName(latitude: Double, longitude: Double, language: String): String? {
        if (!Geocoder.isPresent()) return null
        return try {
            val address = Geocoder(context, Locale.forLanguageTag(language))
                .getFromLocation(latitude, longitude, 1)
                ?.firstOrNull() ?: return null
            listOfNotNull(
                address.subLocality ?: address.thoroughfare,
                address.locality ?: address.subAdminArea ?: address.adminArea,
                if (address.locality == null) address.countryName else null,
            ).distinct().joinToString(", ").ifEmpty { null }
        } catch (_: Exception) {
            null
        }
    }

    /** Photos taken between [from] and [to] (ms), newest first. */
    fun photos(from: Long, to: Long, limit: Int): List<Map<String, Any>> {
        if (!hasPhotos()) return emptyList()
        val columns = arrayOf(MediaStore.Images.Media._ID, MediaStore.Images.Media.DATE_TAKEN)
        val rows = mutableListOf<Map<String, Any>>()
        context.contentResolver.query(
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            columns,
            "${MediaStore.Images.Media.DATE_TAKEN} >= ? AND ${MediaStore.Images.Media.DATE_TAKEN} < ?",
            arrayOf(from.toString(), to.toString()),
            "${MediaStore.Images.Media.DATE_TAKEN} DESC",
        )?.use { cursor ->
            while (cursor.moveToNext() && rows.size < limit) {
                rows.add(mapOf("id" to cursor.getLong(0), "taken" to cursor.getLong(1)))
            }
        }
        return rows
    }

    /** A JPEG thumbnail of photo [id], about [size] pixels. Off the main thread. */
    @Suppress("DEPRECATION")
    fun thumbnail(id: Long, size: Int): ByteArray? {
        if (!hasPhotos()) return null
        val bitmap: Bitmap? = try {
            if (Build.VERSION.SDK_INT >= 29) {
                val uri = ContentUris.withAppendedId(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, id)
                context.contentResolver.loadThumbnail(uri, Size(size, size), null)
            } else {
                MediaStore.Images.Thumbnails.getThumbnail(
                    context.contentResolver, id, MediaStore.Images.Thumbnails.MINI_KIND, null,
                )
            }
        } catch (_: Exception) {
            null
        }
        bitmap ?: return null
        val out = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.JPEG, 85, out)
        bitmap.recycle()
        return out.toByteArray()
    }

    companion object {
        private const val LOCATION_CODE = 4711
        private const val PHOTOS_CODE = 4712
    }
}
