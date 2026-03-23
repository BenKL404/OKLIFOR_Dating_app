package com.oklifor.api.domain;

import lombok.Getter;
import lombok.Setter;
import org.springframework.data.mongodb.core.index.CompoundIndex;
import org.springframework.data.mongodb.core.index.CompoundIndexes;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

@Document(collection = "contact_relations")
@CompoundIndexes({
        @CompoundIndex(
                name = "uk_owner_contact",
                def = "{'ownerUserId': 1, 'contactUserId': 1}",
                unique = true)
})
@Getter
@Setter
public class ContactRelation extends UuidMongoDocument {

    @Indexed
    private String ownerUserId;

    @Indexed
    private String contactUserId;

    private String createdVia;
}
