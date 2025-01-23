import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:emsv7/models/user.dart'; // Add User model import

class PendingStudentsScreen extends StatefulWidget {
  const PendingStudentsScreen({Key? key}) : super(key: key);

  @override
  _PendingStudentsScreenState createState() => _PendingStudentsScreenState();
}

class _PendingStudentsScreenState extends State<PendingStudentsScreen> {
  List<User> _pendingStudents = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPendingStudents();
  }

  Future<void> _fetchPendingStudents() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await http.get(
        Uri.parse('https://eljincorp.com/api/pendingstudents'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          final List<User> allUsers = (data['data'] as List)
              .map((user) => User.fromJson(user))
              .toList();

          // Filter for inactive students only
          _pendingStudents = allUsers
              .where(
                  (user) => user.role == 'student' && user.status == 'inactive')
              .toList();

          setState(() {
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load pending students');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _approveStudent(User student) async {
    try {
      final response = await http.put(
        Uri.parse(
            'https://eljincorp.com/api/pendingstudents/${student.id}/status'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({'status': 'active'}),
      );

      // Add debug print
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        await _fetchPendingStudents(); // Add await here
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student approved successfully')),
        );
      } else {
        // Parse error message from response if available
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to approve student');
      }
    } catch (e) {
      print('Error approving student: $e'); // Add debug print
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 21, 0, 141),
        title: const Text(
          'Pending Students',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchPendingStudents,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _pendingStudents.isEmpty
                  ? const Center(child: Text('No pending students found'))
                  : ListView.builder(
                      itemCount: _pendingStudents.length,
                      itemBuilder: (context, index) {
                        final student = _pendingStudents[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.grey[200],
                              child: const Icon(Icons.person),
                            ),
                            title: Text(
                              student.student?.fullname ?? 'N/A',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Email: ${student.email}'),
                                if (student.student?.college != null)
                                  Text(
                                      'College: ${student.student!.college.college}'),
                                if (student.student?.department != null)
                                  Text(
                                      'Department: ${student.student!.department.description}'),
                              ],
                            ),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              onPressed: () => _approveStudent(student),
                              child: const Text(
                                'Approve',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
