# ---- Razorpay SDK ----
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**

# Fix R8 complaining about old ProGuard annotations referenced by SDK
-dontwarn proguard.annotation.Keep
-dontwarn proguard.annotation.KeepClassMembers

# Keep annotations
-keepattributes *Annotation*
