import 'package:uuid/uuid.dart';

enum Gender { male, female, other }

class Patient {
  final String patientId;
  final String name;
  final int age;
  final Gender sex;
  final String occupation;
  final double heightCm;
  final double weightKg;
  final double bmi;
  final bool priorInjuryHistory;
  final String injuryNotes;
  final String preferredLanguage;
  final String campId;
  final String district;

  Patient({
    String? patientId,
    required this.name,
    required this.age,
    required this.sex,
    required this.occupation,
    required this.heightCm,
    required this.weightKg,
    required this.priorInjuryHistory,
    this.injuryNotes = '',
    this.preferredLanguage = 'en',
    required this.campId,
    required this.district,
  })  : patientId = patientId ?? const Uuid().v4(),
        bmi = calculateBmi(heightCm, weightKg);

  static double calculateBmi(double heightCm, double weightKg) {
    if (heightCm <= 0) return 0.0;
    final heightMeters = heightCm / 100.0;
    return double.parse((weightKg / (heightMeters * heightMeters)).toStringAsFixed(1));
  }

  int get sexCode {
    switch (sex) {
      case Gender.male:
        return 0;
      case Gender.female:
        return 1;
      case Gender.other:
        return 2;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'patient_id': patientId,
      'name': name,
      'age': age,
      'sex': sex.name,
      'occupation': occupation,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'bmi': bmi,
      'prior_injury_history': priorInjuryHistory ? 1 : 0,
      'injury_notes': injuryNotes,
      'preferred_language': preferredLanguage,
      'camp_id': campId,
      'district': district,
    };
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      patientId: map['patient_id'] as String,
      name: map['name'] as String,
      age: map['age'] as int,
      sex: Gender.values.firstWhere(
        (e) => e.name == map['sex'],
        orElse: () => Gender.other,
      ),
      occupation: map['occupation'] as String,
      heightCm: (map['height_cm'] as num).toDouble(),
      weightKg: (map['weight_kg'] as num).toDouble(),
      priorInjuryHistory: (map['prior_injury_history'] as int) == 1,
      injuryNotes: (map['injury_notes'] as String?) ?? '',
      preferredLanguage: (map['preferred_language'] as String?) ?? 'en',
      campId: map['camp_id'] as String,
      district: map['district'] as String,
    );
  }
}
