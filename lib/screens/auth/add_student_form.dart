import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Colleges {
  final int id;
  final String college;

  Colleges({required this.id, required this.college});

  factory Colleges.fromJson(Map<String, dynamic> json) {
    return Colleges(
      id: json['id'],
      college: json['college'],
    );
  }
}

class Departments {
  final int id;
  final String description;

  Departments({required this.id, required this.description});

  factory Departments.fromJson(Map<String, dynamic> json) {
    return Departments(
      id: json['id'],
      description: json['description'],
    );
  }
}

class AddStudentForm extends StatefulWidget {
  const AddStudentForm({Key? key}) : super(key: key);

  @override
  _AddStudentFormState createState() => _AddStudentFormState();
}

class _AddStudentFormState extends State<AddStudentForm> {
  final _formKey = GlobalKey<FormState>();
  String _fullName = '';
  String _email = '';
  int? _collegeId;
  int? _departmentId;
  bool _isLoading = true;

  List<Colleges> _colleges = [];
  List<Departments> _departments = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      final collegesResponse = await http.get(
        Uri.parse('https://eljincorp.com/api/colleges'),
        headers: {'Accept': 'application/json'},
      );

      final departmentsResponse = await http.get(
        Uri.parse('https://eljincorp.com/api/departments'),
        headers: {'Accept': 'application/json'},
      );

      if (collegesResponse.statusCode == 200 &&
          departmentsResponse.statusCode == 200) {
        final collegesJson = json.decode(collegesResponse.body);
        final departmentsJson = json.decode(departmentsResponse.body);

        if (mounted) {
          setState(() {
            // Parse colleges (nested in 'data' field)
            if (collegesJson is Map && collegesJson['data'] != null) {
              _colleges = (collegesJson['data'] as List)
                  .map((data) => Colleges.fromJson(data))
                  .toList();
            }

            // Parse departments (direct array)
            if (departmentsJson is List) {
              _departments = departmentsJson
                  .map((data) => Departments.fromJson(data))
                  .toList();
            } else if (departmentsJson is Map &&
                departmentsJson['data'] != null) {
              // Fallback if departments also use 'data' wrapper
              _departments = (departmentsJson['data'] as List)
                  .map((data) => Departments.fromJson(data))
                  .toList();
            }

            print('Loaded colleges: ${_colleges.length}'); // Debug print
            print('Loaded departments: ${_departments.length}'); // Debug print

            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error in _loadData: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addStudent() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    try {
      setState(() => _isLoading = true);

      // Generate a username based on the email (before the @ symbol)
      final username = _email.split('@')[0].toLowerCase();

      // Create the request payload with the expected user data
      final payload = {
        'fullname': _fullName,
        'email': _email,
        'college_id': _collegeId,
        'department_id': _departmentId,
        'username': username, // Add username field
        'role': 'student', // Specify role explicitly
        'status': 'inactive'
      };

      print('Sending request with payload:');
      print(json.encode(payload));

      final response = await http.post(
        Uri.parse('https://eljincorp.com/api/students'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      print('Response status code: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        String errorMessage = 'Failed to add student';
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map) {
            // Extract the specific SQL error message if available
            if (errorData['error'] != null &&
                errorData['error'].toString().contains('SQLSTATE')) {
              errorMessage = 'Database error: Please check the data format';
            } else {
              errorMessage = errorData['message'] ??
                  errorData['error'] ??
                  errorData.toString();
            }
          }
        } catch (e) {
          errorMessage = 'Server error: ${response.statusCode}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error in _addStudent: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error adding student: ${e.toString().replaceAll('Exception:', '')}',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Dismiss',
            onPressed: () {},
            textColor: Colors.white,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 21, 0, 141),
        title: const Text(
          'Add Student',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          border: const OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please enter the full name'
                            : null,
                        onSaved: (value) => _fullName = value!,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: const OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                        onSaved: (value) => _email = value!,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        decoration: InputDecoration(
                          labelText: 'College',
                          border: const OutlineInputBorder(),
                          prefixIcon: Icon(Icons.school),
                        ),
                        value: _collegeId,
                        items: _colleges.map((college) {
                          return DropdownMenuItem(
                            value: college.id,
                            child: Text(college.college),
                          );
                        }).toList(),
                        validator: (value) =>
                            value == null ? 'Please select a college' : null,
                        onChanged: (value) =>
                            setState(() => _collegeId = value),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        decoration: InputDecoration(
                          labelText: 'Department',
                          border: const OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business),
                        ),
                        value: _departmentId,
                        items: _departments.map((department) {
                          return DropdownMenuItem(
                            value: department.id,
                            child: Text(department.description),
                          );
                        }).toList(),
                        validator: (value) =>
                            value == null ? 'Please select a department' : null,
                        onChanged: (value) =>
                            setState(() => _departmentId = value),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 21, 0, 141),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _addStudent,
                        child: const Text(
                          'Add Student',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
