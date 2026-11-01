/*
 * Adapted from Classy (https://github.com/IMSX3D/Classy), commit 8a2499d.
 * Copyright (C) IMSX3D and contributors.
 * Licensed under GNU GPL v3.0; see LICENSE and NOTICE.
 * Modified for course-table integration.
 */
package com.hsu.hsu_schedule

import com.imsx3d.classy.data.jw.JwCourse
import com.imsx3d.classy.data.jw.JwParserRegistry

/** Bridges Classy's GPL-3.0 Kotlin parser layer to Flutter. */
object ClassyParserBridge {
    fun parse(html: String, type: String): List<Map<String, Any>> {
        val courses: List<JwCourse> = try {
            if (type.isNotBlank() && type != "community") {
                JwParserRegistry.parserFor(type, html).generateCourseList()
            } else {
                JwParserRegistry.selectBest(html, null).first
            }
        } catch (_: Throwable) {
            JwParserRegistry.selectBest(html, type.ifBlank { null }).first
        }
        return courses.map {
            mapOf(
                "name" to it.name,
                "room" to it.room,
                "teacher" to it.teacher,
                "day" to it.day,
                "startPeriod" to it.startNode,
                "endPeriod" to it.endNode,
                "startWeek" to it.startWeek,
                "endWeek" to it.endWeek,
                "weekType" to it.type,
            )
        }
    }
}
