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
import android.graphics.Paint
import android.graphics.Typeface
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray
import org.json.JSONObject

class TwoDayWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) = updateAll(context)
    override fun onAppWidgetOptionsChanged(context: Context, manager: AppWidgetManager, id: Int, options: android.os.Bundle) = updateAll(context)

    companion object {
        private val COLORS = intArrayOf(
            0xFF039BE5.toInt(), 0xFF33B679.toInt(), 0xFF8E24AA.toInt(),
            0xFFE67C73.toInt(), 0xFFF6BF26.toInt(), 0xFF7986CB.toInt(), 0xFFF4511E.toInt(),
        )

        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, TwoDayWidgetProvider::class.java))
            if (ids.isEmpty()) return
            val json = runCatching {
                HomeWidgetPlugin.getData(context).getString("schedule_widget", null)?.let { JSONObject(it) }
            }.getOrNull()
            for (id in ids) {
                try {
                    val views = RemoteViews(context.packageName, R.layout.widget_twoday)
                    views.setImageViewBitmap(R.id.widget_twoday_image, render(context, json))
                    val open = Intent(context, MainActivity::class.java).apply {
                        action = Intent.ACTION_MAIN
                        addCategory(Intent.CATEGORY_LAUNCHER)
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    }
                    val pi = PendingIntent.getActivity(
                        context, 45, open,
                        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
                    )
                    views.setOnClickPendingIntent(R.id.widget_twoday_root, pi)
                    manager.updateAppWidget(id, views)
                } catch (_: Throwable) {
                }
            }
        }

        private fun render(context: Context, json: JSONObject?): Bitmap {
            val bitmap = Bitmap.createBitmap(560, 280, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            val night = (context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES
            val fg = if (night) 0xFFE3E3E3.toInt() else 0xFF1F1F1F.toInt()
            val sub = if (night) 0xFF9AA0A6.toInt() else 0xFF5F6368.toInt()
            val pixel = json?.optString("fontStyle") == "pixel"
            val body = Typeface.createFromAsset(context.assets, if (pixel) "FusionPixel12.ttf" else "FandolFang-Regular.otf")
            val time = if (pixel) body else Typeface.createFromAsset(context.assets, "LiberationSerif-Regular.ttf")
            val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { typeface = body; color = fg }
            paint.textSize = 22f
            canvas.drawText("今天", 24f, 32f, paint)
            canvas.drawText("明天", 292f, 32f, paint)
            drawList(canvas, json?.optJSONArray("rows"), 24f, 48f, 244f, paint, body, time, fg, sub)
            drawList(canvas, json?.optJSONArray("tomorrowRows"), 292f, 48f, 244f, paint, body, time, fg, sub)
            return bitmap
        }

        private fun drawList(
            canvas: Canvas, arr: JSONArray?, x: Float, top: Float, width: Float,
            paint: Paint, body: Typeface, time: Typeface, fg: Int, sub: Int,
        ) {
            if (arr == null || arr.length() == 0) {
                paint.typeface = body
                paint.color = sub
                paint.textSize = 18f
                canvas.drawText("没有课程", x, top + 34f, paint)
                return
            }
            var y = top
            for (i in 0 until minOf(arr.length(), 3)) {
                val o = arr.optJSONObject(i) ?: continue
                val color = COLORS[o.optInt("colorIndex", 0).mod(COLORS.size)]
                val bar = Paint(Paint.ANTI_ALIAS_FLAG).apply { this.color = color }
                canvas.drawRoundRect(x, y + 4f, x + 4f, y + 62f, 2f, 2f, bar)
                paint.typeface = time
                paint.color = color
                paint.textSize = 16f
                canvas.drawText(o.optString("time", ""), x + 12f, y + 22f, paint)
                paint.typeface = body
                paint.color = fg
                paint.textSize = 20f
                canvas.drawText(fit(paint, o.optString("name", ""), width - 12f), x + 12f, y + 47f, paint)
                paint.color = sub
                paint.textSize = 13f
                val room = o.optString("room", "")
                if (room.isNotBlank()) canvas.drawText(fit(paint, room, width - 12f), x + 12f, y + 64f, paint)
                y += 76f
            }
        }

        private fun fit(paint: Paint, value: String, maxWidth: Float): String {
            if (paint.measureText(value) <= maxWidth) return value
            var end = value.length
            while (end > 1 && paint.measureText(value.substring(0, end) + "…") > maxWidth) end--
            return value.substring(0, end) + "…"
        }
    }
}
