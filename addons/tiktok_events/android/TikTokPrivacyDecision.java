package com.savethebaby.tiktok;

import java.util.Map;

/** Conservative interpretation of the shared CMP's stored decisions. */
final class TikTokPrivacyDecision {
    static boolean permitted(Map<String, ?> prefs, boolean consentNotRequired, int vendor) {
        String usPrivacy = text(prefs, "IABUSPrivacy_String");
        if (usPrivacy.length() >= 3 && usPrivacy.charAt(2) == 'Y') return false;
        // GPP applicable sections need their own configured processing decision.
        if (!text(prefs, "IABGPP_HDR_GppString").isEmpty()) return false;
        Object gdpr = prefs.get("IABTCF_gdprApplies");
        boolean gdprApplies = gdpr instanceof Number && ((Number) gdpr).intValue() == 1;
        if (!gdprApplies) return consentNotRequired;
        if (!bit(text(prefs, "IABTCF_VendorConsents"), vendor)) return false;
        String purposes = text(prefs, "IABTCF_PurposeConsents");
        for (int purpose : new int[] {1, 7, 9, 10}) {
            if (!bit(purposes, purpose)) return false;
        }
        for (String key : prefs.keySet()) {
            if (key.startsWith("IABTCF_PublisherRestrictions")) return false;
        }
        return true;
    }
    private static String text(Map<String, ?> prefs, String key) {
        Object value = prefs.get(key);
        return value instanceof String ? (String) value : "";
    }
    private static boolean bit(String value, int id) {
        return id > 0 && value.length() >= id && value.charAt(id - 1) == '1';
    }
}
