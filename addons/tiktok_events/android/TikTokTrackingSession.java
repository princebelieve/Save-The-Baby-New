package com.savethebaby.tiktok;

/** Serializes permission changes independently of Android and Godot callbacks. */
final class TikTokTrackingSession {
    interface Callback {
        void success();
        void fail();
    }
    interface Sdk {
        void initialize(Callback callback);
        boolean configurationReady();
        boolean remoteEnabled();
        void setEnabled(boolean enabled);
        void startSending();
        void clearEvents();
    }

    private final Sdk sdk;
    private boolean requested;
    private boolean attempted;
    private boolean initialized;
    private boolean configurationRead;
    private boolean remoteEnabled;
    private boolean discardBeforeResume;
    private boolean running;
    private boolean broken;
    private String status = "inactive";

    TikTokTrackingSession(Sdk sdk) { this.sdk = sdk; }

    synchronized void start() {
        requested = true;
        if (broken) return;
        if (!attempted) {
            attempted = true;
            status = "initializing";
            try {
                sdk.initialize(new Callback() {
                    @Override public void success() {
                        synchronized (TikTokTrackingSession.this) {
                            initialized = true;
                            refresh();
                        }
                    }
                    @Override public void fail() {
                        synchronized (TikTokTrackingSession.this) {
                            // SDK 1.7.1 calls fail only before constructing its singleton.
                            attempted = false;
                            status = requested ? "failed_retryable" : "stopped";
                        }
                    }
                });
            } catch (RuntimeException | LinkageError error) {
                // Partial native initialization cannot safely be reconstructed here.
                broken = true;
                status = "failed_until_restart";
                try { sdk.setEnabled(false); } catch (RuntimeException | LinkageError ignored) { }
            }
        }
        refresh();
    }

    synchronized void stop() {
        requested = false;
        if (broken) return;
        if (!attempted) { status = "inactive"; return; }
        readConfiguration();
        sdk.setEnabled(false);
        sdk.clearEvents();
        discardBeforeResume = true;
        running = false;
        status = "stopped";
        // Keep the single SDK instance and its lifecycle observers for resumption.
    }

    private void readConfiguration() {
        if (!configurationRead && sdk.configurationReady()) {
            remoteEnabled = sdk.remoteEnabled();
            configurationRead = true;
        }
    }

    synchronized void refresh() {
        if (broken || !attempted) return;
        readConfiguration();
        if (!requested) {
            sdk.setEnabled(false);
            status = "stopped";
            return;
        }
        if (!initialized || !configurationRead) {
            status = initialized ? "waiting_for_configuration" : "initializing";
            return;
        }
        if (!remoteEnabled) {
            sdk.setEnabled(false);
            status = "disabled_by_tiktok";
            return;
        }
        if (!running) {
            if (discardBeforeResume) {
                // clearAll and startTrack enqueue work on the SDK's serial event loop.
                sdk.clearEvents();
                discardBeforeResume = false;
            }
            sdk.setEnabled(true);
            sdk.startSending();
            running = true;
        }
        status = "initialized";
    }

    synchronized boolean needsConfigurationCheck() {
        return attempted && !broken && !configurationRead;
    }

    synchronized String status() { return status; }
}
