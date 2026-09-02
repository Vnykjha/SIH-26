import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../models/mobility_test_result.dart';
import '../models/patient.dart';
import '../models/questionnaire_response.dart';
import '../models/screening.dart';
import '../services/database_service.dart';
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

enum SensorRecordingState { idle, countdown, recording, finished }

class _MobilityTestScreenState extends State<MobilityTestScreen> {
  TestType _testType = TestType.phoneOnly;
  TestVariant _testVariant = TestVariant.timedUpAndGo;

  // Sensor recording states
  SensorRecordingState _recordingState = SensorRecordingState.idle;
  int _countdownSeconds = 3;
  double _elapsedSeconds = 0.0;
  Timer? _recordingTimer;
  StreamSubscription<UserAccelerometerEvent>? _accelSubscription;
  StreamSubscription<AccelerometerEvent>? _rawAccelSubscription;

  // Collected sensor data points (acceleration magnitude in m/s^2)
  final List<double> _magnitudes = [];
  final List<double> _timestamps = [];
  double _currentMagnitude = 0.0;
  double _livePeakAccel = 0.0;

  // Calculated features
  double _calculatedDuration = 18.0;
  double _calculatedPeakAccel = 2.4;
  double _calculatedVariance = 0.75;
  double _calculatedCadence = 1.8;
  double _calculatedKineticEnergy = 12.0;

  // Manual fallback controllers
  late final TextEditingController _durationController;
  late final TextEditingController _peakAccelController;
  late final TextEditingController _varianceController;
  late final TextEditingController _cadenceController;
  late final TextEditingController _kineticController;

  bool _showManualInputs = false;
  bool _evaluating = false;

  @override
  void initState() {
    super.initState();
    _syncControllers();
  }

  void _syncControllers() {
    _durationController = TextEditingController(text: _calculatedDuration.toStringAsFixed(1));
    _peakAccelController = TextEditingController(text: _calculatedPeakAccel.toStringAsFixed(2));
    _varianceController = TextEditingController(text: _calculatedVariance.toStringAsFixed(2));
    _cadenceController = TextEditingController(text: _calculatedCadence.toStringAsFixed(2));
    _kineticController = TextEditingController(text: _calculatedKineticEnergy.toStringAsFixed(2));
  }

