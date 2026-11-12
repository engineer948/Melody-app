# The Tailscale library (gomobile) calls these classes from native code
# through JNI; R8 must not remove or rename them.
-keep class go.** { *; }
-keep class io.github.engineer948.melody.go.** { *; }
-keep class io.github.engineer948.melody.TailscaleNode** { *; }
