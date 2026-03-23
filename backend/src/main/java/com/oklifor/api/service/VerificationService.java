package com.oklifor.api.service;

import com.oklifor.api.config.OkliforProperties;
import com.oklifor.api.domain.UserProfile;
import com.oklifor.api.repository.UserProfileRepository;
import com.oklifor.api.web.dto.ProfileResponse;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.time.Instant;
import java.util.Locale;

@Service
public class VerificationService {

    private final UserProfileRepository profiles;
    private final OkliforProperties props;

    public VerificationService(UserProfileRepository profiles, OkliforProperties props) {
        this.profiles = profiles;
        this.props = props;
    }

    public ProfileResponse submitIdentityDocuments(
            String userId,
            MultipartFile selfie,
            MultipartFile idPdf,
            MultipartFile idRecto,
            MultipartFile idVerso) {
        if (selfie == null || selfie.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "selfie_manquant");
        }

        boolean pdfOk = idPdf != null && !idPdf.isEmpty();
        boolean rectoOk = idRecto != null && !idRecto.isEmpty();
        boolean versoOk = idVerso != null && !idVerso.isEmpty();

        if (pdfOk && (rectoOk || versoOk)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "piece_pdf_ou_recto_verso");
        }
        if (pdfOk) {
            if (!looksLikePdf(idPdf)) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "pdf_invalide");
            }
        } else if (rectoOk && versoOk) {
            // images acceptées (jpeg/png/webp/heic selon client)
        } else {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "piece_incomplete");
        }

        UserProfile p =
                profiles.findByUserId(userId)
                        .orElseThrow(
                                () -> new ResponseStatusException(HttpStatus.NOT_FOUND, "profil_manquant"));
        if (p.isIdVerified()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "identite_deja_validee");
        }

        String baseDir = props.getVerification().getUploadDir();
        Path userDir = Path.of(baseDir, userId);
        try {
            Files.createDirectories(userDir);
        } catch (IOException e) {
            throw new ResponseStatusException(
                    HttpStatus.INTERNAL_SERVER_ERROR, "dossier_upload_inaccessible");
        }

        long ts = Instant.now().getEpochSecond();
        String selfieExt = extension(selfie, ".jpg");
        String selfieRel = userId + "/selfie_" + ts + selfieExt;

        try {
            saveTo(userDir.resolve("selfie_" + ts + selfieExt), selfie.getInputStream());
        } catch (IOException e) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "ecriture_fichier");
        }

        p.setVerificationSelfieRelativePath(selfieRel);

        if (pdfOk) {
            String pdfExt = extension(idPdf, ".pdf");
            if (!pdfExt.toLowerCase(Locale.ROOT).endsWith(".pdf")) {
                pdfExt = ".pdf";
            }
            String pdfName = "id_" + ts + pdfExt;
            String pdfRel = userId + "/" + pdfName;
            try {
                saveTo(userDir.resolve(pdfName), idPdf.getInputStream());
            } catch (IOException e) {
                throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "ecriture_fichier");
            }
            p.setVerificationIdPdfRelativePath(pdfRel);
            p.setVerificationIdRectoRelativePath(null);
            p.setVerificationIdVersoRelativePath(null);
            p.setVerificationDocumentRelativePath(pdfRel);
        } else {
            String rectoExt = extension(idRecto, ".jpg");
            String versoExt = extension(idVerso, ".jpg");
            String rectoName = "id_recto_" + ts + rectoExt;
            String versoName = "id_verso_" + ts + versoExt;
            String rectoRel = userId + "/" + rectoName;
            String versoRel = userId + "/" + versoName;
            try {
                saveTo(userDir.resolve(rectoName), idRecto.getInputStream());
                saveTo(userDir.resolve(versoName), idVerso.getInputStream());
            } catch (IOException e) {
                throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "ecriture_fichier");
            }
            p.setVerificationIdPdfRelativePath(null);
            p.setVerificationIdRectoRelativePath(rectoRel);
            p.setVerificationIdVersoRelativePath(versoRel);
            p.setVerificationDocumentRelativePath(rectoRel);
        }

        p.setIdPendingReview(true);
        p.setIdVerified(false);
        return ProfileResponse.from(profiles.save(p));
    }

    public ProfileResponse simulateApprove(String userId) {
        if (!props.getVerification().isDemoApproveEnabled()) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "demo_approve_desactive");
        }
        UserProfile p =
                profiles.findByUserId(userId)
                        .orElseThrow(
                                () -> new ResponseStatusException(HttpStatus.NOT_FOUND, "profil_manquant"));
        p.setIdVerified(true);
        p.setIdPendingReview(false);
        return ProfileResponse.from(profiles.save(p));
    }

    private static boolean looksLikePdf(MultipartFile f) {
        String ct = f.getContentType();
        if (ct != null && ct.toLowerCase(Locale.ROOT).contains("pdf")) {
            return true;
        }
        String n = f.getOriginalFilename();
        return n != null && n.toLowerCase(Locale.ROOT).endsWith(".pdf");
    }

    private static void saveTo(Path target, InputStream in) throws IOException {
        Files.copy(in, target, StandardCopyOption.REPLACE_EXISTING);
    }

    private static String extension(MultipartFile f, String fallback) {
        String n = f.getOriginalFilename();
        if (n == null || !n.contains(".")) {
            return fallback;
        }
        return n.substring(n.lastIndexOf('.'));
    }
}
