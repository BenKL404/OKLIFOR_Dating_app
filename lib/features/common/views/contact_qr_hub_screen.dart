import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/utils/okl_feedback.dart';
import '../../../core/widgets/okl_app_bar_icon_button.dart';
import '../../../core/flows/okl_flows.dart';
import '../../auth/providers/auth_api_provider.dart';
import '../../chat/models/chat_models.dart';
import '../../chat/utils/okl_contact_qr_codec.dart';
import '../../profile/models/user_profile.dart';

/// Onglets : afficher mon QR · scanner une carte Oklifor.
class ContactQrHubScreen extends StatefulWidget {
  /// 0 = Mon QR, 1 = Scanner
  final int initialTab;

  /// Si vrai, après validation le [Navigator.pop] renvoie le [ChatContact] scanné.
  final bool popWithScannedContact;

  /// Si vrai et [popWithScannedContact] est activé, le contact est d'abord
  /// ajouté via API avant d'être renvoyé à l'écran appelant.
  final bool addContactBeforePop;

  const ContactQrHubScreen({
    super.key,
    this.initialTab = 0,
    this.popWithScannedContact = false,
    this.addContactBeforePop = false,
  });

  @override
  State<ContactQrHubScreen> createState() => _ContactQrHubScreenState();
}

class _ContactQrHubScreenState extends State<ContactQrHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final i = widget.initialTab.clamp(0, 1);
    _tabController = TabController(length: 2, vsync: this, initialIndex: i);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.oklScaffold,
      appBar: AppBar(
        backgroundColor: context.oklScaffold,
        leading: OklAppBarBackButton(
          rootNavigator: true,
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
        automaticallyImplyLeading: false,
        title: const Text(
          'QR & contacts',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: context.oklOnSurfaceMuted(0.55),
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(icon: Icon(LucideIcons.qrCode, size: 20), text: 'Mon code'),
            Tab(icon: Icon(LucideIcons.scanLine, size: 20), text: 'Scanner'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MyQrTab(onShowSampleContacts: () => _showSampleQrSheet(context)),
          _ScanQrTab(
            popWithScannedContact: widget.popWithScannedContact,
            addContactBeforePop: widget.addContactBeforePop,
          ),
        ],
      ),
    );
  }

  void _showSampleQrSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.oklSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Exemples de contacts',
                  style: TextStyle(
                    color: ctx.oklOnSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tu peux afficher l’un de ces codes sur un second écran (ou une capture) pour t’entraîner au scan.',
                  style: TextStyle(
                    color: ctx.oklOnSurfaceMuted(0.62),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                for (final c in kDemoContacts.take(4))
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(
                        alpha: 0.15,
                      ),
                    ),
                    title: Text(
                      c.name,
                      style: TextStyle(
                        color: ctx.oklOnSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      OklContactQrCodec.encodeContact(c),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: ctx.oklOnSurfaceMuted(0.5),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      OklFeedback.alert(
                        context,
                        title: 'QR pour ${c.name}',
                        message:
                            'Utilise l’onglet Scanner après avoir affiché ce QR sur un autre écran, ou copie le lien dans un générateur QR en ligne.\n\n${OklContactQrCodec.encodeContact(c)}',
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MyQrTab extends StatelessWidget {
  final VoidCallback onShowSampleContacts;

  const _MyQrTab({required this.onShowSampleContacts});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UserProfile>(
      valueListenable: ProfileSession.profile,
      builder: (context, profile, _) {
        final data = OklContactQrCodec.encodeMyCard(
          userId: profile.userId,
          displayName: profile.displayName,
        );
        final hasUid = data.isNotEmpty;
        return ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.paddingOf(context).bottom + 24,
          ),
          children: [
            Text(
              'Ton code personnel',
              style: TextStyle(
                color: context.oklOnSurface,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasUid
                  ? 'Les autres peuvent t’ajouter en scannant ce code avec Oklifor. Il contient ton identifiant de compte.'
                  : 'Connecte-toi pour générer un code lié à ton compte. Sans session, aucun identifiant serveur n’est disponible.',
              style: TextStyle(
                color: context.oklOnSurfaceMuted(0.62),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            if (hasUid) ...[
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: data,
                    version: QrVersions.auto,
                    size: 220,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF1A1A1A),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  profile.displayName,
                  style: TextStyle(
                    color: context.oklOnSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SelectableText(
                data,
                style: TextStyle(
                  color: context.oklOnSurfaceMuted(0.5),
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ] else ...[
              Center(
                child: Icon(
                  LucideIcons.qrCode,
                  size: 72,
                  color: context.oklOnSurfaceMuted(0.22),
                ),
              ),
            ],
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onShowSampleContacts,
              icon: const Icon(LucideIcons.users, size: 18),
              label: const Text('Voir des exemples de contacts'),
            ),
          ],
        );
      },
    );
  }
}

class _ScanQrTab extends ConsumerStatefulWidget {
  final bool popWithScannedContact;
  final bool addContactBeforePop;

  const _ScanQrTab({
    required this.popWithScannedContact,
    required this.addContactBeforePop,
  });

  @override
  ConsumerState<_ScanQrTab> createState() => _ScanQrTabState();
}

class _ScanQrTabState extends ConsumerState<_ScanQrTab> {
  late final MobileScannerController _controller;
  final TextEditingController _manualQrController = TextEditingController();
  String? _lastRaw;
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      formats: const [BarcodeFormat.qrCode],
    );
  }

  @override
  void dispose() {
    _manualQrController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_dialogOpen) return;
    if (capture.barcodes.isEmpty) return;
    final raw = capture.barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;
    if (raw == _lastRaw) return;

    final contact = OklContactQrCodec.tryDecode(raw);
    if (contact == null) {
      _lastRaw = raw;
      if (mounted) {
        OklFeedback.alert(
          context,
          title: 'Code non reconnu',
          message: 'Ce QR n’est pas une carte de contact Oklifor.',
        );
      }
      Future<void>.delayed(const Duration(seconds: 2), () {
        if (mounted) _lastRaw = null;
      });
      return;
    }

    _lastRaw = raw;
    _dialogOpen = true;
    await _controller.stop();

    if (!mounted) return;

    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: ctx.oklSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Contact détecté',
            style: TextStyle(
              color: ctx.oklOnSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                contact.name,
                style: TextStyle(
                  color: ctx.oklOnSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'ID : ${contact.id}',
                style: TextStyle(
                  color: ctx.oklOnSurfaceMuted(0.55),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text(
                widget.popWithScannedContact ? 'Partager ce contact' : 'OK',
              ),
            ),
          ],
        );
      },
    );

    _dialogOpen = false;

    if (!mounted) return;

    if (go == true) {
      if (widget.popWithScannedContact) {
        if (widget.addContactBeforePop) {
          final added = await _addContact(contact);
          if (!added) {
            _lastRaw = null;
            await _controller.start();
            return;
          }
        }
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pop(contact);
        return;
      }
      final added = await _addContact(contact);
      if (!added) {
        _lastRaw = null;
        await _controller.start();
        return;
      }
    }

    _lastRaw = null;
    await _controller.start();
  }

  Future<bool> _addContact(ChatContact contact) async {
    try {
      final api = ref.read(okliforApiClientProvider);
      await api.addContactByUserId(contact.id);
    } catch (_) {
      if (!mounted) return false;
      OklFeedback.alert(
        context,
        title: 'Ajout impossible',
        message:
            'Vérifie que le QR appartient à un compte existant et que tu es bien connecté.',
      );
      return false;
    }
    if (!mounted) return true;
    await OklFlows.pushResult(
      context,
      icon: LucideIcons.userPlus,
      title: 'Contact enregistré',
      subtitle:
          '${contact.name} est ajouté à tes contacts et prêt pour la messagerie.',
      primaryLabel: 'Super',
    );
    return true;
  }

  Future<void> _addFromManualQr() async {
    final raw = _manualQrController.text.trim();
    if (raw.isEmpty) {
      OklFeedback.alert(
        context,
        title: 'Code requis',
        message: 'Colle le contenu du QR Oklifor pour ajouter le contact.',
      );
      return;
    }
    final contact = OklContactQrCodec.tryDecode(raw);
    if (contact == null) {
      OklFeedback.alert(
        context,
        title: 'Code non reconnu',
        message: 'Le format ne correspond pas à un QR de contact Oklifor.',
      );
      return;
    }
    await _addContact(contact);
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        children: [
          Text(
            'Ajout sur Web',
            style: TextStyle(
              color: context.oklOnSurface,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'La caméra QR est disponible sur iOS/Android. Sur Web, colle le contenu du QR Oklifor pour ajouter un contact.',
            style: TextStyle(
              color: context.oklOnSurfaceMuted(0.65),
              height: 1.4,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _manualQrController,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'oklifor://profile?uid=...&n=...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _addFromManualQr,
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            icon: const Icon(LucideIcons.userPlus, size: 18),
            label: const Text('Ajouter ce contact'),
          ),
        ],
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: _onDetect,
          errorBuilder: (ctx, err) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Caméra indisponible : ${err.errorCode.name}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.oklOnSurfaceMuted(0.7)),
                ),
              ),
            );
          },
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Cadre le code QR dans la zone de visée',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
