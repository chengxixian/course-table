package com.hsu.hsu_schedule

import android.Manifest
import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.provider.CalendarContract.Calendars
import android.provider.CalendarContract.Events
import android.provider.CalendarContract.Reminders
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import androidx.core.content.FileProvider
import java.io.File
import com.tom_roush.pdfbox.pdmodel.PDDocument
import com.tom_roush.pdfbox.text.PDFTextStripper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

class MainActivity : FlutterActivity() {
    private val channelName = "com.hsu.hsu_schedule/calendar"
    private val secureChannelName = "com.hsu.hsu_schedule/secure"
    private val installChannelName = "com.hsu.hsu_schedule/install"
    private val importChannelName = "com.hsu.hsu_schedule/import"
    private val classyChannelName = "com.hsu.hsu_schedule/classy_parser"
    private var pendingResult: MethodChannel.Result? = null
    private var pendingEvents: List<Map<String, Any>>? = null
    private var pendingCalendarId: Long? = null

    override fun onResume() {
        super.onResume()
        runCatching { ScheduleWidgetProvider.updateAll(this) }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, secureChannelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveCredentials" -> {
                    try {
                        val username = call.argument<String>("username").orEmpty()
                        val password = call.argument<String>("password").orEmpty()
                        if (username.isBlank() || password.isBlank()) {
                            result.error("BAD_INPUT", "用户名或密码为空", null)
                        } else {
                            saveSecureCredentials(username, password)
                            result.success(true)
                        }
                    } catch (t: Throwable) {
                        result.error("SECURE_SAVE_FAILED", t.message ?: "保存失败", null)
                    }
                }
                "readCredentials" -> {
                    try {
                        result.success(readSecureCredentials())
                    } catch (t: Throwable) {
                        result.error("SECURE_READ_FAILED", t.message ?: "读取失败", null)
                    }
                }
                "clearCredentials" -> {
                    getSharedPreferences(SECURE_PREFS, Context.MODE_PRIVATE).edit().remove(SECURE_KEY).apply()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasCalendarPermission" -> result.success(hasCalendarPermission())
                "listCalendars" -> Thread {
                    try {
                        val list = queryWritableCalendars().map { mapOf(
                            "id" to it.id, "name" to it.name,
                            "accountName" to it.accountName, "accountType" to it.accountType) }
                        runOnUiThread { result.success(list) }
                    } catch (t: Throwable) {
                        runOnUiThread { result.error("LIST_CALENDAR_FAILED", t.message ?: "无法读取日历列表", null) }
                    }
                }.start()
                "insertEvents" -> {
                    val events = readEvents(call)
                    if (events.isEmpty()) {
                        result.error("EMPTY", "没有可写入的课程事件", null)
                    } else {
                        insertOrRequest(events, result, (call.argument<Number>("calendarId"))?.toLong())
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun readEvents(call: MethodCall): List<Map<String, Any>> {
        val raw = call.argument<List<*>>("events") ?: return emptyList()
        return raw.filterIsInstance<Map<*, *>>().mapNotNull { item ->
            val map = item.entries.associate { it.key.toString() to (it.value ?: "") }
            @Suppress("UNCHECKED_CAST")
            map as? Map<String, Any>
        }
    }

    private fun hasCalendarPermission(): Boolean {
        return checkSelfPermission(Manifest.permission.READ_CALENDAR) == PackageManager.PERMISSION_GRANTED &&
            checkSelfPermission(Manifest.permission.WRITE_CALENDAR) == PackageManager.PERMISSION_GRANTED
    }

    private fun insertOrRequest(events: List<Map<String, Any>>, result: MethodChannel.Result, calendarId: Long? = null) {
        if (hasCalendarPermission()) {
            insertEvents(events, result, calendarId)
            return
        }
        pendingResult = result
        pendingEvents = events
        pendingCalendarId = calendarId
        requestPermissions(
            arrayOf(Manifest.permission.READ_CALENDAR, Manifest.permission.WRITE_CALENDAR),
            CALENDAR_PERMISSION_REQUEST,
        )
    }

    private fun getOrCreateSecureKey(): SecretKey {
        val keyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        (keyStore.getEntry(SECURE_ALIAS, null) as? KeyStore.SecretKeyEntry)?.let { return it.secretKey }
        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
        generator.init(
            KeyGenParameterSpec.Builder(SECURE_ALIAS, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                .build(),
        )
        return generator.generateKey()
    }

    private fun saveSecureCredentials(username: String, password: String) {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, getOrCreateSecureKey())
        val plain = JSONObject().put("username", username).put("password", password).toString().toByteArray(Charsets.UTF_8)
        val encrypted = cipher.doFinal(plain)
        val blob = Base64.encodeToString(cipher.iv + encrypted, Base64.NO_WRAP)
        getSharedPreferences(SECURE_PREFS, Context.MODE_PRIVATE).edit().putString(SECURE_KEY, blob).apply()
    }

    private fun readSecureCredentials(): Map<String, String>? {
        val encoded = getSharedPreferences(SECURE_PREFS, Context.MODE_PRIVATE).getString(SECURE_KEY, null) ?: return null
        val blob = Base64.decode(encoded, Base64.NO_WRAP)
        if (blob.size < 13) return null
        val iv = blob.copyOfRange(0, 12)
        val encrypted = blob.copyOfRange(12, blob.size)
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.DECRYPT_MODE, getOrCreateSecureKey(), GCMParameterSpec(128, iv))
        val obj = JSONObject(String(cipher.doFinal(encrypted), Charsets.UTF_8))
        return mapOf("username" to obj.optString("username"), "password" to obj.optString("password"))
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != CALENDAR_PERMISSION_REQUEST) return
        val result = pendingResult
        val events = pendingEvents
        val calendarId = pendingCalendarId
        pendingResult = null
        pendingEvents = null
        pendingCalendarId = null
        if (result == null) return
        if (hasCalendarPermission()) {
            if (events != null) insertEvents(events, result, calendarId) else result.error("EMPTY", "没有可写入的课程事件", null)
        } else {
            result.error("PERMISSION_DENIED", "需要日历读写权限才能导入全部课程", null)
        }
    }

    private fun insertEvents(events: List<Map<String, Any>>, result: MethodChannel.Result, calendarId: Long? = null) {
        Thread {
            try {
                val calendars = queryWritableCalendars()
                if (calendars.isEmpty()) {
                    runOnUiThread { result.error("NO_CALENDAR", "没有找到可写入的系统日历，请先添加日历账号", null) }
                    return@Thread
                }
                val target = calendarId?.let { id -> calendars.firstOrNull { it.id == id } }
                    ?: calendars.firstOrNull { it.accountType == "com.google" } ?: calendars.first()
                var inserted = 0
                var skipped = 0
                for (event in events) {
                    val title = event["title"]?.toString().orEmpty()
                    val start = (event["start"] as? Number)?.toLong() ?: continue
                    val end = (event["end"] as? Number)?.toLong() ?: continue
                    if (exists(target.id, title, start)) {
                        skipped++
                        continue
                    }
                    val values = ContentValues().apply {
                        put(Events.CALENDAR_ID, target.id)
                        put(Events.TITLE, title)
                        put(Events.DESCRIPTION, event["description"]?.toString().orEmpty())
                        put(Events.EVENT_LOCATION, event["location"]?.toString().orEmpty())
                        put(Events.DTSTART, start)
                        put(Events.DTEND, end)
                        put(Events.ALL_DAY, 0)
                        put(Events.EVENT_TIMEZONE, "Asia/Shanghai")
                        put(Events.EVENT_END_TIMEZONE, "Asia/Shanghai")
                        put(Events.HAS_ALARM, 1)
                        put(Events.STATUS, Events.STATUS_CONFIRMED)
                    }
                    val uri = contentResolver.insert(Events.CONTENT_URI, values) ?: continue
                    val eventId = ContentUris.parseId(uri)
                    val reminder = ContentValues().apply {
                        put(Reminders.EVENT_ID, eventId)
                        put(Reminders.MINUTES, 10)
                        put(Reminders.METHOD, Reminders.METHOD_ALERT)
                    }
                    runCatching { contentResolver.insert(Reminders.CONTENT_URI, reminder) }
                    inserted++
                }
                val payload = mapOf(
                    "inserted" to inserted,
                    "skipped" to skipped,
                    "calendarName" to target.name,
                    "accountType" to target.accountType,
                    "accountName" to target.accountName,
                )
                runOnUiThread { result.success(payload) }
            } catch (t: Throwable) {
                runOnUiThread { result.error("INSERT_FAILED", t.message ?: "写入日历失败", null) }
            }
        }.start()
    }

    private fun queryWritableCalendars(): List<CalendarTarget> {
        val out = mutableListOf<CalendarTarget>()
        val projection = arrayOf(
            Calendars._ID,
            Calendars.CALENDAR_DISPLAY_NAME,
            Calendars.ACCOUNT_NAME,
            Calendars.ACCOUNT_TYPE,
            Calendars.CALENDAR_ACCESS_LEVEL,
            Calendars.VISIBLE,
        )
        val selection = "${Calendars.CALENDAR_ACCESS_LEVEL} >= ? AND ${Calendars.VISIBLE} = 1"
        val args = arrayOf(Calendars.CAL_ACCESS_CONTRIBUTOR.toString())
        contentResolver.query(Calendars.CONTENT_URI, projection, selection, args, null)?.use { cursor ->
            val idCol = cursor.getColumnIndexOrThrow(Calendars._ID)
            val nameCol = cursor.getColumnIndexOrThrow(Calendars.CALENDAR_DISPLAY_NAME)
            val accountCol = cursor.getColumnIndexOrThrow(Calendars.ACCOUNT_NAME)
            val typeCol = cursor.getColumnIndexOrThrow(Calendars.ACCOUNT_TYPE)
            while (cursor.moveToNext()) {
                out += CalendarTarget(
                    id = cursor.getLong(idCol),
                    name = cursor.getString(nameCol) ?: "日历",
                    accountName = cursor.getString(accountCol).orEmpty(),
                    accountType = cursor.getString(typeCol).orEmpty(),
                )
            }
        }
        out.sortBy { if (it.accountType == "com.google") 0 else 1 }
        return out
    }

    private fun exists(calendarId: Long, title: String, start: Long): Boolean {
        val projection = arrayOf(Events._ID)
        val selection = "${Events.CALENDAR_ID} = ? AND ${Events.TITLE} = ? AND ${Events.DTSTART} = ?"
        contentResolver.query(
            Events.CONTENT_URI,
            projection,
            selection,
            arrayOf(calendarId.toString(), title, start.toString()),
            null,
        )?.use { cursor -> if (cursor.moveToFirst()) return true }
        return false
    }

    private data class CalendarTarget(
        val id: Long,
        val name: String,
        val accountName: String,
        val accountType: String,
    )

    companion object {
        private const val CALENDAR_PERMISSION_REQUEST = 7012
        private const val SECURE_ALIAS = "hsu_schedule_credentials"
        private const val SECURE_PREFS = "hsu_secure_store"
        private const val SECURE_KEY = "credentials"
    }
}

