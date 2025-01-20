import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../models/colleges.dart';
import '../../screens/Add/add_college_form.dart';

class CollegeListPage extends StatefulWidget {
  const CollegeListPage({Key? key}) : super(key: key);

  @override
  _CollegeListPageState createState() => _CollegeListPageState();
}

class _CollegeListPageState extends State<CollegeListPage> {
  int _selectedIndex = 0;
  List<Colleges> _colleges = [];
  List<Colleges> _filteredColleges = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchColleges();
    _searchController.addListener(_filterColleges);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterColleges() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredColleges = _colleges.where((college) {
        return college.college.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _fetchColleges() async {
    try {
      final colleges = await context.read<AuthProvider>().fetchColleges();
      setState(() {
        _colleges = colleges;
        _filteredColleges = colleges;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching colleges: $e')),
      );
    }
  }

  void _updateCollege(Colleges college) {
    TextEditingController _collegeController =
        TextEditingController(text: college.college);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update College Name'),
          content: TextField(
            controller: _collegeController,
            decoration:
                const InputDecoration(hintText: 'Enter new college name'),
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
                final newName = _collegeController.text;
                if (newName.isNotEmpty) {
                  try {
                    await context
                        .read<AuthProvider>()
                        .updateCollegeName(college.id, newName);
                    _fetchColleges();
                    Navigator.of(context).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('College name updated!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Error updating college name: $e')),
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

  void _deleteCollege(Colleges college) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete College'),
          content: const Text('Are you sure you want to delete this college?'),
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
                  await context.read<AuthProvider>().deleteCollege(college.id);
                  setState(() {
                    _colleges.remove(college);
                    _filterColleges(); // Update filtered list after deletion
                  });
                  Navigator.of(context).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('College deleted successfully!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting college: $e')),
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

  void _onAddCollegePressed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddCollegeForm(),
      ),
    ).then((_) => _fetchColleges());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 21, 0, 141),
        title: const Text(
          'College List',
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
                hintText: 'Search colleges...',
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
                : _filteredColleges.isEmpty
                    ? const Center(
                        child: Text('No colleges found',
                            style: TextStyle(fontSize: 16, color: Colors.grey)))
                    : ListView.builder(
                        itemCount: _filteredColleges.length,
                        itemBuilder: (context, index) {
                          final college = _filteredColleges[index];
                          return GestureDetector(
                            onLongPress: () {
                              Future.delayed(const Duration(seconds: 2), () {
                                _deleteCollege(college);
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
                                title: Text(college.college),
                                trailing:
                                    const Icon(Icons.edit, color: Colors.blue),
                                onTap: () {
                                  _updateCollege(college);
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
        onPressed: _onAddCollegePressed,
        child: const Icon(Icons.add),
        tooltip: 'Add College',
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
