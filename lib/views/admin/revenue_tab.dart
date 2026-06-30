import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/catalog_viewmodel.dart';
import '../../services/database_service.dart';
import '../../models/order_item.dart';

class RevenueTab extends StatelessWidget {
  const RevenueTab({super.key});

  @override
  Widget build(BuildContext context) {
    final catalogVM = context.read<CatalogViewModel>();
    
    return FutureBuilder<List<OrderItem>>(
      future: DatabaseService.instance.getAllOrdersAdmin(catalogVM.cards),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final orders = snapshot.data ?? [];
        final totalRevenue = orders.fold<double>(0, (sum, order) => sum + order.totalAmount);

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.amber.shade700, Colors.orange.shade800]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))
                  ],
                ),
                child: Column(
                  children: [
                    const Text('TỔNG DOANH THU', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    const SizedBox(height: 8),
                    Text('\$${totalRevenue.toStringAsFixed(2)}', 
                      style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.black)),
                    Text('${orders.length} giao dịch thành công', style: const TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Row(
                children: [
                  Icon(Icons.history, size: 20, color: Colors.amber),
                  SizedBox(width: 8),
                  Text('Lịch sử giao dịch', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const Divider(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Card(
                      color: const Color(0xFF1E1E1E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.shopping_bag, color: Colors.amber),
                        ),
                        title: Text('Đơn #${order.orderId.substring(0, 8).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('ID: ${order.userId.substring(0, 8)}...'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('+\$${order.totalAmount}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(order.timestamp.toString().split(' ')[0], style: const TextStyle(fontSize: 10, color: Colors.white38)),
                          ],
                        ),
                        onTap: () => _showOrderDetail(context, order),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showOrderDetail(BuildContext context, OrderItem order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20.0),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.all(Radius.circular(2)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Chi tiết đơn hàng', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              Text('ID: ${order.orderId}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
              const Divider(height: 32),
              
              _buildInfoRow('Khách hàng (UID)', order.userId),
              _buildInfoRow('Ngày đặt', order.timestamp.toString().split('.')[0]),
              _buildInfoRow('Trạng thái', order.status, color: Colors.blueAccent),
              _buildInfoRow('Thanh toán', order.paymentMethod),
              const SizedBox(height: 16),
              const Text('Địa chỉ giao hàng:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
              Text(order.shippingAddress, style: const TextStyle(color: Colors.white54)),
              
              const SizedBox(height: 24),
              const Text('Sản phẩm:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              ...order.items.map((item) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Image.network(item.card.imageUrl, width: 40),
                title: Text(item.card.name),
                subtitle: Text('\$${item.card.marketPrice} x ${item.quantity}'),
                trailing: Text('\$${(item.card.marketPrice * item.quantity).toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              )),
              
              const Divider(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TỔNG CỘNG:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('${order.totalAmount} PokeGold', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber)),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color ?? Colors.white)),
        ],
      ),
    );
  }
}
