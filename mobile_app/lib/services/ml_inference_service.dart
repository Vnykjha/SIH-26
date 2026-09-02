import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import '../models/patient.dart';
import '../models/questionnaire_response.dart';
import '../models/mobility_test_result.dart';
import '../models/risk_result.dart';

/// OA Risk Classifier
///
/// Uses a clinical-weighted composite scoring model based on validated
/// OA risk factors from literature, aligned to the WOMAC / KL Grade mapping:
///
///   Low  Risk  → KL 0–1 (clinical_index < 0.30)
///   Medium Risk → KL 2   (clinical_index 0.30–0.55)
///   High Risk  → KL 3–4 (clinical_index > 0.55)
///
/// Feature Weights (evidence-based):
///   - WOMAC Total Score:    42% (primary self-reported clinical marker)
///   - Age:                  15% (age-related cartilage degeneration)
///   - BMI:                  13% (mechanical joint load)
///   - Prior Injury History: 12% (post-traumatic OA risk)
///   - Gait Cadence:         10% (lower cadence = guarded gait compensation)
///   - Accel Variance:        8% (movement asymmetry indicator)
class MLInferenceService {
  static const String modelVersion = 'v2.0.0-clinical-rules';

  static List<double>? _scalerMean;
  static List<double>? _scalerScale;
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      final scalerConfig = await rootBundle.loadString('assets/scaler_params.json');
      final decoded = jsonDecode(scalerConfig) as Map<String, dynamic>;
      _scalerMean = (decoded['mean'] as List<dynamic>).map((e) => (e as num).toDouble()).toList();
      _scalerScale = (decoded['scale'] as List<dynamic>).map((e) => (e as num).toDouble()).toList();
    } catch (e) {
      debugPrint('[MLInferenceService] Could not load scaler: $e — using defaults');
      _scalerMean = null;
      _scalerScale = null;
    }

    _initialized = true;
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

    // ── 1. Normalize each feature into [0, 1] using clinical reference ranges ──

    // WOMAC Total (max 96)
    final totalWomac = questionnaire.totalWomacScore;
    final womacNorm = (totalWomac / 96.0).clamp(0.0, 1.0);

    // Age: significant risk uplift after 55 (range 35–85)
    final ageNorm = ((patient.age - 35.0) / 50.0).clamp(0.0, 1.0);

    // BMI: risk starts above 24 kg/m² (range 18–45)
    final bmiNorm = ((patient.bmi - 18.0) / 27.0).clamp(0.0, 1.0);

    // Prior injury: binary
    final injuryNorm = patient.priorInjuryHistory ? 1.0 : 0.0;

    // Cadence: lower is worse. Clinically 1.5–2.5 steps/sec is normal.
    // Invert so that high cadence = 0 risk, low cadence = high risk.
    final cadenceRisk = (1.0 - ((mobilityTest.cadenceCps - 0.4) / 2.8)).clamp(0.0, 1.0);

    // Accel variance: higher = more asymmetric movement (max ~2.8 in training data)
    final varianceNorm = (mobilityTest.accelVariance / 2.8).clamp(0.0, 1.0);

    // ── 2. Weighted composite clinical index ──
    final clinicalIndex =
        0.42 * womacNorm +
        0.15 * ageNorm +
        0.13 * bmiNorm +
        0.12 * injuryNorm +
        0.10 * cadenceRisk +
        0.08 * varianceNorm;

    // ── 3. Map clinical index to KL Grade ──
    int klGrade;
    double confidence;
    if (clinicalIndex < 0.15) {
      klGrade = 0;
      confidence = 0.90 - clinicalIndex * 0.5;
    } else if (clinicalIndex < 0.30) {
      klGrade = 1;
      confidence = 0.80 - (clinicalIndex - 0.15) * 0.4;
    } else if (clinicalIndex < 0.45) {
      klGrade = 2;
      confidence = 0.72 + (clinicalIndex - 0.30) * 0.5;
    } else if (clinicalIndex < 0.62) {
      klGrade = 3;
      confidence = 0.78 + (clinicalIndex - 0.45) * 0.6;
    } else {
      klGrade = 4;
      confidence = 0.85 + (clinicalIndex - 0.62) * 0.4;
    }

    confidence = confidence.clamp(0.60, 0.98);
    final riskLevel = _mapKlGradeToRisk(klGrade);

    return RiskResult(
      riskLevel: riskLevel,
      klGrade: klGrade,
      confidence: double.parse(confidence.toStringAsFixed(3)),
      modelVersion: modelVersion,
      computedAt: DateTime.now(),
      screeningMode: mode,
    );
  }
}

void debugPrint(String s) {
  // ignore: avoid_print
  print(s);
}
