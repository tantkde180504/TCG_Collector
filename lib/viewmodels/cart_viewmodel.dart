import 'package:flutter/foundation.dart';
import 'dart:math';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/pokemon_card.dart';
import '../models/cart_item.dart';
import '../models/order_item.dart';
import '../services/database_service.dart';
import '../services/payos_service.dart';
import '../services/local_notification_service.dart';

class CartViewModel extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  
  List<CartItem> _items = [];
  List<OrderItem> _orders = [];
  bool _isLoading = false;
  StreamSubscription? _ordersSubscription;
  
  String _appliedCoupon = '';
  double _discountPercent = 0.0;
  
  // Checkout flow state
  int _checkoutStep = 0; // 0: Address, 1: Payment, 2: Confirmation
  String _shippingName = '';
  String _shippingPhone = '';
  String _shippingAddress = '';
  String _selectedPaymentMethod = 'Credit Card';
  String? _lastCheckoutUrl;
  Map<String, dynamic>? _lastPayOSData;

  List<CartItem> get items => _items;
  List<OrderItem> get orders => _orders;
  bool get isLoading => _isLoading;
  String get appliedCoupon => _appliedCoupon;
  double get discountPercent => _discountPercent;
  int get checkoutStep => _checkoutStep;
  
  String get shippingName => _shippingName;
  String get shippingPhone => _shippingPhone;
  String get shippingAddress => _shippingAddress;
  String get selectedPaymentMethod => _selectedPaymentMethod;
  String? get lastCheckoutUrl => _lastCheckoutUrl;
  Map<String, dynamic>? get lastPayOSData => _lastPayOSData;

  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get discountAmount => subtotal * _discountPercent;
  double get shippingCost => subtotal > 150.0 ? 0.0 : 0.15; // Free shipping above $150
  double get grandTotal => subtotal - discountAmount + shippingCost;

  Future<void> loadCart(List<PokemonCard> catalog) async {
    _isLoading = true;
    notifyListeners();

    try {
      _items = await _db.getCart(catalog);
    } catch (e) {
      debugPrint('Error loading cart: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addToCart(PokemonCard card, {int quantity = 1}) async {
    try {
      if (card.stockQuantity <= 0) return; // Cannot add out of stock

      final index = _items.indexWhere((item) => item.card.id == card.id);
      int newQuantity = quantity;

      if (index >= 0) {
        newQuantity = _items[index].quantity + quantity;
      }
      
      // Cap at available stock
      if (newQuantity > card.stockQuantity) {
        newQuantity = card.stockQuantity;
      }

      // Calculate the actual difference we added
      final actualAdded = index >= 0 ? (newQuantity - _items[index].quantity) : newQuantity;
      if (actualAdded <= 0) return; // Already at max stock

      await _db.addToCart(card.id, actualAdded);
      
      if (index >= 0) {
        _items[index].quantity = newQuantity;
      } else {
        _items.add(CartItem(card: card, quantity: newQuantity));
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding to cart: $e');
    }
  }

  Future<void> updateQuantity(String cardId, int quantity) async {
    try {
      final index = _items.indexWhere((item) => item.card.id == cardId);
      if (index < 0 && quantity > 0) return; // Should not happen

      int targetQuantity = quantity;
      if (index >= 0) {
        final maxStock = _items[index].card.stockQuantity;
        if (targetQuantity > maxStock) {
          targetQuantity = maxStock;
        }
      }

      if (targetQuantity <= 0) {
        await _db.removeFromCart(cardId);
        _items.removeWhere((item) => item.card.id == cardId);
      } else {
        await _db.updateCartQuantity(cardId, targetQuantity);
        if (index >= 0) {
          _items[index].quantity = targetQuantity;
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating quantity: $e');
    }
  }


  Future<void> removeFromCart(String cardId) async {
    try {
      await _db.removeFromCart(cardId);
      _items.removeWhere((item) => item.card.id == cardId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing from cart: $e');
    }
  }

  Future<void> clearCart() async {
    try {
      await _db.clearCart();
      _items.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing cart: $e');
    }
  }

  bool applyCoupon(String code) {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode == 'PIKACHU10') {
      _appliedCoupon = 'PIKACHU10';
      _discountPercent = 0.10; // 10% off
      notifyListeners();
      return true;
    } else if (cleanCode == 'CHARIZARD20') {
      _appliedCoupon = 'CHARIZARD20';
      _discountPercent = 0.20; // 20% off
      notifyListeners();
      return true;
    }
    return false;
  }

  void removeCoupon() {
    _appliedCoupon = '';
    _discountPercent = 0.0;
    notifyListeners();
  }

  // --- CHECKOUT PROCESS ---
  void setCheckoutStep(int step) {
    _checkoutStep = step;
    notifyListeners();
  }

  void saveShippingInfo(String name, String phone, String address) {
    _shippingName = name;
    _shippingPhone = phone;
    _shippingAddress = address;
    notifyListeners();
  }

  void selectPaymentMethod(String method) {
    _selectedPaymentMethod = method;
    notifyListeners();
  }

  Future<OrderItem?> submitOrder(String userId) async {
    if (_items.isEmpty) return null;

    _isLoading = true;
    _lastCheckoutUrl = null;
    _lastPayOSData = null;
    notifyListeners();

    try {
      final random = Random();
      
      String orderId;
      String orderStatus = 'Processing';
      
      if (_selectedPaymentMethod == 'PayOS') {
        // PayOS orderCode must be a positive integer.
        // We'll use DateTime.now().millisecondsSinceEpoch to get a unique int64.
        final int orderCode = DateTime.now().millisecondsSinceEpoch;
        orderId = orderCode.toString();
        orderStatus = 'Unpaid';
        
        final int amountVnd = (grandTotal * 25000).round();
        final List<Map<String, dynamic>> payosItems = _items.map((it) => {
          'name': it.card.name,
          'quantity': it.quantity,
          'price': (it.card.marketPrice * 25000).round(),
        }).toList();

        String cancelUrl = 'https://tcgcollector.com/cancel';
        String returnUrl = 'https://tcgcollector.com/success';
        
        if (kIsWeb) {
          try {
            final origin = Uri.base.origin;
            cancelUrl = '$origin/#/checkout?status=cancel';
            returnUrl = '$origin/#/checkout?status=success';
          } catch (_) {}
        } else {
          cancelUrl = 'tcgcollector://payment-cancel';
          returnUrl = 'tcgcollector://payment-success';
        }

        final res = await PayosService.createPaymentLink(
          orderCode: orderCode,
          amount: amountVnd,
          description: 'TCG Order $orderCode',
          cancelUrl: cancelUrl,
          returnUrl: returnUrl,
          items: payosItems,
        );

        if (res == null) {
          throw Exception('Failed to generate PayOS checkout link');
        }

        _lastPayOSData = res;
        _lastCheckoutUrl = res['checkoutUrl'];
      } else {
        orderId = 'ORD-${DateTime.now().millisecondsSinceEpoch}-${random.nextInt(1000)}';
      }

      final order = OrderItem(
        orderId: orderId,
        userId: userId,
        items: List.from(_items),
        totalAmount: grandTotal,
        status: orderStatus,
        timestamp: DateTime.now(),
        shippingAddress: '$_shippingName, $_shippingPhone\n$_shippingAddress',
        paymentMethod: _selectedPaymentMethod,
      );

      await _db.saveOrder(order);
      _orders.insert(0, order); // Add to local cache list at top

      // Clear DB cart and local cart for non-PayOS methods
      // For PayOS, we only clear the cart upon payment verification
      if (_selectedPaymentMethod != 'PayOS') {
        await clearCart();
        
        // Reset coupon discount
        _appliedCoupon = '';
        _discountPercent = 0.0;

        LocalNotificationService.showOrderNotification(
          title: 'Order Successful',
          body: 'Your order $orderId has been placed successfully!',
        );
      }
      
      _isLoading = false;
      notifyListeners();
      return order;
    } catch (e) {
      debugPrint('Error submitting order: $e');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> verifyPayOSPayment(
    String orderId, {
    bool clearCartAfter = true,
    List<PokemonCard>? catalog,
  }) async {
    final orderCode = int.tryParse(orderId);
    if (orderCode == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final status = await PayosService.getPaymentStatus(orderCode);
      if (status != 'PAID') {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      OrderItem? existing;
      final cacheIndex = _orders.indexWhere((o) => o.orderId == orderId);
      if (cacheIndex >= 0) {
        existing = _orders[cacheIndex];
      } else if (catalog != null) {
        existing = await _db.getOrderById(orderId, catalog);
      }

      if (existing == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final updatedOrder = OrderItem(
        orderId: existing.orderId,
        userId: existing.userId,
        items: existing.items,
        totalAmount: existing.totalAmount,
        status: 'Processing',
        timestamp: existing.timestamp,
        shippingAddress: existing.shippingAddress,
        paymentMethod: existing.paymentMethod,
      );

      await _db.saveOrder(updatedOrder);

      if (cacheIndex >= 0) {
        _orders[cacheIndex] = updatedOrder;
      } else {
        _orders.insert(0, updatedOrder);
      }

      if (clearCartAfter) {
        await clearCart();
        _appliedCoupon = '';
        _discountPercent = 0.0;
      }

      LocalNotificationService.showOrderNotification(
        title: 'Payment Successful',
        body: 'Your payment for order $orderId has been verified!',
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error verifying PayOS payment: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> refreshUnpaidPayOSOrders(List<PokemonCard> catalog) async {
    for (final order in List<OrderItem>.from(_orders)) {
      if (order.status.toLowerCase() == 'unpaid' && order.paymentMethod == 'PayOS') {
        await verifyPayOSPayment(
          order.orderId,
          clearCartAfter: false,
          catalog: catalog,
        );
      }
    }
  }

  Future<bool> regeneratePayOSLink(OrderItem order) async {
    final int? orderCode = int.tryParse(order.orderId);
    if (orderCode == null) return false;

    _isLoading = true;
    _lastCheckoutUrl = null;
    _lastPayOSData = null;
    notifyListeners();

    try {
      final int amountVnd = (order.totalAmount * 25000).round();
      final List<Map<String, dynamic>> payosItems = order.items.map((it) => {
        'name': it.card.name,
        'quantity': it.quantity,
        'price': (it.card.marketPrice * 25000).round(),
      }).toList();

      String cancelUrl = 'https://tcgcollector.com/cancel';
      String returnUrl = 'https://tcgcollector.com/success';
      
      if (kIsWeb) {
        try {
          final origin = Uri.base.origin;
          cancelUrl = '$origin/#/checkout?status=cancel';
          returnUrl = '$origin/#/checkout?status=success';
        } catch (_) {}
      } else {
        cancelUrl = 'tcgcollector://payment-cancel';
        returnUrl = 'tcgcollector://payment-success';
      }

      final res = await PayosService.createPaymentLink(
        orderCode: orderCode,
        amount: amountVnd,
        description: 'TCG Order $orderCode',
        cancelUrl: cancelUrl,
        returnUrl: returnUrl,
        items: payosItems,
      );

      if (res != null) {
        _lastPayOSData = res;
        _lastCheckoutUrl = res['checkoutUrl'];
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error regenerating PayOS link: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  String? _currentSubscriptionUid;

  Future<void> loadOrders(String userId, List<PokemonCard> catalog) async {
    final firebaseUid = _getFirebaseUid();
    
    // Nếu UID thay đổi hoặc chưa có subscription, đăng ký lại
    if (_ordersSubscription != null && _currentSubscriptionUid == firebaseUid) {
      // Đã đang lắng nghe đúng user, chỉ cần đảm bảo dữ liệu mới nhất
      await refreshUnpaidPayOSOrders(catalog);
      return;
    }

    // Cancel subscription cũ nếu có
    await _ordersSubscription?.cancel();
    _ordersSubscription = null;
    _currentSubscriptionUid = firebaseUid;

    _isLoading = true;
    notifyListeners();

    try {
      // 1. Tải dữ liệu ban đầu từ SQLite/Local để UI hiện lên nhanh
      var allOrders = await _db.getOrders(catalog);
      _orders = allOrders.where((o) => o.userId == userId).toList();
      _isLoading = false;
      notifyListeners();

      // 2. Thiết lập lắng nghe thay đổi thời gian thực từ Firestore
      if (firebaseUid != null) {
        _ordersSubscription = _db.getOrdersFirestoreStream(firebaseUid).listen((snapshot) async {
          debugPrint('Orders Firestore real-time update: ${snapshot.docs.length} docs');
          
          List<OrderItem> cloudOrders = [];
          for (var doc in snapshot.docs) {
            final order = OrderItem.fromMap(doc.data(), catalog);
            cloudOrders.add(order);
            // Cập nhật local database ngầm (dùng bản local-only để tránh loop sync)
            await _db.saveOrderLocal(order);
          }
          
          // Cập nhật UI ngay lập tức từ dữ liệu Firestore mới nhất
          cloudOrders.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          _orders = cloudOrders.where((o) => o.userId == userId).toList();
          notifyListeners();
        });
      }
      
      // 3. Thực hiện đồng bộ ngầm
      await _db.syncOrdersFromCloud();
      await refreshUnpaidPayOSOrders(catalog);

    } catch (e) {
      debugPrint('Error loading orders: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  String? _getFirebaseUid() {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    super.dispose();
  }

  Future<void> submitFeedback(String orderId, double rating, String feedback, String userName) async {
    final index = _orders.indexWhere((o) => o.orderId == orderId);
    if (index < 0) return;

    final existing = _orders[index];
    final updatedOrder = OrderItem(
      orderId: existing.orderId,
      userId: existing.userId,
      items: existing.items,
      totalAmount: existing.totalAmount,
      status: existing.status,
      timestamp: existing.timestamp,
      shippingAddress: existing.shippingAddress,
      paymentMethod: existing.paymentMethod,
      rating: rating,
      feedback: feedback,
    );

    try {
      // 1. Lưu vào đơn hàng cá nhân (SQLite + Firestore user subcollection)
      await _db.saveOrder(updatedOrder);
      _orders[index] = updatedOrder;

      // 2. Lưu vào bộ sưu tập reviews công khai cho từng sản phẩm
      for (final item in existing.items) {
        await _db.savePublicReview(
          cardId: item.card.id,
          userName: userName,
          rating: rating,
          feedback: feedback,
        );
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error saving feedback: $e');
    }
  }
}
