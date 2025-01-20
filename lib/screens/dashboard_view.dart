import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../models/events.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import '../screens/search_events_view.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({Key? key}) : super(key: key);

  @override
  _DashboardViewState createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  Map<DateTime, List<Events>> _events = {};
  Map<int, String> _userResponses = {};
  Map<int, int> _participantCounts = {};
  bool _isLoading = true;
  Events? _selectedEvent;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _fetchEvents();
      await _fetchResponses();
      await _fetchParticipantCounts();
    } catch (e) {
      debugPrint('DashboardView: Error during initialization: $e');
    }
  }

  Future<void> _fetchEvents() async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);

      final now = DateTime.now();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final events = await authProvider.fetchEvents(now.month, now.year);

      if (!mounted) return;
      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (e) {
      print('Error in _fetchEvents: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading events: $e')),
        );
      }
    }
  }

  Future<void> _fetchResponses() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final allEvents = _events.values.expand((e) => e).toList();
      final eventIds = allEvents.map((e) => e.id.toString()).toList();

      if (eventIds.isEmpty) return;

      final responses = await authProvider.getUserEventResponses(eventIds);

      if (!mounted) return;
      setState(() {
        responses.forEach((key, value) {
          _userResponses[int.parse(key)] = value;
        });
      });
    } catch (e) {
      print('Error fetching responses: $e');
    }
  }

  Future<void> _fetchParticipantCounts() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final allEvents = _events.values.expand((e) => e).toList();
      final eventIds = allEvents.map((e) => e.id.toString()).toList();

      if (eventIds.isEmpty) return;

      final counts = await authProvider.getEventParticipantCounts(eventIds);

      if (!mounted) return;
      setState(() {
        counts.forEach((key, value) {
          _participantCounts[int.parse(key)] = value;
        });
      });
    } catch (e) {
      print('Error fetching participant counts: $e');
    }
  }

  Future<void> _handleEventResponse(Events event, String response) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.updateEventResponse(event.id.toString(), response);

      // Refresh data after response update
      await _initialize();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully marked as $response')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update response: $e')),
      );
    }
  }

  List<Events> _getEventsByCategory(String category) {
    final now = DateTime.now();
    final allEvents = _events.values.expand((events) => events).toList();

    switch (category) {
      case 'active':
        return allEvents.where((event) {
          final eventDateTime = event.dateTime;
          final eventEndTime = eventDateTime.add(const Duration(hours: 2));
          return eventDateTime.isBefore(now) && eventEndTime.isAfter(now);
        }).toList();
      case 'upcoming':
        return allEvents.where((event) => event.dateTime.isAfter(now)).toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
      case 'recent':
        return allEvents.where((event) => event.dateTime.isBefore(now)).toList()
          ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
      default:
        return [];
    }
  }

  Widget _buildEventCard(Events event) {
    final participantCount = _participantCounts[event.id] ?? 0;
    final progress = event.maxParticipants > 0
        ? participantCount / event.maxParticipants
        : 0.0;

    return GestureDetector(
      onTap: () => _showEventDetails(event),
      child: Container(
        width: 300,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.grey[100],
                    child: event.hasImage
                        ? Image.network(
                            event.imageUrl!,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint('Error loading image: $error');
                              return Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Image.asset(
                                  'images/logo.png',
                                  fit: BoxFit.contain,
                                ),
                              );
                            },
                          )
                        : Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Image.asset(
                              'images/logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.8),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$participantCount/${event.maxParticipants} participants',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.white.withOpacity(0.3),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getProgressColor(progress),
                              ),
                              minHeight: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEventDetails(Events event) {
    setState(() => _selectedEvent = event);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EventDetailsSheet(
        event: event,
        userResponse: _userResponses[event.id],
        participantCount: _participantCounts[event.id] ?? 0,
        onResponseUpdate: _handleEventResponse,
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 0.8) return Colors.red;
    if (progress >= 0.5) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading events...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Events Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final selectedEvent = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchEventsView(),
                ),
              );
              if (selectedEvent != null) {
                _showEventDetails(selectedEvent);
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _initialize,
        child: ListView(
          children: [
            _buildEventSection('Active Events', 'active'),
            _buildEventSection('Upcoming Events', 'upcoming'),
            _buildEventSection('Recent Events', 'recent'),
          ],
        ),
      ),
    );
  }

  Widget _buildEventSection(String title, String category) {
    final events = _getEventsByCategory(category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (events.isEmpty)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: Lottie.asset(
                    category == 'active'
                        ? 'assets/animations/active.json'
                        : category == 'upcoming'
                            ? 'assets/animations/upcoming.json'
                            : 'assets/animations/recent.json',
                    fit: BoxFit.contain,
                    repeat: true,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No ${title.toLowerCase()} events',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 250,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: events.length,
              itemBuilder: (context, index) => _buildEventCard(events[index]),
            ),
          ),
      ],
    );
  }
}

class _EventDetailsSheet extends StatelessWidget {
  final Events event;
  final String? userResponse;
  final int participantCount;
  final Function(Events, String) onResponseUpdate;

  const _EventDetailsSheet({
    required this.event,
    required this.userResponse,
    required this.participantCount,
    required this.onResponseUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 250,
            width: double.infinity,
            color: Colors.grey[100],
            child: event.hasImage
                ? Image.network(
                    event.imageUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('Error loading image: $error');
                      return Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Image.asset(
                          'images/logo.png',
                          fit: BoxFit.contain,
                        ),
                      );
                    },
                  )
                : Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Image.asset(
                      'images/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.calendar_today, event.readableDate),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.access_time, event.formattedTime),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.location_on, event.location),
                  const SizedBox(height: 16),
                  Text(
                    event.description,
                    style: TextStyle(
                      color: Colors.grey[800],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildParticipantsSection(),
                  const SizedBox(height: 24),
                  _buildResponseButtons(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue[700]),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey[800],
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantsSection() {
    final progress = event.maxParticipants > 0
        ? participantCount / event.maxParticipants
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Participants ($participantCount/${event.maxParticipants})',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              progress >= 0.8
                  ? Colors.red
                  : progress >= 0.5
                      ? Colors.orange
                      : Colors.green,
            ),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildResponseButtons(BuildContext context) {
    return Row(
      children: [
        _buildResponseButton('Going', Colors.green, context),
        const SizedBox(width: 8),
        _buildResponseButton('Maybe', Colors.orange, context),
        const SizedBox(width: 8),
        _buildResponseButton('Not Going', Colors.red, context),
      ],
    );
  }

  Widget _buildResponseButton(
      String response, Color color, BuildContext context) {
    final isSelected = userResponse == response;

    return Expanded(
      child: ElevatedButton(
        onPressed: () async {
          // Call the response update function
          await onResponseUpdate(event, response);

          // Close the bottom sheet
          Navigator.of(context).pop();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? color : Colors.grey[200],
          foregroundColor: isSelected ? Colors.white : Colors.grey[800],
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(response),
      ),
    );
  }
}
