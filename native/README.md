# Android native layer

Godot handles the game loop and Android export in v1. No custom Kotlin/Java bridge is required yet. Add Kotlin/Java only if a later feature needs a native Android API (push notifications, billing, platform-specific login, etc.).

The APK workflow currently targets a debug APK for device testing. A release keystore must be stored as GitHub Actions secrets before producing a distributable signed release APK.
