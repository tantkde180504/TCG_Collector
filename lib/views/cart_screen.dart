import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/cart_viewmodel.dart';
import '../viewmodels/catalog_viewmodel.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _couponController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final cartVM = context.read<CartViewModel>();
    final catalogVM = context.read<CatalogViewModel>();
    // Pre-sync cart with the active database catalog
    cartVM.loadCart(catalogVM.cards);
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  void _applyPromo(CartViewModel cartVM) {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;

    final success = cartVM.applyCoupon(code);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Promo code "$code" applied! Save ${(cartVM.discountPercent * 100).toStringAsFixed(0)}%!'),
          backgroundColor: Colors.green,
        ),
      );
      _couponController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Coupon "$code" is invalid or expired!'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartVM = context.watch<CartViewModel>();

    if (cartVM.items.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.white24),
              SizedBox(height: 12),
              Text(
                'Your Shopping Cart is Empty',
                style: TextStyle(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'Add rare cards from the shop to start collection!',
                style: TextStyle(color: Colors.white30, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Column(
        children: [
          // Items list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cartVM.items.length,
              itemBuilder: (context, index) {
                final item = cartVM.items[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                  ),
                  child: Row(
                    children: [
                      // Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 50,
                          height: 70,
                          color: Colors.black26,
                          child: Image.network(
                            item.card.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.style, color: Colors.white30),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Name & type details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.card.name,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item.card.type} • ${item.card.rarity}',
                              style: const TextStyle(color: Colors.white30, fontSize: 11),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '\$${item.card.marketPrice.toStringAsFixed(2)}',
                              style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      
                      // Quantity selector column
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                            onPressed: () {
                              cartVM.removeFromCart(item.card.id);
                            },
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  cartVM.updateQuantity(item.card.id, item.quantity - 1);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white24),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(Icons.remove, color: Colors.white, size: 14),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  '${item.quantity}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  cartVM.updateQuantity(item.card.id, item.quantity + 1);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white24),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(Icons.add, color: Colors.white, size: 14),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // Coupon code block
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: TextField(
                      controller: _couponController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Enter Coupon (PIKACHU10)',
                        hintStyle: TextStyle(color: Colors.white30, fontSize: 12),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 42,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _applyPromo(cartVM),
                    child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
          
          if (cartVM.appliedCoupon.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Coupon Applied: ${cartVM.appliedCoupon}',
                    style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => cartVM.removeCoupon(),
                    child: const Text('Remove', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 16),
          
          // Summary container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E1E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  _buildSummaryRow('Subtotal', '\$${cartVM.subtotal.toStringAsFixed(2)}'),
                  if (cartVM.discountPercent > 0)
                    _buildSummaryRow(
                      'Discount (${(cartVM.discountPercent * 100).toStringAsFixed(0)}%)',
                      '-\$${cartVM.discountAmount.toStringAsFixed(2)}',
                      valueColor: Colors.greenAccent,
                    ),
                  _buildSummaryRow('Shipping Fee', cartVM.shippingCost == 0 ? 'FREE' : '\$${cartVM.shippingCost.toStringAsFixed(2)}'),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 4),
                  _buildSummaryRow(
                    'Total Cost',
                    '\$${cartVM.grandTotal.toStringAsFixed(2)}',
                    isBold: true,
                    valueColor: Colors.amber,
                  ),
                  const SizedBox(height: 16),
                  
                  // Checkout trigger
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        // Reset checkout to step 0 and push screen
                        cartVM.setCheckoutStep(0);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const CheckoutScreen(),
                          ),
                        );
                      },
                      child: const Text('PROCEED TO CHECKOUT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, Color valueColor = Colors.white}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isBold ? Colors.white : Colors.white60,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 14 : 13,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 13,
            ),
          ),
        ],
      ),
    );
  }
}
