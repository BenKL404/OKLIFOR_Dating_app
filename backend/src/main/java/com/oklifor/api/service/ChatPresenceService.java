package com.oklifor.api.service;

import org.springframework.beans.factory.ObjectProvider;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.TimeUnit;

@Service
public class ChatPresenceService {

    private static final String KEY_ONLINE = "okl:chat:presence:online:";
    private static final String KEY_LAST_SEEN = "okl:chat:presence:last-seen:";
    private static final String KEY_TYPING = "okl:chat:presence:typing:";
    private static final long ONLINE_TTL_SECONDS = 70;
    private static final long LAST_SEEN_TTL_DAYS = 30;
    private static final long TYPING_TTL_SECONDS = 6;

    private final StringRedisTemplate redis;
    private final Map<String, Long> onlineMemory = new ConcurrentHashMap<>();
    private final Map<String, Long> lastSeenMemory = new ConcurrentHashMap<>();
    private final Map<String, Long> typingMemory = new ConcurrentHashMap<>();

    public ChatPresenceService(ObjectProvider<StringRedisTemplate> redisProvider) {
        this.redis = redisProvider.getIfAvailable();
    }

    public void markOnline(String userId) {
        long now = Instant.now().getEpochSecond();
        if (redis != null) {
            try {
                redis.opsForValue().set(KEY_ONLINE + userId, "1", ONLINE_TTL_SECONDS, TimeUnit.SECONDS);
                return;
            } catch (Exception ignored) {
            }
        }
        onlineMemory.put(userId, now + ONLINE_TTL_SECONDS);
    }

    public long markOffline(String userId) {
        long now = Instant.now().getEpochSecond();
        if (redis != null) {
            try {
                redis.delete(KEY_ONLINE + userId);
                redis.opsForValue().set(KEY_LAST_SEEN + userId, Long.toString(now), LAST_SEEN_TTL_DAYS, TimeUnit.DAYS);
                return now;
            } catch (Exception ignored) {
            }
        }
        onlineMemory.remove(userId);
        lastSeenMemory.put(userId, now);
        return now;
    }

    public boolean isOnline(String userId) {
        if (redis != null) {
            try {
                return Boolean.TRUE.equals(redis.hasKey(KEY_ONLINE + userId));
            } catch (Exception ignored) {
            }
        }
        Long exp = onlineMemory.get(userId);
        return exp != null && exp > Instant.now().getEpochSecond();
    }

    public long lastSeenEpoch(String userId) {
        if (redis != null) {
            try {
                String v = redis.opsForValue().get(KEY_LAST_SEEN + userId);
                return v == null || v.isBlank() ? 0 : Long.parseLong(v);
            } catch (Exception ignored) {
            }
        }
        return lastSeenMemory.getOrDefault(userId, 0L);
    }

    public void markTyping(String threadId, String userId, boolean typing) {
        String key = KEY_TYPING + threadId + ":" + userId;
        if (redis != null) {
            try {
                if (typing) {
                    redis.opsForValue().set(key, "1", TYPING_TTL_SECONDS, TimeUnit.SECONDS);
                } else {
                    redis.delete(key);
                }
                return;
            } catch (Exception ignored) {
            }
        }
        if (typing) {
            typingMemory.put(key, Instant.now().getEpochSecond() + TYPING_TTL_SECONDS);
        } else {
            typingMemory.remove(key);
        }
    }

    public boolean isTyping(String threadId, String userId) {
        String key = KEY_TYPING + threadId + ":" + userId;
        if (redis != null) {
            try {
                return Boolean.TRUE.equals(redis.hasKey(key));
            } catch (Exception ignored) {
            }
        }
        Long exp = typingMemory.get(key);
        return exp != null && exp > Instant.now().getEpochSecond();
    }
}
