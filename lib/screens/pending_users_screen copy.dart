import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../models/user.dart';

class PendingUsersScreen extends StatefulWidget {
  @override
  _PendingUsersScreenState createState() => _PendingUsersScreenState();
}

class _PendingUsersScreenState extends State<PendingUsersScreen> {
  late Future<List<User>> _pendingUsersFuture;

  @override
  void initState() {
    super.initState();
    // Initialize the future in initState
    _pendingUsersFuture = Future(() async {
      // Delay the provider access until after build
      await Future.microtask(() {});
      return Provider.of<AuthProvider>(context, listen: false)
          .fetchPendingAdminRequests();
    });
  }

  void _loadPendingUsers() {
    setState(() {
      _pendingUsersFuture = Provider.of<AuthProvider>(context, listen: false)
          .fetchPendingAdminRequests();
    });
  }

  Future<void> _handleApproval(User user) async {
    try {
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Confirm Approval'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Are you sure you want to approve:'),
                SizedBox(height: 8),
                Text('Username: ${user.username}',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Email: ${user.email}'),
                Text('Role: ${user.role}'),
                if (user.roleDescription != null)
                  Text('Description: ${user.roleDescription}'),
              ],
            ),
            actions: [
              TextButton(
                child: Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              ElevatedButton(
                child: Text('Approve'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      );

      if (confirm == true) {
        await Provider.of<AuthProvider>(context, listen: false)
            .approveAdminRequest(user.id);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.username} approved successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Reload the list
        setState(() {
          _loadPendingUsers();
        });
      }
    } catch (e) {
      if (!mounted) return;

      // Show error in a dialog for better visibility
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text(e.toString().replaceAll('Exception: ', '')),
            actions: [
              TextButton(
                child: Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _handleRejection(User user) async {
    try {
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Confirm Rejection'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Are you sure you want to reject:'),
                SizedBox(height: 8),
                Text('Username: ${user.username}',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Email: ${user.email}'),
                Text('Role: ${user.role}'),
                if (user.roleDescription != null)
                  Text('Description: ${user.roleDescription}'),
              ],
            ),
            actions: [
              TextButton(
                child: Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text('Reject'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      );

      if (confirm == true) {
        await Provider.of<AuthProvider>(context, listen: false)
            .rejectAdminRequest(user.id);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.username} rejected successfully'),
            backgroundColor: Colors.orange,
          ),
        );

        // Reload the list
        setState(() {
          _loadPendingUsers();
        });
      }
    } catch (e) {
      if (!mounted) return;

      // Show error in a dialog for better visibility
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text(e.toString().replaceAll('Exception: ', '')),
            actions: [
              TextButton(
                child: Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pending Users'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _loadPendingUsers();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<User>>(
        future: _pendingUsersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${snapshot.error}'),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _loadPendingUsers();
                      });
                    },
                    icon: Icon(Icons.refresh),
                    label: Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text('No pending users found'),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final user = snapshot.data![index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(
                    user.username,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Email: ${user.email}'),
                      Text('Role: ${user.role}'),
                      Text('Requested: ${user.createdAt}'),
                      if (user.roleDescription != null)
                        Text('Description: ${user.roleDescription}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.check_circle, color: Colors.green),
                        onPressed: () => _handleApproval(user),
                        tooltip: 'Approve User',
                      ),
                      IconButton(
                        icon: Icon(Icons.cancel, color: Colors.red),
                        onPressed: () => _handleRejection(user),
                        tooltip: 'Reject User',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
