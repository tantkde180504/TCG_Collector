import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Holds complete price data for a card, combining live API + Firestore history.
class PriceData {
  final List<double> prices;
  final List<String> dates; // "YYYY-MM-DD" format, same length as prices
  final double? currentPrice;
  final double? tcgplayerLow;
  final double? tcgplayerHigh;
  final double? cardmarketAvg7;
  final double? cardmarketAvg30;
  final String source; // "TCGPlayer" | "CardMarket" | "N/A"
  final String tcgCardId;
  final String updatedAt;

  const PriceData({
    required this.prices,
    required this.dates,
    required this.currentPrice,
    required this.source,
    required this.tcgCardId,
    this.tcgplayerLow,
    this.tcgplayerHigh,
    this.cardmarketAvg7,
    this.cardmarketAvg30,
    this.updatedAt = '',
  });

  /// % change: last price vs first price in history
  double get percentChange {
    if (prices.length < 2 || prices.first == 0) return 0.0;
    return ((prices.last - prices.first) / prices.first) * 100;
  }

  bool get isRising => percentChange >= 0;
}

class TcgPriceService {
  static final TcgPriceService instance = TcgPriceService._();
  TcgPriceService._();

  static const String _baseUrl = 'https://api.pokemontcg.io/v2/cards';
  static const String _priceCollection = 'card_prices';

  // In-memory cache to avoid repeated API calls during same session
  final Map<String, PriceData> _sessionCache = {};

  bool get _isFirebaseInitialized {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {}
    return false;
  }

