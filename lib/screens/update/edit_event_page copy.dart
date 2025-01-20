// edit_event_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../models/colleges.dart';
import '../../models/events.dart';

class EditEventPage extends StatefulWidget {
  final Events event;

  const EditEventPage({Key? key, required this.event}) : super(key: key);

  @override
  _EditEventPageState createState() => _EditEventPageState();
}

class _EditEventPageState extends State<EditEventPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _maxParticipantsController;

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late String _status;
  late List<int> _selectedColleges;
  List<Colleges> _colleges = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing event data
    _titleController = TextEditingController(text: widget.event.title);
    _descriptionController =
        TextEditingController(text: widget.event.description);
    _locationController = TextEditingController(text: widget.event.location);
    _maxParticipantsController =
        TextEditingController(text: widget.event.maxParticipants.toString());

    _selectedDate = widget.event.eventDate;
    _selectedTime = TimeOfDay.fromDateTime(
        DateTime.parse('2024-01-01 ${widget.event.eventTime}'));
    _status = widget.event.status;
    _selectedColleges = List<int>.from(widget.event.allowedView);

    _fetchColleges();
  }

  Future<void> _fetchColleges() async {
    try {
      final colleges = await Provider.of<AuthProvider>(context, listen: false)
          .fetchColleges();
      setState(() => _colleges = colleges);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching colleges: $e')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2025),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final eventData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'event_date': _selectedDate.toString().split(' ')[0],
        'event_time':
            '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
        'location': _locationController.text,
        'max_participants': int.parse(_maxParticipantsController.text),
        'status': _status,
        'allowedView': _selectedColleges,
      };

      await Provider.of<AuthProvider>(context, listen: false)
          .updateEvent(widget.event.id, eventData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event updated successfully')),
      );
      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating event: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteEvent() async {
    try {
      setState(() => _isLoading = true);

      // Check if the widget is still mounted before proceeding
      if (!mounted) return;

      await Provider.of<AuthProvider>(context, listen: false)
          .deleteEvent(widget.event.id);

      // Check if mounted again before showing SnackBar and navigating
      if (!mounted) return;

      // Return to calendar page with refresh flag
      Navigator.of(context).pop(true);

      // Show success message on the calendar page instead
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event deleted successfully')),
      );
    } catch (e) {
      // Only show error if widget is still mounted
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting event: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Event'),
        backgroundColor: const Color.fromARGB(255, 21, 0, 141),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext dialogContext) => AlertDialog(
                  title: const Text('Delete Event'),
                  content:
                      const Text('Are you sure you want to delete this event?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext)
                          .pop(), // Close dialog only
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop(); // Close dialog first
                        _deleteEvent(); // Then execute delete
                      },
                      child: const Text('Delete',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Description is required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Location is required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _maxParticipantsController,
                      decoration: const InputDecoration(
                        labelText: 'Maximum Participants',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Maximum participants is required';
                        }
                        if (int.tryParse(value!) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Event Date'),
                      subtitle: Text(_selectedDate.toString().split(' ')[0]),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDate(context),
                    ),
                    ListTile(
                      title: const Text('Event Time'),
                      subtitle: Text(_selectedTime.format(context)),
                      trailing: const Icon(Icons.access_time),
                      onTap: () => _selectTime(context),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: ['draft', 'published', 'cancelled', 'completed']
                          .map((status) => DropdownMenuItem(
                                value: status,
                                child: Text(status.toUpperCase()),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() => _status = value!);
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Select Colleges:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Column(
                        children: _colleges
                            .map((college) => CheckboxListTile(
                                  title: Text(college.college),
                                  value: _selectedColleges.contains(college.id),
                                  onChanged: (bool? value) {
                                    setState(() {
                                      if (value ?? false) {
                                        _selectedColleges.add(college.id);
                                      } else {
                                        _selectedColleges.remove(college.id);
                                      }
                                    });
                                  },
                                ))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 21, 0, 141),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: _submitForm,
                        child: const Text(
                          'Update Event',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _maxParticipantsController.dispose();
    super.dispose();
  }
}
