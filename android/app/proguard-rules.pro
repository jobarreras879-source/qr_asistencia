# ======================================================
# ProGuard Rules - QR Asistencia
# Protección contra ingeniería inversa del APK
# ======================================================

# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google Sign In
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Supabase / OkHttp / Retrofit
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**

# Evitar que se eliminen las clases necesarias
-keep class com.google.crypto.tink.** { *; }

# Ofuscar los nombres de clases y métodos
-renamesourcefileattribute SourceFile
-keepattributes SourceFile,LineNumberTable

# Prevenir crashes con serialización
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Google Play Core (requerido por Flutter)
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task