  void _updateControllers() {
    _durationController.text = _calculatedDuration.toStringAsFixed(1);
    _peakAccelController.text = _calculatedPeakAccel.toStringAsFixed(2);
    _varianceController.text = _calculatedVariance.toStringAsFixed(2);
    _cadenceController.text = _calculatedCadence.toStringAsFixed(2);
    _kineticController.text = _calculatedKineticEnergy.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _stopRecordingTimer();
    _accelSubscription?.cancel();
    _rawAccelSubscription?.cancel();
    _durationController.dispose();
    _peakAccelController.dispose();
    _varianceController.dispose();
    _cadenceController.dispose();
    _kineticController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    setState(() {
      _recordingState = SensorRecordingState.countdown;
      _countdownSeconds = 3;
      _magnitudes.clear();
      _timestamps.clear();
      _currentMagnitude = 0.0;
      _livePeakAccel = 0.0;
      _elapsedSeconds = 0.0;
    });

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 1) {
        setState(() => _countdownSeconds--);
      } else {
        timer.cancel();
        _startSensorRecording();
      }
    });
  }

  void _startSensorRecording() {
    setState(() {
      _recordingState = SensorRecordingState.recording;
      _elapsedSeconds = 0.0;
    });

    final startTime = DateTime.now();

    final double maxDuration = _testVariant == TestVariant.sitToStand ? 30.0 : 20.0;

    // Start timer for elapsed duration with auto-stop cutoff
    _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final elapsed = DateTime.now().difference(startTime).inMilliseconds / 1000.0;
      if (elapsed >= maxDuration) {
        setState(() {
          _elapsedSeconds = maxDuration;
        });
        _finishSensorRecording();
      } else {
        setState(() {
          _elapsedSeconds = elapsed;
        });
      }
    });

    // Try listening to userAccelerometer (excluding gravity)
    try {
      _accelSubscription = userAccelerometerEventStream().listen(
        (UserAccelerometerEvent event) {
          _processAccelSample(event.x, event.y, event.z, startTime);
        },
        onError: (err) {
          // Fallback to raw accelerometer if userAccelerometer is not supported
          _fallbackToRawAccelerometer(startTime);
        },
      );
    } catch (_) {
      _fallbackToRawAccelerometer(startTime);
    }
  }

  void _fallbackToRawAccelerometer(DateTime startTime) {
    _accelSubscription?.cancel();
    _rawAccelSubscription = accelerometerEventStream().listen((AccelerometerEvent event) {
      // Remove approximate 9.81 gravity vector
      final mag = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      final netMag = max(0.0, mag - 9.81);
      _processAccelSample(event.x, event.y, netMag, startTime);
    });
  }

  void _processAccelSample(double x, double y, double z, DateTime startTime) {
    final mag = sqrt(x * x + y * y + z * z);
    final now = DateTime.now().difference(startTime).inMilliseconds / 1000.0;

    if (mounted) {
      setState(() {
        _currentMagnitude = mag;
        if (mag > _livePeakAccel) _livePeakAccel = mag;
        _magnitudes.add(mag);
        _timestamps.add(now);
      });
    }
  }

  void _stopRecordingTimer() {
    _recordingTimer?.cancel();
    _accelSubscription?.cancel();
    _rawAccelSubscription?.cancel();
  }

  void _finishSensorRecording() {
    _stopRecordingTimer();

    if (_magnitudes.isEmpty) {
      // If no sensor data collected (e.g. running on desktop emulator without sensors)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No real-time sensor events detected (emulator mode). Using standard test metrics.'),
        ),
      );
      setState(() => _recordingState = SensorRecordingState.finished);
      return;
    }

    // Extract Features from recorded accelerometer stream
    final n = _magnitudes.length;
    final duration = _elapsedSeconds > 0.5 ? _elapsedSeconds : (_timestamps.isNotEmpty ? _timestamps.last : 1.0);
    final peak = _magnitudes.reduce(max);

    // Mean & Variance
    final mean = _magnitudes.reduce((a, b) => a + b) / n;
    double variance = 0.0;
    for (final mag in _magnitudes) {
      variance += (mag - mean) * (mag - mean);
    }
    variance = variance / n;

    // Cadence calculation (steps / peaks per second)
    int peakCount = 0;
    final threshold = mean + max(0.2, sqrt(variance) * 0.5);
    for (int i = 1; i < n - 1; i++) {
      if (_magnitudes[i] > threshold &&
          _magnitudes[i] > _magnitudes[i - 1] &&
          _magnitudes[i] > _magnitudes[i + 1]) {
        peakCount++;
      }
    }
    final cadence = (peakCount / max(1.0, duration)).clamp(0.2, 5.0);

    // Kinetic energy proxy: 0.5 * mean(mag^2)
    double sumSq = 0.0;
    for (final mag in _magnitudes) {
      sumSq += mag * mag;
    }
    final kinetic = 0.5 * (sumSq / n);

    setState(() {
      _calculatedDuration = double.parse(duration.toStringAsFixed(1));
      _calculatedPeakAccel = double.parse(peak.toStringAsFixed(2));
      _calculatedVariance = double.parse(variance.toStringAsFixed(2));
      _calculatedCadence = double.parse(cadence.toStringAsFixed(2));
      _calculatedKineticEnergy = double.parse(kinetic.toStringAsFixed(2));
      _updateControllers();
      _recordingState = SensorRecordingState.finished;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Recorded $n motion samples! Metrics calculated.')),
    );
  }

  Future<void> _runRiskPrediction() async {
    setState(() => _evaluating = true);

    try {
      final mobilityTest = MobilityTestResult(
        testType: _testType,
        testVariant: _testVariant,
        durationSeconds: double.tryParse(_durationController.text.trim()) ?? _calculatedDuration,
        peakAccel: double.tryParse(_peakAccelController.text.trim()) ?? _calculatedPeakAccel,
        accelVariance: double.tryParse(_varianceController.text.trim()) ?? _calculatedVariance,
        cadenceCps: double.tryParse(_cadenceController.text.trim()) ?? _calculatedCadence,
        kineticEnergy: double.tryParse(_kineticController.text.trim()) ?? _calculatedKineticEnergy,
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

      // Auto-save to offline SQLite database
      await DatabaseService.instance.insertScreening(screening);

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
        setState(() => _evaluating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Real-Time Mobility Test')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Test selection card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Test Selection', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<TestVariant>(
                      value: _testVariant,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Select Mobility Protocol',
                        prefixIcon: Icon(Icons.fitness_center),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: TestVariant.timedUpAndGo,
                          child: Text(
                            'Timed Up & Go (TUG)',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: TestVariant.sitToStand,
                          child: Text(
                            '30-Second Chair Sit-to-Stand',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      onChanged: _recordingState == SensorRecordingState.idle || _recordingState == SensorRecordingState.finished
                          ? (value) => setState(() => _testVariant = value ?? TestVariant.timedUpAndGo)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Live Motion Sensor Recording Console
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.vibration, size: 40, color: Colors.teal),
                    const SizedBox(height: 8),
                    Text(
                      'Live Accelerometer Sensor',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Wear/hold phone at waist or pocket while patient performs motion task',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),

                    // Recording States
                    if (_recordingState == SensorRecordingState.idle) ...[
                      ElevatedButton.icon(
                        onPressed: _startCountdown,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start Motion Recording'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        ),
                      ),
                    ] else if (_recordingState == SensorRecordingState.countdown) ...[
                      Column(
                        children: [
                          const Text('Get Ready! Place phone in pocket...', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: Colors.orange,
                            child: Text(
                              '$_countdownSeconds',
                              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ] else if (_recordingState == SensorRecordingState.recording) ...[
                      Column(
                        children: [
                          Builder(
                            builder: (context) {
                              final double maxDuration = _testVariant == TestVariant.sitToStand ? 30.0 : 20.0;
                              final double remaining = max(0.0, maxDuration - _elapsedSeconds);
                              final double progress = (_elapsedSeconds / maxDuration).clamp(0.0, 1.0);

                              return Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'RECORDING: ${_elapsedSeconds.toStringAsFixed(1)}s / ${maxDuration.toInt()}s',
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Time Remaining: ${remaining.toStringAsFixed(1)}s',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.teal),
                                  ),
                                  const SizedBox(height: 12),

                                  // Test Duration Progress Bar
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      backgroundColor: Colors.grey[200],
                                      color: Colors.teal[600],
                                      minHeight: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Live Accel: ${_currentMagnitude.toStringAsFixed(2)} m/s² | Peak: ${_livePeakAccel.toStringAsFixed(2)} m/s²',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  Text(
                                    _testVariant == TestVariant.sitToStand
                                        ? '⚡ Auto-stops automatically at 30.0 seconds'
                                        : '⚡ Auto-stops at 20.0 seconds (or tap Stop when finished)',
                                    style: TextStyle(fontSize: 11, color: Colors.grey[700], fontStyle: FontStyle.italic),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 20),

                          ElevatedButton.icon(
                            onPressed: _finishSensorRecording,
                            icon: const Icon(Icons.stop),
                            label: const Text('Stop Recording & Calculate'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[700],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            ),
                          ),
                        ],
                      ),
                    ] else if (_recordingState == SensorRecordingState.finished) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Motion features successfully recorded!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _startCountdown,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Re-record Motion Test'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Measured Features Summary Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Extracted Motion Metrics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        IconButton(
                          icon: Icon(_showManualInputs ? Icons.tune : Icons.edit_note),
                          tooltip: 'Adjust / Override values',
                          onPressed: () => setState(() => _showManualInputs = !_showManualInputs),
                        ),
                      ],
                    ),
                    const Divider(),
                    _buildMetricRow('Test Duration', '${_durationController.text} seconds', Icons.timer),
                    _buildMetricRow('Peak Acceleration', '${_peakAccelController.text} m/s²', Icons.speed),
                    _buildMetricRow('Acceleration Variance', _varianceController.text, Icons.show_chart),
                    _buildMetricRow('Cadence (Steps/sec)', '${_cadenceController.text} cps', Icons.directions_walk),
                    _buildMetricRow('Kinetic Energy Proxy', _kineticController.text, Icons.bolt),
                  ],
                ),
              ),
            ),

            // Optional Manual Overrides drawer
            if (_showManualInputs) ...[
              const SizedBox(height: 12),
              Card(
                color: Colors.grey[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Manual Override / Emulator Tuning', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _durationController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Duration (seconds)'),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _peakAccelController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Peak Acceleration (m/s²)'),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _varianceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Acceleration Variance'),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _cadenceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Cadence (steps/sec)'),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _kineticController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Kinetic Energy'),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton.icon(
              onPressed: _evaluating ? null : _runRiskPrediction,
              icon: _evaluating
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.analytics),
              label: const Text('Calculate OA Risk Level'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[800],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.teal[700]),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.grey)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
