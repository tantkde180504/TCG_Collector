import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class PayosService {
  static const String clientId = '1e486ec0-9fac-4d03-9f38-c30f9987e1f0';
  static const String apiKey = '0993fd87-b82f-4d17-8ebc-e47deb600a9a';
  static const String checksumKey = '882ff1d4a906a720c4c4ac414a2def108b0eea3f2735950dc96e80315502a8c7';

  static const String baseUrl = 'https://api-merchant.payos.vn';

  /// Generates the SHA-256 HMAC signature required by PayOS.
  static String _generateSignature(Map<String, dynamic> data, String key) {
    // 1. Sort keys alphabetically
    final sortedKeys = data.keys.toList()..sort();

    // 2. Build sorted query string: key1=val1&key2=val2...
    final queryString = sortedKeys.map((k) => '$k=${data[k]}').join('&');

    if (kDebugMode) {
      print('PayOS Sorted Sign String: $queryString');
    }

    // 3. Compute HMAC-SHA256
    final keyBytes = utf8.encode(key);
    final dataBytes = utf8.encode(queryString);
    final hmac = Hmac(sha256, keyBytes);
    final digest = hmac.convert(dataBytes);

    return digest.toString();
  }

  /// Create a payment link on PayOS.
  /// Returns a map with 'checkoutUrl' and 'paymentLinkId' if successful, or null on failure.
  static Future<Map<String, dynamic>?> createPaymentLink({
    required int orderCode,
    required int amount,
    required String description,
    required String cancelUrl,
    required String returnUrl,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      // Clean description to meet PayOS criteria: no accents, max 25 chars, alphanumeric/spaces only
      var cleanedDescription = description
          .replaceAll(RegExp(r'[^\w\s]'), '') // remove special characters
          .trim();
      if (cleanedDescription.length > 25) {
        cleanedDescription = cleanedDescription.substring(0, 25);
      }
      if (cleanedDescription.isEmpty) {
        cleanedDescription = 'Order $orderCode';
      }

      // Fields required for signing
      final Map<String, dynamic> signData = {
        'amount': amount,
        'cancelUrl': cancelUrl,
        'description': cleanedDescription,
        'orderCode': orderCode,
        'returnUrl': returnUrl,
      };

      // Generate HMAC-SHA256 signature
      final signature = _generateSignature(signData, checksumKey);

      // Construct JSON payload
      final Map<String, dynamic> requestBody = {
        'orderCode': orderCode,
        'amount': amount,
        'description': cleanedDescription,
        'cancelUrl': cancelUrl,
        'returnUrl': returnUrl,
        'items': items,
        'signature': signature,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/v2/payment-requests'),
        headers: {
          'x-client-id': clientId,
          'x-api-key': apiKey,
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (kDebugMode) {
        print('PayOS Create Response Status: ${response.statusCode}');
        print('PayOS Create Response Body: ${response.body}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = json.decode(response.body);
        if (decoded['code'] == '00' && decoded['data'] != null) {
          return Map<String, dynamic>.from(decoded['data']);
        }
      }
      return null;
    } catch (e) {
      debugPrint('PayOS createPaymentLink error: $e');
      return null;
    }
  }

  /// Queries PayOS to retrieve the details/status of a payment request.
  /// Status values can be: 'PENDING', 'PAID', 'CANCELLED'
  static Future<String?> getPaymentStatus(int orderCode) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/v2/payment-requests/$orderCode'),
        headers: {
          'x-client-id': clientId,
          'x-api-key': apiKey,
        },
      );

      if (kDebugMode) {
        print('PayOS Status Response Status: ${response.statusCode}');
        print('PayOS Status Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['code'] == '00' && decoded['data'] != null) {
          return decoded['data']['status'] as String;
        }
      }
      return null;
    } catch (e) {
      debugPrint('PayOS getPaymentStatus error: $e');
      return null;
    }
  }
}
