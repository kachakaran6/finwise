# Flutter ProGuard / R8 Rules for Finwise Release
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Flutter Engine and Wrapper
-dontwarn io.flutter.embedding.**

# Keep Google Play Core In-App Update
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Keep Google Play In-App Review & Play Core KTX
-keep class com.google.android.play.core.review.** { *; }
-dontwarn com.google.android.gms.**

# Keep SQLite native methods
-keep class com.tekartik.sqflite.** { *; }
