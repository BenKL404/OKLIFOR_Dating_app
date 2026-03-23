package com.oklifor.api.service;

import com.oklifor.api.domain.ContactRelation;
import com.oklifor.api.domain.UserProfile;
import com.oklifor.api.repository.ContactRelationRepository;
import com.oklifor.api.repository.UserProfileRepository;
import com.oklifor.api.web.dto.ContactResponse;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Optional;

@Service
public class ContactService {

    private static final String DEFAULT_NAME = "Profil Oklifor";

    private final ContactRelationRepository contacts;
    private final UserProfileRepository profiles;

    public ContactService(ContactRelationRepository contacts, UserProfileRepository profiles) {
        this.contacts = contacts;
        this.profiles = profiles;
    }

    public List<ContactResponse> list(String ownerUserId) {
        return contacts.findByOwnerUserIdOrderByCreatedAtDesc(ownerUserId).stream()
                .map(rel -> toResponse(rel.getContactUserId(), rel.getCreatedAt()))
                .toList();
    }

    public ContactResponse add(String ownerUserId, String contactUserId, String createdVia) {
        String peer = contactUserId != null ? contactUserId.trim() : "";
        if (peer.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "contact_invalide");
        }
        if (ownerUserId.equals(peer)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "contact_soi_meme_interdit");
        }
        if (profiles.findByUserId(peer).isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "contact_introuvable");
        }

        if (!contacts.existsByOwnerUserIdAndContactUserId(ownerUserId, peer)) {
            ContactRelation rel = new ContactRelation();
            rel.setOwnerUserId(ownerUserId);
            rel.setContactUserId(peer);
            rel.setCreatedVia(createdVia != null && !createdVia.isBlank() ? createdVia : "manual");
            contacts.save(rel);
        }
        return contacts.findByOwnerUserIdOrderByCreatedAtDesc(ownerUserId).stream()
                .filter(r -> peer.equals(r.getContactUserId()))
                .findFirst()
                .map(r -> toResponse(peer, r.getCreatedAt()))
                .orElseGet(() -> toResponse(peer, null));
    }

    public void remove(String ownerUserId, String contactUserId) {
        contacts.deleteByOwnerUserIdAndContactUserId(ownerUserId, contactUserId);
    }

    private ContactResponse toResponse(String userId, java.time.Instant addedAt) {
        Optional<UserProfile> p = profiles.findByUserId(userId);
        String name =
                p.map(UserProfile::getDisplayName)
                        .filter(v -> v != null && !v.isBlank())
                        .orElse(DEFAULT_NAME);
        String avatar = p.map(UserProfile::getAvatarUrl).orElse("");
        return new ContactResponse(userId, name, avatar != null ? avatar : "", addedAt);
    }
}
