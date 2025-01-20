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

class _DashboardViewState extends State<DashboardView>
    with SingleTickerProviderStateMixin {
  Map<DateTime, List<Events>> _events = {};
  Map<int, String> _userResponses = {};
  Map<int, int> _participantCounts = {};
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _initializeLogging();
    _tabController = TabController(length: 2, vsync: this);
    _initialize();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    debugPrint('DashboardView: Starting initialization');
    try {
      await _fetchEvents();
      await _fetchResponses();
      await _fetchParticipantCounts();
      debugPrint('DashboardView: Initialization completed successfully');
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

      setState(() {
        _userResponses[event.id] = response;
      });

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

      // First, verify the event still exists and is accessible
      await authProvider.getEvent(event.id.toString());

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

      String errorMessage = 'Error sharing event';
      if (e.toString().contains('403')) {
        errorMessage = 'You do not have permission to share this event';
      } else if (e.toString().contains('404')) {
        errorMessage = 'Event not found';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showShareOptions(Events event) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Share Event',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.share, color: Colors.blue[700]),
              title: const Text('Share via...'),
              onTap: () {
                Navigator.pop(context);
                _shareEvent(event);
              },
            ),
            ListTile(
              leading: Icon(Icons.calendar_today, color: Colors.green[700]),
              title: const Text('Add to Calendar'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final authProvider =
                      Provider.of<AuthProvider>(context, listen: false);
                  await authProvider.getEventCalendarLink(event.id.toString());
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error adding to calendar: $e')),
                  );
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.copy, color: Colors.orange[700]),
              title: const Text('Copy event details'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventImage(Events event) {
    debugPrint('Building image for event ${event.id}');
    debugPrint('Image URL: ${event.imageUrl}');
    debugPrint('Event Image Path: ${event.eventImagePath}');

    if (!event.hasImage || event.imageUrl == null) {
      debugPrint('No image available, showing default');
      return _buildDefaultImage();
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Stack(
        children: [
          SizedBox(
            height: 200,
            width: double.infinity,
            child: Image.network(
              event.imageUrl!,
              fit: BoxFit.cover,
              headers: const {
                'Accept': 'image/*',
              },
              loadingBuilder: (context, child, loadingProgress) {
                debugPrint('Loading image for event ${event.id}...');
                if (loadingProgress == null) {
                  debugPrint('Image loaded successfully');
                  return child;
                }
                return _buildLoadingIndicator(loadingProgress);
              },
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Error loading image: $error');
                debugPrint('Stack trace: $stackTrace');
                return _buildDefaultImage();
              },
            ),
          ),
          _buildImageOverlay(),
          Positioned(
            top: 16,
            right: 16,
            child: _buildStatusChip(event),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultImage() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Stack(
        children: [
          Container(
            height: 200,
            width: double.infinity,
            color: Colors.grey[200],
            child: Center(
              child: Icon(
                Icons.image_not_supported,
                size: 48,
                color: Colors.grey[400],
              ),
            ),
          ),
          _buildImageOverlay(),
        ],
      ),
    );
  }

  Widget _buildImageOverlay() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(ImageChunkEvent loadingProgress) {
    return Container(
      height: 200,
      width: double.infinity,
      color: Colors.grey[200],
      child: Center(
        child: CircularProgressIndicator(
          value: loadingProgress.expectedTotalBytes != null
              ? loadingProgress.cumulativeBytesLoaded /
                  loadingProgress.expectedTotalBytes!
              : null,
        ),
      ),
    );
  }

  void _initializeLogging() {
    debugPrint('DashboardView: Initializing dashboard view');
    debugPrint('DashboardView: Debug mode is enabled');
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

  Widget _buildEventCard(Events event) {
    print('Event details for ${event.id}:');
    print('Raw eventImagePath: ${event.eventImagePath}');
    print('Processed imageUrl: ${event.imageUrl}');
    print('Has image: ${event.hasImage}');

    final currentResponse = _userResponses[event.id];
    final participantCount = _participantCounts[event.id] ?? 0;
    final progress = event.maxParticipants > 0
        ? participantCount / event.maxParticipants
        : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 68, 0, 255).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEventImage(event), // Remove the if condition here
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                      icon: const Icon(Icons.share_outlined),
                      onPressed: () => _showShareOptions(event),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.calendar_today,
                  event.readableDate,
                  Colors.blue.shade700,
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.access_time,
                  event.formattedTime,
                  Colors.orange.shade700,
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.location_on,
                  event.location,
                  Colors.red.shade700,
                ),
                const SizedBox(height: 16),
                Text(
                  event.description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                if (event.maxParticipants > 0) ...[
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Participants',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '$participantCount/${event.maxParticipants}',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey[200],
                          color: _getProgressColor(progress),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildResponseButton(
                      'Going',
                      Icons.check_circle_outline,
                      Colors.green,
                      currentResponse == 'Going',
                      () => _handleEventResponse(event, 'Going'),
                    ),
                    _buildResponseButton(
                      'Maybe',
                      Icons.help_outline,
                      Colors.orange,
                      currentResponse == 'Maybe',
                      () => _handleEventResponse(event, 'Maybe'),
                    ),
                    _buildResponseButton(
                      'Not Going',
                      Icons.cancel_outlined,
                      Colors.red,
                      currentResponse == 'Not Going',
                      () => _handleEventResponse(event, 'Not Going'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 0.8) return Colors.red;
    if (progress >= 0.5) return Colors.orange;
    return Colors.green;
  }

  Widget _buildStatusChip(Events event) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: event.isOngoing ? Colors.green : Colors.blue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        event.isOngoing ? 'Active Now' : 'Upcoming',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResponseButton(
    String label,
    IconData icon,
    Color color,
    bool isSelected,
    VoidCallback onPressed,
  ) {
    return Expanded(
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: isSelected ? color : Colors.grey[600],
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsList(List<Events> events, String emptyMessage) {
    return RefreshIndicator(
      onRefresh: _initialize,
      child: events.isEmpty
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
                    emptyMessage,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              itemCount: events.length,
              itemBuilder: (context, index) => _buildEventCard(events[index]),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final upcomingEvents = _getUpcomingEvents();
    final activeEvents = _getActiveEvents();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.blue[700],
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: Colors.blue[700],
            indicatorWeight: 3,
            tabs: const [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.radio_button_checked, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Active Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Upcoming',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEventsList(activeEvents, 'No active events'),
          _buildEventsList(upcomingEvents, 'No upcoming events'),
        ],
      ),
    );
  }
}
