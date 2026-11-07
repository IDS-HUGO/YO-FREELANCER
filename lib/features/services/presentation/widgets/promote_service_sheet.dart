// lib/features/services/presentation/widgets/promote_service_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../payments/data/datasources/payment_remote_datasource.dart';
import '../../domain/entities/ad_campaign_entity.dart';
import '../../domain/entities/service_entity.dart';
import '../viewmodels/service_viewmodel.dart';

class PromoteServiceSheet extends ConsumerStatefulWidget {
  final ServiceEntity service;

  const PromoteServiceSheet({super.key, required this.service});

  static Future<bool?> show(BuildContext context, ServiceEntity service) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PromoteServiceSheet(service: service),
    );
  }

  @override
  ConsumerState<PromoteServiceSheet> createState() => _PromoteServiceSheetState();
}

class _PromoteServiceSheetState extends ConsumerState<PromoteServiceSheet> {
  AdPlanTier _selectedTier = AdPlanTier.proWeekly;
  bool _isProcessing = false;
  PaymentMethodType _selectedPaymentMethod = PaymentMethodType.tarjetaCredito;

  Future<void> _activateCampaign() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isProcessing = true);

    try {
      final success = await ref.read(paymentViewModelProvider.notifier).promoteService(
        serviceId: widget.service.id,
        yoerId: user.id,
        tier: _selectedTier,
        paymentMethod: _selectedPaymentMethod,
      );

      if (!mounted) return;
      setState(() => _isProcessing = false);

      if (success) {
        // Refrescar vitrina y lista de servicios
        await ref.read(serviceViewModelProvider.notifier).getUserServices(user.id);
        await ref.read(serviceViewModelProvider.notifier).getAllServices();

        if (mounted) {
          Navigator.pop(context, true);
          _showSuccessDialog();
        }
      } else {
        final err = ref.read(paymentViewModelProvider).error ?? 'No se pudo activar la campaña';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: context.colors.error),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: context.colors.error),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.rocket_launch_rounded, color: AppTheme.brandGreen, size: 64),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '¡Campaña Publicitaria Activa!',
              style: ctx.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tu servicio "${widget.service.title}" ahora aparecerá destacado en el carrusel principal y en las búsquedas prioritarias de los clientes.',
              style: ctx.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppTheme.brandGreen.withValues(alpha: 0.1),
                borderRadius: AppRadius.mdR,
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: AppTheme.brandGreen, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Alcance estimado: ${_selectedTier.estimatedImpressions}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Entendido'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: context.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: context.textHint.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.campaign_rounded, color: AppTheme.brandGreen, size: 22),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Yoer Ads · Alcance Patrocinado',
                            style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Impulsa tu servicio para llegar a miles de clientes potenciales en tu zona.',
                        style: context.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                // Vista previa de anuncio en vivo
                Text(
                  'VISTA PREVIA DEL ANUNCIO',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: context.textHint,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _LiveAdPreviewCard(
                  service: widget.service,
                  tier: _selectedTier,
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Selección de paquetes
                Text(
                  'ELIGE TU PLAN DE ALCANCE',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: context.textHint,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ...AdPlanTier.values.map((tier) => _TierCard(
                      tier: tier,
                      isSelected: _selectedTier == tier,
                      onTap: () => setState(() => _selectedTier = tier),
                    )),
                const SizedBox(height: AppSpacing.lg),

                // Método de pago
                Text(
                  'MÉTODO DE PAGO (SANDBOX DISPONIBLE)',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: context.textHint,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: _PaymentOptionCard(
                        title: 'Tarjeta Sandbox',
                        subtitle: 'Stripe 4242',
                        icon: Icons.credit_card_rounded,
                        isSelected: _selectedPaymentMethod == PaymentMethodType.tarjetaCredito,
                        onTap: () => setState(() => _selectedPaymentMethod = PaymentMethodType.tarjetaCredito),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _PaymentOptionCard(
                        title: 'Saldo Cartera',
                        subtitle: 'YOER Cash',
                        icon: Icons.account_balance_wallet_rounded,
                        isSelected: _selectedPaymentMethod == PaymentMethodType.efectivo,
                        onTap: () => setState(() => _selectedPaymentMethod = PaymentMethodType.efectivo),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Botón de compra / checkout
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: context.card,
              border: Border(top: BorderSide(color: context.border, width: 0.5)),
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isProcessing ? null : _activateCampaign,
                  child: _isProcessing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.bolt_rounded, size: 20),
                            const SizedBox(width: AppSpacing.sm),
                            Text('Lanzar Campaña · \$${_selectedTier.priceMxn.toStringAsFixed(0)} MXN'),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveAdPreviewCard extends StatelessWidget {
  final ServiceEntity service;
  final AdPlanTier tier;

  const _LiveAdPreviewCard({required this.service, required this.tier});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: AppRadius.lgR,
        border: Border.all(color: AppTheme.brandGreen, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brandGreen.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.brandGreen,
                  borderRadius: AppRadius.pillR,
                ),
                child: Text(
                  tier.badgeLabel,
                  style: const TextStyle(
                    color: AppTheme.bgDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
                decoration: BoxDecoration(
                  color: context.textHint.withValues(alpha: 0.15),
                  borderRadius: AppRadius.pillR,
                ),
                child: Text(
                  'Patrocinado',
                  style: TextStyle(
                    color: context.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                service.priceLabel,
                style: const TextStyle(
                  color: AppTheme.brandGreen,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            service.title,
            style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            service.description,
            style: context.textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _TierCard extends StatelessWidget {
  final AdPlanTier tier;
  final bool isSelected;
  final VoidCallback onTap;

  const _TierCard({
    required this.tier,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: isSelected ? AppTheme.brandGreen.withValues(alpha: 0.1) : context.card,
        borderRadius: AppRadius.lgR,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.lgR,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: AppRadius.lgR,
              border: Border.all(
                color: isSelected ? AppTheme.brandGreen : context.border,
                width: isSelected ? 2 : 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(tier.icon, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                tier.title,
                                style: context.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: isSelected ? AppTheme.brandGreen : context.textPrimary,
                                ),
                              ),
                              if (tier == AdPlanTier.proWeekly) ...[
                                const SizedBox(width: AppSpacing.sm),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF6B3D),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'MÁS POPULAR',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            tier.durationLabel,
                            style: context.textTheme.bodySmall?.copyWith(color: context.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '\$${tier.priceMxn.toStringAsFixed(0)} MXN',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.brandGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm + 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.brandGreen.withValues(alpha: 0.12),
                    borderRadius: AppRadius.smR,
                  ),
                  child: Text(
                    '🎯 Alcance: ${tier.estimatedImpressions}',
                    style: TextStyle(
                      color: isSelected ? AppTheme.brandGreenDark : context.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...tier.highlights.map((h) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_rounded, color: AppTheme.brandGreen, size: 16),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(h, style: context.textTheme.bodySmall?.copyWith(fontSize: 12)),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppTheme.brandGreen.withValues(alpha: 0.1) : context.card,
      borderRadius: AppRadius.mdR,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdR,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadius.mdR,
            border: Border.all(
              color: isSelected ? AppTheme.brandGreen : context.border,
              width: isSelected ? 1.5 : 0.5,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: isSelected ? AppTheme.brandGreen : context.textHint, size: 24),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: isSelected ? context.textPrimary : context.textSecondary,
                      ),
                    ),
                    Text(subtitle, style: TextStyle(color: context.textHint, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
