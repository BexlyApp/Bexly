# Flutter & Dart specific rules
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep HugeIcons (was causing crashes when minified)
-keep class com.hugeicons.** { *; }
-dontwarn com.hugeicons.**

# Keep Google Sign In
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Keep Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Keep Stripe
-keep class com.stripe.** { *; }
-dontwarn com.stripe.**

# Keep Supabase/GoTrue
-keep class io.supabase.** { *; }
-dontwarn io.supabase.**

# Keep SQLite/Drift
-keep class org.sqlite.** { *; }
-keep class sqlite.** { *; }
-dontwarn org.sqlite.**
-dontwarn sqlite.**

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Parcelable
-keepclassmembers class * implements android.os.Parcelable {
    static ** CREATOR;
}

# Keep Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Keep R8 from stripping interface methods
-keepclassmembers,allowobfuscation interface * {
    @retrofit2.http.* <methods>;
}

# OkHttp / Retrofit (if used)
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn retrofit2.**
-keep class retrofit2.** { *; }
-keep class okhttp3.** { *; }

# Facebook Auth
-keep class com.facebook.** { *; }
-dontwarn com.facebook.**

# WorkManager (background tasks)
-keep class androidx.work.** { *; }
-dontwarn androidx.work.**

# Prevent crashes from missing classes
-dontwarn javax.annotation.**
-dontwarn kotlin.Unit
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**

# Google Play Core (deferred components) - not used but referenced by Flutter
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# Keep enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
