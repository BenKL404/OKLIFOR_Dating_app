package com.oklifor.api.service;

import org.springframework.stereotype.Component;

@Component
public class PhoneNormalizer {

    private static final String DEFAULT_CC = "+228";

    /**
     * Normalise en E.164 simple (démo Togo +228 si pas d’indicatif).
     */
    public String toE164(String raw) {
        if (raw == null) {
            return "";
        }
        String digits = raw.replaceAll("\\s+", "").trim();
        if (digits.isEmpty()) {
            return "";
        }
        if (digits.startsWith("+")) {
            return digits;
        }
        return DEFAULT_CC + digits;
    }
}
