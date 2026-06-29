import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'user_management_tab.dart';
import 'product_management_tab.dart';
import 'revenue_tab.dart';
import 'order_management_tab.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
        elevation: 2,
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _handleLogout(context),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          labelColor: Colors.amber,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.people_alt_rounded), text: 'Tài khoản'),
            Tab(icon: Icon(Icons.style_rounded), text: 'Sản phẩm'),
            Tab(icon: Icon(Icons.shopping_bag_rounded), text: 'Đơn hàng'),
            Tab(icon: Icon(Icons.insights_rounded), text: 'Doanh thu'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          UserManagementTab(),
          ProductManagementTab(),
          OrderManagementTab(),
          RevenueTab(),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, child) {
          // Chỉ hiện nút Add ở tab Sản phẩm
          if (_tabController.index == 1) {
            return FloatingActionButton.extended(
              onPressed: () {
                ProductManagementTab.showProductDialog(context);
              },
              backgroundColor: Colors.amber,
              icon: const Icon(Icons.add, color: Colors.black),
              label: const Text('Thêm thẻ', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn muốn rời khỏi trang quản trị?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthViewModel>().logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
