import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_provider.dart';
import '../../../widgets/_DashboardCard.dart'; // The import remains the same

class SuperAdminDashboard extends StatelessWidget {
  const SuperAdminDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin Dashboard'),
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
            // Use the public class
            title: 'Manage Admins',
            icon: Icons.admin_panel_settings,
            onTap: () {
              // Navigate to admin management
            },
          ),
          DashboardCard(
            title: 'Pending Approvals',
            icon: Icons.pending_actions,
            onTap: () {
              // Navigate to approval management
            },
          ),
          DashboardCard(
            title: 'All Events',
            icon: Icons.event,
            onTap: () {
              // Navigate to events list
            },
          ),
          DashboardCard(
            title: 'System Settings',
            icon: Icons.settings,
            onTap: () {
              // Navigate to settings
            },
          ),
        ],
      ),
    );
  }
}
