import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/okl_app_bar_icon_button.dart';
import '../../../core/flows/okl_flows.dart';
import '../../../core/utils/okl_feedback.dart';
import '../models/chat_models.dart';
import '../providers/chat_contacts_provider.dart';

class CreateGroupResult {
  final String name;
  final List<ChatContact> members;

  const CreateGroupResult({required this.name, required this.members});
}

/// Sélection de membres + nom du groupe (démo, max 8 personnes).
class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final Set<String> _selectedIds = {};

  static const _maxMembers = 8;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _toggle(ChatContact c) {
    if (_selectedIds.contains(c.id)) {
      setState(() => _selectedIds.remove(c.id));
      return;
    }
    if (_selectedIds.length >= _maxMembers) {
      OklFlows.pushResult(
        context,
        icon: LucideIcons.users,
        title: 'Limite atteinte',
        subtitle:
            'Tu peux ajouter jusqu’à $_maxMembers personnes dans un groupe pour cette démo.',
        primaryLabel: 'Compris',
      );
      return;
    }
    setState(() => _selectedIds.add(c.id));
  }

  void _submit(List<ChatContact> contacts) {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      OklFeedback.alert(
        context,
        title: 'Nom du groupe',
        message: 'Donne un nom à ton groupe pour continuer.',
      );
      return;
    }
    if (_selectedIds.length < 2) {
      OklFeedback.alert(
        context,
        title: 'Membres',
        message: 'Choisis au moins deux personnes pour créer un groupe.',
      );
      return;
    }
    final members = contacts.where((c) => _selectedIds.contains(c.id)).toList();
    Navigator.pop(context, CreateGroupResult(name: name, members: members));
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(chatContactsProvider);
    return Scaffold(
      backgroundColor: context.oklScaffold,
      appBar: AppBar(
        backgroundColor: context.oklScaffold,
        leading: const OklAppBarBackButton(rootNavigator: true),
        automaticallyImplyLeading: false,
        title: const Text('Nouveau groupe'),
        actions: [
          TextButton(
            onPressed: contactsAsync.maybeWhen(
              data: (contacts) =>
                  () => _submit(contacts),
              orElse: () => null,
            ),
            child: Text(
              'Créer (${_selectedIds.length})',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nom du groupe',
                  style: TextStyle(
                    color: context.oklOnSurfaceMuted(0.55),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  style: TextStyle(color: context.oklOnSurface),
                  decoration: InputDecoration(
                    hintText: 'Ex. Soirée Adidogomé',
                    hintStyle: TextStyle(
                      color:
                          (Theme.of(context).textTheme.bodyMedium?.color ??
                                  context.oklOnSurfaceMuted(0.62))
                              .withValues(alpha: 0.85),
                    ),
                    filled: true,
                    fillColor: context.oklSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Row(
              children: [
                Icon(
                  LucideIcons.users,
                  size: 16,
                  color:
                      Theme.of(context).textTheme.bodyMedium?.color ??
                      context.oklOnSurfaceMuted(0.62),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ajoute entre 2 et $_maxMembers personnes depuis tes matchs.',
                    style: TextStyle(
                      color:
                          (Theme.of(context).textTheme.bodyMedium?.color ??
                                  context.oklOnSurfaceMuted(0.62))
                              .withValues(alpha: 0.95),
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: contactsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) =>
                  const Center(child: Text('Chargement impossible')),
              data: (contacts) => ListView.builder(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: contacts.length,
                itemBuilder: (context, i) {
                  final c = contacts[i];
                  final on = _selectedIds.contains(c.id);
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _toggle(c),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                CircleAvatar(
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
                                if (on)
                                  Positioned(
                                    right: -2,
                                    bottom: -2,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: context.oklScaffold,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        LucideIcons.check,
                                        color: AppColors.primary,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                c.name,
                                style: TextStyle(
                                  color: context.oklOnSurface,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: on
                                      ? AppColors.primary
                                      : context.oklDivider,
                                  width: 2,
                                ),
                                color: on
                                    ? AppColors.primary.withValues(alpha: 0.2)
                                    : null,
                              ),
                              child: on
                                  ? const Icon(
                                      LucideIcons.check,
                                      size: 14,
                                      color: AppColors.primary,
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
