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
import android.graphics.Typeface
import android.util.Log
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONObject
import kotlin.math.roundToInt

class NextClassWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        updateAll(context)
    }

    override fun onAppWidgetOptionsChanged(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int, newOptions: android.os.Bundle) {
        updateAll(context)
    }

    companion object {
        private const val TAG = "HSUNextWidget"

        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, NextClassWidgetProvider::class.java))
            if (ids.isEmpty()) return
            val json = runCatching {
                HomeWidgetPlugin.getData(context).getString("schedule_widget", null)?.let { JSONObject(it) }
            }.onFailure { Log.w(TAG, "read failed", it) }.getOrNull()
            for (id in ids) {
                try {
                    val options = manager.getAppWidgetOptions(id)
                    val width = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 180)
                    val views = RemoteViews(context.packageName, R.layout.widget_next)
                    views.setImageViewBitmap(R.id.widget_next_image, render(context, json, width))
                    val openIntent = Intent(context, MainActivity::class.java).apply {
                        action = Intent.ACTION_MAIN
                        addCategory(Intent.CATEGORY_LAUNCHER)
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    }
                    val pi = PendingIntent.getActivity(context, 42, openIntent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
                    views.setOnClickPendingIntent(R.id.widget_next_root, pi)
                    manager.updateAppWidget(id, views)
                } catch (t: Throwable) {
                    Log.e(TAG, "update failed", t)
                }
            }
        }

        private fun render(context: Context, json: JSONObject?, widthDp: Int): Bitmap {
            val bmpW = 560
            val bmpH = 280
            val bitmap = Bitmap.createBitmap(bmpW, bmpH, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            val night = (context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES
            val onSurface = if (night) 0xFFE3E3E3.toInt() else 0xFF1F1F1F.toInt()
            val secondary = if (night) 0xFF9AA0A6.toInt() else 0xFF5F6368.toInt()
            val accent = try {
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) context.getColor(android.R.color.system_accent1_500)
                else Color.parseColor("#0B57D0")
            } catch (_: Throwable) {
                Color.parseColor("#0B57D0")
            }
            val pixelFont = json?.optString("fontStyle") == "pixel"
            val bodyTypeface = Typeface.createFromAsset(context.assets, if (pixelFont) "FusionPixel12.ttf" else "FangSongGB.ttf")
            val timeTypeface = if (pixelFont) bodyTypeface else Typeface.createFromAsset(context.assets, "TimesNewRoman.ttf")
            val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                typeface = bodyTypeface
                color = onSurface
            }
            val course = json?.optString("nextCourse", "").orEmpty()
            val start = json?.optString("nextStart", "").orEmpty()
            val end = json?.optString("nextEnd", "").orEmpty()
            val room = json?.optString("nextRoom", "").orEmpty()
            val teacher = json?.optString("nextTeacher", "").orEmpty()
            val empty = course.isEmpty()
            val pad = 22f
            if (empty) {
                paint.color = onSurface
                paint.textSize = 44f
                canvas.drawText(fit(paint, "今天没有更多课", bmpW - pad * 2), pad, 120f, paint)
                paint.color = secondary
                paint.textSize = 24f
                canvas.drawText("课程表", pad, 172f, paint)
                return bitmap
            }
            paint.color = secondary
            paint.textSize = 24f
            canvas.drawText(fit(paint, listOf(room, teacher).filter { it.isNotEmpty() }.joinToString(" · "), bmpW - pad * 2), pad, 42f, paint)
            paint.color = onSurface
            paint.textSize = 56f
            canvas.drawText(fit(paint, course, bmpW - pad * 2), pad, 112f, paint)
            paint.color = accent
            paint.textSize = 38f
            paint.typeface = timeTypeface
            val time = if (start.isEmpty()) "" else if (end.isEmpty()) start else "$start–$end"
            canvas.drawText(time, pad, 172f, paint)
            paint.typeface = bodyTypeface
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
