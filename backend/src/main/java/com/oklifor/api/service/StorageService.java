package com.oklifor.api.service;

import com.oklifor.api.config.OkliforProperties;
import io.minio.GetPresignedObjectUrlArgs;
import io.minio.MinioClient;
import io.minio.http.Method;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.concurrent.TimeUnit;

@Service
public class StorageService {

    private final OkliforProperties props;
    private final MinioClient minio;

    public StorageService(OkliforProperties props) {
        this.props = props;
        OkliforProperties.Storage cfg = props.getStorage();
        this.minio = MinioClient.builder()
                .endpoint(cfg.getEndpoint())
                .credentials(cfg.getAccessKey(), cfg.getSecretKey())
                .build();
    }

    /**
     * Returns a presigned PUT URL for a direct client → MinIO upload.
     * TTL is driven by {@code oklifor.storage.presigned-put-ttl-seconds}.
     */
    public String presignedPutUrl(String bucket, String objectKey) {
        try {
            return minio.getPresignedObjectUrl(
                    GetPresignedObjectUrlArgs.builder()
                            .method(Method.PUT)
                            .bucket(bucket)
                            .object(objectKey)
                            .expiry((int) props.getStorage().getPresignedPutTtlSeconds(), TimeUnit.SECONDS)
                            .build());
        } catch (Exception e) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "presign_failed");
        }
    }

    /**
     * Returns the permanent public URL of an object (bucket must have download policy).
     */
    public String publicUrl(String bucket, String objectKey) {
        return props.getStorage().getEndpoint() + "/" + bucket + "/" + objectKey;
    }
}
