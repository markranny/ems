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
import '../../models/location.dart';
import '../../models/events.dart';
import 'package:path/path.dart' as path;
import 'package:http_parser/http_parser.dart';
import 'package:intl/intl.dart';

class AddEventForm extends StatefulWidget {
  final Events? events;
  const AddEventForm({Key? key, this.events}) : super(key: key);

  @override
  State<AddEventForm> createState() => _AddEventFormState();
}

class _AddEventFormState extends State<AddEventForm> {
  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final maxParticipantsController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  List<int> selectedColleges = [];
  String status = 'pending';
  List<Colleges> _colleges = [];
  List<Location> _locations = [];
  Location? _selectedLocation;
  bool _isLoading = false;
  bool _isLoadingLocations = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isImageLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
    _initializeFormData();
  }

  Future<void> _fetchInitialData() async {
    await Future.wait([
      _fetchLocations(),
      _fetchColleges(),
    ]);
  }

  void _initializeFormData() {
    if (widget.events != null) {
      titleController.text = widget.events!.title;
      descriptionController.text = widget.events!.description;
      maxParticipantsController.text =
          widget.events!.maxParticipants.toString();
      selectedDate = widget.events!.eventDate;

      try {
        selectedTime = TimeOfDay.fromDateTime(
            DateFormat('HH:mm').parse(widget.events!.eventTime));
      } catch (e) {
        selectedTime = TimeOfDay.now();
        debugPrint('Error parsing event time: $e');
      }

      selectedColleges = List<int>.from(widget.events!.allowedView);
      status = widget.events!.status;
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    maxParticipantsController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocations() async {
    if (!mounted) return;

    setState(() => _isLoadingLocations = true);
    try {
      final locations = await Provider.of<AuthProvider>(context, listen: false)
          .fetchLocations();
      if (mounted) {
        setState(() {
          _locations = locations;
          if (widget.events != null && locations.isNotEmpty) {
            try {
              _selectedLocation = locations.firstWhere(
                (loc) => loc.description == widget.events!.location,
                orElse: () => locations.first,
              );
            } catch (e) {
              _selectedLocation = locations.first;
            }
          }
          _isLoadingLocations = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingLocations = false);
        _showErrorSnackBar('Error fetching locations: $e');
      }
    }
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
        lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
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
      _showErrorSnackBar('Error showing date picker');
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

    if (_selectedLocation == null) {
      _showErrorSnackBar('Please select a location');
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
    if (status.isEmpty) {
      status = isSuperAdmin ? 'published' : 'draft';
    }

    List<String> availableStatuses;
    try {
      availableStatuses = isSuperAdmin ? ['published'] : ['draft'];
    } catch (e) {
      debugPrint('Error setting available statuses: $e');
      availableStatuses = ['draft'];
    }

    if (widget.events != null &&
        status.isNotEmpty &&
        !availableStatuses.contains(status)) {
      availableStatuses.add(status);
    }

    if (availableStatuses.isEmpty) {
      availableStatuses = ['draft'];
    }

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
      items: availableStatuses.map((String s) {
        return DropdownMenuItem(
          value: s,
          child: Text(s[0].toUpperCase() + s.substring(1)),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null && newValue.isNotEmpty) {
          setState(() => status = newValue);
        }
      },
      validator: (value) =>
          value?.isEmpty ?? true ? 'Please select a status' : null,
    );
  }

  Widget _buildLocationDropdown() {
    return DropdownButtonFormField<Location>(
      value: _selectedLocation,
      decoration: const InputDecoration(
        labelText: 'Location',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.location_on),
      ),
      items: _locations.map((Location location) {
        return DropdownMenuItem<Location>(
          value: location,
          child: Text(location.description),
        );
      }).toList(),
      onChanged: (Location? newValue) {
        setState(() {
          _selectedLocation = newValue;
        });
      },
      validator: (value) => value == null ? 'Please select a location' : null,
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
        _isLoadingLocations
            ? const Center(child: CircularProgressIndicator())
            : _buildLocationDropdown(),
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
          onTap: _selectDate,
          child: InputDecorator(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.calendar_today),
              labelText: 'Event Date',
            ),
            child: Text(
              DateFormat('yyyy-MM-dd').format(selectedDate),
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
              labelText: 'Event Time',
            ),
            child: Text(
              selectedTime.format(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCollegesSection() {
    bool areAllSelected = _colleges.length == selectedColleges.length;
    bool areSomeSelected = selectedColleges.isNotEmpty && !areAllSelected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Allowed Colleges:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
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
                      selectedColleges = _colleges.map((c) => c.id).toList();
                    } else {
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

  Future<void> _submitEvent() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final eventData = {
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'event_date': DateFormat('yyyy-MM-dd').format(selectedDate),
        'event_time':
            '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
        'location': _selectedLocation!.description,
        'max_participants': maxParticipantsController.text,
        'status': status,
        'allowedView': selectedColleges,
      };

      if (widget.events != null) {
        await authProvider.updateEvent(
            widget.events!.id, eventData, _imageFile);
      } else {
        await authProvider.createEvent(eventData, _imageFile);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.events == null
                  ? 'Event created successfully'
                  : 'Event updated successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
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
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 21, 0, 141),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
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
                              widget.events == null
                                  ? 'Create Event'
                                  : 'Update Event',
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.white),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
