import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/utils/okl_feedback.dart';
import '../../../core/widgets/okl_app_bar_icon_button.dart';
import '../models/vip_subscription.dart';

/// Opérateur mobile money (noms génériques — intégration réelle plus tard).
class _MomoOperator {
  final String id;
  final String name;
  final String subtitle;
  final Color accent;
  final IconData icon;

  const _MomoOperator({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.accent,
    required this.icon,
  });
}

const _operators = <_MomoOperator>[
  _MomoOperator(
    id: 'tmoney',
    name: 'T Money',
    subtitle: 'Togocom · paiement sécurisé',
    accent: Color(0xFF0066CC),
    icon: LucideIcons.smartphone,
  ),
  _MomoOperator(
    id: 'flooz',
    name: 'Flooz',
    subtitle: 'Moov Africa · compte mobile',
    accent: Color(0xFFE87722),
    icon: LucideIcons.wallet,
  ),
  _MomoOperator(
    id: 'mixx',
    name: 'Mixx by Yas',
    subtitle: 'Yas Togo',
    accent: Color(0xFF00A651),
    icon: LucideIcons.banknote,
  ),
];

class _PlanOption {
  final String id;
  final String title;
  final String priceLabel;
  final String detail;
  final Duration validity;
  final String? badge;

  const _PlanOption({
    required this.id,
    required this.title,
    required this.priceLabel,
    required this.detail,
    required this.validity,
    this.badge,
  });
}

const _plans = <_PlanOption>[
  _PlanOption(
    id: 'monthly',
    title: 'Mensuel',
    priceLabel: '2 500 FCFA',
    detail: 'par mois · résiliable à tout moment',
    validity: Duration(days: 30),
  ),
  _PlanOption(
    id: 'yearly',
    title: 'Annuel',
    priceLabel: '24 000 FCFA',
    detail: 'par an · équivalent à 2 000 FCFA / mois',
    validity: Duration(days: 365),
    badge: 'Économise ~20 %',
  ),
];

/// Parcours complet : choix du plan → mobile money → numéro → simulation USSD → succès.
class VipPassScreen extends StatefulWidget {
  const VipPassScreen({super.key});

  @override
  State<VipPassScreen> createState() => _VipPassScreenState();
}

class _VipPassScreenState extends State<VipPassScreen> {
  int _step = 0;
  String _planId = 'monthly';
  String _operatorId = _operators.first.id;
  final _phoneCtrl = TextEditingController(text: '90 12 34 56');
  Timer? _mockTimer;

  _PlanOption get _selectedPlan =>
      _plans.firstWhere((p) => p.id == _planId, orElse: () => _plans.first);

  _MomoOperator get _selectedOperator =>
      _operators.firstWhere((o) => o.id == _operatorId, orElse: () => _operators.first);

