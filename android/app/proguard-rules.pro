-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Flutter Play Store deferred components optional classes (not used in standalone APK)
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# Keep libtorrent4j JNI classes
-keep class org.libtorrent4j.** { *; }
-dontwarn org.libtorrent4j.**

# Keep NanoHTTPD
-keep class fi.iki.elonen.** { *; }
-dontwarn fi.iki.elonen.**

# Keep AndroidX Media3 + Jellyfin FFmpeg decoder JNI bindings
-keep class androidx.media3.** { *; }
-dontwarn androidx.media3.**
-keepclasseswithmembernames class * {
    native <methods>;
}
-keep class app.muvio.mobile.** { *; }
