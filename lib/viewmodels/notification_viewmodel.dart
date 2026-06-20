import 'package:flutter/material.dart';
import '../models/notification_model.dart';

class NotificationViewModel extends ChangeNotifier {
  List<NotificationModel> _notifications = [];

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationViewModel() {
    _loadDefaultNotifications();
  }

  void _loadDefaultNotifications() {
    _notifications = [
      NotificationModel(
        id: 'notif-1',
        title: 'New Booster Pack Release!',
        body: 'The highly anticipated "Scarlet & Violet: Stellar Crown" booster packs are now available in-store and online!',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        type: 'news',
      ),
      NotificationModel(
        id: 'notif-2',
        title: 'Flash Sale: 20% Off Dark Types',
        body: 'Use code CHARIZARD20 at checkout to save 20% on selected Premium Dark/Fire type cards. Ends tonight!',
        timestamp: DateTime.now().subtract(const Duration(hours: 8)),
        type: 'promotion',
      ),
      NotificationModel(
        id: 'notif-3',
        title: 'Welcome Trainer!',
        body: 'Thank you for registering at Pokémon TCG Collector. Get ready to explore authentic rare cards and charts!',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        type: 'news',
        isRead: true,
      ),
    ];
    notifyListeners();
  }

  void addNotification({required String title, required String body, required String type}) {
    final newNotif = NotificationModel(
      id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      timestamp: DateTime.now(),
      type: type,
    );
    _notifications.insert(0, newNotif);
    notifyListeners();
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index >= 0) {
      _notifications[index].isRead = true;
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  void removeNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }
}
