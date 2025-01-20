import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../models/students.dart';
import '../../models/colleges.dart';
import '../../models/departments.dart';
import '../../models/user.dart';
import '../../screens/Add/add_student_form.dart';

class StudentListPage extends StatefulWidget {
  const StudentListPage({Key? key}) : super(key: key);

  @override
  _StudentListPageState createState() => _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage> {
  List<Students> _students = [];
  List<Students> _filteredStudents = [];
  List<Colleges> _colleges = [];
  List<Departments> _departments = [];
  bool _isLoading = true;
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _searchController.addListener(_filterStudents);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterStudents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredStudents = _students.where((student) {
        return student.fullname.toLowerCase().contains(query) ||
            student.user.email.toLowerCase().contains(query) ||
            student.college.college.toLowerCase().contains(query) ||
            student.department.description.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final futures = await Future.wait([
        authProvider.fetchStudents(),
        authProvider.fetchColleges(),
        authProvider.fetchDepartments(),
      ]);

      if (!mounted) return;

      setState(() {
        _students = futures[0] as List<Students>? ?? [];
        _filteredStudents = _students;
        _colleges = futures[1] as List<Colleges>? ?? [];
        _departments = futures[2] as List<Departments>? ?? [];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadStudents() async {
    try {
      final students = await context.read<AuthProvider>().fetchStudents();
      if (!mounted) return;
      setState(() {
        _students = students;
        _filterStudents();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching students: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /* Future<void> _onAddStudentPressed() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddStudentForm(),
      ),
    );

    if (result == true) {
      await _loadStudents();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Student added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } */

  void _onAddStudentPressed() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddStudentForm(),
      ),
    );

    if (result == true) {
      _loadStudents();
    }
  }

  void _deleteStudent(Students student) {
    // Store the AuthProvider reference before showing the dialog
    final authProvider = context.read<AuthProvider>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Student'),
        content: Text('Are you sure you want to delete ${student.fullname}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            onPressed: () async {
              try {
                // Close the confirmation dialog
                Navigator.of(dialogContext).pop();

                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (loadingContext) {
                    return WillPopScope(
                      onWillPop: () async => false,
                      child: const Center(
                        child: Card(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text('Deleting student...'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );

                // Perform delete operation using the stored provider reference
                await authProvider.deleteStudent(student.id);

                if (!mounted) return;

                // Close loading indicator
                Navigator.of(context).pop();

                // Refresh the student list
                await _loadStudents();

                if (!mounted) return;

                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Student deleted successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;

                // Close loading indicator if it's still showing
                Navigator.of(context).pop();

                // Show error message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting student: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _updateStudent(Students student) {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController(text: student.fullname);
    final _emailController = TextEditingController(text: student.user.email);
    final _passwordController = TextEditingController();
    int? selectedCollegeId = student.college.id;
    int? selectedDepartmentId = student.department.id;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Update Student'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Full Name Field
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Name is required';
                          }
                          if (value!.length < 2) {
                            return 'Name is too short';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Email is required';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value!)) {
                            return 'Invalid email format';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password Field (Optional)
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'New Password (Optional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                          helperText: 'Leave empty to keep current password',
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value?.isNotEmpty ?? false) {
                            if (value!.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // College Dropdown
                      DropdownButtonFormField<int>(
                        value: selectedCollegeId,
                        decoration: const InputDecoration(
                          labelText: 'College',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.school),
                        ),
                        items: _colleges.map((college) {
                          return DropdownMenuItem(
                            value: college.id,
                            child: Text(college.college),
                          );
                        }).toList(),
                        validator: (value) =>
                            value == null ? 'Please select a college' : null,
                        onChanged: (value) {
                          setState(() {
                            selectedCollegeId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Department Dropdown
                      DropdownButtonFormField<int>(
                        value: selectedDepartmentId,
                        decoration: const InputDecoration(
                          labelText: 'Department',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business),
                        ),
                        items: _departments.map((department) {
                          return DropdownMenuItem(
                            value: department.id,
                            child: Text(department.description),
                          );
                        }).toList(),
                        validator: (value) =>
                            value == null ? 'Please select a department' : null,
                        onChanged: (value) {
                          setState(() {
                            selectedDepartmentId = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                // Cancel Button
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey,
                  ),
                ),

                // Update Button
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      try {
                        // Show loading indicator
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            return Center(
                              child: Card(
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  child: const Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(),
                                      SizedBox(height: 16),
                                      Text('Updating student...'),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );

                        // Perform the update
                        await context.read<AuthProvider>().updateStudent(
                              student.id,
                              _nameController.text,
                              _emailController.text,
                              selectedCollegeId!,
                              selectedDepartmentId!,
                              _passwordController.text.isNotEmpty
                                  ? _passwordController.text
                                  : null,
                            );

                        if (!mounted) return;

                        // Close loading indicator and update dialog
                        Navigator.of(context)
                          ..pop() // Close loading
                          ..pop(); // Close update dialog

                        // Refresh the student list
                        await _loadStudents();

                        // Show success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Student updated successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;

                        // Close loading indicator
                        Navigator.of(context).pop();

                        // Show error message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('Error updating student: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 21, 0, 141),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 21, 0, 141),
        title: const Text(
          'Student List',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notifications clicked!')),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search students...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterStudents();
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredStudents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off,
                                size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'No students found'
                                  : 'No matching students found',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredStudents.length,
                        itemBuilder: (context, index) {
                          final student = _filteredStudents[index];
                          return GestureDetector(
                            onLongPress: () => _deleteStudent(student),
                            child: Card(
                              margin: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 16,
                              ),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                title: Text(student.fullname),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Email: ${student.user.email}'),
                                    Text('College: ${student.college.college}'),
                                    Text(
                                        'Department: ${student.department.description}'),
                                  ],
                                ),
                                trailing:
                                    const Icon(Icons.edit, color: Colors.blue),
                                onTap: () => _updateStudent(student),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onAddStudentPressed,
        backgroundColor: const Color.fromARGB(255, 21, 0, 141),
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Add Student',
      ),
      /* bottomNavigationBar: BottomNavigationBar(
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
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        backgroundColor: const Color.fromARGB(255, 21, 0, 141),
        type: BottomNavigationBarType.fixed,
      ), */
    );
  }
}
