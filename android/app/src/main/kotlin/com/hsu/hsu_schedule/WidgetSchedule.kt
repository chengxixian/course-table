package com.hsu.hsu_schedule

import org.json.JSONArray
import org.json.JSONObject
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit

/**
 * Recomputes the derived widget fields from the raw course list at render
 * time, so the 30-minute system redraw shows the *current* next class instead
 * of whatever was true when the app last published the payload.
 *
 * Falls back to the frozen fields when the payload predates `allCourses`
 * (installed update, widget refresh before the app has been opened once).
 */
object WidgetSchedule {

    private val WEEKDAY_LABELS = arrayOf("周一", "周二", "周三", "周四", "周五", "周六", "周日")

    private data class Entry(
        val day: Int,
        val weeks: Set<Int>,
        val period: Int,
        val span: Int,
        val name: String,
        val room: String,
        val teacher: String,
        val colorIndex: Int,
        val startMin: Int,
        val endMin: Int,
        val time: String,
        val end: String,
    )

    fun refresh(raw: JSONObject?): JSONObject? {
        if (raw == null) return null
        val arr = raw.optJSONArray("allCourses") ?: return raw
        val startText = raw.optString("semesterStart")
        val start = runCatching { LocalDate.parse(startText, DateTimeFormatter.ISO_LOCAL_DATE) }.getOrNull()
            ?: return raw
        val totalWeeks = raw.optInt("totalWeeks", 20).coerceAtLeast(1)

        val entries = mutableListOf<Entry>()
        for (i in 0 until arr.length()) {
            val o = arr.optJSONObject(i) ?: continue
            val weeksArray = o.optJSONArray("weeks")
            val weekSet: Set<Int> = if (weeksArray != null && weeksArray.length() > 0) {
                (0 until weeksArray.length()).map { weeksArray.optInt(it) }.toSet()
            } else {
                (1..totalWeeks).toSet()
            }
            entries.add(
                Entry(
                    day = o.optInt("day", 1),
                    weeks = weekSet,
                    period = o.optInt("period", 1),
                    span = o.optInt("span", 1),
                    name = o.optString("name"),
                    room = o.optString("room"),
                    teacher = o.optString("teacher"),
                    colorIndex = o.optInt("colorIndex", 0),
                    startMin = o.optInt("startMin", 0),
                    endMin = o.optInt("endMin", 0),
                    time = o.optString("time"),
                    end = o.optString("end"),
                ),
            )
        }

        val now = LocalDateTime.now()
        val nowMin = now.hour * 60 + now.minute
        val out = JSONObject(raw.toString())

        fun meetingsOn(offsetDays: Long): List<Entry> {
            val date = now.toLocalDate().plusDays(offsetDays)
            val w = weekOf(start, totalWeeks, date)
            if (w <= 0) return emptyList()
            val day = date.dayOfWeek.value
            return entries.filter { it.day == day && it.weeks.contains(w) }.sortedBy { it.startMin }
        }

        val week = weekOf(start, totalWeeks, now.toLocalDate())
        val todayFull = meetingsOn(0)
        val upcoming = todayFull.filter { it.endMin > nowMin }

        out.put("rows", rowsOf(if (upcoming.isNotEmpty()) upcoming else todayFull, 3))
        out.put("morningRows", rowsOf(todayFull.filter { it.startMin < 12 * 60 }, 4))
        out.put("tomorrowRows", rowsOf(meetingsOn(1), 3))

        var nextEntry: Entry? = null
        var nextOffset = 0L
        outer@ for (offset in 0L..6L) {
            for (e in meetingsOn(offset)) {
                if (offset == 0L && e.endMin <= nowMin) continue
                nextEntry = e
                nextOffset = offset
                break@outer
            }
        }
        val n = nextEntry
        if (n == null) {
            out.put("nextCourse", "")
            out.put("nextSummary", if (week > 0) "今日课程已结束" else "假期中")
        } else {
            val ongoing = nextOffset == 0L && n.startMin <= nowMin
            out.put("nextCourse", n.name)
            out.put("nextStart", n.time)
            out.put("nextEnd", n.end)
            out.put("nextRoom", n.room)
            out.put("nextTeacher", n.teacher)
            val prefix = when (nextOffset) {
                0L -> ""
                1L -> "明天 "
                else -> {
                    val d = now.toLocalDate().plusDays(nextOffset)
                    "${d.monthValue}月${d.dayOfMonth}日 "
                }
            }
            out.put(
                "nextSummary",
                if (ongoing) "正在上课 · ${n.name}" else "下一节 $prefix${n.time}  ${n.name}",
            )
        }

        out.put("footer", if (todayFull.isEmpty()) "今天没有课 · 课程表" else "今日 ${todayFull.size} 节 · 课程表")
        out.put("week", if (week > 0) "第 $week 周" else "假期")
        out.put("dateLabel", "${now.monthValue}月${now.dayOfMonth}日 · ${WEEKDAY_LABELS[now.dayOfWeek.value - 1]}")

        val cells = JSONArray()
        if (week > 0) {
            for (e in entries.filter { it.day in 1..5 && it.weeks.contains(week) }) {
                cells.put(
                    JSONObject()
                        .put("day", e.day)
                        .put("period", e.period)
                        .put("span", e.span)
                        .put("name", e.name)
                        .put("room", e.room)
                        .put("colorIndex", e.colorIndex),
                )
            }
        }
        out.put("weekCourses", cells)
        return out
    }

    private fun rowsOf(list: List<Entry>, n: Int): JSONArray {
        val a = JSONArray()
        list.take(n).forEach {
            a.put(
                JSONObject()
                    .put("time", it.time)
                    .put("end", it.end)
                    .put("name", it.name)
                    .put("room", if (it.room.isNotEmpty()) it.room else it.teacher)
                    .put("colorIndex", it.colorIndex),
            )
        }
        return a
    }

    private fun weekOf(start: LocalDate, totalWeeks: Int, date: LocalDate): Int {
        val days = ChronoUnit.DAYS.between(start, date)
        if (days < 0) return 0
        val w = (days / 7).toInt() + 1
        return if (w in 1..totalWeeks) w else 0
    }
}
