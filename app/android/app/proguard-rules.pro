# Razorpay Checkout (https://razorpay.com/docs/payments/payment-gateway/android-integration/standard/)
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-keepattributes JavascriptInterface
-keepattributes *Annotation*
-dontwarn com.razorpay.**
-keep class com.razorpay.** { *; }
-optimizations !method/inlining/*
-keepclasseswithmembers class * {
    public void onPayment*(...);
}

# Flutter references Play Core (deferred components) classes that are not
# on the classpath unless that feature is used.
-dontwarn com.google.android.play.core.**
