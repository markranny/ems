import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../screens/student_list_page.dart';
import '../../screens/location_list_page.dart';
import '../../screens/survey_list_page.dart';
import '../../screens/events_calendar_page.dart';
import '../../screens/notificationscreen.dart';
import '../../screens/dashboard_view.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;
  Timer? _notificationTimer;

  @override
  void initState() {
    super.initState();
    _pages = [
      const DashboardView(),
      SizedBox.shrink(),
      EventsCalendarPage(canManageEvents: true),
      const NotificationsScreen(),
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
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildManageCards() {
    return [
      _buildManageCard(Icons.assessment, "Survey List", onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SurveyListPage()),
        );
      }),
      _buildManageCard(Icons.people, "Student List", onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => StudentListPage()),
        );
      }),
      _buildManageCard(Icons.business, "Location List", onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LocationListPage()),
        );
      }),
    ];
  }

  List<BottomNavigationBarItem> _buildNavigationItems() {
    return [
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.admin_panel_settings),
        label: 'Manage',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.event),
        label: 'Events',
      ),
      BottomNavigationBarItem(
        icon: Stack(
          children: [
            const Icon(Icons.notifications),
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final unreadCount = authProvider.unreadNotificationsCount;
                if (unreadCount == 0) return const SizedBox.shrink();
                return Positioned(
                  right: -5,
                  top: -5,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 15,
                      minHeight: 15,
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        label: 'Notifications',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.logout),
        label: 'Logout',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (_selectedIndex == 1) {
      _pages[1] = GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16.0),
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        children: _buildManageCards(),
      );
    }

    void handleNavigation(int index) {
      if (index == _buildNavigationItems().length - 1) {
        // Logout button index
        _notificationTimer?.cancel();
        authProvider.logout();
      } else {
        setState(() {
          _selectedIndex = index;
        });
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize:
            Size.fromHeight(MediaQuery.of(context).size.height * 0.1),
        child: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          flexibleSpace: ClipRRect(
            child: Image.asset(
              'images/claveria.png',
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
        items: _buildNavigationItems(),
        currentIndex: _selectedIndex,
        onTap: handleNavigation,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        backgroundColor: const Color.fromARGB(255, 21, 0, 141),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
