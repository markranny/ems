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

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({Key? key}) : super(key: key);

  @override
  _SuperAdminDashboardState createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const DashboardView(), // Replace the placeholder Text widget
      Center(
        child: Text('Approvals Page',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black)),
      ),
      SizedBox.shrink(),
      EventsCalendarPage(canManageEvents: true),
    ];
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
                'Overview of all system activities and statistics.',
              ),
              _buildHelpItem(
                Icons.pending_actions,
                'Approvals',
                'Manage pending requests and approvals.',
              ),
              _buildHelpItem(
                Icons.admin_panel_settings,
                'Management',
                'Access to all user and system management features.',
              ),
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

  List<Widget> _buildAppBarActions() {
    // Common actions that appear in all sections
    List<Widget> commonActions = [
      Stack(
        children: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
          ),
          Consumer<AuthProvider>(
            builder: (context, auth, child) {
              if (auth.unreadNotificationsCount == 0) return Container();
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
                    '${auth.unreadNotificationsCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ];

    // Additional actions for Events page
    if (_selectedIndex == 3) {
      commonActions.addAll([
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: () {
            context.read<AuthProvider>().fetchNotifications();
            // Add event refresh functionality here
          },
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) {
            switch (value) {
              case 'filter':
                // Add filter functionality
                break;
              case 'settings':
                // Add settings navigation
                break;
              case 'help':
                _showHelpDialog();
                break;
            }
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(
              value: 'filter',
              child: Row(
                children: [
                  Icon(Icons.filter_list, size: 20),
                  SizedBox(width: 8),
                  Text('Filter Events'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings, size: 20),
                  SizedBox(width: 8),
                  Text('Settings'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'help',
              child: Row(
                children: [
                  Icon(Icons.help_outline, size: 20),
                  SizedBox(width: 8),
                  Text('Help'),
                ],
              ),
            ),
          ],
        ),
      ]);
    }

    // Add logout button as the last action
    commonActions.add(
      IconButton(
        icon: const Icon(Icons.logout, color: Colors.white),
        onPressed: () => context.read<AuthProvider>().logout(),
      ),
    );

    return commonActions;
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Super Admin Dashboard';
      case 1:
        return 'Approvals';
      case 2:
        return 'Manage';
      case 3:
        return 'Events Calendar';
      default:
        return 'Super Admin Dashboard';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Update manage page when selected
    if (_selectedIndex == 2) {
      _pages[2] = GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16.0),
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        children: [
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
          _buildManageCard(Icons.person_add, "Attendees", onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => AddStudentForm()));
          }),
        ],
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 21, 0, 141),
        title: Text(
          _getAppBarTitle(),
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
        ),
        actions: _buildAppBarActions(),
      ),
      body: Container(
        color: Colors.white,
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.pending_actions), label: 'Approvals'),
          BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings), label: 'Manage'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Events'),
        ],
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