  Future<bool> _hasInternet() async {
    if (kIsWeb) return true;
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Extract TCG API card ID from imageUrl
  /// "https://images.pokemontcg.io/sv3pt5/199_hires.png" → "sv3pt5-199"
  String? extractTcgCardId(String imageUrl) {
    try {
      if (imageUrl.isEmpty) return null;
      final uri = Uri.parse(imageUrl);
      final segments = uri.pathSegments;
      if (segments.length < 2) return null;
      final setId = segments[segments.length - 2];
      final fileName = segments.last;
      final cardNumber = fileName.split('_').first.split('.').first;
      if (setId.isEmpty || cardNumber.isEmpty) return null;
      return '$setId-$cardNumber';
    } catch (_) {
      return null;
    }
  }

  /// Fetch live price from pokemontcg.io (free, no API key needed for basic use)
  Future<Map<String, dynamic>?> _fetchFromApi(String tcgCardId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$tcgCardId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) return null;

      final data = json.decode(response.body)['data'];
      final result = <String, dynamic>{};

      // ── TCGPlayer ────────────────────────────────────────────────────────
      if (data['tcgplayer'] != null) {
        final pricesMap = data['tcgplayer']['prices'] as Map<String, dynamic>?;
        if (pricesMap != null && pricesMap.isNotEmpty) {
          // Priority: holofoil > normal > 1stEditionHolofoil > first available
          final priceEntry = (pricesMap['holofoil'] ??
                  pricesMap['normal'] ??
                  pricesMap['1stEditionHolofoil'] ??
                  pricesMap.values.first) as Map<String, dynamic>?;

          if (priceEntry != null) {
            result['tcgplayer_market'] =
                (priceEntry['market'] ?? priceEntry['mid'] ?? 0.0).toDouble();
            result['tcgplayer_low'] = (priceEntry['low'] ?? 0.0).toDouble();
            result['tcgplayer_high'] = (priceEntry['high'] ?? 0.0).toDouble();
          }
        }
        result['tcgplayer_updated'] = data['tcgplayer']['updatedAt'] ?? '';
      }

      // ── CardMarket ───────────────────────────────────────────────────────
      if (data['cardmarket'] != null) {
        final cm = data['cardmarket']['prices'] as Map<String, dynamic>?;
        if (cm != null) {
          result['cardmarket_trend'] =
              (cm['trendPrice'] ?? cm['avg7'] ?? cm['averageSellPrice'] ?? 0.0)
                  .toDouble();
          result['cardmarket_avg7'] = (cm['avg7'] ?? 0.0).toDouble();
          result['cardmarket_avg30'] = (cm['avg30'] ?? 0.0).toDouble();
        }
        result['cardmarket_updated'] = data['cardmarket']['updatedAt'] ?? '';
      }

      return result.isNotEmpty ? result : null;
    } catch (e) {
      debugPrint('TcgPriceService: API error for $tcgCardId: $e');
      return null;
    }
  }

  /// Persist today's price into Firestore (deduplicates by date)
  Future<void> _saveTodayPrice(
      String tcgCardId, double price, String source) async {
    if (!_isFirebaseInitialized) return;
    try {
      final today = DateTime.now();
      final dateStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final docRef = FirebaseFirestore.instance
          .collection(_priceCollection)
          .doc(tcgCardId);

      final doc = await docRef.get();
      List<dynamic> history = [];
      if (doc.exists) {
        history = List.from(doc.data()?['history'] ?? []);
      }

      // Remove existing entry for today (idempotent)
      history.removeWhere((e) => (e as Map)['date'] == dateStr);
      history.add({'date': dateStr, 'price': price, 'source': source});

      // Cap at 90 days of history
      if (history.length > 90) {
        history = history.sublist(history.length - 90);
      }

      await docRef.set({
        'last_price': price,
        'source': source,
        'updated_at': FieldValue.serverTimestamp(),
        'history': history,
      }, SetOptions(merge: true));

      debugPrint(
          'TcgPriceService: saved $tcgCardId → \$$price ($source) on $dateStr');
    } catch (e) {
      debugPrint('TcgPriceService: Firestore write error for $tcgCardId: $e');
    }
  }

  /// Read full price history from Firestore (sorted ascending by date)
  Future<List<Map<String, dynamic>>> _readHistory(String tcgCardId) async {
    if (!_isFirebaseInitialized) return [];
    try {
      final doc = await FirebaseFirestore.instance
          .collection(_priceCollection)
          .doc(tcgCardId)
          .get();

      if (!doc.exists) return [];

      final raw = doc.data()?['history'] as List<dynamic>? ?? [];
      final history = raw
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList()
        ..sort((a, b) =>
            (a['date'] as String).compareTo(b['date'] as String));

      return history;
    } catch (e) {
      debugPrint('TcgPriceService: Firestore read error for $tcgCardId: $e');
      return [];
    }
  }

  /// Main public method: fetch live price → save to Firestore → return PriceData
  ///
  /// [imageUrl] is used to derive the TCG card ID automatically.
  /// [fallbackPriceHistory] is the hardcoded mock data used as initial display
  ///   before real history accumulates.
  Future<PriceData?> getAndUpdatePriceData(
    String imageUrl, {
    List<double> fallbackPriceHistory = const [],
  }) async {
    final tcgCardId = extractTcgCardId(imageUrl);
    if (tcgCardId == null) {
      debugPrint('TcgPriceService: Could not extract card ID from $imageUrl');
      return null;
    }

    // Return from session cache if available
    if (_sessionCache.containsKey(tcgCardId)) {
      return _sessionCache[tcgCardId];
    }

    final hasNet = await _hasInternet();

    // ── Step 1: Fetch live data from API ─────────────────────────────────
    Map<String, dynamic>? apiData;
    double? livePrice;
    String source = 'TCGPlayer';
    String updatedAt = '';

    if (hasNet) {
      apiData = await _fetchFromApi(tcgCardId);
      if (apiData != null) {
        final tcg = (apiData['tcgplayer_market'] as double?) ?? 0.0;
        final cm = (apiData['cardmarket_trend'] as double?) ?? 0.0;

        if (tcg > 0) {
          livePrice = tcg;
          source = 'TCGPlayer';
          updatedAt = apiData['tcgplayer_updated'] ?? '';
        } else if (cm > 0) {
          livePrice = cm;
          source = 'CardMarket';
          updatedAt = apiData['cardmarket_updated'] ?? '';
        }

        // ── Step 2: Persist to Firestore ──────────────────────────────────
        if (livePrice != null && livePrice > 0) {
          await _saveTodayPrice(tcgCardId, livePrice, source);
        }
      }
    }

    // ── Step 3: Read accumulated history from Firestore ───────────────────
    List<Map<String, dynamic>> history = [];
    if (hasNet) {
      history = await _readHistory(tcgCardId);
    }

    // ── Step 4: Build PriceData ───────────────────────────────────────────
    List<double> prices;
    List<String> dates;

    if (history.isNotEmpty) {
      prices = history.map((e) => (e['price'] as num).toDouble()).toList();
      dates = history.map((e) => e['date'] as String).toList();
    } else if (fallbackPriceHistory.isNotEmpty) {
      // Use hardcoded mock as temporary display until real data accumulates
      prices = fallbackPriceHistory;
      final today = DateTime.now();
      dates = List.generate(prices.length, (i) {
        final d = today.subtract(Duration(days: prices.length - 1 - i));
        return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      });
    } else {
      prices = livePrice != null ? [livePrice] : [];
      final today = DateTime.now();
      dates = prices.isNotEmpty
          ? ['${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}']
          : [];
    }

    final result = PriceData(
      prices: prices,
      dates: dates,
      currentPrice: livePrice ?? (prices.isNotEmpty ? prices.last : null),
      source: source,
      tcgCardId: tcgCardId,
      tcgplayerLow: apiData?['tcgplayer_low']?.toDouble(),
      tcgplayerHigh: apiData?['tcgplayer_high']?.toDouble(),
      cardmarketAvg7: apiData?['cardmarket_avg7']?.toDouble(),
      cardmarketAvg30: apiData?['cardmarket_avg30']?.toDouble(),
      updatedAt: updatedAt,
    );

    _sessionCache[tcgCardId] = result;
    return result;
  }

  /// Clear session cache (e.g. on logout or manual refresh)
  void clearCache() => _sessionCache.clear();
}
