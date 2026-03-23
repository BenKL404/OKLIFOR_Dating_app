package com.oklifor.api.security;

import com.oklifor.api.config.OkliforProperties;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.Map;

@Service
public class JwtService {

    private final OkliforProperties props;
    private final SecretKey key;

    public JwtService(OkliforProperties props) {
        this.props = props;
        byte[] bytes = props.getJwt().getSecret().getBytes(StandardCharsets.UTF_8);
        if (bytes.length < 32) {
            throw new IllegalStateException(
                    "oklifor.jwt.secret doit faire au moins 32 octets (256 bits) pour HS256");
        }
        this.key = Keys.hmacShaKeyFor(bytes);
    }

    public String createAccessToken(String userId) {
        return buildToken(userId, "access", props.getJwt().getAccessTokenMinutes() * 60_000L);
    }

    public String createRefreshToken(String userId) {
        return buildToken(userId, "refresh", props.getJwt().getRefreshTokenDays() * 86_400_000L);
    }

    private String buildToken(String userId, String typ, long ttlMillis) {
        var now = new Date();
        return Jwts.builder()
                .subject(userId)
                .claims(Map.of("typ", typ))
                .issuedAt(now)
                .expiration(new Date(now.getTime() + ttlMillis))
                .signWith(key)
                .compact();
    }

    public String parseUserIdIfAccessToken(String token) {
        Claims claims = Jwts.parser().verifyWith(key).build().parseSignedClaims(token).getPayload();
        if (!"access".equals(claims.get("typ"))) {
            throw new IllegalArgumentException("Token invalide");
        }
        return claims.getSubject();
    }
}