  @override
  void dispose() {
    _mockTimer?.cancel();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _goStep(int s) => setState(() => _step = s);

  void _startMockPayment() {
    _goStep(3);
    _mockTimer?.cancel();
    _mockTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      VipSession.activate(
        planId: _planId,
        validity: _selectedPlan.validity,
      );
      _goStep(4);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: context.oklScaffold,
      appBar: AppBar(
        backgroundColor: context.oklScaffold,
        leading: OklAppBarBackButton(
          onPressed: () {
            if (_step > 0 && _step < 4) {
              _goStep(_step - 1);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        automaticallyImplyLeading: false,
        title: Text(
          _step == 4 ? 'Pass VIP activé' : 'Pass VIP Oklifor',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: switch (_step) {
        0 => _buildPlansStep(context, bottom),
        1 => _buildOperatorsStep(context, bottom),
        2 => _buildPhoneStep(context, bottom),
        3 => _buildProcessingStep(context),
        4 => _buildSuccessStep(context, bottom),
        _ => const SizedBox.shrink(),
      },
    );
  }

  Widget _buildPlansStep(BuildContext context, double bottom) {
    final active = VipSession.subscription.value;
    return ListView(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + bottom),
      children: [
        if (active.isActive) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.green.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.checkCircle2, color: AppColors.green, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tu as déjà le Pass VIP jusqu’au ${active.expiresLabelFr}. '
                    'Tu peux prolonger avec un nouveau paiement (démo).',
                    style: TextStyle(
                      color: context.oklOnSurfaceMuted(0.78),
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.togoGold.withValues(alpha: 0.22),
                AppColors.primary.withValues(alpha: 0.12),
              ],
            ),
            border: Border.all(color: AppColors.togoGold.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.crown, color: AppColors.togoGold, size: 36),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Obtenir mon Pass VIP',
                      style: TextStyle(
                        color: context.oklOnSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Paiement par mobile money (simulation). Aucun prélèvement réel.',
                      style: TextStyle(
                        color: context.oklOnSurfaceMuted(0.65),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Avantages',
          style: TextStyle(
            color: context.oklOnSurface,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        _benefitRow(context, LucideIcons.heart, 'Voir qui t’a liké'),
        _benefitRow(context, LucideIcons.sparkles, 'Super likes boostés (démo)'),
        _benefitRow(context, LucideIcons.crown, 'Badge VIP sur ton profil'),
        _benefitRow(context, LucideIcons.mapPin, 'Visibilité renforcée dans Sorties'),
        const SizedBox(height: 24),
        Text(
          'Formule',
          style: TextStyle(
            color: context.oklOnSurface,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        for (final p in _plans)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: context.oklSurface,
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => setState(() => _planId = p.id),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _planId == p.id
                          ? AppColors.primary
                          : context.oklDivider,
                      width: _planId == p.id ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _planId == p.id
                            ? LucideIcons.checkCircle2
                            : LucideIcons.circle,
                        color: _planId == p.id ? AppColors.primary : context.oklOnSurfaceMuted(0.45),
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  p.title,
                                  style: TextStyle(
                                    color: context.oklOnSurface,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                                if (p.badge != null) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.togoGold.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      p.badge!,
                                      style: TextStyle(
                                        color: AppColors.togoGold.withValues(alpha: 0.95),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              p.priceLabel,
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              p.detail,
                              style: TextStyle(
                                color: context.oklOnSurfaceMuted(0.58),
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _goStep(1),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.togoGold,
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(LucideIcons.smartphone, size: 22),
            label: const Text(
              'Payer avec Mobile Money',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _benefitRow(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: context.oklOnSurfaceMuted(0.85),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperatorsStep(BuildContext context, double bottom) {
    return ListView(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + bottom),
      children: [
        Text(
          'Choisis ton opérateur',
          style: TextStyle(
            color: context.oklOnSurface,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Montant : ${_selectedPlan.priceLabel} — ${_selectedPlan.title.toLowerCase()}',
          style: TextStyle(color: context.oklOnSurfaceMuted(0.62), fontSize: 14),
        ),
        const SizedBox(height: 20),
        for (final o in _operators)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: context.oklSurface,
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => setState(() => _operatorId = o.id),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _operatorId == o.id ? o.accent : context.oklDivider,
                      width: _operatorId == o.id ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: o.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(o.icon, color: o.accent, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              o.name,
                              style: TextStyle(
                                color: context.oklOnSurface,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              o.subtitle,
                              style: TextStyle(
                                color: context.oklOnSurfaceMuted(0.58),
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_operatorId == o.id)
                        Icon(LucideIcons.checkCircle2, color: o.accent, size: 22),
                    ],
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => _goStep(2),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Continuer', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneStep(BuildContext context, double bottom) {
    return ListView(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + bottom),
      children: [
        Text(
          'Numéro Mobile Money',
          style: TextStyle(
            color: context.oklOnSurface,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Entre le numéro débité pour ${_selectedOperator.name}. '
          'En production, une demande USSD ou une appli banque confirmerait le paiement.',
          style: TextStyle(
            color: context.oklOnSurfaceMuted(0.62),
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          style: TextStyle(color: context.oklOnSurface, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            labelText: 'Numéro (ex. 90 XX XX XX)',
            filled: true,
            fillColor: context.oklSurface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.oklSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.oklDivider),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LucideIcons.info, size: 18, color: context.oklOnSurfaceMuted(0.55)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Simulation : aucun SMS ni débit réel. Appuie sur « Confirmer » pour valider le scénario démo.',
                  style: TextStyle(
                    color: context.oklOnSurfaceMuted(0.65),
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              final digits = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
              if (digits.length < 8) {
                OklFeedback.alert(
                  context,
                  title: 'Numéro incomplet',
                  message: 'Entre au moins 8 chiffres pour le compte Mobile Money.',
                );
                return;
              }
              _startMockPayment();
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.togoGold,
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(LucideIcons.check, size: 22),
            label: const Text(
              'Confirmer le paiement (démo)',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProcessingStep(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'En attente de validation…',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.oklOnSurface,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Sur ton téléphone, valide la demande ${_selectedOperator.name} '
              '(simulation — rien n’apparaît en vrai).',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.oklOnSurfaceMuted(0.65),
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessStep(BuildContext context, double bottom) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.togoGold.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.crown, size: 48, color: AppColors.togoGold),
          ),
          const SizedBox(height: 28),
          Text(
            'Bienvenue en VIP !',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.oklOnSurface,
              fontWeight: FontWeight.w800,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${_selectedPlan.title} activé · valable jusqu’au ${VipSession.subscription.value.expiresLabelFr}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.oklOnSurfaceMuted(0.68),
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          ...[
            'Profil avec badge couronne',
            'Accès « Qui m’a liké »',
            'Boost dans Sorties',
          ].map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(LucideIcons.check, size: 18, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      t,
                      style: TextStyle(
                        color: context.oklOnSurfaceMuted(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Retour au profil', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}
