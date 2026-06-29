import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/order_item.dart';
import '../viewmodels/cart_viewmodel.dart';
import '../viewmodels/notification_viewmodel.dart';

class PayOSPaymentInfo extends StatelessWidget {
  final double grandTotal;

  const PayOSPaymentInfo({
    super.key,
    required this.grandTotal,
  });

  @override
  Widget build(BuildContext context) {
    final amountVnd = (grandTotal * 25000).round();
    final amountVndStr = amountVnd.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.qr_code, color: Colors.amber),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PayOS - QR Bank Transfer (VND)',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Exchange rate: \$1 = 25,000 VND. Total payment amount: $amountVndStr ₫',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                const SizedBox(height: 2),
                const Text(
                  'A secure checkout portal will open. Verify payment after completion.',
                  style: TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void showPayOSPendingDialog({
  required BuildContext context,
  required CartViewModel cartVM,
  required OrderItem order,
  required Function(OrderItem) onPaymentVerified,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return _PayOSPendingDialog(
        cartVM: cartVM,
        order: order,
        onPaymentVerified: onPaymentVerified,
      );
    },
  );
}

class _PayOSPendingDialog extends StatefulWidget {
  final CartViewModel cartVM;
  final OrderItem order;
  final Function(OrderItem) onPaymentVerified;

  const _PayOSPendingDialog({
    required this.cartVM,
    required this.order,
    required this.onPaymentVerified,
  });

  @override
  State<_PayOSPendingDialog> createState() => _PayOSPendingDialogState();
}

class _PayOSPendingDialogState extends State<_PayOSPendingDialog> {
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _checkPayment(auto: true));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkPayment({required bool auto}) async {
    if (widget.cartVM.isLoading) return;

    final success = await widget.cartVM.verifyPayOSPayment(widget.order.orderId);
    if (!mounted) return;

    if (!success) {
      if (!auto) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment not completed yet. Please finish transaction or scan QR again!'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
      return;
    }

    _pollTimer?.cancel();
    Navigator.of(context).pop();

    final updatedOrder = widget.cartVM.orders.firstWhere(
      (o) => o.orderId == widget.order.orderId,
      orElse: () => OrderItem(
        orderId: widget.order.orderId,
        userId: widget.order.userId,
        items: widget.order.items,
        totalAmount: widget.order.totalAmount,
        status: 'Paid',
        timestamp: widget.order.timestamp,
        shippingAddress: widget.order.shippingAddress,
        paymentMethod: widget.order.paymentMethod,
      ),
    );

    widget.onPaymentVerified(updatedOrder);

    final amountVnd = (widget.order.totalAmount * 25000).round();
    final amountVndStr = amountVnd.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );

    final notifVM = context.read<NotificationViewModel>();
    notifVM.addNotification(
      title: 'Payment Confirmed via PayOS!',
      body: 'Your order ${widget.order.orderId} of $amountVndStr ₫ has been successfully paid.',
      type: 'order_status',
    );

    widget.cartVM.setCheckoutStep(2);
  }

  @override
  Widget build(BuildContext context) {
    final cartVM = widget.cartVM;
    final order = widget.order;
    final amountVnd = (order.totalAmount * 25000).round();
    final amountVndStr = amountVnd.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );

    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.amber, width: 1.5),
      ),
      title: const Row(
        children: [
          Icon(Icons.qr_code, color: Colors.amber),
          SizedBox(width: 8),
          Text(
            'PayOS Verification',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Please scan the QR code below to pay via Bank Transfer.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            if (cartVM.lastPayOSData != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.network(
                  'https://img.vietqr.io/image/${cartVM.lastPayOSData!['bin']}-${cartVM.lastPayOSData!['accountNumber']}-compact2.png?amount=${cartVM.lastPayOSData!['amount']}&addInfo=${Uri.encodeComponent(cartVM.lastPayOSData!['description'])}&accountName=${Uri.encodeComponent(cartVM.lastPayOSData!['accountName'])}',
                  width: 220,
                  height: 220,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const SizedBox(
                      width: 220,
                      height: 220,
                      child: Center(child: CircularProgressIndicator(color: Colors.amber)),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => const SizedBox(
                    width: 220,
                    height: 220,
                    child: Center(child: Icon(Icons.broken_image, size: 64, color: Colors.grey)),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Amount (VND):',
                    style: TextStyle(color: Colors.white30, fontSize: 10),
                  ),
                  Text(
                    '$amountVndStr ₫',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Description / Memo:',
                    style: TextStyle(color: Colors.white30, fontSize: 10),
                  ),
                  Text(
                    cartVM.lastPayOSData?['description'] ?? order.orderId,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber),
                ),
                SizedBox(width: 8),
                Text(
                  'Waiting for payment...',
                  style: TextStyle(color: Colors.white54, fontSize: 11, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('PAY LATER', style: TextStyle(color: Colors.white30, fontSize: 11)),
        ),
        if (cartVM.lastCheckoutUrl != null)
          TextButton(
            onPressed: () => launchUrl(Uri.parse(cartVM.lastCheckoutUrl!), mode: LaunchMode.externalApplication),
            child: const Text('OPEN WEB', style: TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: cartVM.isLoading ? null : () => _checkPayment(auto: false),
          child: cartVM.isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                )
              : const Text('VERIFY PAYMENT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ],
    );
  }
}
