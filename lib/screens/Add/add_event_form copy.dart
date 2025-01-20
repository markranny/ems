// add_event_form.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/auth_provider.dart';
import '../../models/colleges.dart';
import 'package:path/path.dart' as path;
import 'package:http_parser/http_parser.dart';
import 'package:intl/intl.dart';

class AddEventForm extends StatefulWidget {
  final dynamic events;
  const AddEventForm({Key? key, this.events}) : super(key: key);

  @override
  _AddEventFormState createState() => _AddEventFormState();
}

class _AddEventFormState extends State<AddEventForm> {
  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();
  final maxParticipantsController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  List<int> selectedColleges = [];
  String status = 'draft';
  List<Colleges> _colleges = [];
  bool _isLoading = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchColleges();
    _initializeFormData();
  }

  void _initializeFormData() {
    if (widget.events != null) {
      titleController.text = widget.events.title;
      descriptionController.text = widget.events.description;
      locationController.text = widget.events.location;
      maxParticipantsController.text = widget.events.maxParticipants.toString();
      selectedDate = widget.events.eventDate;
      selectedTime = TimeOfDay.fromDateTime(
          DateFormat('HH:mm').parse(widget.events.eventTime));
      selectedColleges = List<int>.from(widget.events.allowedView);
      status = widget.events.status;
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    maxParticipantsController.dispose();
    super.dispose();
  }

  Future<void> _fetchColleges() async {
    if (!mounted) return;

    try {
      final colleges = await Provider.of<AuthProvider>(context, listen: false)
          .fetchColleges();
      if (mounted) {
        setState(() => _colleges = colleges);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching colleges: $e')),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2025),
    );
    if (picked != null && mounted) {
      setState(() => selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null && mounted) {
      setState(() => selectedTime = picked);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );

      if (pickedFile != null && mounted) {
        setState(() => _imageFile = File(pickedFile.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  bool _validateForm() {
    if (selectedColleges.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one college')),
      );
      return false;
    }

    if (!_formKey.currentState!.validate()) {
      return false;
    }

    // Validate date is not in the past
    if (selectedDate.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event date cannot be in the past')),
      );
      return false;
    }

    return true;
  }

  Future<void> _submitEvent() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) throw Exception('Not authenticated');

      var uri = Uri.parse(
          '${authProvider.baseUrl}/api/events${widget.events != null ? '/${widget.events.id}' : ''}');

      var request = http.MultipartRequest(
        widget.events != null ? 'PUT' : 'POST',
        uri,
      );

      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      // Format time string properly
      String formattedTime =
          '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';

      // Add all fields
      request.fields.addAll({
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'event_date': DateFormat('yyyy-MM-dd').format(selectedDate),
        'event_time': formattedTime,
        'location': locationController.text.trim(),
        'max_participants': maxParticipantsController.text,
        'status': status,
        'allowedView': jsonEncode(selectedColleges),
      });

      // Add image if selected
      if (_imageFile != null) {
        var stream = http.ByteStream(_imageFile!.openRead());
        var length = await _imageFile!.length();

        var multipartFile = http.MultipartFile(
          'image',
          stream,
          length,
          filename: path.basename(_imageFile!.path),
          contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(multipartFile);
      }

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.events == null
                  ? 'Event created successfully'
                  : 'Event updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(jsonResponse['message'] ?? 'Failed to save event');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
        title: Text(
          widget.events == null ? 'Add Event' : 'Edit Event',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Title is required';
                  }
                  if (value!.length > 255) {
                    return 'Title must be less than 255 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (_imageFile != null || widget.events?.eventImagePath != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        if (_imageFile != null)
                          Stack(
                            alignment: Alignment.topRight,
                            children: [
                              Image.file(
                                _imageFile!,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.close, color: Colors.red),
                                onPressed: () =>
                                    setState(() => _imageFile = null),
                              ),
                            ],
                          )
                        else if (widget.events?.eventImagePath != null)
                          Image.network(
                            widget.events!.eventImagePath!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                      ],
                    ),
                  ),
                ),
              TextButton.icon(
                icon: const Icon(Icons.image),
                label: Text(_imageFile == null ? 'Add Image' : 'Change Image'),
                onPressed: _pickImage,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Description is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Location is required';
                  }
                  if (value!.length > 255) {
                    return 'Location must be less than 255 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: maxParticipantsController,
                decoration: const InputDecoration(
                  labelText: 'Maximum Participants',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.group),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Maximum participants is required';
                  }
                  final number = int.tryParse(value!);
                  if (number == null || number < 1) {
                    return 'Please enter a valid number greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    'Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _selectTime,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.access_time),
                  ),
                  child: Text(
                    'Time: ${selectedTime.format(context)}',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flag),
                ),
                items: ['draft', 'published', 'cancelled', 'completed']
                    .map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.toUpperCase()),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => status = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              const Text('Allowed Colleges:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ...(_colleges.map((college) => CheckboxListTile(
                    title: Text(college.college),
                    value: selectedColleges.contains(college.id),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value ?? false) {
                          selectedColleges.add(college.id);
                        } else {
                          selectedColleges.remove(college.id);
                        }
                      });
                    },
                  ))),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 21, 0, 141),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _isLoading ? null : _submitEvent,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        widget.events == null ? 'Create Event' : 'Update Event',
                        style:
                            const TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
