import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/okl_app_bar_icon_button.dart';
import '../../common/views/contact_qr_hub_screen.dart';
import '../models/chat_models.dart';

/// Choisir un contact à partager dans la conversation (démo).
class ShareContactScreen extends StatelessWidget {
  final void Function(ChatContact contact) onPick;

  const ShareContactScreen({super.key, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.oklScaffold,
      appBar: AppBar(
        backgroundColor: context.oklScaffold,
        leading: const OklAppBarBackButton(rootNavigator: true),
        automaticallyImplyLeading: false,
        title: const Text('Partager un contact'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: kDemoContacts.length + 1,
        separatorBuilder: (context, index) {
          if (index == 0) return const SizedBox.shrink();
          return Divider(height: 1, color: context.oklDivider);
        },
        itemBuilder: (context, i) {
          if (i == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Ou utilise un code QR : montre ton code ou scanne celui d’un·e ami·e.',
                  style: TextStyle(
                    color: context.oklOnSurfaceMuted(0.62),
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context, rootNavigator: true).push<void>(
                            MaterialPageRoute<void>(
                              builder: (_) => const ContactQrHubScreen(initialTab: 0),
                            ),
                          );
                        },
                        icon: const Icon(LucideIcons.qrCode, size: 18),
                        label: const Text('Mon QR'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.oklOnSurface,
                          side: BorderSide(color: context.oklDivider),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async {
                          final contact = await Navigator.of(context, rootNavigator: true)
                              .push<ChatContact>(
                            MaterialPageRoute<ChatContact>(
                              builder: (_) => const ContactQrHubScreen(
                                popWithScannedContact: true,
                                initialTab: 1,
                              ),
                            ),
                          );
                          if (contact != null && context.mounted) {
                            onPick(contact);
                            Navigator.of(context, rootNavigator: true).pop();
                          }
                        },
                        icon: const Icon(LucideIcons.scanLine, size: 18),
                        label: const Text('Scanner'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Contacts suggérés',
                  style: TextStyle(
                    color: context.oklOnSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
              ],
            );
          }
          final c = kDemoContacts[i - 1];
          return ListTile(
            leading: ClipOval(
              child: CachedNetworkImage(
                imageUrl: c.avatarUrl,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                memCacheWidth: 88,
              ),
            ),
            title: Text(c.name, style: TextStyle(color: context.oklOnSurface)),
            onTap: () {
              onPick(c);
              Navigator.of(context, rootNavigator: true).pop();
            },
          );
        },
      ),
    );
  }
}
