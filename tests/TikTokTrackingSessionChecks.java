package com.savethebaby.tiktok;

public final class TikTokTrackingSessionChecks {
    private static final class FakeSdk implements TikTokTrackingSession.Sdk {
        TikTokTrackingSession.Callback callback;
        int initializations, transmissions, clears;
        boolean broken;
        boolean ready, enabled = true, network;
        public void initialize(TikTokTrackingSession.Callback cb) {
            initializations++;
            if (broken) throw new LinkageError("Simulated unavailable SDK");
            callback = cb;
        }
        public boolean configurationReady() { return ready; }
        public boolean remoteEnabled() { return enabled; }
        public void setEnabled(boolean value) { enabled = value; }
        public void startSending() { network = true; transmissions++; }
        public void clearEvents() { clears++; }
        void receiveConfiguration(boolean value) { enabled = value; ready = true; }
    }
    private static void check(boolean condition, String message) {
        if (!condition) throw new AssertionError(message);
    }
    public static void main(String[] args) {
        FakeSdk sdk = new FakeSdk();
        TikTokTrackingSession session = new TikTokTrackingSession(sdk);
        session.stop();
        check(sdk.initializations == 0, "Decline must not initialize the SDK");
        session.start(); session.start();
        check(sdk.initializations == 1, "Do not initialize twice during pending startup");
        sdk.callback.success();
        check(!sdk.network, "Initialization alone must not open the event network");
        check(session.status().equals("waiting_for_configuration"), "Report missing configuration honestly");
        session.stop();
        sdk.receiveConfiguration(true); // Simulate remote config overriding the global switch.
        session.refresh();
        check(!sdk.network && !sdk.enabled, "Revocation during remote startup must not transmit");
        session.start();
        check(sdk.enabled && sdk.network && sdk.transmissions == 1, "Allow must enable measurement");
        check(sdk.clears >= 2, "Discard events accumulated during the stopped interval");
        session.stop();
        check(!sdk.enabled && session.status().equals("stopped"), "Stop without destroying SDK");
        session.start();
        check(sdk.enabled && sdk.initializations == 1 && sdk.transmissions == 2, "Resume without restart/reinitialization");
        session.start();
        check(sdk.transmissions == 2, "Repeated starts must be idempotent");

        FakeSdk disabled = new FakeSdk();
        TikTokTrackingSession disabledSession = new TikTokTrackingSession(disabled);
        disabledSession.start(); disabled.callback.success();
        disabled.receiveConfiguration(false); disabledSession.refresh();
        disabledSession.stop(); disabledSession.start();
        check(!disabled.enabled && !disabled.network, "Never override TikTok's remote disable decision");
        check(disabledSession.status().equals("disabled_by_tiktok"), "Expose remote disable status");

        FakeSdk retry = new FakeSdk();
        TikTokTrackingSession retrySession = new TikTokTrackingSession(retry);
        retrySession.start(); retry.callback.fail();
        check(retrySession.status().equals("failed_retryable"), "Pre-singleton failure must permit retry");
        retrySession.start();
        check(retry.initializations == 2, "Retry a failed initialization rather than permanently latching attempted");
        retrySession.stop(); retry.callback.success();
        check(!retry.network, "A late initialization callback must respect withdrawal");
        FakeSdk partial = new FakeSdk();
        partial.broken = true;
        TikTokTrackingSession partialSession = new TikTokTrackingSession(partial);
        partialSession.start(); partialSession.stop(); partialSession.start();
        check(partial.initializations == 1 && partialSession.status().equals("failed_until_restart"),
                "Do not reconstruct a partially initialized or unavailable SDK");
        System.out.println("Native session checks passed: deferred network, remote configuration race, stop/resume, idempotence, remote disable and retry.");
    }
}
