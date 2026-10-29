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
import android.util.Log
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONObject

class WeekGridWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) = updateAll(context)
    override fun onAppWidgetOptionsChanged(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int, newOptions: android.os.Bundle) = updateAll(context)

    companion object {
        private const val TAG = "HSUWeekWidget"
        private val COLORS = intArrayOf(0xFF0B57D0.toInt(), 0xFF0F9D58.toInt(), 0xFF9C27B0.toInt(), 0xFFE8710A.toInt(), 0xFFC2185B.toInt(), 0xFF00838F.toInt())

        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, WeekGridWidgetProvider::class.java))
            if (ids.isEmpty()) return
            val json = runCatching { HomeWidgetPlugin.getData(context).getString("schedule_widget", null)?.let { JSONObject(it) } }.getOrNull()
            for (id in ids) {
                try {
                    val views = RemoteViews(context.packageName, R.layout.widget_week)
                    views.setImageViewBitmap(R.id.widget_week_image, render(context, json))
                    val pi = PendingIntent.getActivity(context, 44, Intent(context, MainActivity::class.java).apply {
                        action = Intent.ACTION_MAIN
                        addCategory(Intent.CATEGORY_LAUNCHER)
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    }, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
                    views.setOnClickPendingIntent(R.id.widget_week_root, pi)
                    manager.updateAppWidget(id, views)
                } catch (t: Throwable) { Log.e(TAG, "update failed", t) }
            }
        }

        private fun render(context: Context, json: JSONObject?): Bitmap {
            val size = 560
            val bmp = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bmp)
            val night = (context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES
            val onSurface = if (night) 0xFFE3E3E3.toInt() else 0xFF1F1F1F.toInt()
            val secondary = if (night) 0xFF9AA0A6.toInt() else 0xFF5F6368.toInt()
            val pixel = json?.optString("fontStyle") == "pixel"
            val tf = Typeface.createFromAsset(context.assets, if (pixel) "FusionPixel12.ttf" else "FangSongGB.ttf")
            val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { typeface = tf; color = onSurface }
            paint.textSize = 26f
            canvas.drawText(json?.optString("week", "课程表").orEmpty(), 22f, 38f, paint)
            paint.color = secondary
            paint.textSize = 16f
            canvas.drawText(json?.optString("dateLabel", "").orEmpty(), 22f, 62f, paint)
            val days = arrayOf("周一", "周二", "周三", "周四", "周五")
            val left = 42f
            val top = 82f
            val cellW = (size - left - 12f) / 5f
            val cellH = 72f
            paint.textSize = 17f
            for (d in 0..4) {
                paint.color = onSurface
                val x = left + d * cellW + cellW / 2 - paint.measureText(days[d]) / 2
                canvas.drawText(days[d], x, top - 10f, paint)
            }
            paint.textSize = 12f
            for (p in 1..6) {
                paint.color = secondary
                canvas.drawText(p.toString(), 12f, top + (p - 1) * cellH + 30f, paint)
            }
            val arr = json?.optJSONArray("weekCourses")
            if (arr == null || arr.length() == 0) {
                paint.color = secondary
                paint.textSize = 28f
                canvas.drawText("本周没有课", 170f, 300f, paint)
                return bmp
            }
            for (i in 0 until arr.length()) {
                val o = arr.optJSONObject(i) ?: continue
                val day = o.optInt("day", 1)
                val period = o.optInt("period", 1)
                val span = o.optInt("span", 1).coerceAtLeast(1)
                if (day !in 1..5 || period !in 1..6) continue
                val x = left + (day - 1) * cellW + 3f
                val y = top + (period - 1) * cellH + 3f
                val w = cellW - 6f
                val h = span * cellH - 6f
                val color = COLORS[o.optInt("colorIndex", 0).mod(COLORS.size)]
                val fill = Paint(Paint.ANTI_ALIAS_FLAG).apply { this.color = Color.argb(225, Color.red(color), Color.green(color), Color.blue(color)) }
                canvas.drawRoundRect(RectF(x, y, x + w, y + h), 10f, 10f, fill)
                paint.color = Color.WHITE
                paint.textSize = 17f
                val name = o.optString("name", "")
                val line = if (name.length > 7) name.substring(0, 7) else name
                canvas.drawText(line, x + 8f, y + 28f, paint)
                paint.textSize = 12f
                val room = o.optString("room", "")
                canvas.drawText(if (room.length > 8) room.substring(0, 8) else room, x + 8f, y + 48f, paint)
            }
            return bmp
        }
    }
}
