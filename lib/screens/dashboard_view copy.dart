import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/auth_provider.dart';
import '../models/events.dart';
import 'package:intl/intl.dart';

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

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _fetchEvents();
    await _fetchResponses();
    await _fetchParticipantCounts();
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

      setState(() {
        _userResponses[event.id] = response;
      });

      // Refresh participant counts if response is "Going"
      if (response == 'Going') {
        await _fetchParticipantCounts();
      }

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

  Future<void> _shareEvent(Events event) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.shareEvent(event.id.toString());

      final String shareText = '''
${event.title}
Date: ${event.readableDate}
Time: ${event.formattedTime}
Location: ${event.location}
Description: ${event.description}
${event.hasImage ? "\nImage: ${event.imageUrl}" : ""}''';

      await Share.share(shareText, subject: 'Check out this event!');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing event: $e')),
      );
    }
  }

  Widget _buildEventCard(Events event) {
    final currentResponse = _userResponses[event.id];
    final participantCount = _participantCounts[event.id] ?? 0;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (event.hasImage)
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                image: DecorationImage(
                  image: NetworkImage(event.imageUrl!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16),
                    const SizedBox(width: 4),
                    Text(event.formattedTime),
                    const SizedBox(width: 16),
                    const Icon(Icons.calendar_today, size: 16),
                    const SizedBox(width: 4),
                    Text(event.readableDate),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16),
                    const SizedBox(width: 4),
                    Expanded(child: Text(event.location)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  event.description,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                if (event.maxParticipants > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.people, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Going: $participantCount/${event.maxParticipants}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildResponseButton(
                  label: 'Going',
                  icon: Icons.check_circle,
                  selectedColor: Colors.green,
                  isSelected: currentResponse == 'Going',
                  onPressed: () => _handleEventResponse(event, 'Going'),
                ),
                _buildResponseButton(
                  label: 'Maybe',
                  icon: Icons.help,
                  selectedColor: Colors.orange,
                  isSelected: currentResponse == 'Maybe',
                  onPressed: () => _handleEventResponse(event, 'Maybe'),
                ),
                _buildResponseButton(
                  label: 'Not Going',
                  icon: Icons.cancel,
                  selectedColor: Colors.red,
                  isSelected: currentResponse == 'Not Going',
                  onPressed: () => _handleEventResponse(event, 'Not Going'),
                ),
                IconButton(
                  onPressed: () => _showShareOptions(event),
                  icon: const Icon(Icons.share),
                  tooltip: 'Share Event',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseButton({
    required String label,
    required IconData icon,
    required Color selectedColor,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon,
        color: isSelected ? selectedColor : Colors.grey,
      ),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: isSelected ? selectedColor : Colors.grey,
      ),
    );
  }

  void _showShareOptions(Events event) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Share Event',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share via...'),
              onTap: () {
                Navigator.pop(context);
                _shareEvent(event);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Add to Calendar'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final authProvider =
                      Provider.of<AuthProvider>(context, listen: false);
                  final calendarLink = await authProvider
                      .getEventCalendarLink(event.id.toString());
                  // Handle calendar link (implement calendar integration)
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error adding to calendar: $e')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy event details'),
              onTap: () {
                Navigator.pop(context);
                // Implement copy functionality if needed
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Events> _getUpcomingEvents() {
    final now = DateTime.now();
    final allEvents = _events.values.expand((events) => events).toList();

    return allEvents.where((event) {
      try {
        return event.dateTime.isAfter(now);
      } catch (e) {
        print('Error comparing event dates: $e');
        return false;
      }
    }).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  List<Events> _getActiveEvents() {
    final now = DateTime.now();
    final allEvents = _events.values.expand((events) => events).toList();

    return allEvents.where((event) {
      try {
        final eventDateTime = event.dateTime;
        final eventEndTime = eventDateTime.add(const Duration(hours: 2));
        return eventDateTime.isBefore(now) && eventEndTime.isAfter(now);
      } catch (e) {
        print('Error checking active events: $e');
        return false;
      }
    }).toList();
  }

  Widget _buildSection(String title, List<Events> events) {
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                'No ${title.toLowerCase()} at this time',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: events.length,
            itemBuilder: (context, index) => _buildEventCard(events[index]),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final upcomingEvents = _getUpcomingEvents();
    final activeEvents = _getActiveEvents();

    return RefreshIndicator(
      onRefresh: _initialize,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('Active Events', activeEvents),
            const Divider(height: 32),
            _buildSection('Upcoming Events', upcomingEvents),
          ],
        ),
      ),
    );
  }
}
