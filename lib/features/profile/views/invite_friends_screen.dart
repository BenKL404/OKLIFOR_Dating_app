import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/okl_app_bar_icon_button.dart';
import '../../../core/flows/okl_flows.dart';
import '../../common/views/contact_qr_hub_screen.dart';

/// Utilisateur dont le profil est public : peut recevoir une invitation.
class _PublicProfileUser {
  final String name;
  final String area;
  final String avatarUrl;
  final String relationHint;

  const _PublicProfileUser({
    required this.name,
    required this.area,
    required this.avatarUrl,
    required this.relationHint,
  });
}

/// Liste démo : uniquement des profils publics (invitation autorisée).
const _invitableUsers = <_PublicProfileUser>[
  _PublicProfileUser(
    name: 'Edem',
    area: 'Kpalimé',
    avatarUrl:
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&q=80&auto=format&fit=crop',
    relationHint: 'Profil public',
  ),
  _PublicProfileUser(
    name: 'Mawuli',
    area: 'Bè, Lomé',
    avatarUrl:
        'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=200&q=80&auto=format&fit=crop',
    relationHint: 'Profil public',
  ),
  _PublicProfileUser(
    name: 'Fati',
    area: 'Adidogome',
    avatarUrl:
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&q=80&auto=format&fit=crop',
    relationHint: 'Profil public',
  ),
  _PublicProfileUser(
    name: 'Kodjo',
    area: 'Sokodé',
    avatarUrl:
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&q=80&auto=format&fit=crop',
    relationHint: 'Profil public',
  ),
  _PublicProfileUser(
    name: 'Yawa',
    area: 'Zanguéra',
    avatarUrl:
        'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200&q=80&auto=format&fit=crop',
    relationHint: 'Profil public',
  ),
];

class InviteFriendsScreen extends StatelessWidget {
  const InviteFriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.oklScaffold,
      appBar: AppBar(
        backgroundColor: context.oklScaffold,
        leading: const OklAppBarBackButton(),
        automaticallyImplyLeading: false,
        title: const Text('Inviter des amis'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: OklAppBarIconButton(
                icon: LucideIcons.qrCode,
                onPressed: () => Navigator.of(context, rootNavigator: true).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const ContactQrHubScreen(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          MediaQuery.paddingOf(context).bottom + 16,
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.oklSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.oklDivider),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  LucideIcons.globe,
                  size: 20,
                  color: context.oklOnSurfaceMuted(0.62),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Seuls les membres avec un profil public acceptent les invitations depuis cette liste. Les profils privés ou restreints n’apparaissent pas.',
                    style: TextStyle(
                      color: context.oklOnSurfaceMuted(0.62).withValues(alpha: 0.95),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Personnes à inviter (${_invitableUsers.length})',
            style: TextStyle(
              color: context.oklOnSurface,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ..._invitableUsers.map(
            (u) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _InviteUserTile(user: u),
            ),
          ),
        ],
      ),
    );
  }
}

class _InviteUserTile extends StatelessWidget {
  final _PublicProfileUser user;

  const _InviteUserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.oklSurface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              ClipOval(
                child: CachedNetworkImage(
                  imageUrl: user.avatarUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  memCacheWidth: 120,
                  placeholder: (ctx, url) => Container(
                    width: 50,
                    height: 50,
                    color: ctx.oklSurface,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: TextStyle(
                        color: context.oklOnSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.area,
                      style: TextStyle(
                        color: context.oklOnSurfaceMuted(0.62),
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Color.alphaBlend(
                          context.oklOnSurface.withValues(alpha: 0.08),
                          context.oklSurface,
                        ),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: context.oklDivider),
                      ),
                      child: Text(
                        user.relationHint,
                        style: TextStyle(
                          color: context.oklOnSurfaceMuted(0.55),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => OklFlows.pushResult(
                  context,
                  icon: LucideIcons.send,
                  title: 'Invitation envoyée',
                  subtitle:
                      '${user.name} recevra un lien pour te rejoindre sur Oklifor.',
                  primaryLabel: 'OK',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Inviter',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
