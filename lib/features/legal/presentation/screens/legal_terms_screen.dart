// lib/features/legal/presentation/screens/legal_terms_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/theme/app_theme.dart';

class LegalTermsScreen extends StatefulWidget {
  final bool requireAcceptance;
  final VoidCallback? onAccepted;

  const LegalTermsScreen({
    super.key,
    this.requireAcceptance = false,
    this.onAccepted,
  });

  @override
  State<LegalTermsScreen> createState() => _LegalTermsScreenState();
}

class _LegalTermsScreenState extends State<LegalTermsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _accepted = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        title: const Text('Términos Legales & Privacidad'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.brandGreen,
          labelColor: context.textPrimary,
          unselectedLabelColor: context.textSecondary,
          tabs: const [
            Tab(text: 'Términos de Uso'),
            Tab(text: 'Pagos & Comisión'),
            Tab(text: 'Aviso de Privacidad'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Banner de validez legal
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppTheme.brandGreen.withValues(alpha: 0.12),
                border: Border(bottom: BorderSide(color: AppTheme.brandGreen.withValues(alpha: 0.2))),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_rounded, color: AppTheme.brandGreen, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Vigente conforme a la legislación mercantil y civil de los Estados Unidos Mexicanos (Código de Comercio y Ley Federal de Protección al Consumidor).',
                      style: context.textTheme.labelSmall?.copyWith(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _TermsOfUseTab(),
                  _PaymentAndCommissionTab(),
                  _PrivacyTab(),
                ],
              ),
            ),

            // Footer con aceptación si se requiere
            if (widget.requireAcceptance)
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: context.card,
                  border: Border(top: BorderSide(color: context.border, width: 0.5)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CheckboxListTile(
                      value: _accepted,
                      onChanged: (v) => setState(() => _accepted = v ?? false),
                      title: Text(
                        'He leído, comprendo y acepto los Términos y Condiciones, la Política de Intermediación (comisión del 10%) y el Aviso de Privacidad.',
                        style: context.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppTheme.brandGreen,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _accepted
                            ? () {
                                widget.onAccepted?.call();
                                context.pop(true);
                              }
                            : null,
                        child: const Text('Aceptar y Continuar'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TermsOfUseTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        _clauseCard(
          context,
          number: '1',
          title: 'Naturaleza del Servicio (Marketplace de Intermediación)',
          content:
              'YO FREELANCER es una plataforma tecnológica de contacto e intermediación entre proveedores independientes ("Yoers") y clientes ("Usuarios"). '
              'YO FREELANCER NO es un empleador, patrón ni contratista general. Los Yoers prestan sus servicios por cuenta propia, con sus propias herramientas, '
              'sin subordinación laboral, bajo el régimen de prestación de servicios profesionales o de oficios independientes.',
        ),
        _clauseCard(
          context,
          number: '2',
          title: 'Capacidad Legal y Registro de Usuarios',
          content:
              'Para contratar o prestar servicios en la plataforma, el usuario debe tener al menos 18 años de edad y plena capacidad de goce y ejercicio. '
              'Toda la información proporcionada en el perfil debe ser verídica, actual y comprobable mediante el proceso de validación de identidad (KYC).',
        ),
        _clauseCard(
          context,
          number: '3',
          title: 'Publicidad y Alcance Patrocinado ("Yoer Ads")',
          content:
              'Los Yoers tienen la facultad voluntaria de contratar paquetes de alcance y promoción ("Yoer Ads") para destacar sus servicios en el buscador '
              'y en los carruseles principales. La contratación de publicidad no garantiza contrataciones forzosas, sino mayor volumen de impresiones y visibilidad. '
              'Conforme a las disposiciones de PROFECO, todo contenido impulsado monetariamente llevará la etiqueta visible "Patrocinado".',
        ),
        _clauseCard(
          context,
          number: '4',
          title: 'Seguridad y Conducta Comunitaria',
          content:
              'Queda estrictamente prohibido utilizar la plataforma para ofertar actividades ilícitas, sustancias prohibidas, acoso o fraude. '
              'YO FREELANCER se reserva el derecho de suspender o revocar perfiles que acumulen sanciones, amonestaciones o reportes de fraude.',
        ),
      ],
    );
  }
}

class _PaymentAndCommissionTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        _clauseCard(
          context,
          number: '5',
          title: 'Sistema de Pago en Garantía (Escrow)',
          content:
              'Para salvaguardar los intereses de ambas partes, cuando un cliente paga con tarjeta o método digital, '
              'el dinero es resguardado en garantía (Escrow) dentro de la plataforma. '
              'El monto NO es transferido al Yoer hasta que el cliente confirme la entrega satisfactoria del servicio o transcurran 72 horas sin disputa fundada.',
        ),
        _clauseCard(
          context,
          number: '6',
          title: 'Comisión de Intermediación de la Plataforma (10%)',
          content:
              'Por concepto de uso de la infraestructura tecnológica, validación de identidad, procesamiento bancario y soporte de mediación, '
              'YO FREELANCER retiene una tarifa de intermediación del 10% (diez por ciento) sobre el valor total de cada servicio liquidado.\n\n'
              '• Ejemplo: En un servicio de \$1,000.00 MXN, la plataforma acredita \$900.00 MXN al Yoer y \$100.00 MXN corresponden a la comisión de la plataforma.\n'
              '• Dicha comisión no es reembolsable una vez que el servicio ha sido prestado.',
        ),
        _clauseCard(
          context,
          number: '7',
          title: 'Política de Cancelaciones y Reembolsos',
          content:
              '• Si el cliente cancela con más de 24 horas de anticipación: Reembolso del 100%.\n'
              '• Si el cliente cancela con menos de 24 horas: Cargo de cancelación del 20% para compensar al Yoer.\n'
              '• Si el Yoer no se presenta o cancela: Reembolso íntegro al cliente del 100% y amonestación en el ranking del Yoer.',
        ),
        _clauseCard(
          context,
          number: '8',
          title: 'Retenciones Fiscales (SAT México)',
          content:
              'Conforme al Régimen de Plataformas Tecnológicas del Servicio de Administración Tributaria (SAT), '
              'la plataforma realizará las retenciones de Impuesto sobre la Renta (ISR) e Impuesto al Valor Agregado (IVA) '
              'aplicables a los pagos recibidos por los Yoers según cuenten o no con RFC registrado en su perfil.',
        ),
      ],
    );
  }
}

class _PrivacyTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        _clauseCard(
          context,
          number: '9',
          title: 'Aviso de Privacidad Integral (LFPDPPP)',
          content:
              'YO FREELANCER, con domicilio legal en México, es responsable del tratamiento de sus datos personales. '
              'Sus datos de contacto, geolocalización e identificación biométrica (KYC) son tratados estrictamente para la prestación del servicio, '
              'verificación de identidad, prevención de delitos y facturación.',
        ),
        _clauseCard(
          context,
          number: '10',
          title: 'Derechos ARCO y Seguridad de Datos',
          content:
              'Usted podrá en cualquier momento ejercer sus derechos de Acceso, Rectificación, Cancelación y Oposición (ARCO) '
              'mediante solicitud directa a soporte@yofreelancer.com. La plataforma no vende ni comparte su información financiera sensible con terceros.',
        ),
      ],
    );
  }
}

Widget _clauseCard(
  BuildContext context, {
  required String number,
  required String title,
  required String content,
}) {
  return Card(
    margin: const EdgeInsets.only(bottom: AppSpacing.lg),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.brandGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  number,
                  style: const TextStyle(
                    color: AppTheme.bgDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  title,
                  style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          Text(
            content,
            style: context.textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
        ],
      ),
    ),
  );
}
