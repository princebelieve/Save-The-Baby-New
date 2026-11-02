# Android startup branding

Android's system splash used the game's adaptive launcher foreground (the avatar). The post-splash Android window was black (`screen/background_color`), so engine initialization could expose a black interval before the Godot brand scene.

Both Android export presets now override the system splash drawable with the existing transparent S. B. company artwork, inset within Android's icon safe area. The system splash, Android activity window, Godot clear color and engine splash use the same cream background. Launcher icons remain the game icons.

The `brand_launch` editor export plugin copies the source artwork into the native drawable resources and patches the Godot 4.6.3 Activity to keep its system splash until the main loop starts and the UI gets two animation frames. These changes are applied on export, so they survive a fresh Android build template installation. The generated `android/` directory remains ignored. If Godot changes its Activity template, the plugin reports an unsupported-template error instead of silently applying a partial patch.

Boot constructs its logo before configuration loading and yields until the first rendered frame. Ad consent starts after the company splash, rather than from autoload startup. The Godot brand scene stays visible for its existing duration, then switches to the game.

`tests/boot_launch_checks.tscn` checks the graphical first-frame company logo and handoff to the game. Native splash behavior must be checked on Android with a cold launch, including Android 12+ and an older supported version. The Android system controls the size and animation of its splash icon; it uses the S. B. artwork instead of the avatar.
