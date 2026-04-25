package com.oklifor.api.service;

import com.oklifor.api.domain.ChatMessage;
import com.oklifor.api.domain.ChatMessageKind;
import com.oklifor.api.domain.ChatThread;
import com.oklifor.api.domain.ChatThreadType;
import com.oklifor.api.repository.ChatMessageRepository;
import com.oklifor.api.repository.ChatThreadRepository;
import com.oklifor.api.web.dto.SendMessageRequest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ChatServiceUnitTest {

    @Mock ChatThreadRepository threadRepo;
    @Mock ChatMessageRepository messageRepo;
    @Mock ChatMediaService chatMediaService;
    @Mock ApplicationEventPublisher eventPublisher;

    ChatService chatService;

    @BeforeEach
    void setUp() {
        chatService = new ChatService(threadRepo, messageRepo, chatMediaService, eventPublisher);
    }

    // ── getOrCreateDirect ──────────────────────────────────────────────────────

    @Test
    void getOrCreateDirect_sameUser_throwsBadRequest() {
        assertThatThrownBy(() -> chatService.getOrCreateDirect("user1", "user1"))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode())
                        .isEqualTo(HttpStatus.BAD_REQUEST));
    }

    @Test
    void getOrCreateDirect_createsNewThreadWhenNoneExists() {
        when(threadRepo.findDirectBetweenSortedParticipants("alice", "bob"))
                .thenReturn(Optional.empty());

        ChatThread saved = new ChatThread();
        saved.setType(ChatThreadType.DIRECT);
        saved.setParticipantUserIds(new ArrayList<>(List.of("alice", "bob")));
        when(threadRepo.save(any())).thenReturn(saved);

        var response = chatService.getOrCreateDirect("alice", "bob");

        assertThat(response.participantUserIds()).containsExactlyInAnyOrder("alice", "bob");
        verify(threadRepo).save(any());
    }

    @Test
    void getOrCreateDirect_returnsExistingThread_withoutSaving() {
        ChatThread existing = new ChatThread();
        existing.setType(ChatThreadType.DIRECT);
        existing.setParticipantUserIds(new ArrayList<>(List.of("alice", "bob")));
        when(threadRepo.findDirectBetweenSortedParticipants("alice", "bob"))
                .thenReturn(Optional.of(existing));

        chatService.getOrCreateDirect("alice", "bob");

        verify(threadRepo, never()).save(any());
    }

    @Test
    void getOrCreateDirect_sortsParticipantsLexicographically() {
        // "bob" < "zara" lexicographically — peu importe l'ordre d'appel
        when(threadRepo.findDirectBetweenSortedParticipants("bob", "zara"))
                .thenReturn(Optional.empty());

        ChatThread saved = new ChatThread();
        saved.setType(ChatThreadType.DIRECT);
        saved.setParticipantUserIds(new ArrayList<>(List.of("bob", "zara")));
        when(threadRepo.save(any())).thenReturn(saved);

        chatService.getOrCreateDirect("zara", "bob"); // ordre inversé
        verify(threadRepo).findDirectBetweenSortedParticipants("bob", "zara");
    }

    // ── sendMessage ────────────────────────────────────────────────────────────

    @Test
    void sendMessage_deniesNonParticipant() {
        ChatThread t = new ChatThread();
        t.setParticipantUserIds(new ArrayList<>(List.of("alice", "bob")));
        when(threadRepo.findById("thread1")).thenReturn(Optional.of(t));

        assertThatThrownBy(() -> chatService.sendMessage("charlie", "thread1",
                new SendMessageRequest(ChatMessageKind.TEXT, "salut", null, null, null, null, null, null)))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode())
                        .isEqualTo(HttpStatus.FORBIDDEN));
    }

    @Test
    void sendMessage_savesMessageAndUpdatesThread() {
        ChatThread t = new ChatThread();
        t.setParticipantUserIds(new ArrayList<>(List.of("alice", "bob")));
        when(threadRepo.findById("t1")).thenReturn(Optional.of(t));

        ChatMessage saved = new ChatMessage();
        saved.setThreadId("t1");
        saved.setSenderUserId("alice");
        saved.setKind(ChatMessageKind.TEXT);
        saved.setText("bonjour");
        when(messageRepo.save(any())).thenReturn(saved);
        when(threadRepo.save(any())).thenReturn(t);

        var resp = chatService.sendMessage("alice", "t1",
                new SendMessageRequest(ChatMessageKind.TEXT, "bonjour", null, null, null, null, null, null));

        assertThat(resp.senderUserId()).isEqualTo("alice");
        assertThat(resp.text()).isEqualTo("bonjour");
        verify(messageRepo).save(any());
        verify(threadRepo).save(t);
    }

    // ── markThreadRead ─────────────────────────────────────────────────────────

    @Test
    void markThreadRead_throwsNotFound_whenThreadMissing() {
        when(threadRepo.findById("missing")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> chatService.markThreadRead("user1", "missing"))
                .isInstanceOf(ResponseStatusException.class)
                .satisfies(ex -> assertThat(((ResponseStatusException) ex).getStatusCode())
                        .isEqualTo(HttpStatus.NOT_FOUND));
    }

    @Test
    void markThreadRead_returnsPreviousCursor_whenAlreadyAhead() {
        ChatThread t = new ChatThread();
        t.setParticipantUserIds(new ArrayList<>(List.of("alice", "bob")));
        when(threadRepo.findById("t1")).thenReturn(Optional.of(t));
        when(threadRepo.save(any())).thenReturn(t);

        long first = chatService.markThreadRead("alice", "t1");
        assertThat(first).isGreaterThan(0);
    }
}
