import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/okl_app_bar_icon_button.dart';
import '../../../core/flows/okl_flows.dart';

/// Liste complète des demandes d’amis (même données démo que le profil).
class FriendRequestsListScreen extends StatefulWidget {
  const FriendRequestsListScreen({super.key});

  @override
  State<FriendRequestsListScreen> createState() => _FriendRequestsListScreenState();
}

class _FriendRequestsListScreenState extends State<FriendRequestsListScreen> {
  late List<({String name, String area, String avatar, int mutualFriends})> _items;

  static final _seed = <({
    String name,
    String area,
    String avatar,
    int mutualFriends,
  })>[
    (
      name: 'Sena',
      area: 'Tokoin',
      avatar:
          'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=200&q=80&auto=format&fit=crop',
      mutualFriends: 12,
    ),
    (
      name: 'Kossi',
      area: 'Kegue',
      avatar:
          'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200&q=80&auto=format&fit=crop',
      mutualFriends: 5,
    ),
    (
      name: 'Afi',
      area: 'Agoe',
      avatar:
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&q=80&auto=format&fit=crop',
      mutualFriends: 28,
    ),
    (
      name: 'Mawuli',
      area: 'Hedzranawoé',
      avatar:
          'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=200&q=80&auto=format&fit=crop',
      mutualFriends: 3,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _items = List.of(_seed);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.oklScaffold,
      appBar: AppBar(
        backgroundColor: context.oklScaffold,
        leading: const OklAppBarBackButton(rootNavigator: true),
        automaticallyImplyLeading: false,
        title: const Text('Demandes d’amis'),
      ),
      body: _items.isEmpty
          ? Center(
              child: Text(
                'Aucune demande en attente',
                style: TextStyle(color: context.oklOnSurfaceMuted(0.55)),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: _items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final user = _items[i];
                final nameKey = user.name;
                final mutual = user.mutualFriends;
                final mutualLabel =
                    mutual <= 1 ? '1 ami en commun' : '$mutual amis en commun';
                return Container(
                  decoration: BoxDecoration(
                    color: context.oklSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.oklDivider),
                  ),
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: user.avatar,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          memCacheWidth: 120,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              user.name,
                              style: TextStyle(
                                color: context.oklOnSurface,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$mutualLabel · ${user.area}',
                              style: TextStyle(
                                color: context.oklOnSurfaceMuted(0.62),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton(
                                    onPressed: () {
                                      setState(() => _items.removeWhere((e) => e.name == nameKey));
                                      OklFlows.pushResult(
                                        context,
                                        icon: LucideIcons.userCheck,
                                        title: 'Demande acceptée',
                                        subtitle: '${user.name} fait partie de tes contacts.',
                                        primaryLabel: 'Super',
                                      );
                                    },
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                    child: const Text('Confirmer'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: () {
                                      setState(() => _items.removeWhere((e) => e.name == nameKey));
                                      OklFlows.pushResult(
                                        context,
                                        icon: LucideIcons.userX,
                                        title: 'Demande ignorée',
                                        subtitle:
                                            'Tu peux toujours retrouver ${user.name} dans les suggestions.',
                                        primaryLabel: 'OK',
                                      );
                                    },
                                    style: FilledButton.styleFrom(
                                      backgroundColor: context.oklScaffold,
                                      foregroundColor: context.oklOnSurface,
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                    child: const Text('Ignorer'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
