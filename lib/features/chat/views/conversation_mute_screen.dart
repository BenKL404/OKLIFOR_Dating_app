import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/okl_app_bar_icon_button.dart';
import '../../../core/flows/okl_flows.dart';

class ConversationMuteScreen extends StatefulWidget {
  final String threadName;

  const ConversationMuteScreen({super.key, required this.threadName});

  @override
  State<ConversationMuteScreen> createState() => _ConversationMuteScreenState();
}

class _ConversationMuteScreenState extends State<ConversationMuteScreen> {
  bool _muted = false;
  bool _mentions = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.oklScaffold,
      appBar: AppBar(
        backgroundColor: context.oklScaffold,
        leading: const OklAppBarBackButton(rootNavigator: true),
        automaticallyImplyLeading: false,
        title: Text('Notifications · ${widget.threadName}'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          SwitchListTile(
            value: _muted,
            onChanged: (v) => setState(() => _muted = v),
            title: Text('Silencieux', style: TextStyle(color: context.oklOnSurface)),
            subtitle: Text(
              'Aucune alerte sauf si tu ouvres la conversation',
              style: TextStyle(color: context.oklOnSurfaceMuted(0.55), fontSize: 12),
            ),
          ),
          SwitchListTile(
            value: _mentions,
            onChanged: _muted ? null : (v) => setState(() => _mentions = v),
            title: Text('Mentions @', style: TextStyle(color: context.oklOnSurface)),
            subtitle: Text(
              'Garder une alerte si quelqu’un te mentionne',
              style: TextStyle(color: context.oklOnSurfaceMuted(0.55), fontSize: 12),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              final muted = _muted;
              OklFlows.pushResult(
                context,
                icon: muted ? LucideIcons.bellOff : LucideIcons.bell,
                title: muted ? 'Silencieux activé' : 'Notifications normales',
                subtitle: muted
                    ? 'Tu ne seras plus alerté·e sauf si tu ouvres la conversation.'
                    : 'Tu recevras à nouveau les alertes pour ${widget.threadName}.',
                primaryLabel: 'OK',
              ).then((_) {
                if (context.mounted) Navigator.of(context).pop();
              });
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}
