package io.github.engineer948.melody

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Matrix
import android.graphics.Paint
import android.media.AudioFormat
import android.media.Image
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import java.io.ByteArrayOutputStream
import java.io.File
import java.nio.ByteBuffer
import kotlin.math.ceil
import kotlin.math.min

/**
 * Makes an MP4 story video: a still picture (the share card) with a song
 * clip under it, using only the platform codecs (no FFmpeg).
 *
 * The MP3 clip is decoded to PCM and encoded to AAC; the picture is
 * encoded to H.264 as a constant stream of frames. Both are collected in
 * memory (a still picture compresses to very little) and then written to
 * the MP4 interleaved by time.
 */
object StoryVideo {
    private const val WIDTH = 720
    private const val HEIGHT = 1280
    private const val FPS = 24
    private const val VIDEO_BITRATE = 2_500_000
    private const val AUDIO_BITRATE = 160_000
    private const val TIMEOUT_US = 10_000L

    /** A codec that stops answering must not hang the share screen. */
    private const val DEADLINE_MS = 300_000L

    /** 33⅓ turns a minute. */
    private const val DEGREES_PER_SECOND = 200.0

    /** How much the record grows at the loudest moment. */
    private const val PULSE = 0.05

    /** A turning record drawn over the pictures. */
    class Disc(
        val path: String,
        /** Left, top, width, height as parts (0–1) of the picture. */
        val rect: List<Double>,
        /** 0–1 per frame at [FPS]. */
        val pulse: List<Double>,
    )

    private fun deadline(): Long = System.currentTimeMillis() + DEADLINE_MS

    private fun checkDeadline(until: Long) =
        check(System.currentTimeMillis() < until) { "codec timed out" }

    private class Sample(val data: ByteArray, val ptsUs: Long, val flags: Int)

    private class Encoded(val format: MediaFormat, val samples: List<Sample>)

    /**
     * Writes the video to [outPath]: picture `i` of [imagePaths] is shown
     * from [timesUs]`[i]` on (the first from the start). Throws when a codec
     * fails.
     */
    fun make(
        imagePaths: List<String>,
        timesUs: List<Long>,
        audioPath: String,
        outPath: String,
        disc: Disc? = null,
    ) {
        require(imagePaths.isNotEmpty() && imagePaths.size == timesUs.size) {
            "one time per picture"
        }
        val (pcm, sampleRate, channels) = decodeAudio(audioPath)
        val bytesPerFrame = 2 * channels
        val durationUs = pcm.size.toLong() / bytesPerFrame * 1_000_000L / sampleRate
        require(durationUs > 0) { "empty audio" }
        val audio = encodeAudio(pcm, sampleRate, channels)
        val video = encodeVideo(imagePaths, timesUs, durationUs, disc)

        File(outPath).delete()
        val muxer = MediaMuxer(outPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
        try {
            val videoTrack = muxer.addTrack(video.format)
            val audioTrack = muxer.addTrack(audio.format)
            muxer.start()
            val info = MediaCodec.BufferInfo()
            var v = 0
            var a = 0
            // Each track keeps its own order; the two are interleaved by time.
            while (v < video.samples.size || a < audio.samples.size) {
                val takeVideo = a >= audio.samples.size ||
                    (v < video.samples.size &&
                        video.samples[v].ptsUs <= audio.samples[a].ptsUs)
                val track = if (takeVideo) videoTrack else audioTrack
                val sample = if (takeVideo) video.samples[v++] else audio.samples[a++]
                info.set(0, sample.data.size, sample.ptsUs, sample.flags)
                muxer.writeSampleData(track, ByteBuffer.wrap(sample.data), info)
            }
            muxer.stop()
        } finally {
            muxer.release()
        }
    }

    /** The clip as 16-bit PCM with its sample rate and channel count. */
    private fun decodeAudio(path: String): Triple<ByteArray, Int, Int> {
        val extractor = MediaExtractor()
        extractor.setDataSource(path)
        val track = (0 until extractor.trackCount).first {
            extractor.getTrackFormat(it).getString(MediaFormat.KEY_MIME)
                ?.startsWith("audio/") == true
        }
        extractor.selectTrack(track)
        val format = extractor.getTrackFormat(track)
        var sampleRate = format.getInteger(MediaFormat.KEY_SAMPLE_RATE)
        var channels = format.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
        val decoder = MediaCodec.createDecoderByType(format.getString(MediaFormat.KEY_MIME)!!)
        val pcm = ByteArrayOutputStream()
        try {
            decoder.configure(format, null, null, 0)
            decoder.start()
            val info = MediaCodec.BufferInfo()
            var inputDone = false
            var outputDone = false
            val until = deadline()
            while (!outputDone) {
                checkDeadline(until)
                if (!inputDone) {
                    val index = decoder.dequeueInputBuffer(TIMEOUT_US)
                    if (index >= 0) {
                        val buffer = decoder.getInputBuffer(index)!!
                        val size = extractor.readSampleData(buffer, 0)
                        if (size < 0) {
                            decoder.queueInputBuffer(
                                index, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM,
                            )
                            inputDone = true
                        } else {
                            decoder.queueInputBuffer(index, 0, size, extractor.sampleTime, 0)
                            extractor.advance()
                        }
                    }
                }
                val out = decoder.dequeueOutputBuffer(info, TIMEOUT_US)
                if (out == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                    val f = decoder.outputFormat
                    sampleRate = f.getInteger(MediaFormat.KEY_SAMPLE_RATE)
                    channels = f.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
                    if (f.containsKey(MediaFormat.KEY_PCM_ENCODING)) {
                        check(
                            f.getInteger(MediaFormat.KEY_PCM_ENCODING) ==
                                AudioFormat.ENCODING_PCM_16BIT,
                        ) { "unexpected PCM encoding" }
                    }
                } else if (out >= 0) {
                    if (info.size > 0) {
                        val buffer = decoder.getOutputBuffer(out)!!
                        buffer.position(info.offset)
                        buffer.limit(info.offset + info.size)
                        val bytes = ByteArray(info.size)
                        buffer.get(bytes)
                        pcm.write(bytes)
                    }
                    decoder.releaseOutputBuffer(out, false)
                    if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) {
                        outputDone = true
                    }
                }
            }
        } finally {
            decoder.release()
            extractor.release()
        }
        return Triple(pcm.toByteArray(), sampleRate, channels)
    }

