package com.oklifor.api.domain;

import lombok.Getter;
import lombok.Setter;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.Id;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.annotation.Version;

import java.time.Instant;

/**
 * Identifiants MongoDB : toujours {@link java.util.UUID} sous forme de chaîne (jamais 1, 2, …).
 */
@Getter
@Setter
public abstract class UuidMongoDocument {

    @Id
    private String id;

    @CreatedDate
    private Instant createdAt;

    @LastModifiedDate
    private Instant updatedAt;

    @Version
    private Long version;
}
