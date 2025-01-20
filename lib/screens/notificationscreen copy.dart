import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_provider.dart';
import '../models/EventNotification.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isMarkingAll = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().fetchNotifications();
    });
  }

  Future<void> _markAllAsRead(AuthProvider auth) async {
    if (_isMarkingAll) return;

    try {
      setState(() => _isMarkingAll = true);

      final unreadNotifications = auth.notifications
          .where((notification) => !notification.isRead)
          .toList();

      for (var notification in unreadNotifications) {
        await auth.markNotificationAsRead(notification.id);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications marked as read')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error marking notifications as read: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isMarkingAll = false);
      }
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return DateFormat('MMM d, y').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildNotificationList(
      List<EventNotification> notifications, AuthProvider auth) {
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return Dismissible(
          key: Key(notification.id.toString()),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Confirm Delete'),
                  content: const Text(
                      'Are you sure you want to delete this notification?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Delete'),
                    ),
                  ],
                );
              },
            );
          },
          onDismissed: (direction) {
            // Here you would call a method to delete the notification
            // For now we'll just show a snackbar
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notification deleted')),
            );
          },
          child: Card(
            elevation: notification.isRead ? 1 : 2,
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: notification.isRead ? null : Colors.blue[50],
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: notification.isRead
                    ? Colors.grey[200]
                    : const Color.fromARGB(255, 21, 0, 141),
                child: Icon(
                  Icons.event,
                  color: notification.isRead ? Colors.grey[600] : Colors.white,
                ),
              ),
              title: Text(
                notification.title,
                style: TextStyle(
                  fontWeight:
                      notification.isRead ? FontWeight.normal : FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    notification.message,
                    style: TextStyle(color: Colors.grey[800]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getTimeAgo(notification.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              onTap: () async {
                if (!notification.isRead) {
                  try {
                    await auth.markNotificationAsRead(notification.id);
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                }
              },
              trailing: !notification.isRead
                  ? Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 21, 0, 141),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              final hasUnread = auth.notifications.any((n) => !n.isRead);
              return hasUnread
                  ? TextButton(
                      onPressed:
                          _isMarkingAll ? null : () => _markAllAsRead(auth),
                      child: _isMarkingAll
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Mark all as read',
                              style: TextStyle(color: Colors.white),
                            ),
                    )
                  : const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<AuthProvider>().fetchNotifications(),
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isLoadingNotifications) {
            return const Center(child: CircularProgressIndicator());
          }

          if (auth.notificationError != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading notifications',
                    style: TextStyle(color: Colors.red[300]),
                  ),
                  TextButton(
                    onPressed: () => auth.fetchNotifications(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => auth.fetchNotifications(),
            child: _buildNotificationList(auth.notifications, auth),
          );
        },
      ),
    );
  }
}
