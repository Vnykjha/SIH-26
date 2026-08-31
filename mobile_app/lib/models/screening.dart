import 'package:uuid/uuid.dart';
import 'patient.dart';
import 'questionnaire_response.dart';
import 'mobility_test_result.dart';
import 'risk_result.dart';

class Screening {
  final String screeningId;
  final Patient patient;
  final QuestionnaireResponse questionnaire;
  final MobilityTestResult mobilityTest;
  final RiskResult riskResult;
  bool isSynced;
  final DateTime createdAt;

  Screening({
    String? screeningId,
    required this.patient,
    required this.questionnaire,
    required this.mobilityTest,
    required this.riskResult,
    this.isSynced = false,
    DateTime? createdAt,
  })  : screeningId = screeningId ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'screening_id': screeningId,
      'synced': isSynced ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
    map.addAll(patient.toMap());
    map.addAll(questionnaire.toMap());
    map.addAll(mobilityTest.toMap());
    map.addAll(riskResult.toMap());
    return map;
  }

  factory Screening.fromMap(Map<String, dynamic> map) {
    return Screening(
      screeningId: map['screening_id'] as String,
      patient: Patient.fromMap(map),
      questionnaire: QuestionnaireResponse.fromMap(map),
      mobilityTest: MobilityTestResult.fromMap(map),
      riskResult: RiskResult.fromMap(map),
      isSynced: (map['synced'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
