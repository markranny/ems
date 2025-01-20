import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../Add/add_student_form.dart';
import '../../screens/events_calendar_page.dart';
import '../../screens/notificationscreen.dart';
import '../../screens/dashboard_view.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({Key? key}) : super(key: key);

  @override
  _StudentDashboardState createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;
  Timer? _notificationTimer;
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _pages = [
      const DashboardView(),
      EventsCalendarPage(
          canManageEvents: false), // Students can't manage events
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNotifications();
    });
  }

  void _initializeNotifications() async {
    if (!mounted) return;

    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.fetchNotifications();

      _notificationTimer?.cancel();
      _notificationTimer =
          Timer.periodic(const Duration(minutes: 1), (_) async {
        if (!mounted) return;
        try {
          await authProvider.fetchNotifications();
        } catch (e) {
          print('Error fetching notifications: $e');
        }
      });
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshNotifications() async {
    if (mounted) {
      await context.read<AuthProvider>().fetchNotifications();
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildManageCard(IconData icon, String label, {VoidCallback? onTap}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: const Color.fromARGB(255, 21, 0, 141)),
            SizedBox(height: 8),
            Text(label,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color.fromARGB(255, 21, 0, 141)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showHelpDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.help_outline,
                      color: Color.fromARGB(255, 21, 0, 141)),
                  const SizedBox(width: 8),
                  const Text(
                    'Help & Information',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),
              _buildHelpItem(
                Icons.dashboard,
                'Dashboard',
                'Overview of your activities and events.',
              ),
              _buildHelpItem(
                Icons.event,
                'Events',
                'View upcoming events and calendar.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationBadge() {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        if (auth.isLoadingNotifications) {
          return const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          );
        }

        final count = auth.unreadNotificationsCount;
        if (count == 0) return Container();

        return Positioned(
          right: 8,
          top: 8,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
            ),
            constraints: const BoxConstraints(
              minWidth: 20,
              minHeight: 20,
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildAppBarActions() {
    return [
      Stack(
        children: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
              if (mounted) {
                await _refreshNotifications();
              }
            },
          ),
          _buildNotificationBadge(),
        ],
      ),
      IconButton(
        icon: const Icon(Icons.refresh, color: Colors.white),
        onPressed: _refreshNotifications,
      ),
      IconButton(
        icon: const Icon(Icons.help_outline, color: Colors.white),
        onPressed: _showHelpDialog,
      ),
      IconButton(
        icon: const Icon(Icons.logout, color: Colors.white),
        onPressed: () {
          _notificationTimer?.cancel();
          context.read<AuthProvider>().logout();
        },
      ),
    ];
  }

  /* List<BottomNavigationBarItem> _buildNavigationItems() {
    return [
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.event),
        label: 'Events',
      ),
    ];
  } */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 21, 0, 141),
        title: const Text(
          'Student Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        actions: _buildAppBarActions(),
      ),
      body: Container(
        color: Colors.white,
        child: _pages[_selectedIndex],
      ),
      /* bottomNavigationBar: BottomNavigationBar(
        items: _buildNavigationItems(),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        backgroundColor: const Color.fromARGB(255, 21, 0, 141),
        type: BottomNavigationBarType.fixed,
      ), */
    );
  }
}
