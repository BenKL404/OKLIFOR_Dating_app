import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/okl_app_bar_icon_button.dart';
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
        itemCount: kDemoContacts.length,
        separatorBuilder: (context, index) => Divider(height: 1, color: context.oklDivider),
        itemBuilder: (context, i) {
          final c = kDemoContacts[i];
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
