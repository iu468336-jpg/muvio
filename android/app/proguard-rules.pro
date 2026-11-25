-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep libtorrent4j JNI classes
-keep class org.libtorrent4j.** { *; }
-dontwarn org.libtorrent4j.**

# Keep NanoHTTPD
-keep class fi.iki.elonen.** { *; }

# Keep media_kit / libmpv native bindings
-keep class com.alexmercerind.** { *; }
-dontwarn com.alexmercerind.**
