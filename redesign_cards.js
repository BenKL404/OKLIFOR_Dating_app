const fs = require('fs');
const path = 'd:/PDF/oklifor_dating_app/lib/features/chat/views/conversation_screen.dart';
let content = fs.readFileSync(path, 'utf8');

const richBubbleClass = 'class _RichMessageBubble extends StatelessWidget';
const videoBubbleClass = 'class _VideoMessageBubble extends StatelessWidget';
const richStart = content.indexOf(richBubbleClass);
const videoStart = content.indexOf(videoBubbleClass);

const richBuildMarker = '  @override\n  Widget build(BuildContext context) {\n    final m = message;\n    switch (m.kind) {';
const richBuildStart = content.indexOf(richBuildMarker, richStart);
if (richBuildStart === -1) { console.log('MISS build marker'); process.exit(1); }

// New build method + helper classes (inserted between _RichMessageBubble and _VideoMessageBubble)
const newBuildSection = `  @override
  Widget build(BuildContext context) {
    final m = message;
    switch (m.kind) {

      // ── System ────────────────────────────────────────────────────────────
      case ChatMessageKind.system:
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              m.text ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.oklOnSurfaceMuted(0.60),
                fontSize: 11.5,
                height: 1.3,
              ),
            ),
          ),
        );

      // ── Image ─────────────────────────────────────────────────────────────
      case ChatMessageKind.image:
        final heroTag = 'chat_img_\${m.id}';
        final imageUrl = (m.imageUrl ?? '').trim();
        final imgBr = _bubbleRadius(m.mine);
        Widget imgShell(Widget child) => ClipRRect(
              borderRadius: imgBr,
              child: SizedBox(width: 250, height: 320, child: child),
            );
        if (imageUrl.isEmpty) {
          return Align(
            alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
            child: imgShell(Container(
              color: m.mine ? _chatOutgoingBubble(context) : _chatIncomingBubble(context),
              alignment: Alignment.center,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(LucideIcons.imageOff, size: 30, color: Colors.white.withValues(alpha: 0.35)),
                const SizedBox(height: 6),
                Text('Image indisponible',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11)),
              ]),
            )),
          );
        }
        return Align(
          alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: m.mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!m.mine)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 3),
                  child: Text(peerDisplayName,
                      style: TextStyle(
                          color: AppColors.primary.withValues(alpha: 0.9),
                          fontSize: 11.5, fontWeight: FontWeight.w600)),
                ),
              Material(
                color: Colors.transparent,
                borderRadius: imgBr,
                child: InkWell(
                  onTap: onTapImage,
                  borderRadius: imgBr,
                  child: Hero(
                    tag: heroTag,
                    child: imgShell(Stack(fit: StackFit.expand, children: [
                      CachedNetworkImage(
                        imageUrl: imageUrl,
                        cacheManager: _chatMediaCache,
                        fit: BoxFit.cover,
                        memCacheWidth: 520,
                        placeholder: (c, u) =>
                            Container(color: Colors.black.withValues(alpha: 0.4)),
                        errorWidget: (c, u, e) => Container(
                          color: Colors.black.withValues(alpha: 0.5),
                          alignment: Alignment.center,
                          child: Icon(LucideIcons.imageOff, size: 28,
                              color: Colors.white.withValues(alpha: 0.35)),
                        ),
                      ),
                      Positioned(
                        bottom: 0, left: 0, right: 0,
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.70),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      if ((m.text ?? '').trim().isNotEmpty)
                        Positioned(
                          bottom: 26, left: 10, right: 44,
                          child: Text(
                            (m.text ?? '').trim(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12.5, height: 1.25,
                                shadows: [Shadow(color: Colors.black54, blurRadius: 4)]),
                          ),
                        ),
                      Positioned(
                        bottom: 8, right: 10,
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(m.time,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  shadows: [Shadow(color: Colors.black54, blurRadius: 4)])),
                          if (m.mine) ...[
                            const SizedBox(width: 4),
                            _ReadReceiptTicks(message: m, forDarkBackground: true),
                          ],
                        ]),
                      ),
                    ])),
                  ),
                ),
              ),
              if (reactionEmoji != null)
                _ReactionBadge(emoji: reactionEmoji!, mine: m.mine),
            ],
          ),
        );

      // ── Video ─────────────────────────────────────────────────────────────
      case ChatMessageKind.video:
        return _VideoMessageBubble(
          message: m, peerDisplayName: peerDisplayName,
          peerAvatarUrl: peerAvatarUrl, reactionEmoji: reactionEmoji,
        );

      // ── Voice ─────────────────────────────────────────────────────────────
      case ChatMessageKind.voice:
        return _WhatsAppStyleVoiceBubble(message: m, onMessageMenu: onMessageMenu);

      // ── Location ──────────────────────────────────────────────────────────
      case ChatMessageKind.location:
        final locBr = _bubbleRadius(m.mine);
        return Align(
          alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
          child: ClipRRect(
            borderRadius: locBr,
            child: Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width * 0.72),
              decoration: BoxDecoration(
                color: m.mine ? _chatOutgoingBubble(context) : _chatIncomingBubble(context),
                borderRadius: locBr,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 112, width: double.infinity,
                    color: Colors.black.withValues(alpha: 0.28),
                    child: Stack(alignment: Alignment.center, children: [
                      Icon(LucideIcons.map, size: 64,
                          color: Colors.white.withValues(alpha: 0.07)),
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primary, shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.40), blurRadius: 10)
                          ],
                        ),
                        child: const Icon(LucideIcons.mapPin, color: Colors.white, size: 18),
                      ),
                    ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(13, 9, 13, 9),
                    child: Row(children: [
                      Expanded(
                        child: Text(
                          m.locationLabel ?? 'Position partagée',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontSize: 13.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (m.mine) ...[
                        _ReadReceiptTicks(message: m, forDarkBackground: true),
                        const SizedBox(width: 4),
                      ],
                      Text(m.time,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.55), fontSize: 10)),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        );

      // ── File ──────────────────────────────────────────────────────────────
      case ChatMessageKind.file:
        return _DocumentMessageCard(message: m);

      // ── Text ──────────────────────────────────────────────────────────────
      case ChatMessageKind.text:
        final parsed = _splitReplyPayload(m.text);
        final hasReply = parsed.repliedPreview != null;
        final txtBr = _bubbleRadius(m.mine);
        final bg = m.mine ? _chatOutgoingBubble(context) : _chatIncomingBubble(context);
        return Align(
          alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: m.mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!m.mine)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 2),
                  child: Text(peerDisplayName,
                      style: TextStyle(
                          color: AppColors.primary.withValues(alpha: 0.9),
                          fontSize: 11.5, fontWeight: FontWeight.w600)),
                ),
              Container(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width * 0.78),
                decoration: BoxDecoration(color: bg, borderRadius: txtBr),
                padding: const EdgeInsets.fromLTRB(13, 9, 13, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasReply)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 7),
                        padding: const EdgeInsets.fromLTRB(10, 7, 8, 7),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Container(
                            width: 3, height: 32,
                            margin: const EdgeInsets.only(right: 8, top: 1),
                            decoration: BoxDecoration(
                              color: m.mine
                                  ? Colors.white.withValues(alpha: 0.55)
                                  : AppColors.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Expanded(
                            child: Text(parsed.repliedPreview!,
                                maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.80),
                                    fontSize: 12, height: 1.25)),
                          ),
                        ]),
                      ),
                    _InlineTimedText(
                        text: parsed.body, time: m.time,
                        mine: m.mine, message: m),
                  ],
                ),
              ),
              if (reactionEmoji != null)
                _ReactionBadge(emoji: reactionEmoji!, mine: m.mine),
            ],
          ),
        );
    }
  }
}

// ── Inline text + time (text flows naturally, time is overlaid bottom-right) ─

class _InlineTimedText extends StatelessWidget {
  final String text;
  final String time;
  final bool mine;
  final ChatMessage message;
  const _InlineTimedText(
      {required this.text, required this.time, required this.mine, required this.message});

  @override
  Widget build(BuildContext context) {
    final textColor = Colors.white.withValues(alpha: mine ? 0.95 : 0.88);
    final timeColor = Colors.white.withValues(alpha: 0.52);
    const ts = TextStyle(fontSize: 14.5, height: 1.35);
    // Invisible spacer appended to text reserves room so time never overlaps last word.
    final spacer = mine ? '        ' : '      ';
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        RichText(
          text: TextSpan(children: [
            TextSpan(text: text, style: ts.copyWith(color: textColor)),
            TextSpan(text: spacer, style: ts.copyWith(color: Colors.transparent)),
          ]),
        ),
        Row(mainAxisSize: MainAxisSize.min, children: [
          Text(time, style: TextStyle(color: timeColor, fontSize: 10.5)),
          if (mine) ...[
            const SizedBox(width: 3),
            _ReadReceiptTicks(message: message, forDarkBackground: true),
          ],
        ]),
      ],
    );
  }
}

// ── Reaction emoji badge ───────────────────────────────────────────────────

class _ReactionBadge extends StatelessWidget {
  final String emoji;
  final bool mine;
  const _ReactionBadge({required this.emoji, required this.mine});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(mine ? -6 : 6, -2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: context.oklSurface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 14)),
      ),
    );
  }
}

`;

// Splice: replace from build marker to end of class (just before videoBubbleClass)
const oldSection = content.slice(richBuildStart, videoStart);
// The old section ends with "}\n}\n\n" - the class closing brace + blank line
const newContent = content.slice(0, richBuildStart) + newBuildSection + '\n' + content.slice(videoStart);
fs.writeFileSync(path, newContent, 'utf8');
console.log('Replaced _RichMessageBubble.build() + added helper classes');
console.log('New line count:', newContent.split('\n').length);
