package com.oklifor.api.web;

import com.oklifor.api.service.VerificationService;
import com.oklifor.api.web.dto.ProfileResponse;
import org.springframework.http.MediaType;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/v1/me/verification")
public class VerificationController {

    private final VerificationService verificationService;

    public VerificationController(VerificationService verificationService) {
        this.verificationService = verificationService;
    }

    /**
     * Selfie obligatoire. Pièce : soit un PDF ({@code idPdf}), soit recto + verso ({@code idRecto} et
     * {@code idVerso}), pas les deux à la fois.
     */
    @PostMapping(value = "/submit", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ProfileResponse submit(
            Authentication auth,
            @RequestPart("selfie") MultipartFile selfie,
            @RequestPart(value = "idPdf", required = false) MultipartFile idPdf,
            @RequestPart(value = "idRecto", required = false) MultipartFile idRecto,
            @RequestPart(value = "idVerso", required = false) MultipartFile idVerso) {
        return verificationService.submitIdentityDocuments(auth.getName(), selfie, idPdf, idRecto, idVerso);
    }

    /** Démo / recette : valide l’identité sans revue manuelle (désactivable via config). */
    @PostMapping("/simulate-approve")
    public ProfileResponse simulateApprove(Authentication auth) {
        return verificationService.simulateApprove(auth.getName());
    }
}
