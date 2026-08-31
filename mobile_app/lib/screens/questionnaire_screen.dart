import 'package:flutter/material.dart';

import '../models/patient.dart';
import '../models/questionnaire_response.dart';
import 'mobility_test_screen.dart';

class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({super.key, required this.patient});

  final Patient patient;

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  late final List<int> _responses;

  @override
  void initState() {
    super.initState();
    _responses = List<int>.filled(QuestionnaireResponse.standardWomacQuestions.length, 0);
  }

  void _submit() {
    final questionnaire = QuestionnaireResponse(responsesRaw: _responses);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MobilityTestScreen(
          patient: widget.patient,
          questionnaire: questionnaire,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WOMAC / KOOS questionnaire'),
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: QuestionnaireResponse.standardWomacQuestions.length + 1,
          itemBuilder: (context, index) {
            if (index == QuestionnaireResponse.standardWomacQuestions.length) {
              return Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 28),
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Continue to mobility test'),
                ),
              );
            }

            final question = QuestionnaireResponse.standardWomacQuestions[index];
            final value = _responses[index];

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${index + 1}. ${question.title}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(question.description),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: value,
                      decoration: const InputDecoration(labelText: 'Score'),
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('0 - none')),
                        DropdownMenuItem(value: 1, child: Text('1 - mild')),
                        DropdownMenuItem(value: 2, child: Text('2 - moderate')),
                        DropdownMenuItem(value: 3, child: Text('3 - severe')),
                        DropdownMenuItem(value: 4, child: Text('4 - extreme')),
                      ],
                      onChanged: (selected) {
                        if (selected == null) return;
                        setState(() => _responses[index] = selected);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
