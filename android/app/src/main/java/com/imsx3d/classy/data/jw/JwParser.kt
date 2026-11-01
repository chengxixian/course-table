package com.imsx3d.classy.data.jw


/**
 * 鏁欏姟绯荤粺 HTML 瑙ｆ瀽鍣ㄦ娊璞″熀绫汇€? *
 * 璁捐鏉ヨ嚜 dIT8Zv/WakeupSchedule_BUPT (Apache-2.0) 鐨?Parser.kt
 * (https://github.com/dIT8Zv/WakeupSchedule_BUPT/blob/master/app/src/main/java/com/suda/yzune/wakeupschedule/schedule_import/parser/Parser.kt)
 *
 * 绠€鍖栫偣锛? *   - 鍘绘帀浜?[saveCourse] / [convertCourse] 涓 wakeup 绉佹湁 bean 鐨勪緷璧? *   - 鏀规垚鐩存帴杈撳嚭 List<JwCourse>锛岀敱 [JwImportViewModel] 缁熶竴杞?[CourseEntity]
 *   - 鍘绘帀浜?Context 渚濊禆锛堥鑹茬敓鎴愮瓑鏀惧埌 ViewModel 灞傦級
 *
 * 鐢ㄦ硶锛? *   ```
 *   val courses = JwQzCrazyParser(html).generateCourseList()
 *   ```
 */
abstract class JwParser(val source: String) {

    /**
     * 瑙ｆ瀽鏁欏姟 HTML 婧愮爜锛岃緭鍑虹粺涓€缁撴瀯鐨勮绋嬪垪琛?     */
    abstract fun generateCourseList(): List<JwCourse>

    /**
     * T8 鏂板锛氬熀浜?HTML 缁撴瀯閿氱偣鐨勫懡涓疆淇″害锛?..100锛夈€?     *
     * 瑙勫垯锛?     *   - 鍛戒腑鍗忚鏃忓敮涓€閿氱偣锛堝 Table1 / kbtable / kbxx / datagrid锛夛細80..100
     *   - 鍛戒腑鍗忚鏃忓父瑙侀敋鐐癸紙font[title=鑰佸笀] 绛夊崟鍏冩牸绾э級锛?0..79
     *   - 浠呴潬瑙ｆ瀽缁撴灉鍙嶆帹锛堟棤娉曡瘉浼級锛?..49
     *   - 鍏滃簳杩斿洖 0
     *
     * 瀹炵幇瑕佺偣锛?     *   - confidence 涓嶈皟 generateCourseList锛堥伩鍏?N+1锛夛紝鍙湅 HTML 闈欐€佺壒寰?     *   - confidence 涓嶄緷璧栧崗璁被鍨嬩笂涓嬫枃锛圧egistry 灞傚仛浼樺厛绾ц鍐筹級
     */
    open fun confidence(): Int = 0

    /**
     * T8 鏂板锛氭湰 parser 瀹為檯鍛戒腑鐨?HTML 閿氱偣鍒楄〃锛堢敤浜庤瘖鏂緭鍑猴級銆?     * 榛樿绌猴紝瀛愮被鎸夐渶瑕嗙洊銆?     */
    open fun matchedFeatures(): List<String> = emptyList()
}

