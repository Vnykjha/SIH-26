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
  bool _guidelinesExpanded = false;
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
      if (!mounted) {
        timer.cancel();
        return;
      }
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
      if (!mounted) return;
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
    const darkText = Color(0xFF243845);
    const brandTeal = Color(0xFF1D7D8D);
    const lightTeal = Color(0xFFE7F3F6);
    const border = Color(0xFFB9D6D7);
    const danger = Color(0xFFEA6A5A);

    return Scaffold(
      backgroundColor: const Color(0xFFEFF4F5),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Mobility Test',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: darkText,
                      letterSpacing: -1.0,
                    ),
                  ),
                ),
                Container(
                  width: 110,
                  height: 8,
                  decoration: BoxDecoration(
                    color: brandTeal,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Step 3 of 3',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7F7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: border),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: _recordingState == SensorRecordingState.idle || _recordingState == SensorRecordingState.finished
                          ? () => setState(() => _testVariant = TestVariant.sitToStand)
                          : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          color: _testVariant == TestVariant.sitToStand ? lightTeal : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _testVariant == TestVariant.sitToStand ? brandTeal : border),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.access_time_filled_rounded, color: brandTeal, size: 24),
                            const SizedBox(width: 10),
                            const Text(
                              '30-sec Sit-to-Stand',
                              style: TextStyle(
                                color: darkText,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            const Text('30s', style: TextStyle(color: darkText, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: _recordingState == SensorRecordingState.idle || _recordingState == SensorRecordingState.finished
                          ? () => setState(() => _testVariant = TestVariant.timedUpAndGo)
                          : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          color: _testVariant == TestVariant.timedUpAndGo ? lightTeal : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _testVariant == TestVariant.timedUpAndGo ? brandTeal : border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.directions_walk_rounded, color: darkText, size: 24),
                            const SizedBox(width: 10),
                            const Text(
                              'Timed Up & Go',
                              style: TextStyle(
                                color: darkText,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: border),
                              ),
                              child: const Text('TUG', style: TextStyle(color: darkText, fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(color: danger, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'RECORDING PROTOCOL',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: darkText,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Place phone in front pocket',
                        style: TextStyle(fontSize: 12, color: Color(0xFF607680)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (_recordingState == SensorRecordingState.idle) ...[
                    Column(
                      children: [
                        SizedBox(
                          width: 190,
                          height: 190,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 190,
                                height: 190,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: brandTeal.withOpacity(0.5), width: 6),
                                ),
                              ),
                              Container(
                                width: 124,
                                height: 124,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Text(
                                '${_elapsedSeconds.toStringAsFixed(1)}s',
                                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: darkText),
                              ),
                              Positioned(
                                bottom: 48,
                                child: Text(
                                  'Elapsed',
                                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton.icon(
                          onPressed: _startCountdown,
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Start Recording'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: brandTeal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 180,
                            height: 180,
                            child: CircularProgressIndicator(
                              value: _recordingState == SensorRecordingState.recording ? (_elapsedSeconds / (_testVariant == TestVariant.sitToStand ? 30.0 : 20.0)).clamp(0.0, 1.0) : 1.0,
                              strokeWidth: 12,
                              valueColor: const AlwaysStoppedAnimation<Color>(brandTeal),
                              backgroundColor: Colors.grey[200],
                            ),
                          ),
                          Text(
                            '${_elapsedSeconds.toStringAsFixed(1)}s',
                            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: darkText),
                          ),
                          Positioned(
                            bottom: 32,
                            child: Text(
                              'Elapsed',
                              style: TextStyle(color: Colors.grey[700], fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: lightTeal,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'LIVE ACCELEROMETER Z-AXIS (m/s²)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: Color(0xFF3F5E6B),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: border),
                          ),
                          child: CustomPaint(
                            painter: _LineChartPainter(List<double>.from(_magnitudes)),
                            child: const SizedBox.expand(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Auto-stops at 30.0s • Minimum 5 reps required',
                          style: TextStyle(color: Color(0xFF536B75), fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _recordingState == SensorRecordingState.recording
                                ? _finishSensorRecording
                                : null,
                            icon: const Icon(Icons.stop_circle_outlined),
                            label: const Text('Stop Early (Save Partial)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFDEAE7),
                              foregroundColor: const Color(0xFFD26A5A),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7F7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border),
              ),
              child: ExpansionTile(
                initiallyExpanded: _guidelinesExpanded,
                onExpansionChanged: (expanded) => setState(() => _guidelinesExpanded = expanded),
                title: const Text(
                  'TEST PROTOCOL GUIDELINES',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: darkText),
                ),
                children: const [
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      'Place the phone securely in the front pocket. Follow the selected test protocol and keep the phone upright during the movement.',
                      style: TextStyle(color: Color(0xFF536B75), height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (_recordingState == SensorRecordingState.finished)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _evaluating ? null : _runRiskPrediction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    _evaluating ? 'Calculating...' : 'Calculate OA Risk Level',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),
              )
            else
              const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter(this.samples);

  final List<double> samples;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1D7D8D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final path = Path();
    if (samples.isEmpty) {
      path.moveTo(0, size.height * 0.7);
      path.lineTo(size.width, size.height * 0.7);
      canvas.drawPath(path, paint);
      return;
    }

    final minimum = samples.reduce(min);
    final maximum = samples.reduce(max);
    final range = max(0.1, maximum - minimum);
    for (var index = 0; index < samples.length; index++) {
      final x = samples.length == 1 ? 0.0 : size.width * index / (samples.length - 1);
      final y = size.height - ((samples[index] - minimum) / range * size.height * 0.8) - size.height * 0.1;
      if (index == 0) {
        path.moveTo(x, y.clamp(0.0, size.height));
      } else {
        path.lineTo(x, y.clamp(0.0, size.height));
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) => oldDelegate.samples != samples;
}
