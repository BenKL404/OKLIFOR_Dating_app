package com.oklifor.api.web;

import com.oklifor.api.service.ContactService;
import com.oklifor.api.web.dto.AddContactRequest;
import com.oklifor.api.web.dto.ContactResponse;
import jakarta.validation.Valid;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/contacts")
public class ContactController {

    private final ContactService contactService;

    public ContactController(ContactService contactService) {
        this.contactService = contactService;
    }

    @GetMapping
    public List<ContactResponse> list(Authentication auth) {
        return contactService.list(auth.getName());
    }

    @PostMapping
    public ContactResponse add(Authentication auth, @Valid @RequestBody AddContactRequest body) {
        return contactService.add(auth.getName(), body.peerUserId(), "qr");
    }

    @DeleteMapping("/{contactUserId}")
    public void remove(Authentication auth, @PathVariable String contactUserId) {
        contactService.remove(auth.getName(), contactUserId);
    }
}
