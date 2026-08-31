import 'dart:convert';

enum TestType { phoneOnly, imuPuck }
enum TestVariant { timedUpAndGo, sitToStand }

class MobilityTestResult {
  final TestType testType;
  final TestVariant testVariant;
  final double durationSeconds;
  final double peakAccel;
  final double accelVariance;
  final double cadenceCps;
  final double kineticEnergy;
  final Map<String, dynamic>? imuPuckFeatures;

  MobilityTestResult({
    required this.testType,
    required this.testVariant,
    required this.durationSeconds,
    required this.peakAccel,
    required this.accelVariance,
    required this.cadenceCps,
    required this.kineticEnergy,
    this.imuPuckFeatures,
  });

  Map<String, dynamic> toMap() {
    return {
      'test_type': testType.name,
      'test_variant': testVariant.name,
      'duration_seconds': durationSeconds,
      'peak_accel': peakAccel,
      'accel_variance': accelVariance,
      'cadence_cps': cadenceCps,
      'kinetic_energy': kineticEnergy,
      'imu_puck_features_json': imuPuckFeatures != null ? jsonEncode(imuPuckFeatures) : null,
    };
  }

  factory MobilityTestResult.fromMap(Map<String, dynamic> map) {
    return MobilityTestResult(
      testType: TestType.values.firstWhere((e) => e.name == map['test_type'], orElse: () => TestType.phoneOnly),
      testVariant: TestVariant.values.firstWhere((e) => e.name == map['test_variant'], orElse: () => TestVariant.timedUpAndGo),
      durationSeconds: (map['duration_seconds'] as num).toDouble(),
      peakAccel: (map['peak_accel'] as num).toDouble(),
      accelVariance: (map['accel_variance'] as num).toDouble(),
      cadenceCps: (map['cadence_cps'] as num).toDouble(),
      kineticEnergy: (map['kinetic_energy'] as num).toDouble(),
      imuPuckFeatures: map['imu_puck_features_json'] != null ? jsonDecode(map['imu_puck_features_json']) as Map<String, dynamic> : null,
    );
  }
}
