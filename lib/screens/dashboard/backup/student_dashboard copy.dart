import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_provider.dart';
import '../../../widgets/_DashboardCard.dart'; // Ensure this file is imported correctly

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
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
            // Use the public name here
            title: 'Available Events',
            icon: Icons.event_available,
            onTap: () {
              // Navigate to events list
            },
          ),
          DashboardCard(
            title: 'My Registrations',
            icon: Icons.calendar_today,
            onTap: () {
              // Navigate to registered events
            },
          ),
          DashboardCard(
            title: 'Event History',
            icon: Icons.history,
            onTap: () {
              // Navigate to event history
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
