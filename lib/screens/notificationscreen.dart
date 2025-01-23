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
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().fetchNotifications();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _markAllAsRead(AuthProvider auth) async {
    if (_isMarkingAll) return;

    try {
      setState(() => _isMarkingAll = true);
      await auth.markAllNotificationsAsRead();
      _showSnackBar('All notifications marked as read', isError: false);
    } catch (e) {
      _showSnackBar('Error marking notifications as read: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isMarkingAll = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(20),
      ),
    );
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

  Widget _buildEmptyState() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_outlined,
              size: 80,
              color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll see your notifications here',
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AuthProvider auth) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.red[900]?.withOpacity(0.3)
                  : Colors.red[50],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error_outline,
                size: 64,
                color: isDarkMode ? Colors.red[300] : Colors.red[300]),
          ),
          const SizedBox(height: 24),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Unable to load notifications',
            style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => auth.fetchNotifications(),
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDarkMode
                  ? const Color.fromARGB(255, 50, 50, 100)
                  : const Color.fromARGB(255, 21, 0, 141),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteNotification(
      AuthProvider auth, int notificationId) async {
    try {
      await auth.deleteNotification(notificationId);
      _showSnackBar('Notification deleted', isError: false);
    } catch (e) {
      _showSnackBar('Error deleting notification: $e', isError: true);
    }
  }

  Widget _buildNotificationItem(
      EventNotification notification, AuthProvider auth) {
    final dismissKey = UniqueKey();
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Dynamic color palette based on read/unread and theme
    Color backgroundColor = isDarkMode
        ? (notification.isRead
            ? Colors.grey[800]!
            : const Color.fromARGB(255, 45, 45, 100))
        : (notification.isRead ? Colors.white : Colors.blue[50]!);

    Color iconBackgroundColor = isDarkMode
        ? (notification.isRead
            ? Colors.grey[700]!
            : const Color.fromARGB(255, 21, 0, 141))
        : (notification.isRead
            ? Colors.grey[100]!
            : const Color.fromARGB(255, 21, 0, 141));

    Color textColor = isDarkMode
        ? (notification.isRead ? Colors.grey[400]! : Colors.white)
        : (notification.isRead ? Colors.grey[700]! : Colors.black);

    Color subtextColor = isDarkMode ? Colors.grey[500]! : Colors.grey[600]!;

    return Dismissible(
      key: dismissKey,
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red[400],
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Delete Notification',
                  style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black)),
              content: Text(
                'Are you sure you want to delete this notification?',
                style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.grey[300] : Colors.black),
              ),
              backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Cancel',
                      style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(
                    foregroundColor: isDarkMode ? Colors.red[300] : Colors.red,
                  ),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) async {
        await _deleteNotification(auth, notification.id);
      },
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border(
            bottom: BorderSide(
              color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
              width: 1,
            ),
          ),
        ),
        child: InkWell(
          onTap: () async {
            if (!notification.isRead) {
              try {
                await auth.markNotificationAsRead(notification.id);
              } catch (e) {
                if (mounted) {
                  _showSnackBar('Error: $e', isError: true);
                }
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconBackgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.event_outlined,
                    size: 24,
                    color: isDarkMode
                        ? Colors.white
                        : (notification.isRead
                            ? Colors.grey[600]
                            : Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: notification.isRead
                                    ? FontWeight.w500
                                    : FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? Colors.white
                                    : const Color.fromARGB(255, 21, 0, 141),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 14,
                          color: subtextColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getTimeAgo(notification.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: subtextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: isDarkMode
            ? const Color.fromARGB(255, 10, 10, 70)
            : const Color.fromARGB(255, 21, 0, 141),
        elevation: 0,
        actions: [
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              final hasUnread = auth.notifications.any((n) => !n.isRead);
              return hasUnread
                  ? TextButton.icon(
                      onPressed:
                          _isMarkingAll ? null : () => _markAllAsRead(auth),
                      icon: _isMarkingAll
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    isDarkMode ? Colors.white : Colors.white),
                              ),
                            )
                          : Icon(Icons.done_all,
                              color: isDarkMode ? Colors.white : Colors.white),
                      label: Text(
                        'Mark all read',
                        style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.white),
                      ),
                    )
                  : const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh,
                color: isDarkMode ? Colors.white : Colors.white),
            onPressed: () => context.read<AuthProvider>().fetchNotifications(),
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isLoadingNotifications) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDarkMode
                      ? Colors.white
                      : const Color.fromARGB(255, 21, 0, 141),
                ),
              ),
            );
          }

          if (auth.notificationError != null) {
            return _buildErrorState(auth);
          }

          if (auth.notifications.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () => auth.fetchNotifications(),
            color: isDarkMode
                ? Colors.white
                : const Color.fromARGB(255, 21, 0, 141),
            child: ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: auth.notifications.length,
              itemBuilder: (context, index) {
                return _buildNotificationItem(auth.notifications[index], auth);
              },
            ),
          );
        },
      ),
    );
  }
}
