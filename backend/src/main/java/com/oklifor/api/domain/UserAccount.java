package com.oklifor.api.domain;

import lombok.Getter;
import lombok.Setter;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

@Document(collection = "users")
@Getter
@Setter
public class UserAccount extends UuidMongoDocument {

    @Indexed(unique = true)
    private String phoneE164;

    private UserAccountStatus status = UserAccountStatus.ACTIVE;
}
