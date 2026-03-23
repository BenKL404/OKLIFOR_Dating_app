package com.oklifor.api.config;

import com.oklifor.api.domain.UuidMongoDocument;
import org.springframework.data.mongodb.core.mapping.event.BeforeConvertCallback;
import org.springframework.stereotype.Component;

import java.util.UUID;

@Component
public class UuidMongoBeforeConvertCallback implements BeforeConvertCallback<Object> {

    @Override
    public Object onBeforeConvert(Object entity, String collection) {
        if (entity instanceof UuidMongoDocument d && (d.getId() == null || d.getId().isBlank())) {
            d.setId(UUID.randomUUID().toString());
        }
        return entity;
    }
}
