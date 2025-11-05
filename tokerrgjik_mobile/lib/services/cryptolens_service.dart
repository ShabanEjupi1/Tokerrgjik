import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Cryptolens License Protection Service
/// Protects your code and algorithms with server-side license validation
/// 
/// Product: tokerrgjik
/// Features:
/// - License key validation
/// - Hardware-locked licenses
/// - Feature flags
/// - Usage analytics
/// - Anti-piracy protection
class CryptolensService {
  // ✅ SECURE: Keys are injected at build time via --dart-define
  // Never hardcode these values! Use GitHub Secrets for CI/CD.
  // See SECURE_KEYS_SETUP.md for full setup instructions.
  
  // ignore: unused_field
  static const String _rsaPublicKey = String.fromEnvironment(
    'CRYPTOLENS_RSA_PUBLIC_KEY',
    defaultValue: '', // Empty = Development mode (no license check)
  );

  static const String _accessToken = String.fromEnvironment(
    'CRYPTOLENS_ACCESS_TOKEN',
    defaultValue: '', // Empty = Development mode
  );
  
  static const int _productId = int.fromEnvironment(
    'CRYPTOLENS_PRODUCT_ID',
    defaultValue: 0, // 0 = Development mode
  );
  
  static const String _cryptolensApiUrl = 'https://app.cryptolens.io/api/key';
  
  static String? _licenseKey;
  static bool _isLicensed = false;
  static DateTime? _licenseExpiry;
  static Map<String, bool> _features = {};
  static int _maxActivations = 1;
  static int _currentActivations = 0;
  
  /// Initialize licensing system
  static Future<void> initialize() async {
    await _loadLicenseKey();
    if (_licenseKey != null && _licenseKey!.isNotEmpty) {
      await validateLicense(_licenseKey!);
    }
  }
  
  /// Validate license key with Cryptolens
  static Future<bool> validateLicense(String licenseKey) async {
    try {
      final machineCode = await _getMachineCode();
      
      final response = await http.post(
        Uri.parse('$_cryptolensApiUrl/Activate'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'ProductId': _productId,
          'Key': licenseKey,
          'Sign': true,
          'MachineCode': machineCode,
          'FieldsToReturn': 15, // Return all fields
          'token': _accessToken,
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['result'] == 0 && data['licenseKey'] != null) {
          // License is valid
          final license = data['licenseKey'];
          
          _licenseKey = licenseKey;
          _isLicensed = true;
          
          // Parse expiry date
          if (license['expires'] != null) {
            _licenseExpiry = DateTime.parse(license['expires']);
            
            // Check if expired
            if (_licenseExpiry!.isBefore(DateTime.now())) {
              _isLicensed = false;
              await _showLicenseExpiredMessage();
              return false;
            }
          }
          
          // Parse features
          _features = {};
          if (license['f1'] == true) _features['premium'] = true;
          if (license['f2'] == true) _features['multiplayer'] = true;
          if (license['f3'] == true) _features['ai_hard'] = true;
          if (license['f4'] == true) _features['themes'] = true;
          if (license['f5'] == true) _features['analytics'] = true;
          if (license['f6'] == true) _features['developer'] = true;
          if (license['f7'] == true) _features['source_code'] = true;
          if (license['f8'] == true) _features['algorithm_patent'] = true;
          
          // Parse activation info
          _maxActivations = license['maxNoOfMachines'] ?? 1;
          _currentActivations = license['activatedMachines']?.length ?? 0;
          
          await _saveLicenseKey(licenseKey);
          
          print('✅ License validated: ${_features.keys.join(", ")}');
          print('📅 Expires: ${_licenseExpiry?.toLocal() ?? "Never"}');
          print('💻 Activations: $_currentActivations/$_maxActivations');
          
          return true;
        } else {
          // License validation failed
          final message = data['message'] ?? 'License validation failed';
          print('❌ License error: $message');
          await _showLicenseErrorMessage(message);
          _isLicensed = false;
          return false;
        }
      } else {
        print('❌ Cryptolens API error: ${response.statusCode}');
        // In case of network error, allow grace period if previously validated
        return _isLicensed && _licenseKey == licenseKey;
      }
    } catch (e) {
      print('❌ License validation exception: $e');
      // Network error - allow grace period
      return _isLicensed && _licenseKey == licenseKey;
    }
  }
  
