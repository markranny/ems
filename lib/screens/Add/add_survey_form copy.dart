import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../models/events.dart';

class AddSurveyForm extends StatefulWidget {
  const AddSurveyForm({Key? key}) : super(key: key);

  @override
  _AddSurveyFormState createState() => _AddSurveyFormState();
}

class _AddSurveyFormState extends State<AddSurveyForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  Events? _selectedEvent;
  List<Map<String, dynamic>> _questions = [];
  bool _isLoading = false;
  List<Events> _events = [];
  bool _loadingEvents = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    try {
      final year = DateTime.now().year;
      final month = DateTime.now().month;
      final events =
          await context.read<AuthProvider>().fetchEvents(month, year);

      setState(() {
        // Convert the Map<DateTime, List<Events>> to a flat List<Events>
        _events = events.values.expand((eventList) => eventList).toList();
        _loadingEvents = false;
      });
    } catch (e) {
      setState(() {
        _loadingEvents = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading events: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addQuestion() {
    setState(() {
      _questions.add({
        'question': '',
        'type': 'multiple_choice',
        'options': <String>[],
        'required': true,
      });
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  void _addOption(int questionIndex) {
    setState(() {
      if (_questions[questionIndex]['options'] == null) {
        _questions[questionIndex]['options'] = <String>[];
      }
      _questions[questionIndex]['options'].add('');
    });
  }

  void _removeOption(int questionIndex, int optionIndex) {
    setState(() {
      _questions[questionIndex]['options'].removeAt(optionIndex);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedEvent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an event'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one question'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate questions
    for (var i = 0; i < _questions.length; i++) {
      final question = _questions[i];
      if (question['question'].toString().trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Question ${i + 1} text is required'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (question['type'] == 'multiple_choice') {
        final options = question['options'] as List;
        if (options.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Question ${i + 1} needs at least one option'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        for (var option in options) {
          if (option.toString().trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Question ${i + 1} has empty options'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
        }
      }
    }

    setState(() => _isLoading = true);

    try {
      final surveyData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'event_id': _selectedEvent!.id,
        'questions': _questions,
      };

      await context.read<AuthProvider>().createSurvey(surveyData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Survey created successfully'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating survey: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 21, 0, 141),
        title: const Text('Create Survey'),
      ),
      body: _loadingEvents
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Survey Title',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Title is required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (value) => value?.isEmpty ?? true
                        ? 'Description is required'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Events>(
                    value: _selectedEvent,
                    decoration: const InputDecoration(
                      labelText: 'Select Event',
                      border: OutlineInputBorder(),
                    ),
                    items: _events.map((event) {
                      return DropdownMenuItem(
                        value: event,
                        child: Text(event.title),
                      );
                    }).toList(),
                    onChanged: (Events? value) {
                      setState(() {
                        _selectedEvent = value;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Questions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _addQuestion,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Question'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 21, 0, 141),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ..._questions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final question = entry.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Question ${index + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  color: Colors.red,
                                  onPressed: () => _removeQuestion(index),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              initialValue: question['question'],
                              decoration: const InputDecoration(
                                labelText: 'Question Text',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _questions[index]['question'] = value;
                                });
                              },
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: question['type'],
                              decoration: const InputDecoration(
                                labelText: 'Question Type',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'multiple_choice',
                                  child: Text('Multiple Choice'),
                                ),
                                DropdownMenuItem(
                                  value: 'text',
                                  child: Text('Text Response'),
                                ),
                                DropdownMenuItem(
                                  value: 'rating',
                                  child: Text('Rating (1-5)'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _questions[index]['type'] = value;
                                  if (value == 'multiple_choice') {
                                    _questions[index]['options'] = [];
                                  } else {
                                    _questions[index].remove('options');
                                  }
                                });
                              },
                            ),
                            if (question['type'] == 'multiple_choice') ...[
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Options',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => _addOption(index),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add Option'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ...(question['options'] as List<String>)
                                  .asMap()
                                  .entries
                                  .map((option) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          initialValue: option.value,
                                          decoration: InputDecoration(
                                            labelText:
                                                'Option ${option.key + 1}',
                                            border: const OutlineInputBorder(),
                                          ),
                                          onChanged: (value) {
                                            setState(() {
                                              _questions[index]['options']
                                                  [option.key] = value;
                                            });
                                          },
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle),
                                        color: Colors.red,
                                        onPressed: () =>
                                            _removeOption(index, option.key),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Checkbox(
                                  value: question['required'] ?? true,
                                  onChanged: (value) {
                                    setState(() {
                                      _questions[index]['required'] = value;
                                    });
                                  },
                                ),
                                const Text('Required'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 21, 0, 141),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Create Survey',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
