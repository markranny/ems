import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../models/user.dart';

class AdminApprovalPage extends StatefulWidget {
  const AdminApprovalPage({Key? key}) : super(key: key);

  @override
  _AdminApprovalPageState createState() => _AdminApprovalPageState();
}

class _AdminApprovalPageState extends State<AdminApprovalPage> {
  List<User> _pendingRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingRequests();
  }

  Future<void> _loadPendingRequests() async {
    try {
      final requests =
          await context.read<AuthProvider>().fetchPendingAdminRequests();
      setState(() {
        _pendingRequests = requests;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading requests: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleApprove(User user) async {
    try {
      await context.read<AuthProvider>().approveAdminRequest(user.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin request approved')),
      );
      _loadPendingRequests();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving request: $e')),
      );
    }
  }

  Future<void> _handleReject(User user) async {
    try {
      await context.read<AuthProvider>().rejectAdminRequest(user.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin request rejected')),
      );
      _loadPendingRequests();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rejecting request: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pendingRequests.isEmpty) {
      return const Center(
        child: Text('No pending admin requests'),
      );
    }

    return ListView.builder(
      itemCount: _pendingRequests.length,
      itemBuilder: (context, index) {
        final user = _pendingRequests[index];
        return Card(
          margin: const EdgeInsets.all(8.0),
          child: ListTile(
            title: Text(user.username),
            subtitle: Text(user.email),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () => _handleApprove(user),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => _handleReject(user),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
