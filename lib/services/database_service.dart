import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'mock_catalog.dart';
import '../models/pokemon_card.dart';
import '../models/cart_item.dart';
import '../models/order_item.dart';
import '../models/chat_message.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  // Self-healing fallback flag
  bool _forceFallback = false;

  // In-memory fallbacks for Web/Windows/Test platforms where sqflite is not supported
  final Map<String, int> _fallbackCart = {}; // cardId -> quantity
  final List<Map<String, dynamic>> _fallbackOrders = [];
  final List<Map<String, dynamic>> _fallbackMessages = [];
  List<PokemonCard> _fallbackCards = [];

  DatabaseService._init();

  bool get _useFallback =>
      _forceFallback ||
      kIsWeb ||
      (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.windows ||
              defaultTargetPlatform == TargetPlatform.macOS ||
              defaultTargetPlatform == TargetPlatform.linux));

  Future<Database?> get database async {
    if (_useFallback) return null;
    if (_database != null) return _database;
    
    try {
      _database = await _initDB('pokemon_tcg.db');
      return _database;
    } catch (e) {
      debugPrint('SQLite initialization failed, self-healing to memory fallback: $e');
      _forceFallback = true;
      return null;
    }
  }

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
    } on SocketException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _syncCartItemToCloud(String cardId, int quantity) async {
    if (!_isFirebaseInitialized) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && await _hasInternet()) {
      try {
        final docRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cart')
            .doc(cardId);
        if (quantity <= 0) {
          await docRef.delete();
        } else {
          await docRef.set({
            'card_id': cardId,
            'quantity': quantity,
            'updated_at': FieldValue.serverTimestamp(),
          });
        }
      } catch (e) {
        debugPrint('Failed to sync cart item to Firestore: $e');
      }
    }
  }

  Future<void> _clearCartCloud() async {
    if (!_isFirebaseInitialized) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && await _hasInternet()) {
      try {
        final cartSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cart')
            .get();
        final batch = FirebaseFirestore.instance.batch();
        for (var doc in cartSnapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      } catch (e) {
        debugPrint('Failed to clear cart in Firestore: $e');
      }
    }
  }

  Future<void> _syncOrderToCloud(OrderItem order) async {
    if (!_isFirebaseInitialized) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && await _hasInternet()) {
      try {
        final orderMap = order.toMap();
        final numericId = int.tryParse(order.orderId.replaceAll(RegExp(r'\D'), '')) ?? DateTime.now().millisecondsSinceEpoch;
        orderMap['orderCode'] = numericId;
        orderMap['sync_timestamp'] = FieldValue.serverTimestamp();
        
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('orders')
            .doc(order.orderId)
            .set(orderMap);
      } catch (e) {
        debugPrint('Failed to sync order to Firestore: $e');
      }
    }
  }

  Future<void> syncFromCloudOnLogin(String userId) async {
    if (!_isFirebaseInitialized) return;
    if (!await _hasInternet()) return;
    
    try {
      // 1. Sync Cart
      final cartSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('cart')
          .get();
          
      final db = await database;
      if (db != null) {
        await db.delete('cart');
        final batch = db.batch();
        for (var doc in cartSnapshot.docs) {
          final data = doc.data();
          batch.insert('cart', {
            'card_id': doc.id,
            'quantity': data['quantity'] ?? 1,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await batch.commit();
      } else {
        _fallbackCart.clear();
        for (var doc in cartSnapshot.docs) {
          final data = doc.data();
          _fallbackCart[doc.id] = data['quantity'] ?? 1;
        }
      }
      
      // 2. Sync Orders
      final ordersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('orders')
          .get();
          
      if (db != null) {
        for (var doc in ordersSnapshot.docs) {
          final data = doc.data();
          final dbMap = Map<String, dynamic>.from(data);
          dbMap.remove('sync_timestamp');
          dbMap.remove('orderCode');
          await db.insert('orders', dbMap, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      } else {
        for (var doc in ordersSnapshot.docs) {
          final data = doc.data();
          final dbMap = Map<String, dynamic>.from(data);
          dbMap.remove('sync_timestamp');
          dbMap.remove('orderCode');
          final exists = _fallbackOrders.any((o) => o['order_id'] == doc.id);
          if (!exists) {
            _fallbackOrders.add(dbMap);
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to sync from cloud on login: $e');
    }
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE cards (
        card_id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        rarity TEXT NOT NULL,
        market_price REAL NOT NULL,
        price_history TEXT NOT NULL,
        description TEXT,
        image_url TEXT,
        hp INTEGER,
        attack_name TEXT,
        attack_damage INTEGER,
        weakness TEXT,
        retreat_cost INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE cart (
        card_id TEXT PRIMARY KEY,
        quantity INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE orders (
        order_id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        items_json TEXT NOT NULL,
        total_amount REAL NOT NULL,
        status TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        shipping_address TEXT NOT NULL,
        payment_method TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE messages (
        message_id TEXT PRIMARY KEY,
        sender_id TEXT NOT NULL,
        sender_name TEXT NOT NULL,
        text TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');
  }

  // --- CARDS CATALOG ---
  Future<void> initializeFirestoreCatalog() async {
    if (!_isFirebaseInitialized) return;
    try {
      final collection = FirebaseFirestore.instance.collection('cards');
      final snapshot = await collection.limit(1).get();
      if (snapshot.docs.isEmpty) {
        final defaultCards = MockCatalog.getCards();
        final batch = FirebaseFirestore.instance.batch();
        for (var card in defaultCards) {
          final docRef = collection.doc(card.id);
          batch.set(docRef, card.toMap());
        }
        await batch.commit();
        debugPrint('Successfully seeded Firestore catalog with mock cards.');
      }
    } catch (e) {
      debugPrint('Failed to seed Firestore catalog: $e');
    }
  }

  Future<List<PokemonCard>> getCards() async {
    // 1. Tự động tải danh sách thẻ bài lên Firestore nếu db trống
    await initializeFirestoreCatalog();

    // 2. Lấy dữ liệu sản phẩm từ Firestore nếu có mạng làm nguồn tin cậy
    if (_isFirebaseInitialized && await _hasInternet()) {
      try {
        final snapshot = await FirebaseFirestore.instance.collection('cards').get();
        final List<PokemonCard> firestoreCards = snapshot.docs
            .map((doc) => PokemonCard.fromMap(doc.data()))
            .toList();

        // Lưu cache cục bộ xuống SQLite để hỗ trợ offline
        final db = await database;
        if (db != null) {
          final batch = db.batch();
          for (var card in firestoreCards) {
            batch.insert('cards', card.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
          }
          await batch.commit();
        } else {
          _fallbackCards = firestoreCards;
        }
        return firestoreCards;
      } catch (e) {
        debugPrint('Failed to fetch cards from Firestore: $e. Falling back to local/mock.');
      }
    }

    // 3. Dự phòng: lấy từ SQLite cục bộ hoặc mock catalog
    final db = await database;
    if (_useFallback || db == null) {
      if (_fallbackCards.isEmpty) {
        _fallbackCards = MockCatalog.getCards();
      }
      return _fallbackCards;
    }

    try {
      final List<Map<String, dynamic>> maps = await db.query('cards');
      if (maps.isEmpty) {
        final defaultCards = MockCatalog.getCards();
        for (var card in defaultCards) {
          await db.insert('cards', card.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
        }
        return defaultCards;
      }
      return List.generate(maps.length, (i) => PokemonCard.fromMap(maps[i]));
    } catch (e) {
      debugPrint('Failed to query SQLite cards: $e. Falling back to MockCatalog.');
      return MockCatalog.getCards();
    }
  }

  // --- CART OPERATIONS ---
  Future<List<CartItem>> getCart(List<PokemonCard> catalog) async {
    final db = await database;
    if (_useFallback || db == null) {
      final List<CartItem> cartItems = [];
      _fallbackCart.forEach((cardId, qty) {
        final card = catalog.firstWhere((c) => c.id == cardId,
            orElse: () => PokemonCard(
                  id: cardId,
                  name: 'Unknown Card',
                  type: 'Colorless',
                  rarity: 'Common',
                  marketPrice: 0.0,
                  priceHistory: [],
                  description: '',
                  imageUrl: '',
                  hp: 0,
                  attackName: '',
                  attackDamage: 0,
                  weakness: 'None',
                  retreatCost: 1,
                ));
        cartItems.add(CartItem(card: card, quantity: qty));
      });
      return cartItems;
    }

    try {
      final List<Map<String, dynamic>> maps = await db.query('cart');
      final List<CartItem> cartItems = [];

      for (var row in maps) {
        final String cardId = row['card_id'];
        final int quantity = row['quantity'];

        final card = catalog.firstWhere((c) => c.id == cardId,
            orElse: () => PokemonCard(
                  id: cardId,
                  name: 'Unknown Card',
                  type: 'Colorless',
                  rarity: 'Common',
                  marketPrice: 0.0,
                  priceHistory: [],
                  description: '',
                  imageUrl: '',
                  hp: 0,
                  attackName: '',
                  attackDamage: 0,
                  weakness: 'None',
                  retreatCost: 1,
                ));
        cartItems.add(CartItem(card: card, quantity: quantity));
      }
      return cartItems;
    } catch (e) {
      debugPrint('Failed to query SQLite cart: $e');
      return [];
    }
  }

  Future<void> addToCart(String cardId, int quantity) async {
    final db = await database;
    if (_useFallback || db == null) {
      _fallbackCart[cardId] = (_fallbackCart[cardId] ?? 0) + quantity;
      await _syncCartItemToCloud(cardId, _fallbackCart[cardId]!);
      return;
    }

    try {
      int newQty = quantity;
      final existing = await db.query('cart', where: 'card_id = ?', whereArgs: [cardId]);
      if (existing.isNotEmpty) {
        final currentQty = existing.first['quantity'] as int;
        newQty = currentQty + quantity;
        await db.update('cart', {'quantity': newQty},
            where: 'card_id = ?', whereArgs: [cardId]);
      } else {
        await db.insert('cart', {'card_id': cardId, 'quantity': quantity});
      }
      await _syncCartItemToCloud(cardId, newQty);
    } catch (e) {
      debugPrint('Failed write to SQLite cart: $e');
      _fallbackCart[cardId] = (_fallbackCart[cardId] ?? 0) + quantity;
      await _syncCartItemToCloud(cardId, _fallbackCart[cardId]!);
    }
  }

  Future<void> updateCartQuantity(String cardId, int quantity) async {
    final db = await database;
    if (_useFallback || db == null) {
      if (quantity <= 0) {
        _fallbackCart.remove(cardId);
      } else {
        _fallbackCart[cardId] = quantity;
      }
      await _syncCartItemToCloud(cardId, quantity);
      return;
    }

    try {
      if (quantity <= 0) {
        await db.delete('cart', where: 'card_id = ?', whereArgs: [cardId]);
      } else {
        await db.update('cart', {'quantity': quantity}, where: 'card_id = ?', whereArgs: [cardId]);
      }
      await _syncCartItemToCloud(cardId, quantity);
    } catch (e) {
      debugPrint('Failed update SQLite quantity: $e');
      if (quantity <= 0) {
        _fallbackCart.remove(cardId);
      } else {
        _fallbackCart[cardId] = quantity;
      }
      await _syncCartItemToCloud(cardId, quantity);
    }
  }

  Future<void> removeFromCart(String cardId) async {
    final db = await database;
    if (_useFallback || db == null) {
      _fallbackCart.remove(cardId);
      await _syncCartItemToCloud(cardId, 0);
      return;
    }

    try {
      await db.delete('cart', where: 'card_id = ?', whereArgs: [cardId]);
      await _syncCartItemToCloud(cardId, 0);
    } catch (e) {
      debugPrint('Failed delete from SQLite cart: $e');
      _fallbackCart.remove(cardId);
      await _syncCartItemToCloud(cardId, 0);
    }
  }

  Future<void> clearCart() async {
    final db = await database;
    if (_useFallback || db == null) {
      _fallbackCart.clear();
      await _clearCartCloud();
      return;
    }

    try {
      await db.delete('cart');
      await _clearCartCloud();
    } catch (e) {
      debugPrint('Failed clear SQLite cart: $e');
      _fallbackCart.clear();
      await _clearCartCloud();
    }
  }

  // --- ORDER HISTORY ---
  Future<List<OrderItem>> getOrders(List<PokemonCard> catalog) async {
    final db = await database;
    if (_useFallback || db == null) {
      return _fallbackOrders.map((m) => OrderItem.fromMap(m, catalog)).toList();
    }

    try {
      final List<Map<String, dynamic>> maps = await db.query('orders', orderBy: 'timestamp DESC');
      return maps.map((m) => OrderItem.fromMap(m, catalog)).toList();
    } catch (e) {
      debugPrint('Failed query SQLite orders: $e');
      return _fallbackOrders.map((m) => OrderItem.fromMap(m, catalog)).toList();
    }
  }

  Future<void> saveOrder(OrderItem order) async {
    final db = await database;
    if (_useFallback || db == null) {
      _fallbackOrders.add(order.toMap());
      await _syncOrderToCloud(order);
      return;
    }

    try {
      await db.insert('orders', order.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      await _syncOrderToCloud(order);
    } catch (e) {
      debugPrint('Failed save SQLite order: $e');
      _fallbackOrders.add(order.toMap());
      await _syncOrderToCloud(order);
    }
  }

  // --- MESSAGES / SUPPORT CHAT ---
  Future<List<ChatMessage>> getMessages() async {
    final db = await database;
    if (_useFallback || db == null) {
      if (_fallbackMessages.isEmpty) {
        final welcome = ChatMessage(
          id: 'welcome',
          senderId: 'support',
          senderName: 'Prof. Oak',
          text:
              'Hello Trainer! Welcome to the Pokémon TCG Collector Support Desk. I am Professor Oak. How can I assist you with your cards, decks, or orders today?',
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        );
        _fallbackMessages.add(welcome.toMap());
      }
      return _fallbackMessages.map((m) => ChatMessage.fromMap(m)).toList();
    }

    try {
      final List<Map<String, dynamic>> maps = await db.query('messages', orderBy: 'timestamp ASC');
      if (maps.isEmpty) {
        final welcome = ChatMessage(
          id: 'welcome',
          senderId: 'support',
          senderName: 'Prof. Oak',
          text:
              'Hello Trainer! Welcome to the Pokémon TCG Collector Support Desk. I am Professor Oak. How can I assist you with your cards today?',
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        );
        await db.insert('messages', welcome.toMap());
        return [welcome];
      }
      return maps.map((m) => ChatMessage.fromMap(m)).toList();
    } catch (e) {
      debugPrint('Failed query SQLite messages: $e');
      return _fallbackMessages.map((m) => ChatMessage.fromMap(m)).toList();
    }
  }

  Future<void> saveMessage(ChatMessage message) async {
    final db = await database;
    if (_useFallback || db == null) {
      _fallbackMessages.add(message.toMap());
      return;
    }

    try {
      await db.insert('messages', message.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      debugPrint('Failed save SQLite message: $e');
      _fallbackMessages.add(message.toMap());
    }
  }
}
