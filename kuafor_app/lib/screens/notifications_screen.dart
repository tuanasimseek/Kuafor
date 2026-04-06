import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../widgets/app_widgets.dart';

class NotificationsScreen extends StatefulWidget {
  final int userId;
  const NotificationsScreen({super.key, required this.userId});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  List<dynamic> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _notificationService.getUserNotifications(widget.userId);
    if (mounted) {
      setState(() {
        _notifications = data;
        _loading = false;
      });
    }
  }

  Future<void> _markAsRead(int id) async {
    await _notificationService.markAsRead(id);
    _load();
  }

  Future<void> _markAllAsRead() async {
    await _notificationService.markAllAsRead(widget.userId);
    _load();
  }

  int get _unreadCount =>
      _notifications.where((n) => n['isRead'] != true).length;

  String _formatDate(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}'
          '  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw.length > 16 ? raw.substring(0, 16).replaceAll('T', ' ') : raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────────
          Container(
            color: AppColors.primary,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 24, right: 24, bottom: 24,
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_ios,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('BİLDİRİMLER',
                          style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2.5)),
                      const SizedBox(height: 2),
                      Row(children: [
                        const Text('Son güncellemeler',
                            style: TextStyle(
                                color: AppColors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w500)),
                        if (_unreadCount > 0) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$_unreadCount yeni',
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ]),
                    ],
                  ),
                ),
                // Tümünü okundu işaretle
                if (_unreadCount > 0)
                  GestureDetector(
                    onTap: _markAllAsRead,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.2)),
                      ),
                      child: const Text(
                        'Tümü okundu',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Liste ─────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.accent))
                : _notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_none,
                                size: 56,
                                color: AppColors.muted.withOpacity(0.4)),
                            const SizedBox(height: 12),
                            const Text('Bildirim yok',
                                style: TextStyle(
                                    color: AppColors.muted, fontSize: 14)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: AppColors.accent,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _notifications.length,
                          itemBuilder: (context, index) {
                            final notif = _notifications[index];
                            final isRead = notif['isRead'] == true;
                            final title = (notif['title'] ?? notif['Title'] ?? '') as String;
                            final message = (notif['message'] ?? notif['Message'] ?? '') as String;
                            final createdAt = (notif['createdAt'] ?? notif['CreatedAt']) as String?;
                            final id = notif['id'] ?? notif['Id'];

                            return GestureDetector(
                              onTap: isRead ? null : () => _markAsRead(id),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: isRead
                                      ? AppColors.surface
                                      : AppColors.accent.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isRead
                                        ? AppColors.border
                                        : AppColors.accent.withOpacity(0.25),
                                  ),
                                ),
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 36, height: 36,
                                      decoration: BoxDecoration(
                                        color: isRead
                                            ? AppColors.border
                                            : AppColors.accent.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        isRead
                                            ? Icons.notifications_none
                                            : Icons.notifications_active,
                                        color: isRead
                                            ? AppColors.muted
                                            : AppColors.accent,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (title.isNotEmpty)
                                            Text(
                                              title,
                                              style: TextStyle(
                                                color: AppColors.primary,
                                                fontSize: 13,
                                                fontWeight: isRead
                                                    ? FontWeight.w600
                                                    : FontWeight.w700,
                                              ),
                                            ),
                                          if (title.isNotEmpty)
                                            const SizedBox(height: 3),
                                          Text(
                                            message,
                                            style: TextStyle(
                                              color: isRead
                                                  ? AppColors.muted
                                                  : AppColors.primary,
                                              fontSize: 13,
                                              fontWeight: isRead
                                                  ? FontWeight.normal
                                                  : FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                _formatDate(createdAt),
                                                style: const TextStyle(
                                                    color: AppColors.muted,
                                                    fontSize: 11),
                                              ),
                                              if (!isRead)
                                                const Text(
                                                  'Okundu işaretle',
                                                  style: TextStyle(
                                                      color: AppColors.accent,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w500),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
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
      ),
    );
  }
}