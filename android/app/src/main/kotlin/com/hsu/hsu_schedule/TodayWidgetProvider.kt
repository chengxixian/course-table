package com.hsu.hsu_schedule

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Typeface
import android.os.Build
import android.util.Log
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONObject

class TodayWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        updateAll(context)
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: android.os.Bundle,
    ) {
        updateAll(context)
    }

    override fun onEnabled(context: Context) {
        updateAll(context)
    }

    companion object {
        private const val TAG = "HSUTodayWidget"

        private const val BITMAP_SIZE = 480
        private const val DESIGN_SIZE = 180f
        private const val PAD = 14f
        private val EVENT_COLORS = intArrayOf(
            0xFF039BE5.toInt(),
            0xFF33B679.toInt(),
            0xFF8E24AA.toInt(),
            0xFFE67C73.toInt(),
            0xFFF6BF26.toInt(),
            0xFF7986CB.toInt(),
            0xFFF4511E.toInt(),
            0xFF616161.toInt(),
        )

        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, TodayWidgetProvider::class.java))
            if (ids.isEmpty()) return
            val json = runCatching {
                HomeWidgetPlugin.getData(context).getString("schedule_widget", null)?.let { JSONObject(it) }
            }.onFailure { Log.w(TAG, "read widget data failed", it) }.getOrNull()
            for (id in ids) {
                try {
                    val views = RemoteViews(context.packageName, R.layout.widget_today)
                    views.setImageViewBitmap(R.id.widget_today_image, render(context, json))
                    val openIntent = Intent(context, MainActivity::class.java).apply {
                        action = Intent.ACTION_MAIN
                        addCategory(Intent.CATEGORY_LAUNCHER)
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    }
                    val pi = PendingIntent.getActivity(
                        context,
                        43,
                        openIntent,
                        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
                    )
                    views.setOnClickPendingIntent(R.id.widget_today_root, pi)
                    manager.updateAppWidget(id, views)
                } catch (t: Throwable) {
                    Log.e(TAG, "update failed", t)
                }
            }
        }

        private fun render(context: Context, json: JSONObject?): Bitmap {
            // The bitmap is a transparent, supersampled square. The rounded card
            // and its 24dp corners come from widget_today.xml, so the ImageView
            // can fitCenter the artwork at any host cell aspect.
            val bitmap = Bitmap.createBitmap(BITMAP_SIZE, BITMAP_SIZE, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            canvas.scale(BITMAP_SIZE / DESIGN_SIZE, BITMAP_SIZE / DESIGN_SIZE)

            val night = (context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) ==
                Configuration.UI_MODE_NIGHT_YES
            val onSurface = if (night) 0xFFE3E3E3.toInt() else 0xFF1F1F1F.toInt()
            val secondary = if (night) 0xFF9AA0A6.toInt() else 0xFF5F6368.toInt()
            val outline = if (night) 0xFF3C4043.toInt() else 0xFFDADCE0.toInt()
            val accent = try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    context.getColor(android.R.color.system_accent1_500)
                } else {
                    Color.parseColor("#0B57D0")
                }
            } catch (_: Throwable) {
                Color.parseColor("#0B57D0")
            }

            val pixelFont = json?.optString("fontStyle") == "pixel"
            val bodyTypeface = Typeface.createFromAsset(
                context.assets,
                if (pixelFont) "FusionPixel12.ttf" else "FandolFang-Regular.otf",
            )
            val timeTypeface = if (pixelFont) {
                bodyTypeface
            } else {
                Typeface.createFromAsset(context.assets, "LiberationSerif-Regular.ttf")
            }
            val text = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                typeface = bodyTypeface
                color = onSurface
            }

            val date = json?.optString("dateLabel").orEmpty().ifBlank { "今天" }
            val summary = json?.optString("nextSummary").orEmpty().ifBlank { "打开课程表同步课表" }
            val contentWidth = DESIGN_SIZE - PAD * 2

            // 18px date header, 9px "next class" summary.
            text.textSize = 18f
            canvas.drawText(fit(text, date, contentWidth), PAD, 26f, text)
            text.textSize = 9f
            text.color = secondary
            canvas.drawText(fit(text, summary, contentWidth), PAD, 41f, text)

            val divider = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = outline
                strokeWidth = 0.8f
            }
            canvas.drawLine(PAD, 48f, DESIGN_SIZE - PAD, 48f, divider)

            val rowsTop = 52.5f
            val rowsBottom = 159f
            val footerBaseline = 170f
            val rows = json?.optJSONArray("rows")
            text.typeface = bodyTypeface
            if (rows == null || rows.length() == 0) {
                text.color = onSurface
                text.textSize = 13f
                canvas.drawText("今天没有课", PAD, rowsTop + 28f, text)
                text.color = secondary
                text.textSize = 8.5f
                canvas.drawText("打开应用同步课表", PAD, rowsTop + 44f, text)
            } else {
                val count = minOf(rows.length(), 3)
                val rowHeight = (rowsBottom - rowsTop) / count
                for (i in 0 until count) {
                    val row = rows.optJSONObject(i) ?: continue
                    val top = rowsTop + i * rowHeight
                    val nameX = PAD + 9f
                    val maxWidth = DESIGN_SIZE - PAD - nameX

                    val bar = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                        color = EVENT_COLORS[row.optInt("colorIndex", i).mod(EVENT_COLORS.size)]
                    }
                    canvas.drawRoundRect(
                        RectF(PAD, top + 6.5f, PAD + 3f, top + rowHeight - 6.5f),
                        1.5f,
                        1.5f,
                        bar,
                    )

                    text.color = onSurface
                    text.textSize = 11.5f
                    canvas.drawText(fit(text, row.optString("name"), maxWidth), nameX, top + 14.5f, text)

                    val start = row.optString("time")
                    val end = row.optString("end")
                    val timeText = if (start.isEmpty()) "" else if (end.isEmpty()) start else "$start–$end"
                    var metaX = nameX
                    text.color = secondary
                    text.textSize = 8f
                    text.typeface = timeTypeface
                    if (timeText.isNotEmpty()) {
                        canvas.drawText(timeText, metaX, top + 27.5f, text)
                        metaX += text.measureText(timeText)
                    }
                    text.typeface = bodyTypeface
                    val room = row.optString("room")
                    if (room.isNotEmpty()) {
                        val meta = if (timeText.isEmpty()) room else " · $room"
                        canvas.drawText(
                            fit(text, meta, DESIGN_SIZE - PAD - metaX),
                            metaX,
                            top + 27.5f,
                            text,
                        )
                    }
                }
            }

            text.typeface = bodyTypeface
            text.color = secondary
            text.textSize = 8f
            val footer = json?.optString("footer").orEmpty().ifBlank { "HSU 课程表" }
            val open = "打开"
            val openWidth = text.measureText(open)
            canvas.drawText(
                fit(text, footer, contentWidth - openWidth - 8f),
                PAD,
                footerBaseline,
                text,
            )
            text.color = accent
            canvas.drawText(open, DESIGN_SIZE - PAD - openWidth, footerBaseline, text)
            return bitmap
        }

        private fun fit(paint: Paint, value: String, maxWidth: Float): String {
            if (paint.measureText(value) <= maxWidth) return value
            var end = value.length
            while (end > 1 && paint.measureText(value.substring(0, end) + "...") > maxWidth) end--
            return value.substring(0, end) + "..."
        }
    }
}
