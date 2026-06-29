import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
      (!kIsWeb && (!Platform.isAndroid && !Platform.isIOS)) ||
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
      
      await _mergeOrdersFromCloud(userId, db);
    } catch (e) {
      debugPrint('Failed to sync from cloud on login: $e');
    }
  }

  Future<void> syncOrdersFromCloud() async {
    if (!_isFirebaseInitialized) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !await _hasInternet()) return;

    try {
      final db = await database;
      // Đẩy đơn hàng từ local lên Firebase trước
      await _syncLocalOrdersToCloud(user, db);
      // Lấy đơn hàng từ Firebase về local
      await _mergeOrdersFromCloud(user.uid, db);
    } catch (e) {
      debugPrint('Failed to sync orders from cloud: $e');
    }
  }

  Future<void> _syncLocalOrdersToCloud(User user, Database? db) async {
    if (db == null) return;
    try {
      final maps = await db.query('orders', where: 'user_id = ?', whereArgs: [user.email ?? '']);
      final batch = FirebaseFirestore.instance.batch();
      final collection = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('orders');
      
      for (var map in maps) {
        final String orderId = map['order_id'].toString();
        final numericId = int.tryParse(orderId.replaceAll(RegExp(r'\D'), '')) ?? DateTime.now().millisecondsSinceEpoch;
        final cloudMap = Map<String, dynamic>.from(map);
        cloudMap['orderCode'] = numericId;
        // Bỏ qua sync_timestamp bằng serverTimestamp ở batch để tối ưu tốc độ hoặc để client tự resolve
        
        batch.set(collection.doc(orderId), cloudMap, SetOptions(merge: true));
      }
      
      if (maps.isNotEmpty) {
        await batch.commit();
        debugPrint('Synced ${maps.length} local orders to Firebase.');
      }
    } catch (e) {
      debugPrint('Failed to sync local orders to cloud: $e');
    }
  }

  Future<void> _mergeOrdersFromCloud(String firebaseUid, Database? db) async {
    final ordersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(firebaseUid)
        .collection('orders')
        .get();

    for (var doc in ordersSnapshot.docs) {
      final data = doc.data();
      final dbMap = Map<String, dynamic>.from(data);
      dbMap.remove('sync_timestamp');
      dbMap.remove('orderCode');

      if (db != null) {
        await db.insert('orders', dbMap, conflictAlgorithm: ConflictAlgorithm.replace);
      } else {
        _upsertFallbackOrder(dbMap);
      }
    }
  }

  void _upsertFallbackOrder(Map<String, dynamic> orderMap) {
    final orderId = orderMap['order_id'] as String?;
    if (orderId == null) return;

    final index = _fallbackOrders.indexWhere((o) => o['order_id'] == orderId);
    if (index >= 0) {
      _fallbackOrders[index] = orderMap;
    } else {
      _fallbackOrders.add(orderMap);
    }
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          try {
            await db.execute('ALTER TABLE orders ADD COLUMN rating REAL');
            await db.execute('ALTER TABLE orders ADD COLUMN feedback TEXT');
          } catch (e) {
            debugPrint('Error upgrading database: $e');
          }
        }
      },
      onUpgrade: _upgradeDB,
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
        retreat_cost INTEGER,
        stock_quantity INTEGER DEFAULT 0
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
        payment_method TEXT NOT NULL,
        rating REAL,
        feedback TEXT
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

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE cards ADD COLUMN stock_quantity INTEGER DEFAULT 0');
    }
  }

  // --- CARDS CATALOG ---
  Future<void> cacheCards(List<PokemonCard> cards) async {
    if (cards.isEmpty) return;

    // Save to SQLite
    final db = await database;
    if (db != null) {
      final batch = db.batch();
      for (var card in cards) {
        batch.insert('cards', card.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit();
    } else {
      for (var card in cards) {
        _fallbackCards.removeWhere((c) => c.id == card.id);
        _fallbackCards.add(card);
      }
    }

    // Save to Firestore for persistence
    if (_isFirebaseInitialized && await _hasInternet()) {
      try {
        final collection = FirebaseFirestore.instance.collection('cards');
        final batch = FirebaseFirestore.instance.batch();
        for (var card in cards) {
          final docRef = collection.doc(card.id);
          final map = card.toMap();
          // Loại bỏ trường stock_quantity để không đè lên số lượng mà Admin đã set trên Firebase
          map.remove('stock_quantity');
          batch.set(docRef, map, SetOptions(merge: true));
        }
        await batch.commit();
      } catch (e) {
        debugPrint('Failed to cache cards to Firestore: $e');
      }
    }
  }

  Future<List<PokemonCard>> getCards() async {
    // Return local fallback immediately if needed
    if (_useFallback) return _fallbackCards;

    // 1. Try to read from fast local SQLite
    final db = await database;
    if (db != null) {
      try {
        final List<Map<String, dynamic>> maps = await db.query('cards');
        if (maps.isNotEmpty) {
          return List.generate(maps.length, (i) => PokemonCard.fromMap(maps[i]));
        }
      } catch (e) {
        debugPrint('Failed to query SQLite cards: $e');
      }
    }

    // 2. Fallback to Firestore if local SQLite is empty
    if (_isFirebaseInitialized && await _hasInternet()) {
      try {
        final snapshot = await FirebaseFirestore.instance.collection('cards').get();
        final List<PokemonCard> firestoreCards = snapshot.docs
            .map((doc) => PokemonCard.fromMap(doc.data()))
            .toList();

        // Update local memory fallback
        _fallbackCards = firestoreCards;
        return firestoreCards;
      } catch (e) {
        debugPrint('Failed to fetch cards from Firestore: $e');
      }
    }

    return _fallbackCards;
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
  List<OrderItem> _dedupeOrders(List<OrderItem> orders) {
    final byId = <String, OrderItem>{};
    for (final order in orders) {
      byId[order.orderId] = order;
    }
    final deduped = byId.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return deduped;
  }

  Future<List<OrderItem>> getOrders(List<PokemonCard> catalog) async {
    final db = await database;
    if (_useFallback || db == null) {
      return _dedupeOrders(
        _fallbackOrders.map((m) => OrderItem.fromMap(m, catalog)).toList(),
      );
    }

    try {
      final List<Map<String, dynamic>> maps = await db.query('orders', orderBy: 'timestamp DESC');
      return _dedupeOrders(maps.map((m) => OrderItem.fromMap(m, catalog)).toList());
    } catch (e) {
      debugPrint('Failed query SQLite orders: $e');
      return _dedupeOrders(
        _fallbackOrders.map((m) => OrderItem.fromMap(m, catalog)).toList(),
      );
    }
  }

  Future<OrderItem?> getOrderById(String orderId, List<PokemonCard> catalog) async {
    final orders = await getOrders(catalog);
    for (final order in orders) {
      if (order.orderId == orderId) return order;
    }
    return null;
  }

  Future<void> saveOrder(OrderItem order) async {
    final db = await database;
    if (_useFallback || db == null) {
      _upsertFallbackOrder(order.toMap());
      await _syncOrderToCloud(order);
      return;
    }

    try {
      await db.insert('orders', order.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      await _syncOrderToCloud(order);
    } catch (e) {
      debugPrint('Failed save SQLite order: $e');
      _upsertFallbackOrder(order.toMap());
      await _syncOrderToCloud(order);
    }
  }

  ChatMessage _welcomeMessage() {
    return ChatMessage(
      id: 'welcome',
      senderId: 'support',
      senderName: 'Prof. Oak (Groq AI)',
      text:
          'Xin chào Trainer! Tôi là Professor Oak, trợ lý AI của Pokémon TCG Collector. '
          'Hãy hỏi tôi về thẻ bài, bộ deck, giao hàng hoặc đơn hàng nhé!',
      timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
    );
  }

  // --- MESSAGES / SUPPORT CHAT ---
  Future<List<ChatMessage>> getMessages() async {
    final db = await database;
    if (_useFallback || db == null) {
      if (_fallbackMessages.isEmpty) {
        _fallbackMessages.add(_welcomeMessage().toMap());
      }
      return _fallbackMessages.map((m) => ChatMessage.fromMap(m)).toList();
    }

    try {
      final List<Map<String, dynamic>> maps =
          await db.query('messages', orderBy: 'timestamp ASC');
      if (maps.isEmpty) {
        final welcome = _welcomeMessage();
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
      await db.insert('messages', message.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      debugPrint('Failed save SQLite message: $e');
      _fallbackMessages.add(message.toMap());
    }
  }

  Future<void> clearMessages() async {
    final db = await database;
    if (_useFallback || db == null) {
      _fallbackMessages.clear();
      _fallbackMessages.add(_welcomeMessage().toMap());
      return;
    }

    try {
      await db.delete('messages');
      final welcome = _welcomeMessage();
      await db.insert('messages', welcome.toMap());
    } catch (e) {
      debugPrint('Failed clear SQLite messages: $e');
      _fallbackMessages.clear();
      _fallbackMessages.add(_welcomeMessage().toMap());
    }
  }

  // --- ADMIN TOOLS ---
  Future<List<OrderItem>> getAllOrdersAdmin(List<PokemonCard> catalog) async {
    if (!_isFirebaseInitialized || !await _hasInternet()) return [];
    try {
      // Vì orders nằm trong subcollection của users, ta dùng collectionGroup
      final snapshot = await FirebaseFirestore.instance.collectionGroup('orders').get();
      return snapshot.docs.map((doc) => OrderItem.fromMap(doc.data(), catalog)).toList();
    } catch (e) {
      debugPrint('Admin: Failed to fetch all orders: $e');
      return [];
    }
  }

  Future<bool> updateOrderStatus(String userId, String orderId, String newStatus) async {
    if (_isFirebaseInitialized && await _hasInternet()) {
      try {
        // Dùng collectionGroup để tìm đúng document reference theo orderId,
        // tránh lỗi mismatch giữa email (userId trong order) và UID (Firestore path thực tế)
        final snapshot = await FirebaseFirestore.instance
            .collectionGroup('orders')
            .where('order_id', isEqualTo: orderId)
            .limit(1)
            .get();

        if (snapshot.docs.isEmpty) {
          debugPrint('Admin: Order $orderId not found in Firestore');
          return false;
        }

        // Cập nhật trực tiếp qua reference thực của document (đúng path UID)
        await snapshot.docs.first.reference.update({'status': newStatus});
      } catch (e) {
        debugPrint('Failed to update order status in Firestore: $e');
        return false;
      }
    }

    // Cập nhật local SQLite để phản ánh ngay lập tức trên UI
    final db = await database;
    if (db != null) {
      try {
        await db.update(
          'orders',
          {'status': newStatus},
          where: 'order_id = ?',
          whereArgs: [orderId],
        );
      } catch (e) {
        debugPrint('Failed to update order status in SQLite: $e');
      }
    } else {
      // Cập nhật fallback memory list
      final index = _fallbackOrders.indexWhere((o) => o['order_id'] == orderId);
      if (index >= 0) {
        _fallbackOrders[index]['status'] = newStatus;
      }
    }
    return true;
  }

  Future<bool> deleteCard(String cardId) async {
    final db = await database;
    if (db != null) {
      await db.delete('cards', where: 'card_id = ?', whereArgs: [cardId]);
    }
    _fallbackCards.removeWhere((c) => c.id == cardId);

    if (_isFirebaseInitialized && await _hasInternet()) {
      try {
        await FirebaseFirestore.instance.collection('cards').doc(cardId).delete();
        return true;
      } catch (e) {
        debugPrint('Admin: Failed to delete card from Firestore: $e');
      }
    }
    return true;
  }

  // --- PUBLIC REVIEWS ---
  Future<void> savePublicReview({
    required String cardId,
    required String userName,
    required double rating,
    required String feedback,
  }) async {
    if (!_isFirebaseInitialized || !await _hasInternet()) return;

    try {
      await FirebaseFirestore.instance.collection('reviews').add({
        'card_id': cardId,
        'user_name': userName,
        'rating': rating,
        'feedback': feedback,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Failed to save public review: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getCardReviews(String cardId) {
    if (!_isFirebaseInitialized) return Stream.value([]);
    
    return FirebaseFirestore.instance
        .collection('reviews')
        .where('card_id', ==: cardId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getOrdersFirestoreStream(String firebaseUid) {
    if (!_isFirebaseInitialized) return const Stream.empty();
    
    return FirebaseFirestore.instance
        .collection('users')
        .doc(firebaseUid)
        .collection('orders')
        .snapshots();
  }
}

