import 'dart:math';

class AccelReading {
  final double x;
  final double y;
  final double z;
  final int timestampMs;

  AccelReading({required this.x, required this.y, required this.z, required this.timestampMs});
}

class ExtractedAccelFeatures {
  final double durationSeconds;
  final double peakAccel;
  final double accelVariance;
  final double cadenceCps;
  final double kineticEnergy;

  ExtractedAccelFeatures({
    required this.durationSeconds,
    required this.peakAccel,
    required this.accelVariance,
    required this.cadenceCps,
    required this.kineticEnergy,
  });
}

class AccelerometerFeatureExtractor {
  /// Processes a sequence of raw 3-axis accelerometer readings sampled during a mobility test.
  static ExtractedAccelFeatures extract(List<AccelReading> readings) {
    if (readings.isEmpty) {
      return ExtractedAccelFeatures(
        durationSeconds: 0.0,
        peakAccel: 0.0,
        accelVariance: 0.0,
        cadenceCps: 0.0,
        kineticEnergy: 0.0,
      );
    }

    final startTime = readings.first.timestampMs;
    final endTime = readings.last.timestampMs;
    final durationSeconds = (endTime - startTime) / 1000.0;

    // Calculate magnitude vectors m = sqrt(x^2 + y^2 + z^2) in Gs (9.81 m/s^2)
    final magnitudes = readings.map((r) {
      final mag = sqrt(r.x * r.x + r.y * r.y + r.z * r.z) / 9.81;
      return mag;
    }).toList();

    // 1. Peak Acceleration
    final peakAccel = magnitudes.reduce(max);

    // 2. Mean and Variance
    final meanMag = magnitudes.reduce((a, b) => a + b) / magnitudes.length;
    final varianceSum = magnitudes.fold(0.0, (prev, m) => prev + (m - meanMag) * (m - meanMag));
    final accelVariance = varianceSum / magnitudes.length;

    // 3. Cadence Estimation (Step detection using peak threshold above mean)
    int stepPeaks = 0;
    final stepThreshold = meanMag + 0.25;
    bool aboveThreshold = false;

    for (final mag in magnitudes) {
      if (mag > stepThreshold && !aboveThreshold) {
        stepPeaks++;
        aboveThreshold = true;
      } else if (mag < meanMag) {
        aboveThreshold = false;
      }
    }

    final cadenceCps = durationSeconds > 0 ? stepPeaks / durationSeconds : 0.0;

    // 4. Kinetic Energy Proxy (Integral of squared magnitude dynamic component)
    final dynamicComponentSum = magnitudes.fold(0.0, (prev, m) => prev + (m - 1.0) * (m - 1.0));
    final kineticEnergy = dynamicComponentSum / (magnitudes.length > 0 ? magnitudes.length : 1);

    return ExtractedAccelFeatures(
      durationSeconds: double.parse(durationSeconds.toStringAsFixed(2)),
      peakAccel: double.parse(peakAccel.toStringAsFixed(2)),
      accelVariance: double.parse(accelVariance.toStringAsFixed(3)),
      cadenceCps: double.parse(cadenceCps.toStringAsFixed(2)),
      kineticEnergy: double.parse(kineticEnergy.toStringAsFixed(2)),
    );
  }
}
