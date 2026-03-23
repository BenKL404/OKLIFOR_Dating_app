import 'package:flutter/material.dart';

/// Contact démo pour nouvelle discussion / groupe.
class ChatContact {
  final String id;
  final String name;
  final String avatarUrl;

  const ChatContact({
    required this.id,
    required this.name,
    required this.avatarUrl,
  });
}

const kDemoContacts = <ChatContact>[
  ChatContact(
    id: 'yawa',
    name: 'Yawa',
    avatarUrl:
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&q=80&auto=format&fit=crop',
  ),
  ChatContact(
    id: 'kojo',
    name: 'Kojo',
    avatarUrl:
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&q=80&auto=format&fit=crop',
  ),
  ChatContact(
    id: 'akos',
    name: 'Akos',
    avatarUrl:
        'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200&q=80&auto=format&fit=crop',
  ),
  ChatContact(
    id: 'komla',
    name: 'Komla',
    avatarUrl:
        'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200&q=80&auto=format&fit=crop',
  ),
  ChatContact(
    id: 'afia',
    name: 'Afia',
    avatarUrl:
        'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=200&q=80&auto=format&fit=crop',
  ),
  ChatContact(
    id: 'edo',
    name: 'Edo',
    avatarUrl:
        'https://images.unsplash.com/photo-1507591064344-4c6ce005b128?w=200&q=80&auto=format&fit=crop',
  ),
];

enum ChatMessageKind { text, image, video, voice, location, system }

class ChatMessage {
  final String id;
  final ChatMessageKind kind;
  final String? text;
  final String? imageUrl;
  final String? videoUrl;
  final String? audioUrl;
  final int? voiceSeconds;
  final String? locationLabel;
  final bool mine;
  final String time;
  final bool showTail;
  final bool readByRecipient;
  final DateTime? createdAt;

  const ChatMessage({
    required this.id,
    required this.kind,
    this.text,
    this.imageUrl,
    this.videoUrl,
    this.audioUrl,
    this.voiceSeconds,
    this.locationLabel,
    required this.mine,
    required this.time,
    this.showTail = true,
    this.readByRecipient = false,
    this.createdAt,
  });

