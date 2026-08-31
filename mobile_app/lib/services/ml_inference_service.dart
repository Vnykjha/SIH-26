import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/patient.dart';
import '../models/questionnaire_response.dart';
import '../models/mobility_test_result.dart';
import '../models/risk_result.dart';

class MLInferenceService {
  static const String modelVersion = 'v1.0.0-tflite';

  static Interpreter? _interpreter;
  static List<double>? _scalerMean;
  static List<double>? _scalerScale;

  static Future<void> initialize() async {
    if (_interpreter != null) return;

    final modelData = await rootBundle.load('assets/model.tflite');
    _interpreter = Interpreter.fromBuffer(modelData.buffer.asUint8List());

    final scalerConfig = await rootBundle.loadString('assets/scaler_params.json');
    final decoded = jsonDecode(scalerConfig) as Map<String, dynamic>;
    _scalerMean = (decoded['mean'] as List<dynamic>).map((e) => (e as num).toDouble()).toList();
    _scalerScale = (decoded['scale'] as List<dynamic>).map((e) => (e as num).toDouble()).toList();
  }

  static RiskLevel _mapKlGradeToRisk(int klGrade) {
    if (klGrade <= 1) return RiskLevel.low;
    if (klGrade == 2) return RiskLevel.medium;
    return RiskLevel.high;
  }

  static Future<RiskResult> predictRisk({
    required Patient patient,
    required QuestionnaireResponse questionnaire,
    required MobilityTestResult mobilityTest,
    ScreeningMode mode = ScreeningMode.standard,
  }) async {
    await initialize();

    final rawFeatures = [
      patient.age.toDouble(),
      patient.sexCode.toDouble(),
      patient.bmi,
      patient.priorInjuryHistory ? 1.0 : 0.0,
      questionnaire.painScore.toDouble(),
      questionnaire.stiffnessScore.toDouble(),
      questionnaire.functionScore.toDouble(),
      mobilityTest.durationSeconds,
      mobilityTest.peakAccel,
      mobilityTest.accelVariance,
      mobilityTest.cadenceCps,
      mobilityTest.kineticEnergy,
    ];

    final mean = _scalerMean ?? List.filled(rawFeatures.length, 0.0);
    final scale = _scalerScale ?? List.filled(rawFeatures.length, 1.0);
    final scaled = List<double>.generate(rawFeatures.length, (index) {
      final divisor = scale[index] == 0 ? 1.0 : scale[index];
      return (rawFeatures[index] - mean[index]) / divisor;
    });

    final input = [scaled];
    final output = [List.filled(5, 0.0)];
    _interpreter!.run(input, output);

    final probabilities = List<double>.from(output[0].map((value) => (value as num).toDouble()));
    final bestIndex = probabilities.indexOf(probabilities.reduce(max));
    final confidence = probabilities[bestIndex];
    final riskLevel = _mapKlGradeToRisk(bestIndex);

    return RiskResult(
      riskLevel: riskLevel,
      klGrade: bestIndex,
      confidence: double.parse(confidence.toStringAsFixed(3)),
      modelVersion: modelVersion,
      computedAt: DateTime.now(),
      screeningMode: mode,
    );
  }
}
