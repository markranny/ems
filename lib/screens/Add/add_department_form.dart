import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';

class AddDepartmentForm extends StatefulWidget {
  @override
  _AddDepartmentFormState createState() => _AddDepartmentFormState();
}

class _AddDepartmentFormState extends State<AddDepartmentForm> {
  final _formKey = GlobalKey<FormState>();
  String _departmentName = '';
  int _selectedIndex = 0;
  bool _isLoading = false;

  Future<void> _addDepartment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    _formKey.currentState!.save();

    try {
      await Provider.of<AuthProvider>(context, listen: false)
          .addDepartment(_departmentName);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Department added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add department: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 21, 0, 141),
        title: const Text(
          'Add Department',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Notifications clicked!')),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Department Name',
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color.fromARGB(255, 21, 0, 141),
                      ),
                    ),
                    prefixIcon: Icon(Icons.business),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter the department name'
                      : null,
                  onSaved: (value) => _departmentName = value!,
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 21, 0, 141),
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isLoading ? null : _addDepartment,
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Add Department',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
      /* bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.pending_actions), label: 'Approvals'),
          BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings), label: 'Manage'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Events'),
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
