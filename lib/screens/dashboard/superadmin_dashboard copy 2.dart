import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../Add/add_student_form.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({Key? key}) : super(key: key);

  @override
  _SuperAdminDashboardState createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    Center(
        child: Text('Dashboard Page',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
    Center(
        child: Text('Approvals Page',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
    SizedBox.shrink(), // Placeholder for the Manage Page
    Center(
        child: Text('Events Page',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
  ];

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
            Icon(icon, size: 40, color: Colors.blue),
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
    if (_selectedIndex == 2) {
      _pages[2] = GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16.0),
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        children: [
          _buildManageCard(Icons.group_add, "Add Executives"),
          _buildManageCard(Icons.person_add, "Add Students", onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => AddStudentForm()));
          }),
          _buildManageCard(Icons.work, "Add Faculty"),
          _buildManageCard(Icons.account_balance, "Add College"),
          _buildManageCard(Icons.business, "Add Department"),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: const Text('Notifications clicked!')),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: _pages[_selectedIndex],
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
        backgroundColor:
            const Color.fromARGB(255, 21, 0, 141), // Custom background color
      ),
    );
  }
}
