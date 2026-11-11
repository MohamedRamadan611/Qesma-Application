# R8 rules for the release build (FL9).
#
# The generated API client (packages/qesma_api, built_value + dio) is plain Dart compiled by Flutter: R8 never sees it.
# Only the Android/Java side is shrunk: Flutter's embedding and the plugins (flutter_secure_storage, google_sign_in,
# url_launcher, connectivity). Flutter's Gradle plugin already adds the embedding's keep rules; the lines below cover what
# the plugins reach by reflection or through Google Play services. Verify any change by running the release APK
# (docs/mobile-release.md, "R8 check").

# Google Sign-In (Credential Manager / Play services) and its coroutines helpers.
-keep class com.google.android.libraries.identity.googleid.** { *; }
-keep class androidx.credentials.** { *; }
-dontwarn androidx.credentials.**

# flutter_secure_storage uses AndroidX security/crypto classes.
-keep class androidx.security.crypto.** { *; }
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**

# Flutter may reference Play Core deferred components, which this app does not use.
-dontwarn com.google.android.play.core.**
