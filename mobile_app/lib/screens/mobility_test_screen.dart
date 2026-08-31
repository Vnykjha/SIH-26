import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../models/mobility_test_result.dart';
import '../models/patient.dart';
import '../models/questionnaire_response.dart';
import '../models/screening.dart';
import '../services/accelerometer_feature_extractor.dart';
import '../services/ml_inference_service.dart';
import 'results_screen.dart';

class MobilityTestScreen extends StatefulWidget {
  const MobilityTestScreen({
    super.key,
    required this.patient,
    required this.questionnaire,
  });

  final Patient patient;
  final QuestionnaireResponse questionnaire;

  @override
  State<MobilityTestScreen> createState() => _MobilityTestScreenState();
}

class _MobilityTestScreenState extends State<MobilityTestScreen> {
  TestType _testType = TestType.phoneOnly;
  TestVariant _testVariant = TestVariant.timedUpAndGo;

  final TextEditingController _durationController = TextEditingController(text: '15');
  final List<AccelReading> _samples = <AccelReading>[];
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  bool _recording = false;
  bool _loading = false;
  bool _hasRecordedSamples = false;

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _durationController.dispose();
    super.dispose();
  }

  void _startRecording() {
    _samples.clear();
    _hasRecordedSamples = false;

    _accelerometerSubscription = accelerometerEvents.listen((event) {
      if (!_recording) return;

      final sample = AccelReading(
        x: event.x,
        y: event.y,
        z: event.z,
        timestampMs: DateTime.now().millisecondsSinceEpoch,
      );

      _samples.add(sample);
    });

    setState(() {
      _recording = true;
    });

    final durationSeconds = double.tryParse(_durationController.text.trim()) ?? 15.0;
    Future.delayed(Duration(seconds: durationSeconds.ceil()), () {
      if (mounted && _recording) {
        _stopRecording();
      }
    });
  }

  Future<void> _stopRecording() async {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;

    if (!mounted) return;

    setState(() {
      _recording = false;
      _hasRecordedSamples = _samples.isNotEmpty;
    });

    if (_samples.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No accelerometer samples captured. Please try again.')),
      );
      return;
    }

    await _runTestFromSamples();
  }

  Future<void> _runTestFromSamples() async {
    setState(() => _loading = true);

    try {
      final features = AccelerometerFeatureExtractor.extract(_samples);

      final mobilityTest = MobilityTestResult(
        testType: _testType,
        testVariant: _testVariant,
        durationSeconds: features.durationSeconds,
        peakAccel: features.peakAccel,
        accelVariance: features.accelVariance,
        cadenceCps: features.cadenceCps,
        kineticEnergy: features.kineticEnergy,
      );

      final riskResult = await MLInferenceService.predictRisk(
        patient: widget.patient,
        questionnaire: widget.questionnaire,
        mobilityTest: mobilityTest,
      );

      final screening = Screening(
        patient: widget.patient,
        questionnaire: widget.questionnaire,
        mobilityTest: mobilityTest,
        riskResult: riskResult,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultsScreen(screening: screening),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Model evaluation failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mobility Test')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Phone mobility test',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hold the phone steadily in the correct test position and tap start. The app will record accelerometer data automatically.',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TestType>(
              value: _testType,
              decoration: const InputDecoration(labelText: 'Test type'),
              items: TestType.values
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(value.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _testType = value ?? TestType.phoneOnly),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<TestVariant>(
              value: _testVariant,
              decoration: const InputDecoration(labelText: 'Test variant'),
              items: TestVariant.values
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(value.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _testVariant = value ?? TestVariant.timedUpAndGo),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _durationController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Duration in seconds'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading || _recording ? null : _startRecording,
              child: _recording
                  ? const Text('Recording...')
                  : const Text('Start phone mobility test'),
            ),
            if (_hasRecordedSamples) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Captured ${_samples.length} accelerometer readings. Ready for inference.',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
