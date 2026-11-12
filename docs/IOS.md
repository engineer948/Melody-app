# iOS

The code is ready; since this development environment has no macOS / Xcode,
the build is only tried on GitHub Actions (CI → "iOS build", unsigned).

## What is there

- Background playback (`UIBackgroundModes: audio`), Control Center and lock
  screen (audio_service), headphone buttons
- **AirPlay:** the output button on the full-screen player → "AirPlay" (the
  system's own device picker, `ios/Runner/AirPlayButton.swift`)
- **CarPlay:** the same library tree as Android Auto
  (`ios/Runner/CarPlaySceneDelegate.swift`, Dart side
  `lib/player/carplay_bridge.dart`). The app must have been opened on the
  phone at least once.
- DLNA and Jellyfin discovery on the local network (the local network
  permission text is in `Info.plist`)
- App Transport Security exception for HTTP servers
- Privacy manifest (`ios/Runner/PrivacyInfo.xcprivacy`): no tracking, no
  data collected; UserDefaults and file timestamp usage with their reasons
- Sharing (story image and text) through the system share sheet
- Haptic feedback (play / pause / skip), swipe-back on iOS
- The equalizer, Android Auto settings and the home screen widget are
  hidden on iOS

## Needs permission from Apple

Both are requested separately from the Apple developer account; once
approved, `ios/Runner/Runner.entitlements.carplay` is renamed to
`Runner.entitlements` and set as the Runner target's
`CODE_SIGN_ENTITLEMENTS` in Xcode.

- `com.apple.developer.carplay-audio`: to appear in CarPlay
- `com.apple.developer.networking.multicast`: to find Jellyfin on the local
  network over UDP (without it the address is entered by hand)

## App Store

Distribution is currently F-Droid + GitHub only. The App Store additionally
needs an Apple developer account, signing, screenshots and App Store texts.
None of these steps have been done yet.
