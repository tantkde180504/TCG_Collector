import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order_item.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/cart_viewmodel.dart';
import '../viewmodels/notification_viewmodel.dart';
import '../widgets/payos_widgets.dart';
import '../services/user_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _addressFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  final _cardFormKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _cardExpiryController = TextEditingController();
  final _cardCvvController = TextEditingController();

  OrderItem? _completedOrder;

  @override
  void initState() {
    super.initState();
    final cartVM = context.read<CartViewModel>();
    final authVM = context.read<AuthViewModel>();
    
    if (cartVM.shippingName.isNotEmpty || cartVM.shippingPhone.isNotEmpty || cartVM.shippingAddress.isNotEmpty) {
      _nameController.text = cartVM.shippingName;
      _phoneController.text = cartVM.shippingPhone;
      _addressController.text = cartVM.shippingAddress;
    } else {
      _loadDefaultAddress(authVM.userId, authVM.displayName);
    }
  }

  Future<void> _loadDefaultAddress(String userId, String defaultName) async {
    final addresses = await UserService.instance.getAddresses(userId);
    if (!mounted) return;
    if (addresses.isNotEmpty) {
      UserAddress? def;
      try {
        def = addresses.firstWhere((a) => a.isDefault);
      } catch (_) {
        def = addresses.first;
      }
      
      setState(() {
        _nameController.text = def!.fullName.isNotEmpty ? def.fullName : defaultName;
        _phoneController.text = def.phoneNumber;
        _addressController.text = '${def.street}, ${def.city}, ${def.country}';
      });
    }
  }

  void _showAddressBook() async {
    final authVM = context.read<AuthViewModel>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CheckoutAddressBookSheet(
        userId: authVM.userId,
        onSelect: (addr) {
          setState(() {
            _nameController.text = addr.fullName.isNotEmpty ? addr.fullName : authVM.displayName;
            _phoneController.text = addr.phoneNumber;
            _addressController.text = '${addr.street}, ${addr.city}, ${addr.country}';
          });
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    super.dispose();
  }

  void _nextStep(CartViewModel cartVM) {
    if (cartVM.checkoutStep == 0) {
      if (_addressFormKey.currentState!.validate()) {
        cartVM.saveShippingInfo(
          _nameController.text,
          _phoneController.text,
          _addressController.text,
        );
        cartVM.setCheckoutStep(1);
      }
    } else if (cartVM.checkoutStep == 1) {
      if (cartVM.selectedPaymentMethod == 'Credit Card') {
        if (!_cardFormKey.currentState!.validate()) return;
      }
      _placeOrder(cartVM);
    }
  }

  void _placeOrder(CartViewModel cartVM) async {
    final authVM = context.read<AuthViewModel>();
    final notifVM = context.read<NotificationViewModel>();
    
    final order = await cartVM.submitOrder(authVM.email);
    if (!mounted) return;
    
    if (order != null) {
      if (cartVM.selectedPaymentMethod == 'PayOS') {
        if (!mounted) return;
        
        showPayOSPendingDialog(
          context: context,
          cartVM: cartVM,
          order: order,
          onPaymentVerified: (updatedOrder) {
            setState(() {
              _completedOrder = updatedOrder;
            });
          },
        );
      } else {
        setState(() {
          _completedOrder = order;
        });
        // Add success order notification
        notifVM.addNotification(
          title: 'Order Placed Successfully!',
          body: 'Your order ${order.orderId} for \$${order.totalAmount.toStringAsFixed(2)} is now processing.',
          type: 'order_status',
        );
        cartVM.setCheckoutStep(2);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit order. Please try again!'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    final cartVM = context.watch<CartViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Checkout Process', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Visual Stepper indicator
          _buildStepperHeader(cartVM.checkoutStep),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: _buildStepContent(cartVM),
            ),
          ),
          
          // Bottom button bar (except for Confirmation step)
          if (cartVM.checkoutStep < 2)
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF1E1E1E),
              child: Row(
                children: [
                  if (cartVM.checkoutStep == 1)
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white30),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          cartVM.setCheckoutStep(0);
                        },
                        child: const Text('BACK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  if (cartVM.checkoutStep == 1) const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: cartVM.isLoading ? null : () => _nextStep(cartVM),
                      child: cartVM.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : Text(
                              cartVM.checkoutStep == 0 ? 'PROCEED TO PAYMENT' : 'PLACE ORDER (\$${cartVM.grandTotal.toStringAsFixed(2)})',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepperHeader(int step) {
    return Container(
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      child: Row(
        children: [
          _buildStepCircle(1, 'Shipping', step >= 0, step > 0),
          _buildStepLine(step > 0),
          _buildStepCircle(2, 'Payment', step >= 1, step > 1),
          _buildStepLine(step > 1),
          _buildStepCircle(3, 'Confirm', step >= 2, false),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int number, String label, bool isActive, bool isDone) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isDone
                ? Colors.green
                : isActive
                    ? Colors.amber
                    : Colors.white12,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    '$number',
                    style: TextStyle(
                      color: isDone || isActive ? Colors.black : Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white30,
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(bool isFinished) {
    return Expanded(
      child: Container(
        height: 2,
        color: isFinished ? Colors.green : Colors.white12,
        margin: const EdgeInsets.only(bottom: 14),
      ),
    );
  }

  Widget _buildStepContent(CartViewModel cartVM) {
    switch (cartVM.checkoutStep) {
      case 0:
        return _buildAddressStep();
      case 1:
        return _buildPaymentStep(cartVM);
      case 2:
      default:
        return _buildConfirmationStep();
    }
  }

  Widget _buildAddressStep() {
    return Form(
      key: _addressFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Shipping Information',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: _showAddressBook,
                icon: const Icon(Icons.import_contacts_rounded, size: 16),
                label: const Text('Address Book', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.amber,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Full name input
          TextFormField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: _buildInputDecoration('Full Name', Icons.person),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Please enter your full name';
              return null;
            },
          ),
          const SizedBox(height: 16),
          // Phone number input
          TextFormField(
            controller: _phoneController,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.phone,
            decoration: _buildInputDecoration('Phone Number', Icons.phone),
            validator: (value) {
              if (value == null || value.trim().isEmpty || value.length < 8) {
                return 'Please enter a valid phone number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          // Shipping Address input
          TextFormField(
            controller: _addressController,
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            decoration: _buildInputDecoration('Delivery Address', Icons.home),
            validator: (value) {
              if (value == null || value.trim().isEmpty || value.length < 10) {
                return 'Please specify a complete delivery address';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStep(CartViewModel cartVM) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose Payment Method',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        // Payment choices grid
        Row(
          children: [
            _buildPaymentCard(cartVM, 'Credit Card', Icons.credit_card),
            const SizedBox(width: 8),
            _buildPaymentCard(cartVM, 'PayPal', Icons.payment),
            const SizedBox(width: 8),
            _buildPaymentCard(cartVM, 'PokeGold', Icons.catching_pokemon),
            const SizedBox(width: 8),
            _buildPaymentCard(cartVM, 'PayOS', Icons.qr_code),
          ],
        ),
        const SizedBox(height: 24),
        
        // Show Card Inputs if Credit Card is selected
        if (cartVM.selectedPaymentMethod == 'Credit Card')
          Form(
            key: _cardFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Card Information', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cardNumberController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: _buildInputDecoration('Card Number', Icons.credit_card),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty || value.length < 16) return 'Invalid Card Number';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cardExpiryController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration('MM/YY', Icons.calendar_today),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty || !value.contains('/')) return 'Invalid Expiry';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _cardCvvController,
                        style: const TextStyle(color: Colors.white),
                        obscureText: true,
                        decoration: _buildInputDecoration('CVV', Icons.lock),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty || value.length < 3) return 'Invalid CVV';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
        if (cartVM.selectedPaymentMethod == 'PayPal')
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.payment, color: Colors.blue),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You will be redirected to PayPal to complete authentication upon placement.',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),

        if (cartVM.selectedPaymentMethod == 'PokeGold')
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.catching_pokemon, color: Colors.amber),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'PokeGold Balance: 2,500 ★. The order will be deducted from your Trainer Vault.',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),

        if (cartVM.selectedPaymentMethod == 'PayOS')
          PayOSPaymentInfo(grandTotal: cartVM.grandTotal),
          
        const SizedBox(height: 24),
        const Divider(color: Colors.white24),
        const SizedBox(height: 12),
        // Simple Summary breakdown
        const Text('Order Items Summary', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cartVM.items.length,
          itemBuilder: (context, idx) {
            final it = cartVM.items[idx];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${it.quantity}x ${it.card.name}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  Text('\$${(it.card.marketPrice * it.quantity).toStringAsFixed(2)}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildConfirmationStep() {
    if (_completedOrder == null) return const SizedBox();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          // Success animated icon
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.check, size: 48, color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'ORDER PLACED!',
            style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 2),
          ),
          const SizedBox(height: 6),
          Text(
            'Order Reference: ${_completedOrder!.orderId}',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 20),
          
          // Receipt Details Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('INVOICE RECEIPT', style: TextStyle(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.bold)),
                const Divider(color: Colors.white24),
                const SizedBox(height: 8),
                _buildReceiptRow('Payment Method', _completedOrder!.paymentMethod),
                _buildReceiptRow('Order Status', _completedOrder!.status, valColor: Colors.amber),
                _buildReceiptRow('Ship To', _completedOrder!.shippingAddress.split(',')[0]),
                const Divider(color: Colors.white12),
                const SizedBox(height: 6),
                const Text('Items Bought:', style: TextStyle(color: Colors.white60, fontSize: 11)),
                const SizedBox(height: 4),
                ..._completedOrder!.items.map((it) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${it.quantity}x ${it.card.name}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          Text('\$${(it.card.marketPrice * it.quantity).toStringAsFixed(2)}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    )),
                const Divider(color: Colors.white24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Amount Paid', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('\$${_completedOrder!.totalAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          
          // Complete button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                // Exit checkout screen back to home
                Navigator.of(context).pop();
              },
              child: const Text('BACK TO SHOP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {Color valColor = Colors.white70}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white30, fontSize: 12)),
          Text(value, style: TextStyle(color: valColor, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(CartViewModel cartVM, String method, IconData icon) {
    final isSelected = cartVM.selectedPaymentMethod == method;
    return Expanded(
      child: GestureDetector(
        onTap: () => cartVM.selectPaymentMethod(method),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.amber.withValues(alpha: 0.15) : const Color(0xFF1E1E1E),
            border: Border.all(
              color: isSelected ? Colors.amber : Colors.white12,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.amber : Colors.white70),
              const SizedBox(height: 8),
              Text(
                method,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.amber, size: 18),
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.amber),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    );
  }
}

class _CheckoutAddressBookSheet extends StatefulWidget {
  final String userId;
  final void Function(UserAddress) onSelect;
  const _CheckoutAddressBookSheet({required this.userId, required this.onSelect});

  @override
  State<_CheckoutAddressBookSheet> createState() => _CheckoutAddressBookSheetState();
}

class _CheckoutAddressBookSheetState extends State<_CheckoutAddressBookSheet> {
  List<UserAddress> _addresses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await UserService.instance.getAddresses(widget.userId);
    if (!mounted) return;
    setState(() {
      _addresses = res;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(
                children: [
                  Icon(Icons.import_contacts_rounded, color: Colors.amber),
                  SizedBox(width: 12),
                  Text('Select Address', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Colors.amber))
                  : _addresses.isEmpty
                      ? const Center(child: Text('No saved addresses.', style: TextStyle(color: Colors.white54)))
                      : ListView.separated(
                          controller: ctrl,
                          padding: const EdgeInsets.all(20),
                          itemCount: _addresses.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final addr = _addresses[i];
                            return InkWell(
                              onTap: () => widget.onSelect(addr),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF242424),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: addr.isDefault ? Colors.amber : Colors.white12, width: addr.isDefault ? 1.5 : 1),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(addr.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                        if (addr.isDefault) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                                            child: const Text('Default', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (addr.fullName.isNotEmpty || addr.phoneNumber.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text([if (addr.fullName.isNotEmpty) addr.fullName, if (addr.phoneNumber.isNotEmpty) addr.phoneNumber].join(' - '), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                                    ],
                                    const SizedBox(height: 6),
                                    Text('${addr.street}, ${addr.city}, ${addr.country}', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

