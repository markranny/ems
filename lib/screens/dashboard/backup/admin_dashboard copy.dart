import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_provider.dart';
import '../../../widgets/_DashboardCard.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          DashboardCard(
            // Use the public class name
            title: 'Create Event',
            icon: Icons.add_circle,
            onTap: () {
              // Navigate to event creation
            },
          ),
          DashboardCard(
            title: 'My Events',
            icon: Icons.event_available,
            onTap: () {
              // Navigate to events management
            },
          ),
          DashboardCard(
            title: 'Event Reports',
            icon: Icons.analytics,
            onTap: () {
              // Navigate to reports
            },
          ),
          DashboardCard(
            title: 'Profile',
            icon: Icons.person,
            onTap: () {
              // Navigate to profile
            },
          ),
        ],
      ),
    );
  }
}