    private fun encodeAudio(pcm: ByteArray, sampleRate: Int, channels: Int): Encoded {
        val format = MediaFormat.createAudioFormat(
            MediaFormat.MIMETYPE_AUDIO_AAC, sampleRate, channels,
        ).apply {
            setInteger(
                MediaFormat.KEY_AAC_PROFILE,
                MediaCodecInfo.CodecProfileLevel.AACObjectLC,
            )
            setInteger(MediaFormat.KEY_BIT_RATE, AUDIO_BITRATE)
            setInteger(MediaFormat.KEY_MAX_INPUT_SIZE, 16 * 1024)
        }
        val encoder = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_AUDIO_AAC)
        val bytesPerFrame = 2 * channels
        var offset = 0
        try {
            encoder.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
            encoder.start()
            return drain(encoder) { index ->
                val buffer = encoder.getInputBuffer(index)!!
                buffer.clear()
                val room = buffer.remaining() / bytesPerFrame * bytesPerFrame
                val size = min(room, pcm.size - offset)
                val ptsUs = offset.toLong() / bytesPerFrame * 1_000_000L / sampleRate
                if (size <= 0) {
                    encoder.queueInputBuffer(
                        index, 0, 0, ptsUs, MediaCodec.BUFFER_FLAG_END_OF_STREAM,
                    )
                    false
                } else {
                    buffer.put(pcm, offset, size)
                    encoder.queueInputBuffer(index, 0, size, ptsUs, 0)
                    offset += size
                    true
                }
            }
        } finally {
            encoder.release()
        }
    }

    private fun encodeVideo(
        imagePaths: List<String>,
        timesUs: List<Long>,
        durationUs: Long,
        disc: Disc?,
    ): Encoded {
        // Still pictures are converted once (about 1.4 MB each); with a
        // record, every frame is drawn and converted.
        val pictures = if (disc == null) imagePaths.map { yuv(it) } else emptyList()
        val composer = disc?.let { Composer(imagePaths, it) }
        val format = MediaFormat.createVideoFormat(
            MediaFormat.MIMETYPE_VIDEO_AVC, WIDTH, HEIGHT,
        ).apply {
            setInteger(
                MediaFormat.KEY_COLOR_FORMAT,
                MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420Flexible,
            )
            setInteger(MediaFormat.KEY_BIT_RATE, VIDEO_BITRATE)
            setInteger(MediaFormat.KEY_FRAME_RATE, FPS)
            setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 1)
        }
        val encoder = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_VIDEO_AVC)
        val frames = ceil(durationUs * FPS / 1_000_000.0).toInt().coerceAtLeast(1)
        val frameSize = WIDTH * HEIGHT * 3 / 2
        var frame = 0
        try {
            encoder.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
            encoder.start()
            return drain(encoder) { index ->
                val ptsUs = frame * 1_000_000L / FPS
                if (frame >= frames) {
                    composer?.release()
                    encoder.queueInputBuffer(
                        index, 0, 0, ptsUs, MediaCodec.BUFFER_FLAG_END_OF_STREAM,
                    )
                    false
                } else {
                    var shown = 0
                    while (shown + 1 < timesUs.size && timesUs[shown + 1] <= ptsUs) shown++
                    val (y, u, v) = composer?.frame(shown, frame, ptsUs) ?: pictures[shown]
                    val image = encoder.getInputImage(index)
                    if (image != null) {
                        fill(image.planes[0], y, WIDTH, HEIGHT)
                        fill(image.planes[1], u, WIDTH / 2, HEIGHT / 2)
                        fill(image.planes[2], v, WIDTH / 2, HEIGHT / 2)
                    } else {
                        // No image view: assume plain I420 without padding.
                        val buffer = encoder.getInputBuffer(index)!!
                        buffer.clear()
                        buffer.put(y).put(u).put(v)
                    }
                    encoder.queueInputBuffer(index, 0, frameSize, ptsUs, 0)
                    frame++
                    true
                }
            }
        } finally {
            encoder.release()
        }
    }

    /**
     * Feeds [encoder] through [feed] (which returns false once it queued
     * the end of stream) and collects its output until the end.
     */
    private fun drain(encoder: MediaCodec, feed: (Int) -> Boolean): Encoded {
        val samples = ArrayList<Sample>()
        var format: MediaFormat? = null
        val info = MediaCodec.BufferInfo()
        var inputDone = false
        val until = deadline()
        while (true) {
            checkDeadline(until)
            if (!inputDone) {
                val index = encoder.dequeueInputBuffer(TIMEOUT_US)
                if (index >= 0) inputDone = !feed(index)
            }
            val out = encoder.dequeueOutputBuffer(info, TIMEOUT_US)
            if (out == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                format = encoder.outputFormat
            } else if (out >= 0) {
                val config = info.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG != 0
                if (info.size > 0 && !config) {
                    val buffer = encoder.getOutputBuffer(out)!!
                    buffer.position(info.offset)
                    buffer.limit(info.offset + info.size)
                    val bytes = ByteArray(info.size)
                    buffer.get(bytes)
                    val flags = info.flags and MediaCodec.BUFFER_FLAG_KEY_FRAME
                    samples.add(Sample(bytes, info.presentationTimeUs, flags))
                }
                encoder.releaseOutputBuffer(out, false)
                if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) break
            }
        }
        return Encoded(checkNotNull(format) { "no output format" }, samples)
    }

    /** The picture at [path] scaled to the video size. */
    private fun scaled(path: String, width: Int, height: Int): Bitmap {
        val decoded = checkNotNull(BitmapFactory.decodeFile(path)) { "bad image" }
        val bitmap = Bitmap.createScaledBitmap(decoded, width, height, true)
        if (bitmap !== decoded) decoded.recycle()
        return bitmap
    }

    /** The picture scaled to the video size, as Y, U and V planes (BT.601). */
    private fun yuv(path: String): Triple<ByteArray, ByteArray, ByteArray> {
        val bitmap = scaled(path, WIDTH, HEIGHT)
        val pixels = IntArray(WIDTH * HEIGHT)
        bitmap.getPixels(pixels, 0, WIDTH, 0, 0, WIDTH, HEIGHT)
        bitmap.recycle()
        val planes = Triple(
            ByteArray(WIDTH * HEIGHT),
            ByteArray(WIDTH * HEIGHT / 4),
            ByteArray(WIDTH * HEIGHT / 4),
        )
        toYuv(pixels, planes)
        return planes
    }

    /** Draws each frame: the picture shown at that time and the record. */
    private class Composer(imagePaths: List<String>, private val disc: Disc) {
        private val backgrounds = imagePaths.map { scaled(it, WIDTH, HEIGHT) }
        private val record = scaled(
            disc.path,
            (disc.rect[2] * WIDTH).toInt().coerceAtLeast(2),
            (disc.rect[3] * HEIGHT).toInt().coerceAtLeast(2),
        )
        private val centerX = ((disc.rect[0] + disc.rect[2] / 2) * WIDTH).toFloat()
        private val centerY = ((disc.rect[1] + disc.rect[3] / 2) * HEIGHT).toFloat()
        private val canvasBitmap = Bitmap.createBitmap(WIDTH, HEIGHT, Bitmap.Config.ARGB_8888)
        private val canvas = Canvas(canvasBitmap)
        private val matrix = Matrix()
        private val paint = Paint(Paint.FILTER_BITMAP_FLAG or Paint.ANTI_ALIAS_FLAG)
        private val pixels = IntArray(WIDTH * HEIGHT)
        private val planes = Triple(
            ByteArray(WIDTH * HEIGHT),
            ByteArray(WIDTH * HEIGHT / 4),
            ByteArray(WIDTH * HEIGHT / 4),
        )

        fun frame(picture: Int, index: Int, ptsUs: Long): Triple<ByteArray, ByteArray, ByteArray> {
            canvas.drawBitmap(backgrounds[picture], 0f, 0f, null)
            val angle = (ptsUs / 1_000_000.0 * DEGREES_PER_SECOND % 360).toFloat()
            val pulse = disc.pulse.getOrNull(index) ?: disc.pulse.lastOrNull() ?: 0.0
            val scale = (1 + PULSE * pulse.coerceIn(0.0, 1.0)).toFloat()
            matrix.reset()
            matrix.postTranslate(-record.width / 2f, -record.height / 2f)
            matrix.postRotate(angle)
            matrix.postScale(scale, scale)
            matrix.postTranslate(centerX, centerY)
            canvas.drawBitmap(record, matrix, paint)
            canvasBitmap.getPixels(pixels, 0, WIDTH, 0, 0, WIDTH, HEIGHT)
            toYuv(pixels, planes)
            return planes
        }

        fun release() {
            backgrounds.forEach { it.recycle() }
            record.recycle()
            canvasBitmap.recycle()
        }
    }

    /** ARGB pixels of the video size to Y, U and V planes (BT.601). */
    private fun toYuv(pixels: IntArray, planes: Triple<ByteArray, ByteArray, ByteArray>) {
        val (y, u, v) = planes
        for (row in 0 until HEIGHT) {
            for (col in 0 until WIDTH) {
                val p = pixels[row * WIDTH + col]
                val r = (p shr 16) and 0xFF
                val g = (p shr 8) and 0xFF
                val b = p and 0xFF
                y[row * WIDTH + col] = (((66 * r + 129 * g + 25 * b + 128) shr 8) + 16).toByte()
                if (row % 2 == 0 && col % 2 == 0) {
                    val i = (row / 2) * (WIDTH / 2) + col / 2
                    u[i] = (((-38 * r - 74 * g + 112 * b + 128) shr 8) + 128).toByte()
                    v[i] = (((112 * r - 94 * g - 18 * b + 128) shr 8) + 128).toByte()
                }
            }
        }
    }

    /** Copies a [width] x [height] plane into an image plane of any layout. */
    private fun fill(plane: Image.Plane, data: ByteArray, width: Int, height: Int) {
        val buffer = plane.buffer
        val rowStride = plane.rowStride
        val pixelStride = plane.pixelStride
        if (pixelStride == 1) {
            for (row in 0 until height) {
                buffer.position(row * rowStride)
                buffer.put(data, row * width, width)
            }
        } else {
            for (row in 0 until height) {
                val base = row * rowStride
                for (col in 0 until width) {
                    buffer.put(base + col * pixelStride, data[row * width + col])
                }
            }
        }
    }
}