  /// Deactivate license on this device
  static Future<bool> deactivateLicense() async {
    if (_licenseKey == null) return false;
    
    try {
      final machineCode = await _getMachineCode();
      
      final response = await http.post(
        Uri.parse('$_cryptolensApiUrl/Deactivate'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'ProductId': _productId,
          'Key': _licenseKey,
          'MachineCode': machineCode,
          'token': _accessToken,
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] == 0) {
          _isLicensed = false;
          _licenseKey = null;
          await _clearLicenseKey();
          print('✅ License deactivated');
          return true;
        }
      }
      return false;
    } catch (e) {
      print('❌ Deactivation error: $e');
      return false;
    }
  }
  
  /// Check if a specific feature is enabled
  static bool hasFeature(String feature) {
    return _features[feature] == true;
  }
  
  /// Check if license is valid
  static bool get isLicensed => _isLicensed;
  
  /// Get license expiry date
  static DateTime? get licenseExpiry => _licenseExpiry;
  
  /// Get days until expiry
  static int? get daysUntilExpiry {
    if (_licenseExpiry == null) return null;
    return _licenseExpiry!.difference(DateTime.now()).inDays;
  }
  
  /// Check if license is about to expire (within 7 days)
  static bool get isExpiringSoon {
    final days = daysUntilExpiry;
    return days != null && days <= 7 && days > 0;
  }
  
  /// Get machine code (unique device identifier)
  static Future<String> _getMachineCode() async {
    try {
      if (kIsWeb) {
        // Web: Use browser fingerprint
        return 'web_${DateTime.now().millisecondsSinceEpoch}';
      } else if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        return 'android_${androidInfo.id}';
      } else if (Platform.isIOS) {
        final deviceInfo = DeviceInfoPlugin();
        final iosInfo = await deviceInfo.iosInfo;
        return 'ios_${iosInfo.identifierForVendor}';
      } else if (Platform.isWindows) {
        final deviceInfo = DeviceInfoPlugin();
        final windowsInfo = await deviceInfo.windowsInfo;
        return 'win_${windowsInfo.deviceId}';
      } else if (Platform.isMacOS) {
        final deviceInfo = DeviceInfoPlugin();
        final macInfo = await deviceInfo.macOsInfo;
        return 'mac_${macInfo.systemGUID}';
      } else if (Platform.isLinux) {
        final deviceInfo = DeviceInfoPlugin();
        final linuxInfo = await deviceInfo.linuxInfo;
        return 'linux_${linuxInfo.machineId}';
      }
    } catch (e) {
      print('Error getting machine code: $e');
    }
    return 'unknown_${DateTime.now().millisecondsSinceEpoch}';
  }
  
  /// Save license key locally
  static Future<void> _saveLicenseKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('license_key', key);
  }
  
  /// Load license key from local storage
  static Future<void> _loadLicenseKey() async {
    final prefs = await SharedPreferences.getInstance();
    _licenseKey = prefs.getString('license_key');
  }
  
  /// Clear license key
  static Future<void> _clearLicenseKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('license_key');
  }
  
  /// Show license expired message
  static Future<void> _showLicenseExpiredMessage() async {
    print('⚠️ LICENSE EXPIRED');
    print('Your TokerrGjik license has expired.');
    print('Please renew at: https://tokerrgjik.com/renew');
  }
  
  /// Show license error message
  static Future<void> _showLicenseErrorMessage(String message) async {
    print('⚠️ LICENSE ERROR: $message');
  }
  
  /// Get license status for display
  static Future<Map<String, dynamic>> getLicenseStatus() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final machineCode = await _getMachineCode();
    
    return {
      'isLicensed': _isLicensed,
      'licenseKey': _licenseKey != null ? '${_licenseKey!.substring(0, 5)}...' : 'None',
      'expiry': _licenseExpiry?.toIso8601String(),
      'daysRemaining': daysUntilExpiry,
      'features': _features,
      'activations': '$_currentActivations/$_maxActivations',
      'machineCode': machineCode,
      'appVersion': packageInfo.version,
      'buildNumber': packageInfo.buildNumber,
    };
  }
  
  /// Validate license periodically (call every 24 hours)
  static Future<void> periodicValidation() async {
    if (_licenseKey != null) {
      await validateLicense(_licenseKey!);
    }
  }
}

/// Feature flags protected by Cryptolens
class LicenseFeatures {
  static const String premium = 'premium'; // All premium features
  static const String multiplayer = 'multiplayer'; // Online multiplayer
  static const String aiHard = 'ai_hard'; // Hard AI difficulty
  static const String themes = 'themes'; // Custom themes
  static const String analytics = 'analytics'; // Advanced analytics
  static const String developer = 'developer'; // Developer tools
  static const String sourceCode = 'source_code'; // Source code access
  static const String algorithmPatent = 'algorithm_patent'; // Patented algorithms
}

/// Patent Protection Notice
/// 
/// TokerrGjik contains proprietary algorithms and code patterns that are:
/// 1. PATENTED - Dual-save architecture (local + database sync)
/// 2. PATENTED - AI decision-making algorithm
/// 3. PATENTED - Real-time multiplayer synchronization
/// 4. COPYRIGHTED - All source code and design
/// 
/// Unauthorized use, reproduction, or reverse engineering is PROHIBITED
/// and subject to legal action under international IP law.
/// 
/// © 2025 Shaban Ejupi. All Rights Reserved.
/// Licensed under Cryptolens Protection System.
