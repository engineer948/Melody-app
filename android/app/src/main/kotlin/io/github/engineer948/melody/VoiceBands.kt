package io.github.engineer948.melody

import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import java.nio.ByteOrder
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.sin
import kotlin.math.sqrt

/**
 * Loudness of the voice band at the start of a song, for syncing lyrics
 * to where the singing starts. The sound is decoded on the phone; for
 * every 20 ms it gives the level of 250–3500 Hz in the middle of the
 * stereo picture (where singers are) and at the sides.
 */
object VoiceBands {
    const val HOP_MS = 20

    private class Biquad(
        private val b0: Double,
        private val b1: Double,
        private val b2: Double,
        private val a1: Double,
        private val a2: Double,
    ) {
        private var x1 = 0.0
        private var x2 = 0.0
        private var y1 = 0.0
        private var y2 = 0.0

        fun run(x: Double): Double {
            val y = b0 * x + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
            x2 = x1
            x1 = x
            y2 = y1
            y1 = y
            return y
        }

        companion object {
            fun highPass(f: Double, rate: Double): Biquad {
                val w = 2 * PI * f / rate
                val alpha = sin(w) / (2 * 0.7071)
                val c = cos(w)
                val a0 = 1 + alpha
                return Biquad((1 + c) / 2 / a0, -(1 + c) / a0, (1 + c) / 2 / a0, -2 * c / a0, (1 - alpha) / a0)
            }

            fun lowPass(f: Double, rate: Double): Biquad {
                val w = 2 * PI * f / rate
                val alpha = sin(w) / (2 * 0.7071)
                val c = cos(w)
                val a0 = 1 + alpha
                return Biquad((1 - c) / 2 / a0, (1 - c) / a0, (1 - c) / 2 / a0, -2 * c / a0, (1 - alpha) / a0)
            }
        }
    }

    private fun filters(rate: Int): List<Biquad> {
        val r = rate.toDouble()
        return listOf(
            Biquad.highPass(250.0, r), Biquad.lowPass(3500.0, r),
            Biquad.highPass(250.0, r), Biquad.lowPass(3500.0, r),
        )
    }

    /** Voice band levels of the first [maxSeconds] of the audio file at [path]. */
    fun analyze(path: String, maxSeconds: Int): Map<String, Any> {
        val extractor = MediaExtractor()
        extractor.setDataSource(path)
        var format: MediaFormat? = null
        for (i in 0 until extractor.trackCount) {
            val f = extractor.getTrackFormat(i)
            if (f.getString(MediaFormat.KEY_MIME)?.startsWith("audio/") == true) {
                extractor.selectTrack(i)
                format = f
                break
            }
        }
        if (format == null) {
            extractor.release()
            throw IllegalArgumentException("no audio")
        }
        val codec = MediaCodec.createDecoderByType(format.getString(MediaFormat.KEY_MIME)!!)
        codec.configure(format, null, null, 0)
        codec.start()
        var rate = format.getInteger(MediaFormat.KEY_SAMPLE_RATE)
        var channels = format.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
        var f = filters(rate)
        var hop = rate * HOP_MS / 1000
        val mid = ArrayList<Double>()
        val side = ArrayList<Double>()
        val limit = maxSeconds * 1000 / HOP_MS
        var count = 0
        var sumMid = 0.0
        var sumSide = 0.0
        val info = MediaCodec.BufferInfo()
        var inputDone = false
        var outputDone = false
        try {
            while (!outputDone && mid.size < limit) {
                if (!inputDone) {
                    val i = codec.dequeueInputBuffer(10000)
                    if (i >= 0) {
                        val buffer = codec.getInputBuffer(i)!!
                        val n = extractor.readSampleData(buffer, 0)
                        if (n < 0) {
                            codec.queueInputBuffer(i, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                            inputDone = true
                        } else {
                            codec.queueInputBuffer(i, 0, n, extractor.sampleTime, 0)
                            extractor.advance()
                        }
                    }
                }
                val o = codec.dequeueOutputBuffer(info, 10000)
                if (o == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                    val out = codec.outputFormat
                    rate = out.getInteger(MediaFormat.KEY_SAMPLE_RATE)
                    channels = out.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
                    f = filters(rate)
                    hop = rate * HOP_MS / 1000
                } else if (o >= 0) {
                    val buffer = codec.getOutputBuffer(o)!!
                    buffer.position(info.offset)
                    buffer.limit(info.offset + info.size)
                    val samples = buffer.order(ByteOrder.nativeOrder()).asShortBuffer()
                    val frames = samples.remaining() / channels
                    for (k in 0 until frames) {
                        val l = samples.get() / 32768.0
                        val r = if (channels > 1) samples.get() / 32768.0 else l
                        for (c in 2 until channels) samples.get()
                        val m = f[1].run(f[0].run((l + r) / 2))
                        val s = f[3].run(f[2].run((l - r) / 2))
                        sumMid += m * m
                        sumSide += s * s
                        count++
                        if (count >= hop) {
                            mid.add(sqrt(sumMid / count))
                            side.add(sqrt(sumSide / count))
                            count = 0
                            sumMid = 0.0
                            sumSide = 0.0
                        }
                    }
                    codec.releaseOutputBuffer(o, false)
                    if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) outputDone = true
                }
            }
        } finally {
            runCatching { codec.stop() }
            codec.release()
            extractor.release()
        }
        return mapOf("hopMs" to HOP_MS, "mid" to mid.toDoubleArray(), "side" to side.toDoubleArray())
    }
}
