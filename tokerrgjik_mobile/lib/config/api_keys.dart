/// API Keys Configuration
/// This file contains all API keys and sensitive configuration
/// DO NOT commit this file to version control with real keys
/// 
/// Setup Instructions:
/// 1. Copy this file to api_keys.dart (already done)
/// 2. Replace the placeholder values with your actual API keys
/// 3. Add api_keys.dart to .gitignore to keep your keys secure

class ApiKeys {
  //neon database
  static const String neonDatabaseUrl = 'postgresql://neondb_owner:npg_d6WqxY0NaMnR@ep-super-water-aedl5ojl-pooler.c-2.us-east-2.aws.neon.tech/neondb?channel_binding=require&sslmode=require';
  static const String neonDatabaseUrlUnpooled = 'postgresql://neondb_owner:npg_d6WqxY0NaMnR@ep-super-water-aedl5ojl.c-2.us-east-2.aws.neon.tech/neondb?channel_binding=require&sslmode=require';

  // ==================== ADMOB ====================
  /// Get your AdMob App IDs from: https://apps.admob.google.com/
  /// Create an account, add your app, and get the App ID
  static const String admobAppIdAndroid = 'ca-app-pub-8491001524308476~9753001043';
  static const String admobAppIdIos = 'ca-app-pub-8491001524308476~5326670873';
  
  /// AdMob Ad Unit IDs (create these in AdMob console)
  static const String admobBannerAndroid = 'ca-app-pub-8491001524308476/7116257088'; // Test ID - Replace with yours
  static const String admobBannerIos = 'ca-app-pub-8491001524308476/4681665438'; // Test ID - Replace with yours
  
  static const String admobInterstitialAndroid = 'ca-app-pub-8491001524308476/9581997693'; // Test ID
  static const String admobInterstitialIos = 'ca-app-pub-8491001524308476/5179718251'; // Test ID
  
  static const String admobRewardedAndroid = 'ca-app-pub-8491001524308476/8248347684'; // Test ID
  static const String admobRewardedIos = 'ca-app-pub-8491001524308476/3041280706'; // Test ID

  // ==================== STRIPE ====================
  /// Get your Stripe keys from: https://dashboard.stripe.com/apikeys
  /// Use test keys for development, production keys for release
  static const String stripePublishableKey = 'pk_test_51SJpPtRny7FwUV21mosCRJAQ3mtXRVdZzaHrH7u2Czy8pDjdBm1tD04xa99pdsWtUb4EAawGiH7vtE1R2YHPoPtc00ZC2TU43I';
  static const String stripeSecretKey = 'sk_test_51SJpPtRny7FwUV21NybTiOdtKKeXYvhDIwUHQE4mbg6vga7061wFcNyH8IOpGsFdkUheizZsdwZfoqX0i8mn5oEH00RrukTMNR';

  // ==================== SENTRY ====================
  /// Get your Sentry DSN from: https://sentry.io/
  /// Create a project and copy the DSN
  static const String sentryDsn = 'https://XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX@oXXXXXX.ingest.sentry.io/XXXXXXX'; // TODO: Replace

  // ==================== BACKEND SERVER ====================
  /// Your backend server URL
  /// Development: Use your local IP or ngrok URL
  /// Production: Use your deployed server URL (Netlify Functions)
  static const String serverUrl = 'https://tokerrgjik.netlify.app'; // Production - uses /api/* redirect
  static const String serverUrlProduction = 'https://tokerrgjik.netlify.app';
  
  /// WebSocket URL for real-time multiplayer
  static const String websocketUrl = 'ws://tokerrgjik.netlify.app';
  static const String websocketUrlProduction = 'wss://tokerrgjik.netlify.app';

  // ==================== DATABASE ====================
  /// PostgreSQL/MongoDB connection (for backend)
  /// Using Neon database from .env
  static const String databaseUrl = 'postgresql://neondb_owner:npg_d6WqxY0NaMnR@ep-super-water-aedl5ojl-pooler.c-2.us-east-2.aws.neon.tech/neondb?channel_binding=require&sslmode=require';
  static const String mongoDbUrl = ''; // Not used - using PostgreSQL

  // ==================== ANALYTICS ====================
  /// SimpleAnalytics Site ID (privacy-friendly analytics)
  static const String simpleAnalyticsSiteId = 'your-site-id'; // TODO: Replace
  
  /// New Relic License Key
  static const String newRelicLicenseKey = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'; // TODO: Replace

  // ==================== OTHER SERVICES ====================
  /// Icons8 API Key (if using their API)
  static const String icons8ApiKey = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'; // TODO: Replace
  
  /// DevCycle SDK Key
  static const String devCycleSdkKey = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'; // TODO: Replace
  
  /// Blockchair API Key (for blockchain features)
  static const String blockchairApiKey = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'; // TODO: Replace

  // ==================== HELPERS ====================
  
  /// Check if running in development mode
  static bool get isDevelopment {
    return serverUrl.contains('10.0.2.2') || serverUrl.contains('localhost');
  }
  
  /// Get appropriate server URL based on environment
  static String get currentServerUrl {
    return isDevelopment ? serverUrl : serverUrlProduction;
  }
  
  /// Get appropriate WebSocket URL based on environment
  static String get currentWebsocketUrl {
    return isDevelopment ? websocketUrl : websocketUrlProduction;
  }
}
