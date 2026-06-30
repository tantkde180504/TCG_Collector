import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodels/cart_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/catalog_viewmodel.dart';
import '../viewmodels/settings_viewmodel.dart';
import '../models/order_item.dart';
import '../models/cart_item.dart';
import '../widgets/payos_widgets.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Load orders when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authVM = context.read<AuthViewModel>();
      final catalogVM = context.read<CatalogViewModel>();
      if (authVM.isAuthenticated) {
        context.read<CartViewModel>().loadOrders(authVM.email, catalogVM.cards);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartVM = context.watch<CartViewModel>();
    final settingsVM = context.watch<SettingsViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Order History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: cartVM.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE53935)))
          : cartVM.orders.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: cartVM.orders.length,
                  itemBuilder: (context, index) {
                    final order = cartVM.orders[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _showOrderDetailBottomSheet(context, order),
                      child: _buildOrderCard(order, settingsVM),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_rounded, size: 80, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text(
            'No orders yet',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'When you place an order, it will appear here.',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderItem order, SettingsViewModel settingsVM) {
    final DateFormat formatter = DateFormat('MMM dd, yyyy - hh:mm a');
    final String dateString = formatter.format(order.timestamp);
    
    Color statusColor;
    switch (order.status.toLowerCase()) {
      case 'paid':
        statusColor = Colors.teal;
        break;
      case 'processing':
        statusColor = Colors.orange;
        break;
      case 'shipped':
        statusColor = Colors.blue;
        break;
      case 'delivered':
        statusColor = Colors.green;
        break;
      case 'unpaid':
        statusColor = Colors.redAccent;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Order ID & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Order #${order.orderId}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    order.status.toUpperCase(),
                    style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Date & Payment Method
            Text(dateString, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.payment, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(order.paymentMethod, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              ],
            ),
            const Divider(color: Color(0xFF333333), height: 24),
            
            // Items Preview
            ...order.items.take(3).map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: item.card.imageUrl.isNotEmpty
                        ? Image.network(item.card.imageUrl, width: 30, height: 40, fit: BoxFit.cover)
                        : Container(width: 30, height: 40, color: Colors.grey[800]),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${item.quantity}x ${item.card.name}',
                      style: const TextStyle(color: Colors.white70),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    settingsVM.formatPrice(item.card.marketPrice * item.quantity, isExact: true),
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            )),
            if (order.items.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text('+ ${order.items.length - 3} more items', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ),
              
            const Divider(color: Color(0xFF333333), height: 24),
            
            // Footer: Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(color: Colors.white, fontSize: 16)),
                Text(
                  settingsVM.formatPrice(order.totalAmount, isExact: true),
                  style: const TextStyle(color: Color(0xFF00C896), fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderDetailBottomSheet(BuildContext context, OrderItem order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final DateFormat formatter = DateFormat('MMM dd, yyyy - hh:mm a');
        final String dateString = formatter.format(order.timestamp);

        final parts = order.shippingAddress.split('\n');
        final contactInfo = parts.isNotEmpty ? parts[0] : '';
        final addressLine = parts.length > 1 ? parts[1] : '';

        final double subtotal = order.items.fold(0.0, (sum, item) => sum + (item.card.marketPrice * item.quantity));
        final double shipping = subtotal > 150.0 ? 0.0 : 7.99;
        final double computedTotal = subtotal + shipping;
        final double discount = computedTotal > order.totalAmount ? (computedTotal - order.totalAmount) : 0.0;

        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Consumer<CartViewModel>(
              builder: (context, cartVM, child) {
                final settingsVM = context.read<SettingsViewModel>();
                final currentOrder = cartVM.orders.firstWhere(
                  (o) => o.orderId == order.orderId,
                  orElse: () => order,
                );

                return SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Order #${currentOrder.orderId}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  dateString,
                                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          _buildStatusBadge(currentOrder.status),
                        ],
                      ),
                      const Divider(color: Color(0xFF333333), height: 32),

                      if (currentOrder.status.toLowerCase() == 'unpaid' && currentOrder.paymentMethod == 'PayOS') ...[
                        _buildPaymentRetrySection(context, cartVM, currentOrder),
                        const SizedBox(height: 16),
                      ],

                      const Text(
                        'Delivery Status',
                        style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildStatusTimeline(currentOrder.status),
                      const Divider(color: Color(0xFF333333), height: 32),

                      const Text(
                        'Shipping Address',
                        style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2C),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on_rounded, color: Colors.amber, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (contactInfo.isNotEmpty)
                                    Text(
                                      contactInfo,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  if (addressLine.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      addressLine,
                                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: Color(0xFF333333), height: 32),

                      const Text(
                        'Ordered Items',
                        style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ...currentOrder.items.map((item) => _buildDetailItemRow(item, settingsVM)),
                      const Divider(color: Color(0xFF333333), height: 32),

                      _buildReceiptSummary(currentOrder, subtotal, shipping, discount, settingsVM),
                      const SizedBox(height: 24),

                      if (currentOrder.status.toLowerCase() == 'delivered') ...[
                        const Divider(color: Color(0xFF333333), height: 32),
                        _buildFeedbackSection(context, currentOrder),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'paid':
        statusColor = Colors.teal;
        break;
      case 'processing':
        statusColor = Colors.orange;
        break;
      case 'shipped':
        statusColor = Colors.blue;
        break;
      case 'delivered':
        statusColor = Colors.green;
        break;
      case 'unpaid':
        statusColor = Colors.redAccent;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatusTimeline(String status) {
    final lowerStatus = status.toLowerCase();

    bool isUnpaid = lowerStatus == 'unpaid';
    bool isPaid = lowerStatus == 'paid' || lowerStatus == 'processing' || lowerStatus == 'shipped' || lowerStatus == 'delivered';
    bool isProcessing = lowerStatus == 'processing' || lowerStatus == 'shipped' || lowerStatus == 'delivered';
    bool isShipped = lowerStatus == 'shipped' || lowerStatus == 'delivered';
    bool isDelivered = lowerStatus == 'delivered';

    return Column(
      children: [
        if (isUnpaid) ...[
          _buildTimelineStep(
            icon: Icons.error_outline_rounded,
            color: Colors.redAccent,
            title: 'Payment Pending / Unpaid',
            subtitle: 'Waiting for PayOS transaction confirmation',
            isLast: false,
          ),
          _buildTimelineDivider(false),
        ],
        _buildTimelineStep(
          icon: isUnpaid ? Icons.circle_outlined : Icons.check_circle_rounded,
          color: isUnpaid ? Colors.white24 : Colors.green,
          title: 'Order Placed',
          subtitle: 'Invoice created successfully',
          isLast: false,
        ),
        _buildTimelineDivider(isPaid),
        _buildTimelineStep(
          icon: isPaid ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          color: isPaid ? Colors.teal : Colors.white24,
          title: 'Payment Confirmed',
          subtitle: 'Payment has been verified by Admin',
          isLast: false,
        ),
        _buildTimelineDivider(isProcessing),
        _buildTimelineStep(
          icon: isProcessing ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          color: isProcessing ? Colors.green : Colors.white24,
          title: 'Processing',
          subtitle: 'Preparing items for shipping',
          isLast: false,
        ),
        _buildTimelineDivider(isShipped),
        _buildTimelineStep(
          icon: isShipped ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          color: isShipped ? Colors.green : Colors.white24,
          title: 'Shipped',
          subtitle: 'Out for delivery via Courier',
          isLast: false,
        ),
        _buildTimelineDivider(isDelivered),
        _buildTimelineStep(
          icon: isDelivered ? Icons.stars_rounded : Icons.radio_button_unchecked_rounded,
          color: isDelivered ? Colors.amber : Colors.white24,
          title: 'Delivered',
          subtitle: 'Received and verified by Trainer',
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildTimelineStep({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineDivider(bool isActive) {
    return Container(
      alignment: Alignment.centerLeft,
      margin: const EdgeInsets.only(left: 10, top: 4, bottom: 4),
      height: 20,
      width: 2,
      color: isActive ? Colors.green : Colors.white12,
    );
  }

  Widget _buildDetailItemRow(CartItem item, SettingsViewModel settingsVM) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2C),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item.card.imageUrl.isNotEmpty
                  ? Image.network(
                      item.card.imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber)));
                      },
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 20, color: Colors.white30),
                    )
                  : const Icon(Icons.image, size: 20, color: Colors.white30),
            ),
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.card.name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.card.type,
                        style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'HP ${item.card.hp}',
                      style: const TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'x${item.quantity}',
                style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                settingsVM.formatPrice(item.card.marketPrice, isExact: true),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptSummary(OrderItem order, double subtotal, double shipping, double discount, SettingsViewModel settingsVM) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Details',
          style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2C),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Payment Method', style: TextStyle(color: Colors.white54, fontSize: 13)),
                  Row(
                    children: [
                      const Icon(Icons.payment_rounded, color: Colors.amber, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        order.paymentMethod,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(color: Colors.white10, height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal', style: TextStyle(color: Colors.white54, fontSize: 13)),
                  Text(
                    settingsVM.formatPrice(subtotal, isExact: true),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (discount > 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Discount / Coupon', style: TextStyle(color: Colors.white54, fontSize: 13)),
                    Text(
                      '-${settingsVM.formatPrice(discount, isExact: true)}',
                      style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Shipping Fee', style: TextStyle(color: Colors.white54, fontSize: 13)),
                  Text(
                    shipping == 0 ? 'FREE' : settingsVM.formatPrice(shipping, isExact: true),
                    style: TextStyle(
                      color: shipping == 0 ? Colors.greenAccent : Colors.white,
                      fontSize: 13,
                      fontWeight: shipping == 0 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.white10, height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Grand Total', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(
                    settingsVM.formatPrice(order.totalAmount, isExact: true),
                    style: const TextStyle(color: Color(0xFF00C896), fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentRetrySection(BuildContext context, CartViewModel cartVM, OrderItem order) {
    final amountVnd = (order.totalAmount * 25000).round();
    final amountVndStr = amountVnd.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
              SizedBox(width: 8),
              Text(
                'Payment Incomplete',
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'This order requires bank transfer payment of $amountVndStr ₫ to process.',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: cartVM.isLoading
                  ? null
                  : () async {
                      final success = await cartVM.regeneratePayOSLink(order);
                      if (!context.mounted) return;

                      if (success) {
                        showPayOSPendingDialog(
                          context: context,
                          cartVM: cartVM,
                          order: order,
                          onPaymentVerified: (updatedOrder) {
                            final authVM = context.read<AuthViewModel>();
                            final catalogVM = context.read<CatalogViewModel>();
                            cartVM.loadOrders(authVM.email, catalogVM.cards);
                          },
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to generate payment QR code. Please try again!'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    },
              icon: cartVM.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Icon(Icons.qr_code_scanner_rounded, size: 18),
              label: cartVM.isLoading
                  ? const Text('Generating...')
                  : const Text('PAY NOW & VERIFY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackSection(BuildContext context, OrderItem order) {
    if (order.rating != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Feedback',
            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2C),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < (order.rating ?? 0) ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: Colors.amber,
                      size: 20,
                    );
                  }),
                ),
                if (order.feedback != null && order.feedback!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    order.feedback!,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    }

    double localRating = 5;
    final feedbackController = TextEditingController();

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rate your order',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        onPressed: () => setState(() => localRating = index + 1.0),
                        icon: Icon(
                          index < localRating ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: Colors.amber,
                          size: 32,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: feedbackController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Share your thoughts (optional)',
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: const Color(0xFF1E1E1E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final authVM = context.read<AuthViewModel>();
                        await context.read<CartViewModel>().submitFeedback(
                          order.orderId,
                          localRating,
                          feedbackController.text.trim(),
                          authVM.displayName,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Feedback submitted! Thank you!')),
                          );
                        }
                      },
                      child: const Text('SUBMIT FEEDBACK'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
