import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/notification.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  final int userId;

  const NotificationScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final ApiService _apiService = ApiService();
  final NotificationService _notificationService = NotificationService();
  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final notifications = await _apiService.getUserNotifications(widget.userId);
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(int notificationId) async {
    try {
      await _apiService.markNotificationAsRead(notificationId);
      _loadNotifications();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  Future<void> _deleteNotification(int notificationId) async {
    try {
      await _apiService.deleteNotification(notificationId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bildirim silindi')),
      );
      _loadNotifications();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  Future<void> _testLocalNotification() async {
    await _notificationService.showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Test Bildirimi',
      body: 'Bu bir test bildirimidir. Randevunuz 1 saat sonra!',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test bildirimi gönderildi!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Bildirimler'),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active),
            tooltip: 'Test Bildirimi',
            onPressed: _testLocalNotification,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Hata: $_error'),
                      ElevatedButton(
                        onPressed: _loadNotifications,
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                )
              : _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('Henüz bildirim yok'),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _testLocalNotification,
                            icon: const Icon(Icons.notifications),
                            label: const Text('Test Bildirimi Gönder'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notification = _notifications[index];
                        return Dismissible(
                          key: Key(notification.id.toString()),
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 16),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) {
                            _deleteNotification(notification.id!);
                          },
                          child: Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            color: notification.isRead
                                ? Colors.white
                                : Colors.purple[50],
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: notification.isRead
                                    ? Colors.grey
                                    : Colors.purple,
                                child: Icon(
                                  notification.isRead
                                      ? Icons.notifications_none
                                      : Icons.notifications_active,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                notification.message,
                                style: TextStyle(
                                  fontWeight: notification.isRead
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                DateFormat('dd MMM yyyy, HH:mm')
                                    .format(notification.createdAt),
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: !notification.isRead
                                  ? IconButton(
                                      icon: const Icon(Icons.check),
                                      color: Colors.purple,
                                      onPressed: () {
                                        _markAsRead(notification.id!);
                                      },
                                    )
                                  : null,
                              onTap: () {
                                if (!notification.isRead) {
                                  _markAsRead(notification.id!);
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
