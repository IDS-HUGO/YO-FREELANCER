// lib/app/config/payment_config.dart

/// Configuración del motor de pagos, comisiones y publicidad patrocinada de YO FREELANCER.
class PaymentConfig {
  const PaymentConfig._();

  /// Modo Sandbox / Pruebas.
  /// Si es true, las transacciones se realizan en ambiente de pruebas (Stripe test,
  /// simulación de fondos garantizados y tarjetas sandbox) sin dinero real.
  /// En producción, configurar con:
  ///   flutter run --dart-define=PAYMENT_SANDBOX=false
  static const bool isSandbox = bool.fromEnvironment('PAYMENT_SANDBOX', defaultValue: true);

  /// Clave pública de Stripe (Publishable Key).
  /// Reemplazar con la clave 'pk_live_...' de tu Stripe Dashboard en producción.
  static const String stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: 'pk_test_51UYyyFBB3LWiU2txiymMbSyfOlRBr9VytbNpPq231XCJBoyQGatWfUvncNCvTB3LbtqxN4HnVub7fhjSmcDIOX1g00pcKKcChJ',
  );

  /// Porcentaje de comisión de la plataforma (Take-Rate de intermediación).
  /// Por defecto: 10% (0.10).
  /// Ejemplo: en un servicio de $1,000 MXN, la plataforma retiene $100 MXN y el Yoer recibe $900 MXN.
  static const double platformFeeRate = 0.10;

  /// Tarifa de procesamiento de pasarela Stripe en México (3.6% + $3.00 MXN + IVA).
  static const double stripePercentFee = 0.036;
  static const double stripeFixedFeeMxn = 3.00;
  static const double vatRate = 0.16; // IVA 16%

  /// Días de custodia de fondos en depósito de garantía (Escrow) antes de liberación automática.
  static const int escrowAutoReleaseDays = 3;

  /// Tarjetas de prueba oficiales de Stripe para modo Sandbox.
  static const List<SandboxTestCard> testCards = [
    SandboxTestCard(
      label: 'Visa - Aprobación Inmediata',
      cardNumber: '4242 4242 4242 4242',
      expiryMonth: 12,
      expiryYear: 2028,
      cvc: '123',
      cardType: 'VISA',
      expectedOutcome: 'Aprobado sin fricción',
      isSuccessful: true,
    ),
    SandboxTestCard(
      label: 'Mastercard - Verificación 3D Secure',
      cardNumber: '4000 0000 0000 3063',
      expiryMonth: 10,
      expiryYear: 2027,
      cvc: '456',
      cardType: 'MASTERCARD',
      expectedOutcome: 'Requiere autenticación bancaria (OTP)',
      isSuccessful: true,
    ),
    SandboxTestCard(
      label: 'Visa - Fondos Insuficientes',
      cardNumber: '4000 0000 0000 0002',
      expiryMonth: 05,
      expiryYear: 2026,
      cvc: '789',
      cardType: 'VISA',
      expectedOutcome: 'Rechazo: Fondos insuficientes para probar error',
      isSuccessful: false,
    ),
  ];

  /// Calcula el desglose financiero exacto de una transacción.
  static PaymentBreakdown calculateBreakdown(double serviceAmount) {
    final platformFee = serviceAmount * platformFeeRate;
    final yoerNet = serviceAmount - platformFee;

    // Estimación del costo de pasarela Stripe sobre el total cobrado
    final gatewayBase = (serviceAmount * stripePercentFee) + stripeFixedFeeMxn;
    final gatewayTotal = gatewayBase * (1 + vatRate);
    final netPlatformProfit = platformFee - gatewayTotal;

    return PaymentBreakdown(
      serviceAmount: serviceAmount,
      platformFeeRate: platformFeeRate,
      platformFee: platformFee,
      yoerNetAmount: yoerNet,
      estimatedGatewayCost: gatewayTotal,
      netPlatformProfit: netPlatformProfit > 0 ? netPlatformProfit : 0.0,
    );
  }
}

/// Representa una tarjeta de prueba precargada en el entorno Sandbox.
class SandboxTestCard {
  final String label;
  final String cardNumber;
  final int expiryMonth;
  final int expiryYear;
  final String cvc;
  final String cardType;
  final String expectedOutcome;
  final bool isSuccessful;

  const SandboxTestCard({
    required this.label,
    required this.cardNumber,
    required this.expiryMonth,
    required this.expiryYear,
    required this.cvc,
    required this.cardType,
    required this.expectedOutcome,
    required this.isSuccessful,
  });

  String get masked => '•••• ${cardNumber.replaceAll(' ', '').substring(12)}';
  String get expiryFormatted => '${expiryMonth.toString().padLeft(2, '0')}/$expiryYear';
}

/// Desglose financiero detallado de una transacción de intermediación.
class PaymentBreakdown {
  final double serviceAmount;
  final double platformFeeRate;
  final double platformFee;
  final double yoerNetAmount;
  final double estimatedGatewayCost;
  final double netPlatformProfit;

  const PaymentBreakdown({
    required this.serviceAmount,
    required this.platformFeeRate,
    required this.platformFee,
    required this.yoerNetAmount,
    required this.estimatedGatewayCost,
    required this.netPlatformProfit,
  });

  String get formattedTotal => '\$${serviceAmount.toStringAsFixed(2)} MXN';
  String get formattedFee => '\$${platformFee.toStringAsFixed(2)} MXN';
  String get formattedYoerNet => '\$${yoerNetAmount.toStringAsFixed(2)} MXN';
  String get feePercentLabel => '${(platformFeeRate * 100).toInt()}%';
}
