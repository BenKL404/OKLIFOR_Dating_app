package com.oklifor.api.service;

import com.google.firebase.FirebaseApp;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseAuthException;
import com.google.firebase.auth.FirebaseToken;
import com.oklifor.api.config.OkliforProperties;
import com.oklifor.api.domain.UserAccount;
import com.oklifor.api.security.JwtService;
import com.oklifor.api.web.dto.TokenResponse;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

@Service
public class AuthService {

    private final PhoneNormalizer phones;
    private final AccountProvisioningService provisioning;
    private final JwtService jwt;
    private final OkliforProperties props;

    public AuthService(
            PhoneNormalizer phones,
            AccountProvisioningService provisioning,
            JwtService jwt,
            OkliforProperties props) {
        this.phones = phones;
        this.provisioning = provisioning;
        this.jwt = jwt;
        this.props = props;
    }

    public void requestOtp(String rawPhone) {
        String e164 = phones.toE164(rawPhone);
        if (e164.length() < 10) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "numéro_invalide");
        }
        // Intégration SMS / OTP plus tard
    }

    public TokenResponse verifyOtp(String rawPhone, String code) {
        String e164 = phones.toE164(rawPhone);
        if (e164.length() < 10) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "numéro_invalide");
        }
        validateOtp(code);

        UserAccount user = provisioning.findOrCreateByPhone(e164);
        String access = jwt.createAccessToken(user.getId());
        String refresh = jwt.createRefreshToken(user.getId());
        return new TokenResponse(
                access,
                refresh,
                "Bearer",
                props.getJwt().getAccessTokenMinutes() * 60,
                user.getId());
    }

    private void validateOtp(String code) {
        if (code == null || code.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "code_manquant");
        }
        String c = code.trim();
        if (props.getAuth().isOtpDevMode()) {
            if (!c.matches("\\d{6}")) {
                throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "code_invalide");
            }
            return;
        }
        throw new ResponseStatusException(HttpStatus.NOT_IMPLEMENTED, "otp_prod_non_configure");
    }

    /**
     * Échange un jeton Firebase (Phone Auth) contre les JWT applicatifs.
     * Nécessite {@code oklifor.firebase.enabled=true} et Admin SDK initialisé.
     */
    public TokenResponse loginWithFirebaseIdToken(String idToken) {
        if (idToken == null || idToken.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "token_manquant");
        }
        if (FirebaseApp.getApps().isEmpty()) {
            throw new ResponseStatusException(
                    HttpStatus.SERVICE_UNAVAILABLE, "firebase_desactive_cote_serveur");
        }
        try {
            FirebaseToken token = FirebaseAuth.getInstance().verifyIdToken(idToken);
            Object phoneObj = token.getClaims().get("phone_number");
            if (!(phoneObj instanceof String phone) || phone.isBlank()) {
                throw new ResponseStatusException(
                        HttpStatus.BAD_REQUEST, "telephone_manquant_dans_token_firebase");
            }
            String e164 = phones.toE164(phone);
            if (e164.length() < 10) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "numéro_invalide");
            }
            UserAccount user = provisioning.findOrCreateByPhone(e164);
            String access = jwt.createAccessToken(user.getId());
            String refresh = jwt.createRefreshToken(user.getId());
            return new TokenResponse(
                    access,
                    refresh,
                    "Bearer",
                    props.getJwt().getAccessTokenMinutes() * 60,
                    user.getId());
        } catch (FirebaseAuthException e) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "token_firebase_invalide");
        }
    }
}
