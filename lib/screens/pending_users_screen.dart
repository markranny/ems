import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
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
    _loadPendingUsers();
  }

  void _loadPendingUsers() {
    _pendingUsersFuture = Provider.of<AuthProvider>(context, listen: false)
        .fetchPendingAdminRequests();
  }

  Future<void> _showConfirmationDialog({
    required String title,
    required String message,
    required VoidCallback onConfirm,
    required Color confirmButtonColor,
    required String confirmButtonText,
  }) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: confirmButtonColor,
              ),
              child: Text(confirmButtonText),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      onConfirm();
    }
  }

  // In _PendingUsersScreenState class

  Future<void> _handleApproval(User user) async {
    try {
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Confirm Approval'),
            content: Text('Are you sure you want to approve ${user.username}?'),
            actions: [
              TextButton(
                child: Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: Text('Approve'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      ).then((confirmed) async {
        if (confirmed == true) {
          // Show loading indicator
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return Center(child: CircularProgressIndicator());
            },
          );

          await Provider.of<AuthProvider>(context, listen: false)
              .approveAdminRequest(user.id);

          // Hide loading indicator
          Navigator.of(context).pop();

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${user.username} approved successfully'),
              backgroundColor: Colors.green,
            ),
          );

          // Refresh the list
          setState(() {
            _loadPendingUsers();
          });
        }
      });
    } catch (e) {
      // Hide loading indicator if still showing
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleRejection(User user) async {
    try {
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Confirm Rejection'),
            content: Text('Are you sure you want to reject ${user.username}?'),
            actions: [
              TextButton(
                child: Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: Text('Reject'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      ).then((confirmed) async {
        if (confirmed == true) {
          // Show loading indicator
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return Center(child: CircularProgressIndicator());
            },
          );

          await Provider.of<AuthProvider>(context, listen: false)
              .rejectAdminRequest(user.id);

          // Hide loading indicator
          Navigator.of(context).pop();

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${user.username} rejected successfully'),
              backgroundColor: Colors.orange,
            ),
          );

          // Refresh the list
          setState(() {
            _loadPendingUsers();
          });
        }
      });
    } catch (e) {
      // Hide loading indicator if still showing
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Users'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
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
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _loadPendingUsers();
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: SizedBox(
                width: 350,
                height: 350,
                child: Lottie.asset(
                  'assets/animations/waiting.json',
                  fit: BoxFit.contain,
                  repeat: true,
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final user = snapshot.data![index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(
                    user.username,
                    style: const TextStyle(fontWeight: FontWeight.bold),
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
                        icon:
                            const Icon(Icons.check_circle, color: Colors.green),
                        onPressed: () => _handleApproval(user),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () => _handleRejection(user),
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
