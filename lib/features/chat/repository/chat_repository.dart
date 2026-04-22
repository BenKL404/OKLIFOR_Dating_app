import 'dart:typed_data';
import '../models/chat_models.dart';

/// Contrat abstrait du dépôt chat — backend ou mock.
abstract class ChatRepository {
  /// Liste de tous les fils de discussion.
  Future<List<ChatThread>> fetchThreads();

  /// Messages paginés d'un fil (les plus récents d'abord).
  Future<List<ChatMessage>> fetchMessages(String threadId, {int page = 0});

  /// Envoie un message texte, retourne le message créé.
  Future<ChatMessage> sendText(String threadId, String text);

  /// Envoie une image (bytes + nom de fichier), retourne le message créé.
  Future<ChatMessage> sendImage(
    String threadId,
    Uint8List bytes,
    String filename, {
    String? caption,
  });

  /// Envoie une vidéo (bytes + nom de fichier), retourne le message créé.
  Future<ChatMessage> sendVideo(
    String threadId,
    Uint8List bytes,
    String filename, {
    String? caption,
  });

  /// Envoie un audio/vocal (bytes + nom), retourne le message créé.
  Future<ChatMessage> sendAudio(
    String threadId,
    Uint8List bytes,
    String filename, {
    int durationSeconds = 0,
  });

  /// Envoie un fichier document (bytes + nom + mime), retourne le message créé.
  Future<ChatMessage> sendFile(
    String threadId,
    Uint8List bytes,
    String filename, {
    String? caption,
  });

  /// Marque un fil comme lu.
  Future<void> markRead(String threadId);

  /// Supprime un message du fil.
  Future<void> deleteMessage(String threadId, String messageId);

  /// Supprime complètement le fil de discussion.
  Future<void> deleteThread(String threadId);

  /// Crée un fil direct avec un contact.
  Future<ChatThread> createDirectThread(String contactId);

  /// Crée un fil de groupe.
  Future<ChatThread> createGroupThread(String name, List<String> memberIds);

  /// Liste des contacts disponibles.
  Future<List<ChatContact>> fetchContacts();

  /// Stream d'événements en temps réel pour un fil (messages entrants, présence…).
  Stream<ChatRepoEvent> watchThread(String threadId);

  /// Libère les ressources (connexions WS, timers…).
  void dispose();
}

// ── Événements temps réel ─────────────────────────────────────────────────

sealed class ChatRepoEvent {
  const ChatRepoEvent();
}

class ChatRepoMessageEvent extends ChatRepoEvent {
  final ChatMessage message;
  const ChatRepoMessageEvent(this.message);
}

class ChatRepoPresenceEvent extends ChatRepoEvent {
  final bool online;
  const ChatRepoPresenceEvent(this.online);
}

class ChatRepoTypingEvent extends ChatRepoEvent {
  final bool typing;
  const ChatRepoTypingEvent(this.typing);
}

class ChatRepoReadEvent extends ChatRepoEvent {
  const ChatRepoReadEvent();
}
