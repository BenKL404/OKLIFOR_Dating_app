package com.oklifor.api.web;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import static org.hamcrest.Matchers.not;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class SecurityIntegrationTest {

    @Autowired
    MockMvc mockMvc;

    @Test
    void actuatorHealth_isPublicAndReturnsUp() throws Exception {
        mockMvc.perform(get("/actuator/health"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("UP"));
    }

    @Test
    void meEndpoint_withoutToken_returns401() throws Exception {
        mockMvc.perform(get("/api/v1/me"))
                .andExpect(status().isUnauthorized());  // 401 via AuthenticationEntryPoint
    }

    @Test
    void chatThreads_withoutToken_returns401() throws Exception {
        mockMvc.perform(get("/api/v1/chat/threads"))
                .andExpect(status().isUnauthorized());  // 401 via AuthenticationEntryPoint
    }

    @Test
    void subscriptionPlans_isPublic() throws Exception {
        mockMvc.perform(get("/api/v1/subscription-plans"))
                .andExpect(status().isOk());
    }

    @Test
    void otpRequest_isPublicAndAcceptsValidPhone() throws Exception {
        // Le controller renvoie 202 Accepted (pas 200 OK)
        mockMvc.perform(post("/api/v1/auth/otp/request")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"phone\":\"+22890000000\"}"))
                .andExpect(status().isAccepted());
    }

    @Test
    void otpRequest_invalidPhone_returns400() throws Exception {
        // Numéro sans préfixe E.164 — rejeté par @Pattern sur OtpRequest.phone
        mockMvc.perform(post("/api/v1/auth/otp/request")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"phone\":\"invalid\"}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void profileMediaPublic_isAccessibleWithoutToken() throws Exception {
        // 404 attendu (fichier inexistant) mais pas 401 — la sécurité est ouverte
        mockMvc.perform(get("/api/v1/public/profile-media/user123/avatar.jpg"))
                .andExpect(status().is(not(401)));
    }
}
