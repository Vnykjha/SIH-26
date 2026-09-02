import 'package:flutter/material.dart';

import '../models/risk_result.dart';
import '../models/screening.dart';
import '../services/database_service.dart';
import 'results_screen.dart';

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
    _reload();
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
        title: const Text('Saved Screenings History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
            tooltip: 'Refresh list',
          ),
        ],
      ),
      body: FutureBuilder<List<Screening>>(
        future: _screeningsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Could not load screenings: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          final screenings = snapshot.data ?? const <Screening>[];

          if (screenings.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'No saved screenings yet.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Completed patient screenings will automatically appear here.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: screenings.length,
              itemBuilder: (context, index) {
                final screening = screenings[index];
                final risk = screening.riskResult;
                final riskColor = switch (risk.riskLevel) {
                  RiskLevel.low => Colors.green[700]!,
                  RiskLevel.medium => Colors.orange[800]!,
                  RiskLevel.high => Colors.red[700]!,
                };

                final dateStr = screening.createdAt.toLocal().toString().split('.')[0];

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: riskColor.withOpacity(0.15),
                      child: Text(
                        risk.riskLabel.substring(0, 1),
                        style: TextStyle(
                          color: riskColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            screening.patient.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: riskColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${risk.riskLabel} Risk (KL ${risk.klGrade ?? 0})',
                            style: TextStyle(
                              color: riskColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${screening.patient.age} yrs • ${screening.patient.sex.name} • ${screening.patient.district}',
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'WOMAC: ${screening.questionnaire.totalWomacScore}/96 | Mobility Cadence: ${screening.mobilityTest.cadenceCps.toStringAsFixed(1)} cps',
                            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Screened: $dateStr',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ResultsScreen(
                            screening: screening,
                            isSavedView: true,
                          ),
                        ),
                      );
                    },
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
