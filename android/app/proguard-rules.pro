# Flutter ProGuard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# SQLCipher and SQLite
-keep class net.sqlcipher.** { *; }
-keep class net.sqlcipher.database.** { *; }
-keep class org.sqlite.** { *; }
-dontwarn net.sqlcipher.**

# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# Google Sign-In & Google APIs
-keep class com.google.android.gms.auth.api.signin.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.google.api.client.** { *; }
-dontwarn com.google.android.gms.**
-dontwarn com.google.api.client.**

# Open Cloud Health Native Receivers & Activities
-keep class com.opencloudhealth.app.** { *; }
-keepclassmembers class com.opencloudhealth.app.** { *; }

# Drift / Sqlite3 native libraries
-keep class com.simonoid.** { *; }
