import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/okl_app_bar_icon_button.dart';
import '../models/chat_models.dart';

class ConversationSearchScreen extends StatefulWidget {
  final String threadName;
  final List<ChatMessage> messages;

  const ConversationSearchScreen({
    super.key,
    required this.threadName,
    required this.messages,
  });

  @override
  State<ConversationSearchScreen> createState() => _ConversationSearchScreenState();
}

class _ConversationSearchScreenState extends State<ConversationSearchScreen> {
  final _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  List<ChatMessage> get _hits {
    final s = _q.text.trim().toLowerCase();
    if (s.isEmpty) return [];
    return widget.messages.where((m) {
      final t = m.text?.toLowerCase() ?? '';
      final loc = m.locationLabel?.toLowerCase() ?? '';
      return t.contains(s) || loc.contains(s);
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final hits = _hits;
    return Scaffold(
      backgroundColor: context.oklScaffold,
      appBar: AppBar(
        backgroundColor: context.oklScaffold,
        leading: const OklAppBarBackButton(rootNavigator: true),
        automaticallyImplyLeading: false,
        title: Text('Recherche · ${widget.threadName}'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _q,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Mot-clé dans les messages…',
                prefixIcon: const Icon(LucideIcons.search, size: 20),
                filled: true,
                fillColor: context.oklSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.oklDivider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.oklDivider),
                ),
              ),
            ),
          ),
          Expanded(
            child: hits.isEmpty
                ? Center(
                    child: Text(
                      _q.text.trim().isEmpty
                          ? 'Tape un mot pour lancer la recherche'
                          : 'Aucun résultat',
                      style: TextStyle(color: context.oklOnSurfaceMuted(0.55)),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: hits.length,
                    separatorBuilder: (context, index) =>
                        Divider(height: 1, color: context.oklDivider),
                    itemBuilder: (context, i) {
                      final m = hits[i];
                      final preview = m.text ??
                          (m.locationLabel != null ? '📍 ${m.locationLabel}' : 'Média');
                      return ListTile(
                        title: Text(
                          preview,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: context.oklOnSurface),
                        ),
                        subtitle: Text(
                          m.time,
                          style: TextStyle(
                            color: context.oklOnSurfaceMuted(0.55),
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
