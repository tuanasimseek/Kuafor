import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  final int userId;

  const NotificationsScreen({super.key, required this.userId});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  late Future<List<dynamic>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = _notificationService.getUserNotifications(widget.userId);
  }

  Future<void> _markAsRead(int id) async {
    await _notificationService.markAsRead(id);
    setState(() {
      _notificationsFuture = _notificationService.getUserNotifications(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bildirimler')),
      body: FutureBuilder<List<dynamic>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Bildirim yok'));
          }
          final notifications = snapshot.data!;
          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              final isRead = notif['isRead'] == true;
              return ListTile(
                leading: Icon(
                  isRead ? Icons.notifications_none : Icons.notifications_active,
                  color: isRead ? Colors.grey : Colors.blue,
                ),
                title: Text(
                  notif['message'] ?? '',
                  style: TextStyle(
                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                subtitle: notif['createdAt'] != null
                    ? Text(notif['createdAt'].toString().substring(0, 16).replaceAll('T', ' '))
                    : null,
                tileColor: isRead ? null : Colors.blue.withOpacity(0.05),
                onTap: isRead ? null : () => _markAsRead(notif['id']),
                trailing: isRead
                    ? null
                    : const Text('Okundu işaretle', style: TextStyle(fontSize: 11, color: Colors.blue)),
              );
            },
          );
        },
      ),
    );
  }
}