# 保护 Flutter 核心类
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# 保护 Google/Android 官方兼容库
-keep class androidx.** { *; }
-keep class com.google.** { *; }

# 如果使用了 Dio 网络库/Gson 序列化
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# 忽略混淆警告
-dontwarn io.flutter.**
-dontwarn androidx.**