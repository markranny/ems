import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../models/survey.dart';

class SurveyResponsePage extends StatelessWidget {
  final Survey survey;

  const SurveyResponsePage({Key? key, required this.survey}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Survey Responses'),
        backgroundColor: const Color.fromARGB(255, 21, 0, 141),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder(
        future: context.read<AuthProvider>().getSurveyResponses(survey.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final responses = snapshot.data as List<Map<String, dynamic>>;

          return ListView.builder(
            itemCount: responses.length,
            itemBuilder: (context, index) {
              final response = responses[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ExpansionTile(
                  title: Text('Response #${index + 1}'),
                  subtitle: Text('By: ${response['user']['email']}'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: (response['answers'] as Map<String, dynamic>)
                            .entries
                            .map((entry) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.key,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(entry.value.toString()),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
