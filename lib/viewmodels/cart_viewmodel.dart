import 'package:flutter/material.dart';
import 'dart:math';
import '../models/pokemon_card.dart';
import '../models/cart_item.dart';
import '../models/order_item.dart';
import '../services/database_service.dart';

class CartViewModel extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  
  List<CartItem> _items = [];
  List<OrderItem> _orders = [];
  bool _isLoading = false;
  
  String _appliedCoupon = '';
  double _discountPercent = 0.0;
  
  // Checkout flow state
  int _checkoutStep = 0; // 0: Address, 1: Payment, 2: Confirmation
  String _shippingName = '';
  String _shippingPhone = '';
  String _shippingAddress = '';
  String _selectedPaymentMethod = 'Credit Card';

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

  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get discountAmount => subtotal * _discountPercent;
  double get shippingCost => subtotal > 150.0 ? 0.0 : 7.99; // Free shipping above $150
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
      await _db.addToCart(card.id, quantity);
      
      final index = _items.indexWhere((item) => item.card.id == card.id);
      if (index >= 0) {
        _items[index].quantity += quantity;
      } else {
        _items.add(CartItem(card: card, quantity: quantity));
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding to cart: $e');
    }
  }

  Future<void> updateQuantity(String cardId, int quantity) async {
    try {
      await _db.updateCartQuantity(cardId, quantity);
      
      if (quantity <= 0) {
        _items.removeWhere((item) => item.card.id == cardId);
      } else {
        final index = _items.indexWhere((item) => item.card.id == cardId);
        if (index >= 0) {
          _items[index].quantity = quantity;
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
    notifyListeners();

    try {
      final random = Random();
      final orderId = 'ORD-${DateTime.now().millisecondsSinceEpoch}-${random.nextInt(1000)}';
      
      final order = OrderItem(
        orderId: orderId,
        userId: userId,
        items: List.from(_items),
        totalAmount: grandTotal,
        status: 'Processing',
        timestamp: DateTime.now(),
        shippingAddress: '$_shippingName, $_shippingPhone\n$_shippingAddress',
        paymentMethod: _selectedPaymentMethod,
      );

      await _db.saveOrder(order);
      _orders.insert(0, order); // Add to local cache list at top

      // Clear DB cart and local cart
      await clearCart();
      
      // Reset coupon discount and step
      _appliedCoupon = '';
      _discountPercent = 0.0;
      
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

  Future<void> loadOrders(String userId, List<PokemonCard> catalog) async {
    _isLoading = true;
    notifyListeners();

    try {
      final allOrders = await _db.getOrders(catalog);
      // Filter orders for active user
      _orders = allOrders.where((o) => o.userId == userId).toList();
    } catch (e) {
      debugPrint('Error loading orders: $e');
    }

    _isLoading = false;
    notifyListeners();
  }
}
