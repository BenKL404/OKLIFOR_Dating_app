import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/okl_app_bar_icon_button.dart';
import '../../../core/widgets/okl_pill_search_bar.dart';
import '../models/chat_models.dart';

/// Choisir un contact pour démarrer une conversation (démo).
class NewMessageScreen extends StatefulWidget {
  const NewMessageScreen({super.key});

  @override
  State<NewMessageScreen> createState() => _NewMessageScreenState();
}

class _NewMessageScreenState extends State<NewMessageScreen> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();

  void _onSearchChanged() => setState(() {});

  @override
  void initState() {
    super.initState();
    _search.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _search.removeListener(_onSearchChanged);
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<ChatContact> get _filtered {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return kDemoContacts;
    return kDemoContacts.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.oklScaffold,
      appBar: AppBar(
        backgroundColor: context.oklScaffold,
        leading: const OklAppBarBackButton(rootNavigator: true),
        automaticallyImplyLeading: false,
        title: const Text('Nouveau message'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: OklPillSearchBar(
              controller: _search,
              focusNode: _searchFocus,
              hintText: 'Rechercher un contact…',
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Matchs & contacts',
              style: TextStyle(
                color: context.oklOnSurfaceMuted(0.55),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
              itemCount: _filtered.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                color: context.oklDivider,
                indent: 72,
              ),
              itemBuilder: (context, i) {
                final c = _filtered[i];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  leading: CircleAvatar(
                    radius: 26,
                    backgroundColor: context.oklSurface,
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: c.avatarUrl,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        memCacheWidth: 104,
                        placeholder: (c, u) => Container(color: context.oklSurface),
                      ),
                    ),
                  ),
                  title: Text(
                    c.name,
                    style: TextStyle(
                      color: context.oklOnSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Appuie pour ouvrir la conversation',
                    style: TextStyle(
                      color: (Theme.of(context).textTheme.bodyMedium?.color ??
                              context.oklOnSurfaceMuted(0.62))
                          .withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                  ),
                  trailing: Icon(
                    LucideIcons.chevronRight,
                    color: context.oklOnSurfaceMuted(0.55),
                    size: 18,
                  ),
                  onTap: () => Navigator.pop(context, c),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
