import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/order_item.dart';
import '../../services/database_service.dart';
import '../../viewmodels/catalog_viewmodel.dart';

class OrderManagementTab extends StatefulWidget {
  const OrderManagementTab({super.key});

  @override
  State<OrderManagementTab> createState() => _OrderManagementTabState();
}

class _OrderManagementTabState extends State<OrderManagementTab> {
  String _selectedStatusFilter = 'All'; // All, Paid, Processing, Shipped, Delivered
  String _searchQuery = '';
  bool _isLoading = true;
  List<OrderItem> _allOrders = [];
  List<OrderItem> _filteredOrders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    final catalogVM = context.read<CatalogViewModel>();
    if (catalogVM.cards.isEmpty) {
      await catalogVM.loadCatalog();
    }

    final orders = await DatabaseService.instance.getAllOrdersAdmin(catalogVM.cards);
    
    if (mounted) {
      setState(() {
        _allOrders = orders;
        _applyFilters();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<OrderItem> temp = List.from(_allOrders);

    // Filter by status (Excluding Unpaid completely since user asked)
    if (_selectedStatusFilter != 'All') {
      temp = temp.where((o) => o.status.toLowerCase() == _selectedStatusFilter.toLowerCase()).toList();
    }

    // Filter by Search Query (ID or Address or User Email/ID)
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      temp = temp.where((o) =>
          o.orderId.toLowerCase().contains(q) ||
          o.userId.toLowerCase().contains(q) ||
          o.shippingAddress.toLowerCase().contains(q)).toList();
    }

    // Sort by timestamp desc
    temp.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    setState(() {
      _filteredOrders = temp;
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'processing':
        return Colors.orange;
      case 'shipped':
        return Colors.blue;
      case 'delivered':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return 'Đã thanh toán';
      case 'processing':
        return 'Đang chuẩn bị';
      case 'shipped':
        return 'Đang giao';
      case 'delivered':
        return 'Đã giao';
      default:
        return status;
    }
  }

  Future<void> _updateStatus(OrderItem order, String newStatus) async {
    setState(() {
      _isLoading = true;
    });

    final success = await DatabaseService.instance.updateOrderStatus(
      order.userId,
      order.orderId,
      newStatus,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã cập nhật trạng thái đơn hàng sang: ${_getStatusText(newStatus)}'),
            backgroundColor: Colors.green,
          ),
        );
        _loadOrders();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật trạng thái thất bại. Hãy kiểm tra lại kết nối hoặc phân quyền.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showOrderDetails(OrderItem order) {
    showDialog(
      context: context,
      builder: (context) {
        final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(order.timestamp);
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text(
            'Chi tiết đơn hàng\n#${order.orderId}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: Colors.white24),
                  _detailRow('Khách hàng (User/Email):', order.userId),
                  _detailRow('Ngày đặt:', formattedDate),
                  _detailRow('Phương thức:', order.paymentMethod),
                  _detailRow('Địa chỉ giao hàng:', order.shippingAddress),
                  const SizedBox(height: 16),
                  const Text('Sản phẩm đã mua:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                  const SizedBox(height: 8),
                  ...order.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              item.card.imageUrl,
                              width: 35,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, size: 35),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.card.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                Text('Số lượng: ${item.quantity} | Giá: ${item.card.marketPrice} PG', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(color: Colors.white24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng cộng:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                      Text('${order.totalAmount} PG', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.amber)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng', style: TextStyle(color: Colors.white60)),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tìm kiếm
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Tìm theo mã đơn, khách hàng, địa chỉ...',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              filled: true,
              fillColor: const Color(0xFF1E1E1E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
                _applyFilters();
              });
            },
          ),
        ),

        // Lọc theo trạng thái đơn hàng (Không có Unpaid)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
          child: Row(
            children: [
              _filterChip('Tất cả', 'All'),
              _filterChip('Đã thanh toán', 'Paid'),
              _filterChip('Đang chuẩn bị', 'Processing'),
              _filterChip('Đang giao', 'Shipped'),
              _filterChip('Đã giao', 'Delivered'),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Bảng danh sách đơn hàng
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.amber))
              : _filteredOrders.isEmpty
                  ? const Center(child: Text('Không tìm thấy đơn hàng nào.', style: TextStyle(color: Colors.white70)))
                  : RefreshIndicator(
                      onRefresh: _loadOrders,
                      color: Colors.amber,
                      child: ListView.builder(
                        itemCount: _filteredOrders.length,
                        itemBuilder: (context, index) {
                          final order = _filteredOrders[index];
                          final formattedDate = DateFormat('dd/MM HH:mm').format(order.timestamp);
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            color: const Color(0xFF1E1E1E),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Đơn hàng: #${order.orderId}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        formattedDate,
                                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Khách hàng: ${order.userId}',
                                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tổng tiền: ${order.totalAmount} PG',
                                    style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  const Divider(color: Colors.white12, height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Nhãn Trạng thái
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(order.status).withValues(alpha: 0.15),
                                          border: Border.all(color: _getStatusColor(order.status).withValues(alpha: 0.5)),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          _getStatusText(order.status),
                                          style: TextStyle(
                                            color: _getStatusColor(order.status),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),

                                      // Bộ nút hành động
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.visibility, color: Colors.amber),
                                            tooltip: 'Xem chi tiết',
                                            onPressed: () => _showOrderDetails(order),
                                          ),
                                          const SizedBox(width: 4),
                                          PopupMenuButton<String>(
                                            icon: const Icon(Icons.edit_road_rounded, color: Colors.blueAccent),
                                            tooltip: 'Cập nhật trạng thái',
                                            color: const Color(0xFF2C2C2C),
                                            onSelected: (String status) {
                                              _updateStatus(order, status);
                                            },
                                            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                              const PopupMenuItem<String>(
                                                value: 'Paid',
                                                child: Text('Đã thanh toán', style: TextStyle(color: Colors.white)),
                                              ),
                                              const PopupMenuItem<String>(
                                                value: 'Processing',
                                                child: Text('Đang chuẩn bị', style: TextStyle(color: Colors.white)),
                                              ),
                                              const PopupMenuItem<String>(
                                                value: 'Shipped',
                                                child: Text('Đang giao', style: TextStyle(color: Colors.white)),
                                              ),
                                              const PopupMenuItem<String>(
                                                value: 'Delivered',
                                                child: Text('Đã giao', style: TextStyle(color: Colors.white)),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, String statusValue) {
    final isSelected = _selectedStatusFilter == statusValue;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        selected: isSelected,
        label: Text(label, style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
        selectedColor: Colors.amber,
        checkmarkColor: Colors.black,
        backgroundColor: const Color(0xFF1E1E1E),
        onSelected: (bool selected) {
          setState(() {
            _selectedStatusFilter = statusValue;
            _applyFilters();
          });
        },
      ),
    );
  }
}
