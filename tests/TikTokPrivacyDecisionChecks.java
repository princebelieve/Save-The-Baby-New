package com.savethebaby.tiktok;
import java.util.HashMap;
import java.util.Map;

public final class TikTokPrivacyDecisionChecks {
    private static void check(boolean result, String message) {
        if (!result) throw new AssertionError(message);
    }
    public static void main(String[] args) {
        Map<String, Object> prefs = new HashMap<>();
        check(!TikTokPrivacyDecision.permitted(prefs, false, 0), "Unknown/Google-only approval is insufficient");
        check(TikTokPrivacyDecision.permitted(prefs, true, 0), "No extra screen in a not-required region");
        prefs.put("IABUSPrivacy_String", "1YYN");
        check(!TikTokPrivacyDecision.permitted(prefs, true, 0), "Opt-out overrides regional readiness");
        prefs.clear(); prefs.put("IABGPP_HDR_GppString", "present");
        check(!TikTokPrivacyDecision.permitted(prefs, true, 0), "An unhandled GPP signal must not become approval");
        prefs.clear(); prefs.put("IABTCF_gdprApplies", 1);
        check(!TikTokPrivacyDecision.permitted(prefs, true, 2), "GDPR vendor approval overrides generic status");
        prefs.put("IABTCF_VendorConsents", "01");
        prefs.put("IABTCF_PurposeConsents", "1000001011");
        check(TikTokPrivacyDecision.permitted(prefs, false, 2), "Accept the configured vendor's consented purposes");
        check(!TikTokPrivacyDecision.permitted(prefs, false, 1), "Never substitute a different vendor's approval");
        prefs.put("IABTCF_PurposeConsents", "0000001011");
        check(!TikTokPrivacyDecision.permitted(prefs, false, 2), "A withdrawn required purpose must stop reporting");
        System.out.println("Privacy decision checks passed: background/not-required, vendor-specific consent, purpose withdrawal and opt-out overrides.");
    }
}
