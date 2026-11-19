package com.savethebaby.ads;

import android.app.Activity;
import android.util.Log;
import com.unity3d.ads.metadata.MetaData;
import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.UsedByGodot;

/** Explicit privacy choices for the pinned Unity 4.16.6 adapter.
 * Google UMP OBTAINED alone does not prove Unity-specific consent.
 * Keep Unity contextual-only until a verified partner consent flow is implemented.
 * Age treatment remains the Google adapter's responsibility, via RequestConfiguration.
 */
public final class UnityAdsPrivacyPlugin extends GodotPlugin {
    public UnityAdsPrivacyPlugin(Godot godot) { super(godot); }
    @Override public String getPluginName() { return "UnityAdsPrivacy"; }

    @UsedByGodot public boolean prepareContextualAds() {
        Activity activity = getActivity();
        if (activity == null) return false;
        try {
            // Commit synchronously: AdMob must not initialize or load before these values.
            MetaData metadata = new MetaData(activity.getApplicationContext());
            metadata.set("gdpr.consent", false);
            metadata.commit();
            metadata.set("privacy.consent", false);
            metadata.commit();
            Log.i("SBUnityAds", "Contextual privacy metadata applied");
            return true;
        } catch (RuntimeException error) {
            Log.e("SBUnityAds", "Privacy metadata could not be applied");
            return false;
        }
    }
}
