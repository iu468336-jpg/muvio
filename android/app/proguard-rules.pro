-keepattributes SourceFile,LineNumberTable
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-keepattributes RuntimeVisibleAnnotations

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

# Keep Nuvio C++ P2P Engine JNI classes & reflective payloads
-keep class com.nuvio.engine.** { *; }
-keep interface com.nuvio.engine.** { *; }
-dontwarn com.nuvio.engine.**

# Keep QuickJS JNI bindings
-keep class com.dokar.quickjs.** { *; }
-keep interface com.dokar.quickjs.** { *; }
-dontwarn com.dokar.quickjs.**

# Keep AndroidX Media3 + Jellyfin FFmpeg decoder JNI bindings
-keep class androidx.media3.** { *; }
-keep interface androidx.media3.** { *; }
-dontwarn androidx.media3.**
-keep class org.jellyfin.media3.** { *; }
-dontwarn org.jellyfin.media3.**

# OkHttp optional security providers
-dontwarn okhttp3.internal.platform.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**

-keepclasseswithmembernames class * {
    native <methods>;
}
-keep class app.muvio.mobile.** { *; }
