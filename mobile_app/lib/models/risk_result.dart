enum RiskLevel { low, medium, high }
enum ScreeningMode { standard, enhanced }

class RiskResult {
  final RiskLevel riskLevel;
  final int? klGrade;
  final double confidence;
  final String modelVersion;
  final DateTime computedAt;
  final ScreeningMode screeningMode;

  RiskResult({
    required this.riskLevel,
    this.klGrade,
    required this.confidence,
    required this.modelVersion,
    DateTime? computedAt,
    required this.screeningMode,
  }) : computedAt = computedAt ?? DateTime.now();

  String get riskLabel {
    switch (riskLevel) {
      case RiskLevel.low:
        return 'Low';
      case RiskLevel.medium:
        return 'Medium';
      case RiskLevel.high:
        return 'High';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'risk_level': riskLevel.name,
      'kl_grade': klGrade,
      'confidence': confidence,
      'model_version': modelVersion,
      'computed_at': computedAt.toIso8601String(),
      'screening_mode': screeningMode.name,
    };
  }

  factory RiskResult.fromMap(Map<String, dynamic> map) {
    return RiskResult(
      riskLevel: RiskLevel.values.firstWhere(
        (e) => e.name.toLowerCase() == (map['risk_level'] as String).toLowerCase(),
        orElse: () => RiskLevel.low,
      ),
      klGrade: map['kl_grade'] != null ? int.tryParse(map['kl_grade'].toString()) : null,
      confidence: (map['confidence'] as num).toDouble(),
      modelVersion: map['model_version'] as String,
      computedAt: DateTime.parse(map['computed_at'] as String),
      screeningMode: ScreeningMode.values.firstWhere(
        (e) => e.name == map['screening_mode'],
        orElse: () => ScreeningMode.standard,
      ),
    );
  }
}
