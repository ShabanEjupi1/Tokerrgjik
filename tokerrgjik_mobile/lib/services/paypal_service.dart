import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/payment_config.dart';
import '../config/api_keys.dart';
import 'package:url_launcher/url_launcher.dart';

/// PayPal Payment Service for in-app purchases
/// Supports both sandbox (testing) and production modes
class PayPalService {
  static const String _sandboxUrl = 'https://api-m.sandbox.paypal.com';
  static const String _productionUrl = 'https://api-m.paypal.com';
  
  /// Get appropriate API URL based on mode
  static String get _apiUrl {
    return PaymentConfig.useSandbox ? _sandboxUrl : _productionUrl;
  }
  
  /// Get OAuth access token from PayPal
  static Future<String?> _getAccessToken() async {
    try {
      final credentials = base64.encode(
        utf8.encode('${PaymentConfig.paypalClientId}:${PaymentConfig.paypalSecret}')
      );
      
      final response = await http.post(
        Uri.parse('$_apiUrl/v1/oauth2/token'),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: 'grant_type=client_credentials',
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['access_token'];
      }
    } catch (e) {
      print('Error getting PayPal access token: $e');
    }
    return null;
  }
  
  /// Create a PayPal order
  static Future<Map<String, dynamic>?> createOrder({
    required String amount,
    required String currency,
    required String description,
  }) async {
    final accessToken = await _getAccessToken();
    if (accessToken == null) return null;
    
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/v2/checkout/orders'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'intent': 'CAPTURE',
          'purchase_units': [
            {
              'amount': {
                'currency_code': currency,
                'value': amount,
              },
              'description': description,
            }
          ],
          'application_context': {
            'return_url': PaymentConfig.useSandbox
                ? '${ApiKeys.siteUrl}/?payment=success&sandbox=true'
                : '${ApiKeys.siteUrl}/?payment=success',
            'cancel_url': PaymentConfig.useSandbox
                ? '${ApiKeys.siteUrl}/?payment=cancelled&sandbox=true'
                : '${ApiKeys.siteUrl}/?payment=cancelled',
          }
        }),
      );
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final orderId = data['id'];
        
        // Get approval URL
        final links = data['links'] as List;
        final approveLink = links.firstWhere(
          (link) => link['rel'] == 'approve',
          orElse: () => null,
        );
        
        if (approveLink != null) {
          return {
            'order_id': orderId,
            'approval_url': approveLink['href'],
          };
        }
        
        return {'order_id': orderId};
      }
    } catch (e) {
      print('Error creating PayPal order: $e');
    }
    return null;
  }
  
  /// Capture payment for an order
  static Future<bool> captureOrder(String orderId) async {
    final accessToken = await _getAccessToken();
    if (accessToken == null) return false;
    
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/v2/checkout/orders/$orderId/capture'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );
      
      return response.statusCode == 201;
    } catch (e) {
      print('Error capturing PayPal order: $e');
      return false;
    }
  }
  
  /// Purchase PRO subscription
  static Future<bool> purchaseProSubscription({
    required BuildContext context,
    required int months,
  }) async {
    final amount = months == 12 ? '20.82' : '2.99';
    final description = months == 12 
        ? 'TokerrGjik PRO - 12 Months' 
        : 'TokerrGjik PRO - 1 Month';
    
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    try {
      final orderData = await createOrder(
        amount: amount,
        currency: 'EUR',
        description: description,
      );
      
      if (orderData != null && orderData['approval_url'] != null) {
        Navigator.pop(context); // Close loading dialog
        
        // Open PayPal checkout page
        final approvalUrl = orderData['approval_url'];
        final uri = Uri.parse(approvalUrl);
        
        if (await canLaunchUrl(uri)) {
          await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          
          // Show message
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('PayPal checkout opened. Complete payment in browser.'),
                duration: Duration(seconds: 5),
              ),
            );
          }
          
          return true;
        } else {
          print('Could not launch PayPal URL: $approvalUrl');
        }
      } else {
        print('No approval URL received from PayPal');
      }
    } catch (e) {
      print('Error purchasing PRO: $e');
    }
    
    Navigator.pop(context); // Close loading
    return false;
  }
  
  /// Purchase coins
  static Future<bool> purchaseCoins({
    required BuildContext context,
    required int coins,
    required String amount,
  }) async {
    final description = 'TokerrGjik - $coins Monedha';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    try {
      final orderData = await createOrder(
        amount: amount,
        currency: 'EUR',
        description: description,
      );
      
      if (orderData != null && orderData['approval_url'] != null) {
        Navigator.pop(context); // Close loading dialog
        
        // Open PayPal checkout page
        final approvalUrl = orderData['approval_url'];
        final uri = Uri.parse(approvalUrl);
        
        if (await canLaunchUrl(uri)) {
          await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          
          // Show message
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('PayPal checkout opened. Complete payment in browser.'),
                duration: Duration(seconds: 5),
              ),
            );
          }
          
          return true;
        } else {
          print('Could not launch PayPal URL: $approvalUrl');
        }
      }
    } catch (e) {
      print('Error purchasing coins: $e');
    }
    
    Navigator.pop(context);
    return false;
  }
}
