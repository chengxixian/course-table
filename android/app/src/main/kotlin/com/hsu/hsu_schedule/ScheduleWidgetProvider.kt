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
import kotlin.math.roundToInt

class ScheduleWidgetProvider : AppWidgetProvider() {
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
        private const val TAG = "HSUWidget"
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
            val ids = manager.getAppWidgetIds(ComponentName(context, ScheduleWidgetProvider::class.java))
            if (ids.isEmpty()) return
            val json = runCatching {
                HomeWidgetPlugin.getData(context).getString("schedule_widget", null)?.let { JSONObject(it) }
            }.onFailure { Log.w(TAG, "read widget data failed", it) }.getOrNull()
            for (id in ids) {
                try {
                    val options = manager.getAppWidgetOptions(id)
                    val width = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 320)
                    val height = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 190)
                    val views = RemoteViews(context.packageName, R.layout.widget_schedule_v2)
                    views.setImageViewBitmap(R.id.widget_bg, render(context, json, width, height))
                    val openIntent = Intent(context, MainActivity::class.java).apply {
                        action = Intent.ACTION_MAIN
                        addCategory(Intent.CATEGORY_LAUNCHER)
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    }
                    val pi = PendingIntent.getActivity(
                        context,
                        41,
                        openIntent,
                        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
                    )
                    views.setOnClickPendingIntent(R.id.widget_root, pi)
                    manager.updateAppWidget(id, views)
                } catch (t: Throwable) {
                    Log.e(TAG, "update failed", t)
                }
            }
        }

        private fun render(context: Context, json: JSONObject?, widthDp: Int, heightDp: Int): Bitmap {
            Log.d(TAG, "render ${widthDp}x${heightDp}dp rows=${json?.optJSONArray("rows")?.length() ?: 0}")
            // Draw into a fixed 4:3 canvas. The ImageView uses fitCenter, so a host
            // resize can never stretch the text; the rounded card background is a
            // separate drawable behind the transparent bitmap.
            val width = 320f
            val height = 240f
            val bitmapW = 520
            val bitmapH = 390
            val bitmap = Bitmap.createBitmap(bitmapW, bitmapH, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            canvas.scale(bitmapW / width, bitmapH / height)
            val density = 1f
            val night = (context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES
            val onSurface = if (night) 0xFFE3E3E3.toInt() else 0xFF1F1F1F.toInt()
            val secondary = if (night) 0xFF9AA0A6.toInt() else 0xFF5F6368.toInt()
            val outline = if (night) 0xFF3C4043.toInt() else 0xFFDADCE0.toInt()
            val accent = try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) context.getColor(android.R.color.system_accent1_500)
                else Color.parseColor("#0B57D0")
            } catch (_: Throwable) {
                Color.parseColor("#0B57D0")
            }
            val pixelFont = json?.optString("fontStyle") == "pixel"
            val bodyTypeface = Typeface.createFromAsset(context.assets, if (pixelFont) "FusionPixel12.ttf" else "FandolFang-Regular.otf")
            val timeTypeface = if (pixelFont) bodyTypeface else Typeface.createFromAsset(context.assets, "LiberationSerif-Regular.ttf")
            val text = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                typeface = bodyTypeface
                color = onSurface
            }
            val pad = 16f * density
            val date = json?.optString("dateLabel", "今天") ?: "今天"
            val week = json?.optString("week", "HSU") ?: "HSU"
            val summary = json?.optString("nextSummary", "打开课程表同步课表") ?: "打开课程表同步课表"
            text.textSize = 16f * density
            canvas.drawText(fit(text, date, width - pad * 2 - 54f * density), pad, pad + 16f * density, text)
            text.textSize = 9f * density
            text.color = secondary
            canvas.drawText(fit(text, summary, width - pad * 2 - 54f * density), pad, pad + 31f * density, text)

            val chipPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = accent }
            text.textSize = 9f * density
            text.color = accent
            val weekWidth = text.measureText(week) + 12f * density
            val chip = RectF(width - pad - weekWidth, pad + 1f * density, width - pad, pad + 19f * density)
            chipPaint.alpha = 28
            canvas.drawRoundRect(chip, 6f * density, 6f * density, chipPaint)
            text.color = accent
            canvas.drawText(week, chip.left + 6f * density, chip.bottom - 5f * density, text)

            val dividerY = pad + 40f * density
            val divider = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = outline
                strokeWidth = 1f * density
            }
            canvas.drawLine(pad, dividerY, width - pad, dividerY, divider)

            val footerBaseline = height - 9f * density
            val footerSize = 8f * density
            val bodyTop = dividerY + 6f * density
            val bodyBottom = footerBaseline - 9f * density
            val rows = json?.optJSONArray("morningRows") ?: json?.optJSONArray("rows")
            if (rows == null || rows.length() == 0) {
                text.textSize = 13f * density
                text.color = onSurface
                canvas.drawText("今天没有课", pad, bodyTop + 22f * density, text)
                text.textSize = 8.5f * density
                text.color = secondary
                canvas.drawText("打开应用同步课表", pad, bodyTop + 38f * density, text)
            } else {
                val count = minOf(rows.length(), 4)
                val rowHeight = (bodyBottom - bodyTop) / count
                for (i in 0 until count) {
                    val row = rows.optJSONObject(i) ?: continue
                    val top = bodyTop + i * rowHeight
                    val center = top + rowHeight / 2f
                    val timeSize = minOf(7.5f * density, rowHeight * 0.23f)
                    val nameSize = minOf(11f * density, rowHeight * 0.34f)
                    val roomSize = minOf(7.5f * density, rowHeight * 0.23f)
                    val baseline = center + nameSize * 0.35f
                    val start = row.optString("time", "")
                    val end = row.optString("end", "")
                    val timeText = if (start.isEmpty()) "" else if (end.isEmpty()) start else "$start–$end"

                    text.color = secondary
                    text.textSize = timeSize
                    text.typeface = timeTypeface
                    canvas.drawText(timeText, pad, baseline, text)
                    text.typeface = bodyTypeface

                    val barColor = EVENT_COLORS[row.optInt("colorIndex", i).mod(EVENT_COLORS.size)]
                    val bar = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = barColor }
                    val barLeft = pad + 50f * density
                    canvas.drawRoundRect(
                        RectF(barLeft, top + rowHeight * 0.22f, barLeft + 3f * density, top + rowHeight * 0.78f),
                        1.5f * density, 1.5f * density, bar,
                    )

                    val nameX = barLeft + 10f * density
                    val rowMax = width - nameX - pad
                    val room = row.optString("room", "")
                    text.color = secondary
                    text.textSize = roomSize
                    val roomWidth = if (room.isEmpty()) 0f else text.measureText(room)
                    val reserve = if (room.isNotEmpty() && roomWidth < rowMax * 0.46f) roomWidth + 6f * density else 0f
                    text.color = onSurface
                    text.textSize = nameSize
                    val name = fit(text, row.optString("name", ""), rowMax - reserve)
                    canvas.drawText(name, nameX, baseline, text)
                    if (reserve > 0f) {
                        text.color = secondary
                        text.textSize = roomSize
                        canvas.drawText(room, nameX + rowMax - reserve + 6f * density, baseline, text)
                    }
                }
            }

            text.color = secondary
            text.textSize = footerSize
            val footer = json?.optString("footer", "HSU 课程表") ?: "HSU 课程表"
            canvas.drawText(fit(text, footer, width - pad * 2 - 40f * density), pad, footerBaseline, text)
            text.color = accent
            canvas.drawText("打开", width - pad - 28f * density, footerBaseline, text)
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



