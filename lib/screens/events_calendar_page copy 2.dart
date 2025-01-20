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
  const EventsCalendarPage({Key? key}) : super(key: key);

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
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timed out'),
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

                    final eventDate = _parseEventDate(
                      eventMap['event_date'] as String?,
                      normalizedDate,
                    );

                    return Events(
                      id: eventMap['id'] as int? ?? 0,
                      title: eventMap['title'] as String? ?? '',
                      description: eventMap['description'] as String? ?? '',
                      eventDate: eventDate,
                      eventTime:
                          _sanitizeEventTime(eventMap['event_time'] as String?),
                      location: eventMap['location'] as String? ?? '',
                      creatorId: eventMap['creator_id'] as int? ?? 0,
                      maxParticipants:
                          eventMap['max_participants'] as int? ?? 0,
                      status: eventMap['status'] as String? ?? 'draft',
                      eventImagePath: eventMap['eventImagePath'] as String?,
                      allowedView:
                          List<int>.from(eventMap['allowedView'] ?? []),
                    );
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
      try {
        return DateFormat('yyyy-MM-dd').parse(dateString.trim());
      } catch (_) {
        final cleanDateString = dateString
            .replaceAll(RegExp(r'\s+'), '')
            .replaceAll(RegExp(r'[TZ]'), '');

        try {
          return DateTime.parse(cleanDateString);
        } catch (_) {
          debugPrint('Failed to parse date: $dateString, using current date');
          return DateTime.now();
        }
      }
    }
  }

  DateTime _parseEventDate(String? dateString, DateTime fallbackDate) {
    if (dateString == null) return fallbackDate;

    try {
      return _parseDate(dateString);
    } catch (_) {
      debugPrint(
          'Failed to parse event date: $dateString, using fallback date');
      return fallbackDate;
    }
  }

  String _sanitizeEventTime(String? timeString) {
    if (timeString == null) return '00:00';

    final cleanTime = timeString.replaceAll(RegExp(r'\s+'), '');
    if (RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$').hasMatch(cleanTime)) {
      return cleanTime;
    }

    try {
      final time = DateFormat.Hm().parse(cleanTime);
      return DateFormat.Hm().format(time);
    } catch (_) {
      return '00:00';
    }
  }

  Future<void> _handleDeleteEvent(Events event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this event?'),
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

  List<Events> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  // Update the _showEventDetails method in your EventsCalendarPage

  Future<void> _showEventDetails(Events event) async {
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (BuildContext context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Title Header
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

              // Event Image
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

              // Event Details
              _buildDetailRow(
                  Icons.description, 'Description:', event.description),
              _buildDetailRow(Icons.location_on, 'Location:', event.location),
              _buildDetailRow(Icons.access_time, 'Time:', event.formattedTime),
              _buildDetailRow(
                  Icons.calendar_today, 'Date:', event.readableDate),
              _buildDetailRow(Icons.group, 'Maximum Participants:',
                  event.maxParticipants.toString()),
              _buildDetailRow(Icons.flag, 'Status:', event.readableStatus),

              const SizedBox(height: 20),

              // Action Buttons
              if (_userCanEditEvent(event))
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Update Button
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 21, 0, 141),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.edit, color: Colors.white),
                        label: const Text(
                          'Update',
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _handleEventEdit(event);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Delete Button
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.delete, color: Colors.white),
                        label: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _confirmDelete(event);
                        },
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

// Add this helper method for building detail rows
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

// Add this method for delete confirmation
  Future<void> _confirmDelete(Events event) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "${event.title}"?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              _handleDeleteEvent(event);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /* bool _userCanEditEvent(Events event) {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    return user?.id == event.creatorId;
  } */

  bool _userCanEditEvent(Events event) {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    // Allow editing if user is creator, admin, or superadmin
    return user != null &&
        (user.id == event.creatorId ||
            user.role == 'admin' ||
            user.role == 'superadmin');
  }

  Future<void> _handleEventEdit(Events event) async {
    if (!mounted) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditEventPage(event: event),
      ),
    );

    if (mounted && result == true) {
      await _fetchEvents();
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!mounted) return;

    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
  }

  Future<void> _showHelpDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.help_outline,
                      color: Color.fromARGB(255, 21, 0, 141)),
                  const SizedBox(width: 8),
                  const Text(
                    'Help & Information',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),
              _buildHelpItem(
                Icons.calendar_today,
                'Calendar Navigation',
                'Use the calendar to view and select different dates. Events are marked with dots.',
              ),
              _buildHelpItem(
                Icons.add_circle_outline,
                'Adding Events',
                'Click the "Add Event" button to create a new event. Fill in all required details.',
              ),
              _buildHelpItem(
                Icons.edit,
                'Managing Events',
                'Click on any event to view details. Admins and event creators can edit or delete events.',
              ),
              _buildHelpItem(
                Icons.notifications,
                'Notifications',
                'Stay updated with event notifications. Click the bell icon to view all notifications.',
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelpItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color.fromARGB(255, 21, 0, 141)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
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
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Events Calendar',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 21, 0, 141),
        actions: [
          // Notification Icon with Badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  );
                },
              ),
              Consumer<AuthProvider>(
                builder: (context, auth, child) {
                  if (auth.unreadNotificationsCount == 0) return Container();
                  return Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        '${auth.unreadNotificationsCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          // Refresh Button
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _fetchEvents();
              Provider.of<AuthProvider>(context, listen: false)
                  .fetchNotifications();
            },
          ),
          // More Options Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              switch (value) {
                case 'filter':
                  // Add filter functionality
                  break;
                case 'settings':
                  // Add settings navigation
                  break;
                case 'help':
                  _showHelpDialog();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'filter',
                child: Row(
                  children: [
                    Icon(Icons.filter_list, size: 20),
                    SizedBox(width: 8),
                    Text('Filter Events'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 20),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'help',
                child: Row(
                  children: [
                    Icon(Icons.help_outline, size: 20),
                    SizedBox(width: 8),
                    Text('Help'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Container(
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
        child: Column(
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
                    weekendTextStyle: const TextStyle(color: Colors.red),
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_selectedDay != null)
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _fetchEvents,
                  child: _getEventsForDay(_selectedDay!).isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event_busy,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No events for ${DateFormat('MMMM d, yyyy').format(_selectedDay!)}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.all(8),
                          itemCount: _getEventsForDay(_selectedDay!).length,
                          itemBuilder: (context, index) {
                            final event =
                                _getEventsForDay(_selectedDay!)[index];
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _showEventDetails(event),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                                  icon: const Icon(Icons.edit,
                                                      size: 20),
                                                  onPressed: () =>
                                                      _handleEventEdit(event),
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.delete,
                                                    size: 20,
                                                    color: Colors.red[400],
                                                  ),
                                                  onPressed: () =>
                                                      _handleDeleteEvent(event),
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
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            event.formattedTime,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Icon(
                                            Icons.location_on,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              event.location,
                                              style: TextStyle(
                                                color: Colors.grey[600],
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
                        ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEventForm()),
          );
          if (result == true && mounted) {
            await _fetchEvents();
          }
        },
        backgroundColor: const Color.fromARGB(255, 21, 0, 141),
        icon: const Icon(Icons.add),
        label: const Text('Add Event'),
      ),
    );
  }
}
