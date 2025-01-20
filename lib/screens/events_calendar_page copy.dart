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
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

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
                // Improved date parsing with better error handling
                DateTime normalizedDate = _parseDate(entry.key);

                if (entry.value is List) {
                  final eventsList = entry.value as List;
                  final events = eventsList.map((event) {
                    final eventMap = event as Map<String, dynamic>;

                    // Improved event date parsing
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
              // Continue processing other entries even if one fails
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

  // New helper method for parsing dates
  DateTime _parseDate(String dateString) {
    try {
      // First, try parsing as ISO 8601
      return DateTime.parse(dateString.trim());
    } catch (_) {
      try {
        // If ISO 8601 fails, try parsing as yyyy-MM-dd
        return DateFormat('yyyy-MM-dd').parse(dateString.trim());
      } catch (_) {
        // If both parsing attempts fail, try to clean the string and parse again
        final cleanDateString = dateString
            .replaceAll(RegExp(r'\s+'), '') // Remove all whitespace
            .replaceAll(RegExp(r'[TZ]'), ''); // Remove T and Z markers

        try {
          return DateTime.parse(cleanDateString);
        } catch (_) {
          // If all parsing attempts fail, return current date
          debugPrint('Failed to parse date: $dateString, using current date');
          return DateTime.now();
        }
      }
    }
  }

  // New helper method for parsing event dates
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

  // New helper method for sanitizing event time
  String _sanitizeEventTime(String? timeString) {
    if (timeString == null) return '00:00';

    // Remove any spaces and ensure proper format
    final cleanTime = timeString.replaceAll(RegExp(r'\s+'), '');
    if (RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$').hasMatch(cleanTime)) {
      return cleanTime;
    }

    try {
      // Try to parse and format the time
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

  Future<void> _showEventDetails(Events event) async {
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(event.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (event.eventImagePath != null)
                Image.network(
                  event.eventImagePath!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              const SizedBox(height: 8),
              Text('Description: ${event.description}'),
              const SizedBox(height: 8),
              Text('Location: ${event.location}'),
              Text('Time: ${event.formattedTime}'),
              Text('Date: ${event.readableDate}'),
              Text('Maximum Participants: ${event.maxParticipants}'),
              Text('Status: ${event.readableStatus}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (_userCanEditEvent(event)) ...[
            TextButton(
              onPressed: () => _handleEventEdit(event),
              child: const Text('Edit'),
            ),
            TextButton(
              onPressed: () => _handleDeleteEvent(event),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ],
      ),
    );
  }

  bool _userCanEditEvent(Events event) {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    return user?.id == event.creatorId;
  }

  Future<void> _handleEventEdit(Events event) async {
    if (!mounted) return;

    Navigator.pop(context); // Close details dialog
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

  Future<void> _onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
    if (!mounted) return;

    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });

    final events = _getEventsForDay(selectedDay);
    if (events.isNotEmpty) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.8,
          builder: (_, scrollController) => ListView.builder(
            controller: scrollController,
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return ListTile(
                title: Text(event.title),
                subtitle: Text(
                  '${event.formattedTime} - ${event.location}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: _userCanEditEvent(event)
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              Navigator.pop(context);
                              _handleEventEdit(event);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              Navigator.pop(context);
                              _handleDeleteEvent(event);
                            },
                          ),
                        ],
                      )
                    : null,
                onTap: () async {
                  Navigator.pop(context);
                  await _showEventDetails(event);
                },
              );
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events Calendar'),
        backgroundColor: const Color.fromARGB(255, 21, 0, 141),
      ),
      body: Column(
        children: [
          TableCalendar(
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
            calendarStyle: const CalendarStyle(
              markersMaxCount: 1,
              markerDecoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Color.fromARGB(255, 21, 0, 141),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Color.fromARGB(255, 21, 0, 141),
                shape: BoxShape.circle,
              ),
            ),
          ),
          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_selectedDay != null)
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchEvents,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: _getEventsForDay(_selectedDay!).length,
                  itemBuilder: (context, index) {
                    final event = _getEventsForDay(_selectedDay!)[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: ListTile(
                        title: Text(event.title),
                        subtitle: Text(event.description),
                        trailing: _userCanEditEvent(event)
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _handleEventEdit(event),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => _handleDeleteEvent(event),
                                  ),
                                ],
                              )
                            : Text(event.formattedTime),
                        onTap: () => _showEventDetails(event),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
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
        child: const Icon(Icons.add),
      ),
    );
  }
}
