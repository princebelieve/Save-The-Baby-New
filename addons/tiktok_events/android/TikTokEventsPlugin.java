package com.savethebaby.tiktok;

import android.app.Activity;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.UsedByGodot;
import com.tiktok.TikTokBusinessSdk;
import java.util.concurrent.atomic.AtomicLong;

/** Reports promotion events; does not display advertisements. Pinned to SDK 1.7.1. */
public final class TikTokEventsPlugin extends GodotPlugin {
    private static final String TAG = "SBTikTokEvents";
    private static final Handler MAIN = new Handler(Looper.getMainLooper());
    private static final AtomicLong COMMAND = new AtomicLong();
    private static TikTokTrackingSession session;
    private static final Runnable CHECK_CONFIGURATION = new Runnable() {
        @Override public void run() {
            if (session == null) return;
            String previous = session.status();
            session.refresh();
            if (!previous.equals(session.status())) Log.i(TAG, "Measurement state: " + session.status());
            if (session.needsConfigurationCheck()) MAIN.postDelayed(this, 1000);
        }
    };

    public TikTokEventsPlugin(Godot godot) { super(godot); }
    @Override public String getPluginName() { return "TikTokEvents"; }

    @UsedByGodot public boolean isConfigured() {
        Activity activity = getActivity();
        return activity != null && "com.savethebaby.game".equals(activity.getPackageName())
                && resource(activity, "sb_tiktok_app_id").matches("[0-9]+")
                && !resource(activity, "sb_tiktok_access_token").isEmpty();
    }

    /** Read the shared CMP decision; Google OBTAINED is not TikTok vendor consent. */
    @UsedByGodot public boolean measurementPermitted(boolean consentNotRequired) {
        Activity activity = getActivity();
        if (activity == null) return false;
        android.content.SharedPreferences prefs = activity.getSharedPreferences(
                activity.getPackageName() + "_preferences", android.content.Context.MODE_PRIVATE);
        String configuredVendor = resource(activity, "sb_tiktok_consent_vendor_id");
        int vendor = configuredVendor.matches("[1-9][0-9]{0,5}") ? Integer.parseInt(configuredVendor) : 0;
        return TikTokPrivacyDecision.permitted(prefs.getAll(), consentNotRequired, vendor);
    }

    @UsedByGodot public void startTracking() {
        Activity activity = getActivity();
        if (!isConfigured() || activity == null) return;
        long command = COMMAND.incrementAndGet();
        activity.runOnUiThread(() -> {
            synchronized (TikTokEventsPlugin.class) {
                if (command != COMMAND.get()) return;
                if (session == null) session = createSession(activity);
                session.start();
                Log.i(TAG, "Measurement state: " + session.status());
                MAIN.removeCallbacks(CHECK_CONFIGURATION);
                if (session.needsConfigurationCheck()) MAIN.postDelayed(CHECK_CONFIGURATION, 1000);
            }
        });
    }

    private static TikTokTrackingSession createSession(Activity activity) {
        // Retain application context rather than an Activity that may be recreated.
        final android.content.Context context = activity.getApplicationContext();
        final String appId = resource(activity, "sb_tiktok_app_id");
        final String token = resource(activity, "sb_tiktok_access_token");
        final String packageName = activity.getPackageName();
        final boolean testMode = "true".equals(resource(activity, "sb_tiktok_test_mode"));
        return new TikTokTrackingSession(new TikTokTrackingSession.Sdk() {
            @Override public void initialize(TikTokTrackingSession.Callback callback) {
                TikTokBusinessSdk.TTConfig config = new TikTokBusinessSdk.TTConfig(context, token)
                        .setAppId(packageName).setTTAppId(appId)
                        .disableAutoStart().disableAutoEnhancedDataPostbackEvent()
                        .disableAutoIapTrack().disableAdvertiserIDCollection().disableMonitor();
                if (testMode) config.openDebugMode();
                TikTokBusinessSdk.initializeSdk(config, new TikTokBusinessSdk.TTInitCallback() {
                    @Override public void success() {
                        callback.success();
                        Log.i(TAG, "SDK ready; awaiting permission and remote configuration.");
                    }
                    @Override public void fail(int code, String message) {
                        callback.fail();
                        Log.w(TAG, "SDK initialization failed; code=" + code);
                    }
                });
            }
            @Override public boolean configurationReady() {
                return Boolean.TRUE.equals(TikTokBusinessSdk.isGlobalConfigFetched());
            }
            @Override public boolean remoteEnabled() {
                return Boolean.TRUE.equals(TikTokBusinessSdk.getSdkGlobalSwitch());
            }
            @Override public void setEnabled(boolean enabled) { TikTokBusinessSdk.setSdkGlobalSwitch(enabled); }
            @Override public void startSending() { TikTokBusinessSdk.startTrack(); }
            @Override public void clearEvents() { TikTokBusinessSdk.clearAll(); }
        });
    }

    @UsedByGodot public void stopTracking() {
        COMMAND.incrementAndGet();
        synchronized (TikTokEventsPlugin.class) {
            if (session != null) {
                session.stop();
                Log.i(TAG, "Measurement state: " + session.status());
            }
        }
    }

    @UsedByGodot public String getTrackingStatus() {
        synchronized (TikTokEventsPlugin.class) {
            return session == null ? "inactive" : session.status();
        }
    }

    private static String resource(Activity activity, String name) {
        int id = activity.getResources().getIdentifier(name, "string", activity.getPackageName());
        return id == 0 ? "" : activity.getString(id).trim();
    }
}
