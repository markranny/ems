import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_provider.dart';
import 'dart:convert';
import '../models/events.dart';
import '../models/colleges.dart';
import '../screens/Add/add_event_form.dart';
import '../screens/Update/edit_event_page.dart';
import '../screens/notificationscreen.dart';
import 'package:intl/intl.dart';

class EventsCalendarPage extends StatefulWidget {
  // Define the properties at the StatefulWidget level
  final VoidCallback? onRefresh;
  final bool canManageEvents; // This is the missing property
  final bool canEditDeleteEvents;

  // Updated constructor with required properties
  const EventsCalendarPage({
    Key? key,
    this.onRefresh,
    required this.canManageEvents,
    this.canEditDeleteEvents = true,
  }) : super(key: key);

  @override
  _EventsCalendarPageState createState() => _EventsCalendarPageState();
}

class _EventsCalendarPageState extends State<EventsCalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Events>> _events = {};
  bool _isLoading = false;
  List<Colleges> _colleges = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    try {
      await Future.wait([
        _fetchEvents(),
        _fetchColleges(),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: ${e.toString()}')),
        );
      }
    }
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
      debugPrint('Error fetching colleges: $e');
      rethrow;
    }
  }

  Future<void> _fetchEvents() async {
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) throw Exception("Not authenticated");

      final response = await http.get(
        Uri.parse(
            '${authProvider.baseUrl}/api/events/month?month=${_focusedDay.month}&year=${_focusedDay.year}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final Map<DateTime, List<Events>> newEvents = {};

        if (responseData['data'] is Map<String, dynamic>) {
          final data = responseData['data'] as Map<String, dynamic>;

          for (var entry in data.entries) {
            try {
              if (entry.value != null) {
                DateTime normalizedDate = _parseDate(entry.key);

                if (entry.value is List) {
                  final eventsList = entry.value as List;
                  final events = eventsList.map((event) {
                    final eventMap = event as Map<String, dynamic>;
                    return Events.fromJson(eventMap);
                  }).toList();

                  if (events.isNotEmpty) {
                    newEvents[normalizedDate] = events;
                  }
                }
              }
            } catch (e) {
              debugPrint('Error processing date ${entry.key}: $e');
              continue;
            }
          }
        }

        if (mounted) {
          setState(() => _events = newEvents);
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load events: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  DateTime _parseDate(String dateString) {
    try {
      return DateTime.parse(dateString.trim());
    } catch (_) {
      return DateFormat('yyyy-MM-dd').parse(dateString.trim());
    }
  }

  bool _userCanEditEvent(Events event) {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    return user != null &&
        widget.canManageEvents &&
        (user.id == event.creatorId ||
            user.role == 'superadmin' ||
            user.role == 'admin');
  }

  List<Events> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  Future<void> _handleEventEdit(Events event) async {
    if (!mounted || !widget.canManageEvents) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditEventPage(event: event),
      ),
    );

    if (result == true && mounted) {
      await _fetchEvents();
    }
  }

  Future<void> _handleDeleteEvent(Events event) async {
    if (!widget.canManageEvents) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.deleteEvent(event.id);
        await _fetchEvents();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete event: $e')),
          );
        }
      }
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!mounted) return;
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
  }

  Future<void> _showEventDetails(Events event) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                if (event.eventImagePath != null)
                  Container(
                    height: 200,
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image: DecorationImage(
                        image: NetworkImage(event.eventImagePath!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                _buildDetailRow(
                    Icons.description, 'Description:', event.description),
                _buildDetailRow(Icons.location_on, 'Location:', event.location),
                _buildDetailRow(
                    Icons.calendar_today, 'Date:', event.readableDate),
                _buildDetailRow(
                    Icons.access_time, 'Time:', event.formattedTime),
                _buildDetailRow(Icons.group, 'Maximum Participants:',
                    event.maxParticipants.toString()),
                _buildDetailRow(Icons.flag, 'Status:', event.readableStatus),
                if (_userCanEditEvent(event)) ...[
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 21, 0, 141),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.edit, color: Colors.white),
                          label: const Text('Update',
                              style: TextStyle(color: Colors.white)),
                          onPressed: () {
                            Navigator.pop(context);
                            _handleEventEdit(event);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.delete, color: Colors.white),
                          label: const Text('Delete',
                              style: TextStyle(color: Colors.white)),
                          onPressed: () {
                            Navigator.pop(context);
                            _handleDeleteEvent(event);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color.fromARGB(255, 21, 0, 141)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color.fromARGB(255, 21, 0, 141).withOpacity(0.1),
            Colors.white,
          ],
        ),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              Card(
                margin: const EdgeInsets.all(8.0),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TableCalendar(
                    firstDay: DateTime.utc(2024, 1, 1),
                    lastDay: DateTime.utc(2025, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    eventLoader: _getEventsForDay,
                    onDaySelected: _onDaySelected,
                    onPageChanged: (focusedDay) {
                      setState(() => _focusedDay = focusedDay);
                      _fetchEvents();
                    },
                    calendarStyle: CalendarStyle(
                      markersMaxCount: 1,
                      markerDecoration: BoxDecoration(
                        color: Colors.red.shade400,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: const Color.fromARGB(255, 21, 0, 141)
                            .withOpacity(0.7),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: const BoxDecoration(
                        color: Color.fromARGB(255, 21, 0, 141),
                        shape: BoxShape.circle,
                      ),
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                    ),
                  ),
                ),
              ),
              if (_isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchEvents,
                    child: _buildEventsList(),
                  ),
                ),
            ],
          ),
          if (widget.canManageEvents)
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton.extended(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddEventForm(),
                    ),
                  );
                  if (result == true && mounted) {
                    await _fetchEvents();
                  }
                },
                backgroundColor: const Color.fromARGB(255, 21, 0, 141),
                icon: const Icon(
                  Icons.add,
                  color: Color.fromARGB(255, 255, 255, 255), // White icon
                ),
                label: const Text(
                  'Add Event',
                  style: TextStyle(
                    color: Color.fromARGB(255, 255, 255, 255), // White text
                    fontWeight: FontWeight.bold, // Bold text
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEventsList() {
    if (_selectedDay == null) return Container();

    final events = _getEventsForDay(_selectedDay!);

    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: const Color.fromARGB(255, 255, 255, 255),
            ),
            const SizedBox(height: 16),
            Text(
              'No events for ${DateFormat('MMMM d, yyyy').format(_selectedDay!)}',
              style: TextStyle(
                color: const Color.fromARGB(255, 255, 255, 255),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(8),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showEventDetails(event),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_userCanEditEvent(event))
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () => _handleEventEdit(event),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete,
                                size: 20,
                                color: Colors.red[400],
                              ),
                              onPressed: () => _handleDeleteEvent(event),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: const Color.fromARGB(255, 117, 117, 117),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        event.formattedTime,
                        style: TextStyle(
                          color: const Color.fromARGB(255, 117, 117, 117),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: const Color.fromARGB(255, 117, 117, 117),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.location,
                          style: TextStyle(
                            color: const Color.fromARGB(255, 117, 117, 117),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
