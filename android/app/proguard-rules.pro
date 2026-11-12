# PDFBox's optional JPX/JP2 image filters reference the Gemalto decoder, which
# this app does not ship. PDFs using those filters fall back to the existing
# "no extractable text" path; everything else in PDFBox is kept normally.
-dontwarn com.gemalto.jp2.**

# Keep the widget providers and the FlutterActivity entry points referenced
# only from the manifest (AGP keeps manifest classes, this is belt and braces
# for the home_widget reflection path).
-keep class com.hsu.hsu_schedule.** { *; }