  ChatMessage copyWith({
    String? id,
    ChatMessageKind? kind,
    String? text,
    String? imageUrl,
    String? videoUrl,
    String? audioUrl,
    int? voiceSeconds,
    String? locationLabel,
    bool? mine,
    String? time,
    bool? showTail,
    bool? readByRecipient,
    DateTime? createdAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      voiceSeconds: voiceSeconds ?? this.voiceSeconds,
      locationLabel: locationLabel ?? this.locationLabel,
      mine: mine ?? this.mine,
      time: time ?? this.time,
      showTail: showTail ?? this.showTail,
      readByRecipient: readByRecipient ?? this.readByRecipient,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Fil de discussion (1:1 ou groupe) pour la liste Messages.
class ChatThread {
  final String id;
  final String name;
  final String lastMsg;
  final String time;
  final String avatarUrl;
  final String statusImageUrl;
  final String statusCaption;
  final String statusTimeAgo;
  final bool hasStory;
  final bool isUnread;
  final int unreadCount;
  final bool online;
  final bool isGroup;
  final int groupMemberCount;
  final bool isMuted;
  final bool isArchived;

  const ChatThread({
    required this.id,
    required this.name,
    required this.lastMsg,
    required this.time,
    required this.avatarUrl,
    required this.statusImageUrl,
    required this.statusCaption,
    required this.statusTimeAgo,
    this.hasStory = false,
    this.isUnread = false,
    this.unreadCount = 0,
    this.online = true,
    this.isGroup = false,
    this.groupMemberCount = 0,
    this.isMuted = false,
    this.isArchived = false,
  });

  ChatThread copyWith({
    String? id,
    String? name,
    String? lastMsg,
    String? time,
    String? avatarUrl,
    String? statusImageUrl,
    String? statusCaption,
    String? statusTimeAgo,
    bool? hasStory,
    bool? isUnread,
    int? unreadCount,
    bool? online,
    bool? isGroup,
    int? groupMemberCount,
    bool? isMuted,
    bool? isArchived,
  }) {
    return ChatThread(
      id: id ?? this.id,
      name: name ?? this.name,
      lastMsg: lastMsg ?? this.lastMsg,
      time: time ?? this.time,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      statusImageUrl: statusImageUrl ?? this.statusImageUrl,
      statusCaption: statusCaption ?? this.statusCaption,
      statusTimeAgo: statusTimeAgo ?? this.statusTimeAgo,
      hasStory: hasStory ?? this.hasStory,
      isUnread: isUnread ?? this.isUnread,
      unreadCount: unreadCount ?? this.unreadCount,
      online: online ?? this.online,
      isGroup: isGroup ?? this.isGroup,
      groupMemberCount: groupMemberCount ?? this.groupMemberCount,
      isMuted: isMuted ?? this.isMuted,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}

/// Conversations initiales affichées dans l’onglet Messages.
List<ChatThread> kSeedThreads = [
  const ChatThread(
    id: 'afi',
    name: 'Afi',
    lastMsg: 'Haha tu es trop drôle 😂',
    time: '14:20',
    avatarUrl:
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&q=80&auto=format&fit=crop',
    statusImageUrl:
        'https://images.unsplash.com/photo-1519834785169-98be25ec3f84?w=1200&q=85&auto=format&fit=crop',
    statusCaption: 'Petit coucher de soleil a Lome.',
    statusTimeAgo: 'il y a 12 min',
    hasStory: true,
    isUnread: true,
    unreadCount: 2,
    online: true,
  ),
  const ChatThread(
    id: 'kofi',
    name: 'Kofi',
    lastMsg: 'RDV demain à Kodjoviakopé ?',
    time: '13:55',
    avatarUrl:
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&q=80&auto=format&fit=crop',
    statusImageUrl:
        'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=1200&q=85&auto=format&fit=crop',
    statusCaption: 'Direction la plage ce soir.',
    statusTimeAgo: 'il y a 1 h',
    isUnread: true,
    unreadCount: 1,
    online: true,
  ),
  const ChatThread(
    id: 'g-weekend',
    name: 'Week-end Lomé',
    lastMsg: 'Kofi : j’apporte les jus 🧃',
    time: '09:41',
    avatarUrl:
        'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=200&q=80&auto=format&fit=crop',
    statusImageUrl:
        'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=1200&q=85&auto=format&fit=crop',
    statusCaption: 'Groupe sortie',
    statusTimeAgo: 'hier',
    isGroup: true,
    groupMemberCount: 5,
    online: false,
  ),
  const ChatThread(
    id: 'sena',
    name: 'Sena',
    lastMsg: 'J\'ai vu ta story 🔥',
    time: '12:30',
    avatarUrl:
        'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=200&q=80&auto=format&fit=crop',
    statusImageUrl:
        'https://images.unsplash.com/photo-1517457373958-b7bdd4587205?w=1200&q=85&auto=format&fit=crop',
    statusCaption: 'Nouveau cafe spot a Tokoin.',
    statusTimeAgo: 'il y a 34 min',
    hasStory: true,
    online: false,
  ),
  const ChatThread(
    id: 'mawuli',
    name: 'Mawuli',
    lastMsg: 'OK je te fais signe',
    time: '11:00',
    avatarUrl:
        'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=200&q=80&auto=format&fit=crop',
    statusImageUrl:
        'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=1200&q=85&auto=format&fit=crop',
    statusCaption: 'Sortie nature du weekend.',
    statusTimeAgo: 'hier',
    online: true,
  ),
];

String formatTimeNow() {
  final n = TimeOfDay.now();
  return '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
}

/// Membres démo pour l’écran détail d’un groupe (aperçu).
List<ChatContact> demoMembersForGroup(ChatThread thread) {
  if (!thread.isGroup) return const [];
  final n = thread.groupMemberCount.clamp(1, kDemoContacts.length);
  return kDemoContacts.take(n).toList();
}

/// Bio courte démo pour le panneau contact 1:1.
String demoPeerBioForThread(ChatThread thread) {
  if (thread.isGroup) return '';
  const map = <String, String>{
    'afi': 'Photographe amateur · sorties plage et concerts.',
    'kofi': 'Ingénieur · Kodjoviakopé · foot le week-end.',
    'sena': 'Cafés et nouveaux spots à Lomé.',
    'mawuli': 'Nature et randos autour de Kpalimé.',
  };
  return map[thread.id] ??
      'Membre Oklifor — présentation visible sur ton profil public (démo).';
}

List<ChatMessage> seedMessagesForThread(String threadId) {
  final now = TimeOfDay.now();
  String t(int h, int m) =>
      '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

  if (threadId.startsWith('dm_')) {
    return [
      ChatMessage(
        id: 'sys',
        kind: ChatMessageKind.system,
        text:
            'Les messages sont chiffrés de bout en bout sur Oklifor (démo). Sois respectueux·se.',
        mine: false,
        time: t(now.hour, now.minute),
      ),
    ];
  }

  if (threadId.startsWith('group_')) {
    return [
      ChatMessage(
        id: '1',
        kind: ChatMessageKind.system,
        text: 'Groupe créé — invite tes ami·e·s à rejoindre la discussion.',
        mine: false,
        time: formatTimeNow(),
      ),
    ];
  }

  switch (threadId) {
    case 'g-weekend':
      return [
        ChatMessage(
          id: '1',
          kind: ChatMessageKind.system,
          text: 'Tu as créé le groupe « Week-end Lomé »',
          mine: false,
          time: t(10, 0),
        ),
        ChatMessage(
          id: '2',
          kind: ChatMessageKind.text,
          text: 'Salut tout le monde ! On se retrouve où samedi ?',
          mine: false,
          time: t(10, 2),
        ),
        ChatMessage(
          id: '3',
          kind: ChatMessageKind.text,
          text: 'Place de la préf ? 16h',
          mine: true,
          time: t(10, 5),
        ),
        ChatMessage(
          id: '4',
          kind: ChatMessageKind.location,
          text: null,
          locationLabel: 'Marché de Tokoin — Lomé',
          mine: false,
          time: t(10, 8),
        ),
      ];
    default:
      return [
        ChatMessage(
          id: 'a',
          kind: ChatMessageKind.text,
          text: 'Coucou, tu es dispo ce soir ?',
          mine: false,
          time: t(now.hour > 0 ? now.hour - 1 : 12, 18),
        ),
        ChatMessage(
          id: 'b',
          kind: ChatMessageKind.image,
          text: null,
          imageUrl:
              'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=600&q=80&auto=format&fit=crop',
          mine: false,
          time: t(now.hour > 0 ? now.hour - 1 : 12, 20),
        ),
        ChatMessage(
          id: 'c',
          kind: ChatMessageKind.text,
          text: 'Yes, vers 19h ça marche 👍',
          mine: true,
          time: t(now.hour, 5),
        ),
        ChatMessage(
          id: 'd',
          kind: ChatMessageKind.voice,
          voiceSeconds: 12,
          mine: false,
          time: t(now.hour, 8),
        ),
      ];
  }
}
