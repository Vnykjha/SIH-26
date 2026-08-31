import 'package:flutter/material.dart';

import '../models/risk_result.dart';
import '../models/screening.dart';
import '../services/database_service.dart';

class ScreeningHistoryScreen extends StatefulWidget {
  const ScreeningHistoryScreen({super.key});

  @override
  State<ScreeningHistoryScreen> createState() => _ScreeningHistoryScreenState();
}

class _ScreeningHistoryScreenState extends State<ScreeningHistoryScreen> {
  late Future<List<Screening>> _screeningsFuture;

  @override
  void initState() {
    super.initState();
    _screeningsFuture = DatabaseService.instance.getAllScreenings();
  }

  Future<void> _reload() async {
    setState(() {
      _screeningsFuture = DatabaseService.instance.getAllScreenings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved screenings'),
      ),
      body: FutureBuilder<List<Screening>>(
        future: _screeningsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Could not load screenings: ${snapshot.error}'),
            );
          }

          final screenings = snapshot.data ?? const <Screening>[];

          if (screenings.isEmpty) {
            return const Center(
              child: Text('No saved screenings yet.'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: screenings.length,
              itemBuilder: (context, index) {
                final screening = screenings[index];
                final risk = screening.riskResult;
                final riskColor = switch (risk.riskLevel) {
                  RiskLevel.low => Colors.green,
                  RiskLevel.medium => Colors.orange,
                  RiskLevel.high => Colors.red,
                };

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: riskColor.withOpacity(0.15),
                      child: Text(
                        risk.riskLabel.substring(0, 1),
                        style: TextStyle(
                          color: riskColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(screening.patient.name),
                    subtitle: Text(
                      '${screening.patient.age} yrs • ${screening.patient.district} • ${screening.createdAt.toLocal().toString().split(' ')[0]}',
                    ),
                    trailing: Text(
                      risk.riskLabel,
                      style: TextStyle(
                        color: riskColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
