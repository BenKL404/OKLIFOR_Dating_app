import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../auth/providers/auth_api_provider.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/okl_app_bar_icon_button.dart';
import '../../../core/widgets/okl_pill_search_bar.dart';
import '../../common/views/contact_qr_hub_screen.dart';
import '../models/chat_models.dart';

/// Choisir un contact pour démarrer une conversation (démo).
class NewMessageScreen extends ConsumerStatefulWidget {
  const NewMessageScreen({super.key});

  @override
  ConsumerState<NewMessageScreen> createState() => _NewMessageScreenState();
}

class _NewMessageScreenState extends ConsumerState<NewMessageScreen> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  List<ChatContact> _contacts = List<ChatContact>.from(kDemoContacts);
  bool _loading = true;

  void _onSearchChanged() => setState(() {});

  @override
  void initState() {
    super.initState();
    _search.addListener(_onSearchChanged);
    _loadContacts();
  }

  @override
  void dispose() {
    _search.removeListener(_onSearchChanged);
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    try {
      final api = ref.read(okliforApiClientProvider);
      final payloads = await api.fetchContacts();
      final mapped = payloads
          .map(
            (p) => ChatContact(
              id: p.userId,
              name: p.displayName.isEmpty ? 'Profil Oklifor' : p.displayName,
              avatarUrl: p.avatarUrl,
            ),
          )
          .toList(growable: false);
      if (!mounted) return;
      setState(() {
        _contacts = mapped.isEmpty ? <ChatContact>[] : mapped;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _contacts = List<ChatContact>.from(kDemoContacts);
        _loading = false;
      });
    }
  }

  List<ChatContact> get _filtered {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _contacts;
    return _contacts.where((c) => c.name.toLowerCase().contains(q)).toList();
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () async {
                final nav = Navigator.of(context, rootNavigator: true);
                final scanned = await nav.push<ChatContact>(
                  MaterialPageRoute<ChatContact>(
                    builder: (_) => const ContactQrHubScreen(
                      initialTab: 1,
                      popWithScannedContact: true,
                      addContactBeforePop: true,
                    ),
                  ),
                );
                if (!mounted || !context.mounted || scanned == null) return;
                Navigator.of(context).pop(scanned);
              },
              icon: const Icon(LucideIcons.scanLine, size: 18),
              label: const Text('Ajouter via QR et ouvrir la discussion'),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                ? Center(
                    child: Text(
                      'Aucun contact pour le moment.\nAjoute-en via QR pour démarrer une conversation.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.oklOnSurfaceMuted(0.62),
                        height: 1.4,
                      ),
                    ),
                  )
                : ListView.separated(
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
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
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
                              placeholder: (c, u) =>
                                  Container(color: context.oklSurface),
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
                            color:
                                (Theme.of(
                                          context,
                                        ).textTheme.bodyMedium?.color ??
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
