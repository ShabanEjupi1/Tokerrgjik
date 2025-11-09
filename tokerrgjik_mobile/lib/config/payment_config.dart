/// Payment Configuration
/// Stores PayPal credentials and payment settings
class PaymentConfig {
  // PayPal Configuration - PRODUCTION MODE
  // These credentials are loaded from environment variables at runtime
  static String paypalClientId = const String.fromEnvironment(
    'PAYPAL_CLIENT_ID',
    defaultValue: 'AbOjnPTlKSYSn9LB3giuWOl7jjz8jK1IQUS4p4Ne9z5_IhPTUKe1XPK00m67oieLNwPLqGOn3OqXZSrt'
  );
  static String paypalSecret = const String.fromEnvironment(
    'PAYPAL_SECRET',
    defaultValue: 'EIX2J4bpnNzkXM9hB6y-enX0IOU-XCeB-8AXRZs95Ujf81l60jpTF_fblvVpa0X5nOWqYN31DA6TuXAR'
  );
  static bool useSandbox = const bool.fromEnvironment('PAYPAL_SANDBOX', defaultValue: false); // PRODUCTION MODE
  
  // Payment Packages
  static const Map<String, Map<String, dynamic>> proPackages = {
    '1month': {
      'name': 'TOKERRGJIK PRO - 1 Muaj',
      'months': 1,
      'price': '€2.99',
      'priceValue': 2.99,
      'features': [
        '✓ Pa reklama për 1 muaj',
        '✓ Themes ekskluzive',
        '✓ 100 monedha bonus',
      ],
    },
    '12months': {
      'name': 'TOKERRGJIK PRO - 12 Muaj',
      'months': 12,
      'price': '€20.82',
      'priceValue': 20.82,
      'originalPrice': '€41.64',
      'discount': '50% ZBRITJE!',
      'features': [
        '✓ Pa reklama për gjithmonë',
        '✓ Themes ekskluzive',
        '✓ Ikona dhe ngjyra të personalizuara',
        '✓ 1000 monedha bonus',
        '✓ Badge "PRO" në leaderboard',
        '✓ Mbështetje me prioritet',
      ],
    },
  };
  
  static const Map<String, Map<String, dynamic>> coinPackages = {
    '100': {
      'coins': 100,
      'price': '€0.99',
      'priceValue': 0.99,
      'bonus': 0,
    },
    '500': {
      'coins': 500,
      'price': '€3.99',
      'priceValue': 3.99,
      'bonus': 50,
      'label': '+50 BONUS',
    },
    '1000': {
      'coins': 1000,
      'price': '€6.99',
      'priceValue': 6.99,
      'bonus': 150,
      'label': '+150 BONUS',
    },
    '2500': {
      'coins': 2500,
      'price': '€14.99',
      'priceValue': 14.99,
      'bonus': 500,
      'label': '+500 BONUS',
      'popular': true,
    },
  };
  
  /// Set PayPal credentials (call this at app startup)
  static void setPayPalCredentials({
    required String clientId,
    required String secret,
    bool sandbox = true,
  }) {
    paypalClientId = clientId;
    paypalSecret = secret;
    useSandbox = sandbox;
  }
}
