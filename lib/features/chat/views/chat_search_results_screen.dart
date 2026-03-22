import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_extensions.dart';
import '../models/chat_models.dart';
import 'conversation_screen.dart';

/// Résultats de recherche dans la liste des discussions.
class ChatSearchResultsScreen extends StatelessWidget {
  final String query;
  final List<ChatThread> threads;
  final void Function(String threadId, String lastMsg, String time) onThreadUpdated;

  const ChatSearchResultsScreen({
    super.key,
    required this.query,
    required this.threads,
    required this.onThreadUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom + 20;
    final onTitle = context.oklOnSurface;
    final muted = context.oklOnSurfaceMuted(0.58);

    return Scaffold(
      backgroundColor: context.oklScaffold,
      appBar: AppBar(
        backgroundColor: context.oklScaffold,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: onTitle),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Recherche',
          style: TextStyle(
            color: onTitle,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: threads.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.inbox, size: 48, color: muted),
                    const SizedBox(height: 16),
                    Text(
                      'Aucune conversation pour « $query »',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: onTitle,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Essaie un autre nom ou un mot du dernier message.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: muted, fontSize: 14, height: 1.4),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: EdgeInsets.fromLTRB(20, 12, 20, bottom),
              itemCount: threads.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final chat = threads[i];
                return Material(
                  color: context.oklSurface,
                  borderRadius: BorderRadius.circular(14),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => ConversationScreen(
                            thread: chat,
                            onThreadPreviewUpdated: (last, time) {
                              onThreadUpdated(chat.id, last, time);
                            },
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: chat.isGroup
                                ? Container(
                                    width: 48,
                                    height: 48,
                                    color: AppColors.primary.withValues(alpha: 0.15),
                                    child: Icon(
                                      LucideIcons.users,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : CachedNetworkImage(
                                    imageUrl: chat.avatarUrl,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    memCacheWidth: 160,
                                    placeholder: (c, u) => Container(
                                      width: 48,
                                      height: 48,
                                      color: context.oklScaffold,
                                    ),
                                    errorWidget: (c, u, e) => Container(
                                      width: 48,
                                      height: 48,
                                      color: context.oklScaffold,
                                      child: Icon(
                                        LucideIcons.user,
                                        color: muted,
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        chat.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: onTitle,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      chat.time,
                                      style: TextStyle(
                                        color: muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  chat.lastMsg,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: muted,
                                    fontSize: 13,
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            LucideIcons.chevronRight,
                            color: muted,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
