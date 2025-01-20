import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../Add/add_student_form.dart';
import '../../screens/student_list_page.dart';
import '../../screens/faculty_list_page.dart';
import '../../screens/events_calendar_page.dart';
import '../../screens/department_list_page.dart';
import '../../screens/college_list_page.dart';
import '../../screens/executive_list_page.dart';
import '../../screens/notificationscreen.dart';
import '../../screens/dashboard_view.dart';
import '../../screens/pending_users_screen.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({Key? key}) : super(key: key);

  @override
  _SuperAdminDashboardState createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;
  Timer? _notificationTimer; // Add this
  bool _isFirstLoad = true; // Add this

  @override
  void initState() {
    super.initState();
    _pages = [
      const DashboardView(),
      PendingUsersScreen(),
      /* Center(child: Text('Approvals Page')), */
      SizedBox.shrink(),
      EventsCalendarPage(canManageEvents: true),
    ];

    // Modify initialization of notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNotifications();
    });
  }

  void _initializeNotifications() async {
    if (!mounted) return;

    try {
      final authProvider = context.read<AuthProvider>();
      // Initial fetch with error handling
      await authProvider.fetchNotifications();

      // Set up periodic updates with error handling
      _notificationTimer?.cancel(); // Cancel any existing timer
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

  // Add dispose method
  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  // Add this method
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

  List<Widget> _buildManageCardsBasedOnRole(String userRole) {
    if (userRole == 'superadmin') {
      // Full access for superadmin
      return [
        _buildManageCard(Icons.people, "Student List", onTap: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => StudentListPage()));
        }),
        _buildManageCard(Icons.group_add, "Executive List", onTap: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => ExecutiveListPage()));
        }),
        _buildManageCard(Icons.people, "Faculty List", onTap: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => FacultyListPage()));
        }),
        _buildManageCard(Icons.account_balance, "College List", onTap: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => CollegeListPage()));
        }),
        _buildManageCard(Icons.business, "Department List", onTap: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => DepartmentListPage()));
        }),
        /* _buildManageCard(Icons.person_add, "Attendees", onTap: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => AddStudentForm()));
        }), */
      ];
    } else if (userRole == 'admin') {
      // Limited access for admin
      return [
        _buildManageCard(Icons.people, "Student List", onTap: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => StudentListPage()));
        }),
        /* _buildManageCard(Icons.person_add, "Attendees", onTap: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => AddStudentForm()));
        }), */
      ];
    } else {
      // Student role - only show Attendees
      return [
        _buildManageCard(Icons.person_add, "Attendees", onTap: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => AddStudentForm()));
        }),
      ];
    }
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
    final user = context.read<AuthProvider>().user;
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
                'Overview of all system activities and statistics.',
              ),
              if (user?.isSuperAdmin ?? false) ...[
                _buildHelpItem(
                  Icons.admin_panel_settings,
                  'Management',
                  'Access to all user and system management features.',
                ),
              ],
              _buildHelpItem(
                Icons.event,
                'Events',
                'Create and manage events, view calendar.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  /* Widget _buildNotificationBadge() {
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
  } */

  Widget _buildNotificationBadge() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final unreadCount = authProvider.unreadNotificationsCount;

        if (unreadCount == 0) return const SizedBox.shrink();

        return Positioned(
          right: 0,
          top: 0,
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
              '$unreadCount',
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
        icon: const Icon(Icons.logout, color: Colors.white),
        onPressed: () {
          _notificationTimer?.cancel();
          context.read<AuthProvider>().logout();
        },
      ),
    ];
  }

  List<BottomNavigationBarItem> _buildNavigationItems(String userRole) {
    List<BottomNavigationBarItem> items = [
      const BottomNavigationBarItem(
          icon: Icon(Icons.dashboard), label: 'Dashboard'),
      const BottomNavigationBarItem(
          icon: Icon(Icons.pending_actions), label: 'Approvals'),
    ];

    // Only show Manage tab for admin and superadmin
    if (userRole == 'superadmin' || userRole == 'admin') {
      items.add(const BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings), label: 'Manage'));
    }

    items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.event), label: 'Events'));

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userRole = authProvider.user?.role ?? '';

    if (_selectedIndex == 2 &&
        (userRole == 'superadmin' || userRole == 'admin')) {
      _pages[2] = GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16.0),
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        children: _buildManageCardsBasedOnRole(userRole),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      /* appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 21, 0, 141),
        title: Text(
          userRole == 'superadmin' ? 'Super Admin Dashboard' : 'Dashboard',
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
        ),
        actions: _buildAppBarActions(),
      ), */
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(
            MediaQuery.of(context).size.height * 0.2), // 20% of screen height
        child: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          flexibleSpace: ClipRRect(
            child: Image.asset(
              'images/claveria.jpg',
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
          centerTitle: true,
        ),
      ),
      body: Container(
        color: Colors.white,
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: _buildNavigationItems(userRole),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        backgroundColor: const Color.fromARGB(255, 21, 0, 141),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
