import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../models/departments.dart';
import '../screens/Add/add_department_form.dart';

class DepartmentListPage extends StatefulWidget {
  const DepartmentListPage({Key? key}) : super(key: key);

  @override
  _DepartmentListPageState createState() => _DepartmentListPageState();
}

class _DepartmentListPageState extends State<DepartmentListPage> {
  int _selectedIndex = 0;
  List<Departments> _departments = [];
  List<Departments> _filteredDepartments = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
    _searchController.addListener(_filterDepartments);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterDepartments() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredDepartments = _departments.where((department) {
        return department.description.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _fetchDepartments() async {
    try {
      final departments = await context.read<AuthProvider>().fetchDepartments();
      setState(() {
        _departments = departments;
        _filteredDepartments = departments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching departments: $e')),
      );
    }
  }

  void _updateDescription(Departments department) {
    TextEditingController _descriptionController =
        TextEditingController(text: department.description);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Department Description'),
          content: TextField(
            controller: _descriptionController,
            decoration:
                const InputDecoration(hintText: 'Enter new description'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final newDescription = _descriptionController.text;
                if (newDescription.isNotEmpty) {
                  try {
                    await context
                        .read<AuthProvider>()
                        .updateDepartmentDescription(
                            department.id, newDescription);
                    _fetchDepartments(); // Refresh the list
                    Navigator.of(context).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Department description updated!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating description: $e')),
                    );
                  }
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _deleteDepartment(Departments department) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Department'),
          content:
              const Text('Are you sure you want to delete this department?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await context
                      .read<AuthProvider>()
                      .deleteDepartment(department.id);
                  setState(() {
                    _departments.remove(department);
                    _filterDepartments(); // Update filtered list after deletion
                  });
                  Navigator.of(context).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Department deleted successfully!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting department: $e')),
                  );
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _onAddEventPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddDepartmentForm(),
      ),
    ).then(
        (_) => _fetchDepartments()); // Refresh list after adding new department
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 21, 0, 141),
        title: const Text(
          'Department List',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
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
                hintText: 'Search departments...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredDepartments.isEmpty
                    ? const Center(
                        child: Text('No departments found',
                            style: TextStyle(fontSize: 16, color: Colors.grey)))
                    : ListView.builder(
                        itemCount: _filteredDepartments.length,
                        itemBuilder: (context, index) {
                          final department = _filteredDepartments[index];
                          return GestureDetector(
                            onLongPress: () {
                              Future.delayed(const Duration(seconds: 2), () {
                                _deleteDepartment(department);
                              });
                            },
                            child: Card(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 16),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                title: Text(department.description),
                                trailing:
                                    const Icon(Icons.edit, color: Colors.blue),
                                onTap: () {
                                  _updateDescription(department);
                                },
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onAddEventPressed,
        child: const Icon(Icons.add),
        tooltip: 'Add Department',
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
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        backgroundColor: const Color.fromARGB(255, 21, 0, 141),
        type: BottomNavigationBarType.fixed,
      ), */
    );
  }
}
