import 'package:flutter/material.dart';

import '../models/risk_result.dart';
import '../models/screening.dart';
import '../services/database_service.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key, required this.screening});

  final Screening screening;

  Color _riskColor() {
    switch (screening.riskResult.riskLevel) {
      case RiskLevel.low:
        return Colors.green;
      case RiskLevel.medium:
        return Colors.orange;
      case RiskLevel.high:
        return Colors.red;
    }
  }

  Future<void> _saveScreening(BuildContext context) async {
    await DatabaseService.instance.insertScreening(screening);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Screening saved locally')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = screening.riskResult.riskLabel;

    return Scaffold(
      appBar: AppBar(title: const Text('Risk Result')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Risk level', style: TextStyle(fontSize: 18)),
                      const SizedBox(height: 12),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: _riskColor(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text('KL grade: ${screening.riskResult.klGrade ?? 'n/a'}'),
                      Text('Confidence: ${screening.riskResult.confidence.toStringAsFixed(3)}'),
                      Text('Mode: ${screening.riskResult.screeningMode.name}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Patient: ${screening.patient.name}'),
              Text('Age: ${screening.patient.age}'),
              Text('District: ${screening.patient.district}'),
              Text('WOMAC total: ${screening.questionnaire.totalWomacScore}'),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _saveScreening(context),
                      child: const Text('Save offline'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                      child: const Text('Finish'),
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
