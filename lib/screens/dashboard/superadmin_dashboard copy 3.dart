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
      Center(
          child: Text('Dashboard Page',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black))),
      Center(
          child: Text('Approvals Page',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black))),
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
          _buildManageCard(Icons.people, "Faculty List List", onTap: () {
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
        title: const Text('Super Admin Dashboard',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: const Text('Notifications clicked!')),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
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
