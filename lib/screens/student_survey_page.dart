import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../models/events.dart';
import '../../models/survey.dart';

class StudentSurveyPage extends StatefulWidget {
  const StudentSurveyPage({Key? key}) : super(key: key);

  @override
  _StudentSurveyPageState createState() => _StudentSurveyPageState();
}

class _StudentSurveyPageState extends State<StudentSurveyPage> {
  bool _isLoading = true;
  List<Events> _recentEvents = [];
  List<Survey> _surveys = [];
  Map<String, Map<String, dynamic>> _responses = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final now = DateTime.now();

      // Debug: Print current date
      debugPrint('Loading events for ${now.month}/${now.year}');

      final events = await authProvider.fetchEvents(now.month, now.year);

      // Debug: Print fetched events
      debugPrint(
          'Fetched events count: ${events.values.expand((x) => x).length}');

      // Get event IDs
      final eventIds = events.values
          .expand((list) => list)
          .map((e) => e.id.toString())
          .toList();

      // Debug: Print event IDs
      debugPrint('Event IDs to check: $eventIds');

      // Get user's responses
      final userResponses = await authProvider.getUserEventResponses(eventIds);

      // Debug: Print user responses
      debugPrint('User responses: $userResponses');

      // Debug: Print all events before filtering
      debugPrint('\nAll events before filtering:');
      events.values.expand((list) => list).forEach((event) {
        debugPrint(
            'Event ${event.id}: Status=${event.status}, Title=${event.title}');
      });

// Debug user responses more explicitly
      debugPrint('\nUser responses detail:');
      eventIds.forEach((eventId) {
        debugPrint('Event $eventId: Response=${userResponses[eventId]}');
      });

      /* List<Events> recentEvents = [];
      for (var eventList in events.values) {
        for (var event in eventList) {
          debugPrint('\nDetailed event check:');
          debugPrint('Event ID: ${event.id}');
          debugPrint('Event Title: ${event.title}');
          debugPrint('Event Status: ${event.status}');
          debugPrint('User Response: ${userResponses[event.id.toString()]}');

          final isGoing = userResponses[event.id.toString()] == 'Going';
          final isPublished = event.status == 'published';

          debugPrint('Is Going: $isGoing');
          debugPrint('Is Published: $isPublished');

          if (isGoing && isPublished) {
            debugPrint('✓ Adding event to recent events');
            recentEvents.add(event);
          } else {
            debugPrint('✗ Skipping event. Failed criteria:');
            if (!isGoing) debugPrint('  - User is not "Going"');
            if (!isPublished) debugPrint('  - Event is not published');
          }
        }
      } */

      // Inside _loadData() in StudentSurveyPage
      List<Events> recentEvents = [];
      for (var eventList in events.values) {
        for (var event in eventList) {
          debugPrint('\nChecking event: ${event.id} - ${event.title}');
          debugPrint('Status: ${event.status}');

          if (event.status == 'published') {
            debugPrint('✓ Adding published event to recent events');
            recentEvents.add(event);
          } else {
            debugPrint('✗ Event not added - not published');
          }
        }
      }

      // Debug: Print recent events count
      debugPrint('\nFiltered recent events count: ${recentEvents.length}');

      // Fetch surveys
      final surveys = await authProvider.fetchSurveys();

      // Debug: Print surveys
      debugPrint('\nFetched surveys count: ${surveys.length}');
      for (var survey in surveys) {
        debugPrint('Survey ID: ${survey.id}, Event ID: ${survey.eventId}');
      }

      setState(() {
        _recentEvents = recentEvents;
        _surveys = surveys;
        _isLoading = false;
      });

      // Debug final state
      debugPrint('\nFinal state:');
      debugPrint('Recent events count: ${_recentEvents.length}');
      debugPrint('Surveys count: ${_surveys.length}');

      // Debug available surveys logic
      final availableSurveys = _surveys.where((survey) {
        final hasMatchingEvent = _recentEvents
            .any((event) => event.id.toString() == survey.eventId.toString());
        debugPrint('Survey ${survey.id} has matching event: $hasMatchingEvent');
        return hasMatchingEvent;
      }).toList();

      debugPrint('Available surveys count: ${availableSurveys.length}');
    } catch (e, stackTrace) {
      debugPrint('Error loading data: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _submitSurveyResponse(Survey survey) async {
    try {
      final answers = _responses[survey.id.toString()] ?? {};
      await context
          .read<AuthProvider>()
          .submitSurveyResponse(survey.id, answers);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Survey submitted successfully')),
      );
      _loadData(); // Reload to update status
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting survey: $e')),
      );
    }
  }

  Widget _buildQuestionWidget(Map<String, dynamic> question, String surveyId) {
    final questionId = question['id']?.toString() ?? '';

    switch (question['type']) {
      case 'multiple_choice':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(question['question'],
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...(question['options'] as List).map((option) {
              return RadioListTile<String>(
                title: Text(option),
                value: option,
                groupValue: _responses[surveyId]?[questionId],
                onChanged: (value) {
                  setState(() {
                    _responses[surveyId] = _responses[surveyId] ?? {};
                    _responses[surveyId]![questionId] = value;
                  });
                },
              );
            }).toList(),
          ],
        );

      case 'text':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(question['question'],
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              onChanged: (value) {
                setState(() {
                  _responses[surveyId] = _responses[surveyId] ?? {};
                  _responses[surveyId]![questionId] = value;
                });
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter your answer',
              ),
            ),
          ],
        );

      case 'rating':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(question['question'],
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                return InkWell(
                  onTap: () {
                    setState(() {
                      _responses[surveyId] = _responses[surveyId] ?? {};
                      _responses[surveyId]![questionId] =
                          (index + 1).toString();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _responses[surveyId]?[questionId] ==
                              (index + 1).toString()
                          ? Colors.blue
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      (index + 1).toString(),
                      style: TextStyle(
                        color: _responses[surveyId]?[questionId] ==
                                (index + 1).toString()
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSurveyCard(Survey survey) {
    final event = survey.event;
    if (event == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(8),
      child: ExpansionTile(
        title: Text(survey.title),
        subtitle: Text('Event: ${event.title}'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(survey.description),
                const SizedBox(height: 16),
                ...survey.questions.map((question) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildQuestionWidget(question, survey.id.toString()),
                  );
                }).toList(),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _submitSurveyResponse(survey),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 21, 0, 141),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Submit Survey'),
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final availableSurveys = _surveys.where((survey) {
      return _recentEvents
          .any((event) => event.id.toString() == survey.eventId.toString());
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (availableSurveys.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No surveys available for recent events',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          )
        else
          ...availableSurveys.map((survey) => _buildSurveyCard(survey)),
      ],
    );
  }
}
