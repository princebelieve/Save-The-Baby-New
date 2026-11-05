# Completed portraits in the phone gallery

After a successful portrait puzzle, the existing game album and coin reward are preserved. The completed screen also offers **Save to gallery**. The first Android completion asks whether to automatically save completed portraits; the player can enable or disable that preference in **Daily Rewards**. Previously completed pictures in the game album also have a manual gallery button, including pictures restored through cloud progress.

The exported PNG matches the square crop assembled on the puzzle board, at its original resolution. Each completed slot has a stable filename. Automatic exports remember successful saves; interrupted or failed requests can be retried without another coin reward. Pending records remain on the device. Enabling automatic saving also queues earlier unsaved local completions.

The Android bridge writes to **Pictures/Save The Baby** using MediaStore on Android 10 and later. It does not read the player's existing images. Android 7–9 use a legacy storage permission limited to API 28; the player can decline and keep the in-game collection. A failed gallery write never removes the portrait or reverses its reward.

The native source lives in `addons/portrait_gallery/android/PortraitGalleryPlugin.java`. Its export plugin installs that source and registers the Godot singleton in both regular and developer Android packages. Release reflection rules already retain the plugin and its callable methods.

## Verification

`tools/run_checks.ps1 -Suite gallery_checks`: 21 checks passed. Covers PNG encoding/cropping, automatic and manual saves, preference changes, duplicate completion, persistence and retry after failure, earned-album validation, and the completed puzzle's button/status. The native calls in this suite use a test double; they do not constitute a phone MediaStore test.

The 66 developer checks and release checks also passed after integration. No phone was connected over ADB during implementation. On a phone, complete a portrait in the developer APK, enable automatic saving and verify the **Save The Baby** gallery album. Repeat a manual save, decline permission on an Android 7–9 device if available, and confirm retries do not award extra coins. Verify a normal release has no developer button.

References: [Android shared-media storage](https://developer.android.com/training/data-storage/shared/media), [Godot Android plugin API](https://docs.godotengine.org/en/stable/tutorials/platform/android/android_plugin.html).
