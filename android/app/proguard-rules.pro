# Prevent R8 from stripping/obfuscating WorkManager's Room database.
# See: "Failed to create an instance of androidx.work.impl.WorkDatabase"
-keep class androidx.work.** { *; }
-keep class * extends androidx.room.RoomDatabase { *; }
-keep class *._Impl { *; }
-dontwarn androidx.work.**
-dontwarn androidx.room.**