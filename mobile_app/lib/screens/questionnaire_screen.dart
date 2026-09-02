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

  Widget _buildSectionHeader(String title, String subtitle, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
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
        title: const Text('WOMAC Questionnaire'),
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: QuestionnaireResponse.standardWomacQuestions.length + 1,
          itemBuilder: (context, index) {
            if (index == QuestionnaireResponse.standardWomacQuestions.length) {
              return Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 28),
                child: ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.directions_run),
                  label: const Text('Continue to Mobility Sensor Test'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              );
            }

            final question = QuestionnaireResponse.standardWomacQuestions[index];
            final value = _responses[index];

            Widget? header;
            if (index == 0) {
              header = _buildSectionHeader(
                'SECTION 1: PAIN SUBSCALE (Q1 - Q5)',
                'Rate the intensity of PAIN felt during each activity',
                Icons.sick_outlined,
                Colors.red[700]!,
              );
            } else if (index == 5) {
              header = _buildSectionHeader(
                'SECTION 2: STIFFNESS SUBSCALE (Q6 - Q7)',
                'Rate joint STIFFNESS after waking or resting',
                Icons.accessibility_new,
                Colors.orange[700]!,
              );
            } else if (index == 7) {
              header = _buildSectionHeader(
                'SECTION 3: PHYSICAL FUNCTION (Q8 - Q24)',
                'Rate the DIFFICULTY / LIMITATION experienced',
                Icons.directions_walk,
                Colors.teal[700]!,
              );
            }

            final card = Card(
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
                    Text(
                      question.description,
                      style: TextStyle(color: Colors.grey[800]),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      initialValue: value,
                      decoration: const InputDecoration(
                        labelText: 'Severity Rating',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('0 — None (No symptoms/difficulty)')),
                        DropdownMenuItem(value: 1, child: Text('1 — Mild')),
                        DropdownMenuItem(value: 2, child: Text('2 — Moderate')),
                        DropdownMenuItem(value: 3, child: Text('3 — Severe')),
                        DropdownMenuItem(value: 4, child: Text('4 — Extreme / Unable')),
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

            if (header != null) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [header, card],
              );
            }

            return card;
          },
        ),
      ),
    );
  }
}
