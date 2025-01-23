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

enum EventStatus { all, published, pending, recent }

class EventsCalendarPage extends StatefulWidget {
  final VoidCallback? onRefresh;
  final bool canManageEvents;
  final bool canEditDeleteEvents;

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
  EventStatus _selectedStatus = EventStatus.all;

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
      final Map<DateTime, List<Events>> newEvents =
          await authProvider.fetchEvents(_focusedDay.month, _focusedDay.year);

      if (mounted) {
        setState(() {
          _events = newEvents;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load events: ${e.toString()}')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  List<Events> _filterEventsByStatus(List<Events> events) {
    final now = DateTime.now();
    switch (_selectedStatus) {
      case EventStatus.published:
        return events.where((event) => event.status == 'published').toList();
      case EventStatus.pending:
        return events.where((event) => event.status == 'pending').toList();
      case EventStatus.recent:
        return events
            .where((event) =>
                event.dateTime.isBefore(now) &&
                event.dateTime.isAfter(now.subtract(const Duration(days: 7))))
            .toList();
      case EventStatus.all:
      default:
        return events;
    }
  }

  List<Events> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final events = _events[normalizedDay] ?? [];
    return _filterEventsByStatus(events);
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });

      final events = _getEventsForDay(selectedDay);

      if (events.isNotEmpty) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => DayEventsBottomSheet(
            selectedDate: selectedDay,
            events: events,
            canManageEvents: widget.canManageEvents,
            onEditEvent: (event) {
              Navigator.pop(context);
              _handleEventEdit(event);
            },
            onDeleteEvent: (event) {
              Navigator.pop(context);
              _handleDeleteEvent(event);
            },
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'No events on ${DateFormat('MMMM d, yyyy').format(selectedDay)}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _handleEventEdit(Events event) async {
    if (!mounted) return;

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

  Widget _buildFilterChip(String label, EventStatus status) {
    final isSelected = _selectedStatus == status;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          _selectedStatus = status;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: const Color.fromARGB(255, 21, 0, 141),
      checkmarkColor: Colors.white,
      elevation: 2,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(8),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return DayEventCard(
          event: event,
          canManageEvents: widget.canManageEvents,
          onEdit: () => _handleEventEdit(event),
          onDelete: () => _handleDeleteEvent(event),
        );
      },
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
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      _buildFilterChip('All', EventStatus.all),
                      const SizedBox(width: 8),
                      _buildFilterChip('Published', EventStatus.published),
                      const SizedBox(width: 8),
                      _buildFilterChip('Pending', EventStatus.pending),
                      const SizedBox(width: 8),
                      _buildFilterChip('Recent', EventStatus.recent),
                    ],
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
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Add Event',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class DayEventsBottomSheet extends StatelessWidget {
  final DateTime selectedDate;
  final List<Events> events;
  final Function(Events) onEditEvent;
  final Function(Events) onDeleteEvent;
  final bool canManageEvents;

