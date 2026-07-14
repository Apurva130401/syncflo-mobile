import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import '../../core/supabase_service.dart';
import '../../core/theme.dart';
import '../../models/models.dart';

class NotificationsCenterScreen extends StatefulWidget {
  const NotificationsCenterScreen({super.key});

  @override
  State<NotificationsCenterScreen> createState() => _NotificationsCenterScreenState();
}

class _NotificationsCenterScreenState extends State<NotificationsCenterScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  bool _isLoading = true;
  List<AppNotification> _notifications = [];
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
      final list = await _supabaseService.getNotifications();
      setState(() {
        _notifications = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _markRead(AppNotification notification) async {
    if (notification.read) return;
    
    try {
      await _supabaseService.markNotificationRead(notification.id);
      setState(() {
        final index = _notifications.indexWhere((element) => element.id == notification.id);
        if (index != -1) {
          _notifications[index] = AppNotification(
            id: notification.id,
            title: notification.title,
            message: notification.message,
            type: notification.type,
            read: true,
            actionUrl: notification.actionUrl,
            createdAt: notification.createdAt,
          );
        }
      });
    } catch (e) {
      // Fail silently or log
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(LucideIcons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.refresh_cw),
            onPressed: _loadNotifications,
          ),
        ],
      ),
      drawer: const NavigationDrawerWidget(currentRoute: '/notifications'),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Error: $_error',
                      style: TextStyle(color: AppColors.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.bell_off, size: 64, color: AppColors.textMuted),
                          const SizedBox(height: 16),
                          Text(
                            'No notifications found.',
                            style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'We\'ll notify you when changes occur.',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _notifications.length,
                      separatorBuilder: (context, index) => const Divider(height: 16),
                      itemBuilder: (context, index) {
                        final notification = _notifications[index];
                        
                        // Parse date
                        String formattedTime = '';
                        try {
                          final parsed = DateTime.parse(notification.createdAt);
                          formattedTime = DateFormat('MMM d, h:mm a').format(parsed.toLocal());
                        } catch (_) {
                          formattedTime = notification.createdAt;
                        }

                        // Icon based on type
                        IconData icon;
                        Color iconColor;
                        if (notification.type == 'success') {
                          icon = LucideIcons.circle_check;
                          iconColor = AppColors.success;
                        } else if (notification.type == 'warning' || notification.type == 'error') {
                          icon = LucideIcons.triangle_alert;
                          iconColor = AppColors.error;
                        } else {
                          icon = LucideIcons.info;
                          iconColor = AppColors.primary;
                        }

                        return InkWell(
                          onTap: () => _markRead(notification),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: notification.read
                                  ? Colors.transparent
                                  : AppColors.primary.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(8),
                              border: notification.read
                                  ? null
                                  : Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: iconColor.withValues(alpha: 0.1),
                                  child: Icon(icon, color: iconColor, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              notification.title,
                                              style: TextStyle(
                                                color: AppColors.text,
                                                fontSize: 14,
                                                fontWeight: notification.read ? FontWeight.normal : FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          if (!notification.read)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: AppColors.primary,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        notification.message,
                                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.3),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        formattedTime,
                                        style: TextStyle(color: AppColors.textMuted, fontSize: 10),
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
    );
  }
}
