import 'package:flutter/material.dart';

import '../models/patient.dart';
import '../models/risk_result.dart';
import '../models/screening.dart';
import '../services/database_service.dart';
import 'screening_history_screen.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({
    super.key,
    required this.screening,
    this.isSavedView = false,
  });

  final Screening screening;
  final bool isSavedView;

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isSavedView) {
      _autoSave();
    } else {
      _isSaved = true;
    }
  }

  Future<void> _autoSave() async {
    try {
      await DatabaseService.instance.insertScreening(widget.screening);
      if (mounted) {
        setState(() => _isSaved = true);
      }
    } catch (e) {
      debugPrint('Auto-save error: $e');
    }
  }

  Color _riskColor() {
    switch (widget.screening.riskResult.riskLevel) {
      case RiskLevel.low:
        return Colors.green[700]!;
      case RiskLevel.medium:
        return Colors.orange[800]!;
      case RiskLevel.high:
        return Colors.red[700]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screening = widget.screening;
    final risk = screening.riskResult;
    final patient = screening.patient;
    final questionnaire = screening.questionnaire;
    final mobility = screening.mobilityTest;

    return Scaffold(
      appBar: AppBar(
        title: const Text('OA Risk Clinical Report'),
        automaticallyImplyLeading: widget.isSavedView,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Saved Status Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _isSaved
                          ? 'Saved in Offline Database (ID: ${screening.screeningId.substring(0, 8)}...)'
                          : 'Saving to Offline Database...',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Main Risk Outcome Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PREDICTED OA RISK ASSESSMENT',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '${risk.riskLabel.toUpperCase()} RISK',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: _riskColor(),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _riskColor().withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _riskColor()),
                          ),
                          child: Text(
                            'KL Grade ${risk.klGrade ?? 0}',
                            style: TextStyle(color: _riskColor(), fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Model Confidence: ${(risk.confidence * 100).toStringAsFixed(1)}%'),
                        Text('Mode: ${risk.screeningMode.name.toUpperCase()}'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // AI Clinical Prediction Rationale / Explanation Card
            Card(
              elevation: 3,
              color: Colors.teal[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.teal[300]!),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.psychology, color: Colors.teal[800], size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'AI Risk Clinical Rationale & Explanation',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _generateClinicalExplanation(screening),
                      style: TextStyle(fontSize: 13, height: 1.4, color: Colors.teal[950]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // WOMAC Subscale Breakdown Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'WOMAC Symptom Subscales',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'Total: ${questionnaire.totalWomacScore} / 96',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Pain Subscale Gauge
                    _buildSubscaleBar(
                      'Pain Subscale',
                      questionnaire.painScore,
                      20,
                      Colors.red[700]!,
                      'Evaluates pain intensity during activities',
                    ),
                    const SizedBox(height: 12),

                    // Stiffness Subscale Gauge
                    _buildSubscaleBar(
                      'Stiffness Subscale',
                      questionnaire.stiffnessScore,
                      8,
                      Colors.orange[700]!,
                      'Evaluates joint stiffness after waking/resting',
                    ),
                    const SizedBox(height: 12),

                    // Physical Function Subscale Gauge
                    _buildSubscaleBar(
                      'Physical Function Limitation',
                      questionnaire.functionScore,
                      68,
                      Colors.blue[700]!,
                      'Evaluates mobility & daily activity difficulty',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Mobility Sensor & Biomechanical Biomarkers Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Biomechanical & Gait Biomarkers',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureTile(
                      'Body Mass Index (BMI)',
                      '${patient.bmi} kg/m²',
                      patient.bmi >= 25.0 ? 'Overweight — Adds mechanical joint load' : 'Normal weight range',
                      patient.bmi >= 25.0 ? Colors.orange[800]! : Colors.green[700]!,
                      Icons.monitor_weight_outlined,
                    ),
                    const Divider(),
                    _buildFeatureTile(
                      'Prior Injury History',
                      patient.priorInjuryHistory ? 'Yes (${patient.injuryNotes.isNotEmpty ? patient.injuryNotes : 'Reported'})' : 'None Reported',
                      patient.priorInjuryHistory ? 'Elevated secondary OA risk factor' : 'No prior structural trauma',
                      patient.priorInjuryHistory ? Colors.red[700]! : Colors.green[700]!,
                      Icons.healing_outlined,
                    ),
                    const Divider(),
                    _buildFeatureTile(
                      'Gait Cadence',
                      '${mobility.cadenceCps.toStringAsFixed(2)} steps/sec',
                      mobility.cadenceCps < 1.2 ? 'Reduced cadence (signaling gait hesitation/pain)' : 'Normal step frequency',
                      mobility.cadenceCps < 1.2 ? Colors.orange[800]! : Colors.green[700]!,
                      Icons.directions_walk,
                    ),
                    const Divider(),
                    _buildFeatureTile(
                      'Acceleration Variance',
                      mobility.accelVariance.toStringAsFixed(2),
                      mobility.accelVariance > 1.5 ? 'Elevated gait variance (indicates movement asymmetry)' : 'Smooth gait acceleration profile',
                      mobility.accelVariance > 1.5 ? Colors.orange[800]! : Colors.green[700]!,
                      Icons.show_chart,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Patient Information Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Patient & Intake Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text('Name: ${patient.name}'),
                    Text('Age / Gender: ${patient.age} yrs • ${patient.sex.name.toUpperCase()}'),
                    Text('Occupation: ${patient.occupation.isNotEmpty ? patient.occupation : 'Not specified'}'),
                    Text('Height / Weight: ${patient.heightCm} cm • ${patient.weightKg} kg'),
                    Text('District / Camp: ${patient.district} (Camp ${patient.campId})'),
                    Text('Preferred Language: ${patient.preferredLanguage.toUpperCase()}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Navigation Buttons
            Row(
              children: [
                if (!widget.isSavedView) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ScreeningHistoryScreen()),
                        );
                      },
                      icon: const Icon(Icons.history),
                      label: const Text('View All Saved'),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                    icon: const Icon(Icons.home),
                    label: const Text('Return Home'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _generateClinicalExplanation(Screening screening) {
    final patient = screening.patient;
    final q = screening.questionnaire;
    final m = screening.mobilityTest;
    final risk = screening.riskResult;

    final buffer = StringBuffer();

    switch (risk.riskLevel) {
      case RiskLevel.high:
        buffer.writeln('⚠️ HIGH OSTEOARTHRITIS RISK FACTORS IDENTIFIED:');
        if (q.totalWomacScore >= 40) {
          buffer.writeln('• WOMAC Symptom Burden: High total score of ${q.totalWomacScore}/96 (Pain: ${q.painScore}/20, Function Limitation: ${q.functionScore}/68), indicating significant joint discomfort and activity restriction.');
        } else {
          buffer.writeln('• WOMAC Symptom Burden: Moderate total score of ${q.totalWomacScore}/96.');
        }

        if (patient.age >= 55) {
          buffer.writeln('• Age Biomarker: Age ${patient.age} falls in the primary demographic window for age-related articular cartilage degeneration.');
        }
        if (patient.bmi >= 25.0) {
          buffer.writeln('• Biomechanical Load: Elevated BMI (${patient.bmi} kg/m²) increases compressive forces on knee joint cartilage during stance phase.');
        }
        if (patient.priorInjuryHistory) {
          buffer.writeln('• Structural Risk: History of prior knee injury increases secondary post-traumatic OA risk.');
        }
        if (m.cadenceCps < 1.2) {
          buffer.writeln('• Gait Biomarker: Low gait cadence (${m.cadenceCps.toStringAsFixed(1)} steps/sec) reflects guarded gait compensation or pain during movement.');
        }
        buffer.write('Recommendation: Referral for clinical X-ray evaluation and orthopedic consultation.');
        break;

      case RiskLevel.medium:
        buffer.writeln('⚡ MODERATE OSTEOARTHRITIS RISK FACTORS:');
        buffer.writeln('• WOMAC Symptom Burden: Moderate score of ${q.totalWomacScore}/96 (Pain: ${q.painScore}/20, Function: ${q.functionScore}/68).');
        if (patient.bmi >= 25.0) {
          buffer.writeln('• Weight Factor: BMI of ${patient.bmi} kg/m² contributes to joint stress.');
        }
        if (m.cadenceCps < 1.5) {
          buffer.writeln('• Mobility Feature: Cadence of ${m.cadenceCps.toStringAsFixed(1)} steps/sec shows mild gait slowing.');
        }
        buffer.write('Recommendation: Quadriceps strengthening exercises, weight management, and follow-up screening in 6 months.');
        break;

      case RiskLevel.low:
        buffer.writeln('✅ LOW OSTEOARTHRITIS RISK PROFILE:');
        buffer.writeln('• WOMAC Symptom Burden: Minimal score of ${q.totalWomacScore}/96 (Pain: ${q.painScore}/20, Function: ${q.functionScore}/68), indicating healthy joint function.');
        buffer.writeln('• Gait Biomarker: Normal gait cadence (${m.cadenceCps.toStringAsFixed(1)} steps/sec) and movement acceleration.');
        buffer.write('Recommendation: Maintain regular physical activity and joint-friendly exercise routines.');
        break;
    }

    return buffer.toString();
  }

  Widget _buildSubscaleBar(String title, int score, int maxScore, Color color, String description) {
    final fraction = (score / maxScore).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text(
              '$score / $maxScore',
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            backgroundColor: Colors.grey[200],
            color: color,
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 2),
        Text(description, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
      ],
    );
  }

  Widget _buildFeatureTile(String title, String value, String description, Color badgeColor, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 22, color: badgeColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(description, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: badgeColor, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