  const DayEventsBottomSheet({
    Key? key,
    required this.selectedDate,
    required this.events,
    required this.onEditEvent,
    required this.onDeleteEvent,
    required this.canManageEvents,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMMM d, yyyy').format(selectedDate),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${events.length} Event${events.length != 1 ? 's' : ''}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return DayEventCard(
                  event: event,
                  canManageEvents: canManageEvents,
                  onEdit: () => onEditEvent(event),
                  onDelete: () => onDeleteEvent(event),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class DayEventCard extends StatelessWidget {
  final Events event;
  final bool canManageEvents;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const DayEventCard({
    Key? key,
    required this.event,
    required this.canManageEvents,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'published':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      default:
        return const Color.fromARGB(255, 21, 0, 141);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: EventDetailsDialog(
                event: event,
                onEdit: canManageEvents ? onEdit : null,
                onDelete: canManageEvents ? onDelete : null,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                _getStatusColor(event.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            event.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              color: _getStatusColor(event.status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (canManageEvents)
                    PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete',
                                  style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          onEdit();
                        } else if (value == 'delete') {
                          onDelete();
                        }
                      },
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    event.formattedTime,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      event.location,
                      style: TextStyle(color: Colors.grey[600]),
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
  }
}

class EventDetailsDialog extends StatefulWidget {
  final Events event;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const EventDetailsDialog({
    Key? key,
    required this.event,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  _EventDetailsDialogState createState() => _EventDetailsDialogState();
}

class _EventDetailsDialogState extends State<EventDetailsDialog> {
  Map<String, List<Map<String, dynamic>>> _attendees = {
    'Going': [],
    'Not Going': [],
    'Maybe': [],
  };
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAttendees();
  }

  Future<void> _fetchAttendees() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Convert event ID to string explicitly
      final eventIdString = widget.event.id.toString();
      final response = await authProvider.getEventResponses([eventIdString]);

      Map<String, List<Map<String, dynamic>>> groupedAttendees = {
        'Going': [],
        'Not Going': [],
        'Maybe': [],
      };

      if (response['success'] == true && response['data'] != null) {
        // Use event ID string for lookup
        final eventResponses = response['data'][eventIdString];

        if (eventResponses != null) {
          for (var response in eventResponses) {
            final attendee = {
              'name': response['user_name'] ?? 'Anonymous',
              'userId': response['user_id'],
              'timestamp': DateTime.parse(response['created_at']),
            };

            switch (response['response']) {
              case 'Going':
                groupedAttendees['Going']!.add(attendee);
                break;
              case 'Not Going':
                groupedAttendees['Not Going']!.add(attendee);
                break;
              case 'Maybe':
                groupedAttendees['Maybe']!.add(attendee);
                break;
            }
          }

          // Sort each list by timestamp
          for (var key in groupedAttendees.keys) {
            groupedAttendees[key]!.sort((a, b) => (b['timestamp'] as DateTime)
                .compareTo(a['timestamp'] as DateTime));
          }
        }
      }

      if (mounted) {
        setState(() {
          _attendees = groupedAttendees;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
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

  Widget _buildAttendeesList(String status) {
    final List<Map<String, dynamic>> attendees = _attendees[status] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '$status',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color.fromARGB(255, 21, 0, 141),
              ),
            ),
            Text(
              ' (${attendees.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (attendees.isEmpty)
          Text(
            'No one ${status.toLowerCase()} yet',
            style: TextStyle(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: attendees.length,
            itemBuilder: (context, index) {
              final attendee = attendees[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        attendee['name'] as String,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Text(
                      DateFormat('MMM d, h:mm a')
                          .format(attendee['timestamp'] as DateTime),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
                    widget.event.title,
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
            if (widget.event.eventImagePath != null &&
                widget.event.eventImagePath!.isNotEmpty)
              Container(
                height: 200,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  image: DecorationImage(
                    image: NetworkImage(
                        widget.event.imageUrl ?? widget.event.eventImagePath!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            // Event Details
            _buildDetailRow(
                Icons.description, 'Description:', widget.event.description),
            _buildDetailRow(
                Icons.location_on, 'Location:', widget.event.location),
            _buildDetailRow(
                Icons.calendar_today, 'Date:', widget.event.readableDate),
            _buildDetailRow(
                Icons.access_time, 'Time:', widget.event.formattedTime),
            _buildDetailRow(Icons.group, 'Maximum Participants:',
                widget.event.maxParticipants.toString()),
            _buildDetailRow(Icons.flag, 'Status:', widget.event.readableStatus),

            const SizedBox(height: 20),
            const Divider(),

            // Attendees Section
            const Text(
              'Attendees',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              )
            else if (_error != null)
              Center(
                child: Column(
                  children: [
                    Text(
                      'Error loading attendees: $_error',
                      style: const TextStyle(color: Colors.red),
                    ),
                    ElevatedButton(
                      onPressed: _fetchAttendees,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAttendeesList('Going'),
                  _buildAttendeesList('Not Going'),
                  _buildAttendeesList('Maybe'),
                ],
              ),

            if (widget.onEdit != null && widget.onDelete != null) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 21, 0, 141),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.edit, color: Colors.white),
                      label: const Text('Update',
                          style: TextStyle(color: Colors.white)),
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onEdit?.call();
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
                        widget.onDelete?.call();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
