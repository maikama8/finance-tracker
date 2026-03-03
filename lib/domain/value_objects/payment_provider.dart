import 'package:equatable/equatable.dart';

/// Enum representing supported payment providers
enum PaymentProviderType {
  paystack,
  flutterwave,
  stripe,
  paypal,
  razorpay,
}

/// Value object representing a payment provider with regional availability
class PaymentProvider extends Equatable {
  final PaymentProviderType type;
  final String name;
  final String displayName;
  final List<String> supportedRegions; // ISO 3166-1 alpha-2 country codes
  final bool isGlobal;

  const PaymentProvider({
    required this.type,
    required this.name,
    required this.displayName,
    required this.supportedRegions,
    this.isGlobal = false,
  });

  // Provider constants
  static const PaymentProvider paystack = PaymentProvider(
    type: PaymentProviderType.paystack,
    name: 'paystack',
    displayName: 'Paystack',
    supportedRegions: ['NG', 'GH', 'ZA', 'KE'],
    isGlobal: false,
  );

  static const PaymentProvider flutterwave = PaymentProvider(
    type: PaymentProviderType.flutterwave,
    name: 'flutterwave',
    displayName: 'Flutterwave',
    supportedRegions: ['NG', 'GH', 'ZA', 'KE', 'UG', 'TZ'],
    isGlobal: false,
  );

  static const PaymentProvider stripe = PaymentProvider(
    type: PaymentProviderType.stripe,
    name: 'stripe',
    displayName: 'Stripe',
    supportedRegions: [],
    isGlobal: true,
  );

  static const PaymentProvider paypal = PaymentProvider(
    type: PaymentProviderType.paypal,
    name: 'paypal',
    displayName: 'PayPal',
    supportedRegions: [],
    isGlobal: true,
  );

  static const PaymentProvider razorpay = PaymentProvider(
    type: PaymentProviderType.razorpay,
    name: 'razorpay',
    displayName: 'Razorpay',
    supportedRegions: ['IN'],
    isGlobal: false,
  );

  /// List of all supported providers
  static const List<PaymentProvider> allProviders = [
    paystack,
    flutterwave,
    stripe,
    paypal,
    razorpay,
  ];

  /// Check if this provider is available in the given region
  bool isAvailableInRegion(String countryCode) {
    if (isGlobal) return true;
    return supportedRegions.contains(countryCode.toUpperCase());
  }

  /// Get a description of the provider
  String get description {
    if (isGlobal) {
      return 'Available worldwide';
    }
    return 'Available in ${supportedRegions.join(", ")}';
  }

  @override
  List<Object?> get props => [type, name, displayName, supportedRegions, isGlobal];

  @override
  String toString() => displayName;
}
