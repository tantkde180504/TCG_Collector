import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/notification_viewmodel.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  IconData _getIcon(String type) {
    switch (type) {
      case 'order_status':
        return Icons.local_shipping;
      case 'promotion':
        return Icons.local_offer;
      case 'news':
      default:
        return Icons.campaign;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'order_status':
        return Colors.greenAccent;
      case 'promotion':
        return Colors.redAccent;
      case 'news':
      default:
        return Colors.blueAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifVM = context.watch<NotificationViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Column(
        children: [
          // Actions bar
          if (notifVM.notifications.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${notifVM.unreadCount} Unread Alerts',
                    style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: () => notifVM.markAllAsRead(),
                    icon: const Icon(Icons.done_all, size: 16, color: Colors.amber),
                    label: const Text('Mark All Read', style: TextStyle(color: Colors.amber, fontSize: 12)),
                  ),
                ],
              ),
            ),
            
          Expanded(
            child: notifVM.notifications.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off_outlined, size: 56, color: Colors.white24),
                        SizedBox(height: 12),
                        Text(
                          'No Notifications Yet',
                          style: TextStyle(color: Colors.white54, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'You\'ll get alerts about orders and sales here.',
                          style: TextStyle(color: Colors.white30, fontSize: 11),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: notifVM.notifications.length,
                    itemBuilder: (context, index) {
                      final item = notifVM.notifications[index];
                      final notifColor = _getColor(item.type);
                      final formattedTime = DateFormat('jm').format(item.timestamp);

                      return Dismissible(
                        key: Key(item.id),
                        onDismissed: (_) {
                          notifVM.removeNotification(item.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Notification dismissed!'),
                              duration: Duration(milliseconds: 800),
                            ),
                          );
                        },
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.shade700,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: GestureDetector(
                          onTap: () {
                            notifVM.markAsRead(item.id);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: item.isRead ? const Color(0xFF1E1E1E) : const Color(0xFF262626),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: item.isRead ? Colors.white.withOpacity(0.05) : notifColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Category Icon
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: notifColor.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(_getIcon(item.type), color: notifColor, size: 20),
                                ),
                                const SizedBox(width: 12),
                                
                                // Text details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.title,
                                              style: TextStyle(
                                                color: item.isRead ? Colors.white70 : Colors.white,
                                                fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            formattedTime,
                                            style: const TextStyle(color: Colors.white30, fontSize: 10),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.body,
                                        style: TextStyle(
                                          color: item.isRead ? Colors.white38 : Colors.white70,
                                          fontSize: 12,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
