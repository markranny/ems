import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
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
  bool _isImageLoading = false;

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

      // Handle time parsing more safely
      try {
        selectedTime = TimeOfDay.fromDateTime(
            DateFormat('HH:mm').parse(widget.events.eventTime));
      } catch (e) {
        selectedTime = TimeOfDay.now();
        debugPrint('Error parsing event time: $e');
      }

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

    setState(() => _isLoading = true);
    try {
      final colleges = await Provider.of<AuthProvider>(context, listen: false)
          .fetchColleges();
      if (mounted) {
        setState(() {
          _colleges = colleges;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Error fetching colleges: $e');
      }
    }
  }

  Future<void> _selectDate() async {
    try {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate.isBefore(DateTime.now())
            ? DateTime.now()
            : selectedDate,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(
            days: 365 * 2)), // Allow dates up to 2 years in the future
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color.fromARGB(255, 21, 0, 141),
              ),
              dialogBackgroundColor: Colors.white,
            ),
            child: child!,
          );
        },
      );

      if (picked != null && mounted) {
        setState(() {
          selectedDate = picked;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error showing date picker'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      debugPrint('Error in _selectDate: $e');
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
    setState(() => _isImageLoading = true);
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );

      if (pickedFile != null && mounted) {
        final File file = File(pickedFile.path);
        final int fileSize = await file.length();

        // Check if file size is greater than 5MB
        if (fileSize > 5 * 1024 * 1024) {
          _showErrorSnackBar('Image size must be less than 5MB');
          return;
        }

        setState(() => _imageFile = file);
      }
    } catch (e) {
      _showErrorSnackBar('Error picking image: $e');
    } finally {
      if (mounted) {
        setState(() => _isImageLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool _validateForm() {
    if (selectedColleges.isEmpty) {
      _showErrorSnackBar('Please select at least one college');
      return false;
    }

    if (!_formKey.currentState!.validate()) {
      return false;
    }

    final DateTime eventDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    if (eventDateTime.isBefore(DateTime.now())) {
      _showErrorSnackBar('Event date and time cannot be in the past');
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

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      String formattedTime =
          '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';

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

      final response = await request.send().timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw TimeoutException('Request timed out'),
          );

      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.events == null
                  ? 'Event created successfully'
                  : 'Event updated successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        throw Exception(jsonResponse['message'] ?? 'Failed to save event');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error: ${e.toString()}');
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildImageSection(),
                    const SizedBox(height: 16),
                    _buildFormFields(),
                    const SizedBox(height: 16),
                    _buildCollegesSection(),
                    const SizedBox(height: 24),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      children: [
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
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => setState(() => _imageFile = null),
                        ),
                      ],
                    )
                  else if (widget.events?.eventImagePath != null)
                    Image.network(
                      widget.events!.eventImagePath!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Text('Error loading image'),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        TextButton.icon(
          icon: Icon(_isImageLoading ? Icons.hourglass_empty : Icons.image),
          label: Text(_imageFile == null ? 'Add Image' : 'Change Image'),
          onPressed: _isImageLoading ? null : _pickImage,
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    return Column(
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
        _buildDateTimePickers(),
        const SizedBox(height: 16),
        _buildStatusDropdown(),
      ],
    );
  }

  Widget _buildDateTimePickers() {
    return Column(
      children: [
        InkWell(
          onTap: () async {
            await _selectDate();
          },
          child: InputDecorator(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.calendar_today),
              labelText: 'Event Date', // Added label for better UX
            ),
            child: Text(
              DateFormat('yyyy-MM-dd').format(selectedDate),
            ),
          ),
        ),
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
      ],
    );
  }

  bool get isSuperAdmin {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      return authProvider.user?.role?.toLowerCase() == 'superadmin';
    } catch (e) {
      debugPrint('Error checking user role: $e');
      return false;
    }
  }

  Widget _buildStatusDropdown() {
    // Ensure status has a valid initial value
    if (status.isEmpty) {
      status = isSuperAdmin ? 'published' : 'draft';
    }

    // Get available statuses based on role with safe fallback
    List<String> availableStatuses;
    try {
      availableStatuses = isSuperAdmin ? ['published'] : ['draft'];
    } catch (e) {
      debugPrint('Error setting available statuses: $e');
      availableStatuses = ['draft']; // Safe fallback
    }

    // If editing and current status isn't in available statuses, add it
    if (widget.events != null &&
        status.isNotEmpty &&
        !availableStatuses.contains(status)) {
      availableStatuses.add(status);
    }

    // Ensure we have at least one status option
    if (availableStatuses.isEmpty) {
      availableStatuses = ['draft'];
    }

    // Ensure status is valid
    if (!availableStatuses.contains(status)) {
      status = availableStatuses.first;
    }

    return DropdownButtonFormField<String>(
      value: status,
      decoration: const InputDecoration(
        labelText: 'Status',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.flag),
      ),
      items: availableStatuses
          .map((String s) => DropdownMenuItem(
                value: s,
                child: Text(s[0].toUpperCase() + s.substring(1)),
              ))
          .toList(),
      onChanged: (String? newValue) {
        if (newValue != null && newValue.isNotEmpty) {
          setState(() => status = newValue);
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a status';
        }
        return null;
      },
    );
  }

  Widget _buildCollegesSection() {
    bool areAllSelected = _colleges.length == selectedColleges.length;
    bool areSomeSelected = selectedColleges.isNotEmpty && !areAllSelected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Allowed Colleges:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              // Select All Checkbox
              CheckboxListTile(
                title: const Text(
                  'Select All',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                value: areAllSelected,
                tristate: true,
                onChanged: (bool? value) {
                  setState(() {
                    if (value ?? false) {
                      // Select all colleges
                      selectedColleges = _colleges.map((c) => c.id).toList();
                    } else {
                      // Deselect all colleges
                      selectedColleges.clear();
                    }
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                secondary: areSomeSelected
                    ? Text(
                        '${selectedColleges.length}/${_colleges.length}',
                        style: TextStyle(color: Colors.grey[600]),
                      )
                    : null,
              ),
              const Divider(height: 1),
              // Individual college checkboxes
              ..._colleges
                  .map((college) => CheckboxListTile(
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
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                      ))
                  .toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 21, 0, 141),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              widget.events == null ? 'Create Event' : 'Update Event',
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
    );
  }
}
