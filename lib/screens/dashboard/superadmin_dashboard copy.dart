import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';

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
    Center(
        child: Text('Manage Page',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
    Center(
        child: Text('Events Page',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Notifications clicked!'),
                  backgroundColor: Theme.of(context).primaryColor,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFFF5F5F5), // Soft light grey background.
        padding: const EdgeInsets.all(16.0),
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pending_actions),
            label: 'Approvals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings),
            label: 'Manage',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Events',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.white,
        unselectedItemColor: const Color(0xFFB0BEC5), // Muted grey.
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        backgroundColor:
            const Color.fromARGB(255, 21, 0, 141), // Darker navy background.
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: MaterialApp(
        theme: ThemeData(
          primaryColor:
              const Color.fromARGB(255, 21, 0, 141), // Modern navy tone.
          appBarTheme: const AppBarTheme(
            color: Color.fromARGB(255, 21, 0, 141),
            elevation: 2, // Subtle shadow under app bar.
          ),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(
              color: Color.fromARGB(255, 21, 0, 141), // Elegant blue-grey tone.
              fontSize: 16,
            ),
            titleLarge: TextStyle(
              // Use titleLarge instead of headline6.
              color: Color(0xFF263238),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        home: const SuperAdminDashboard(),
      ),
    ),
  );
}
