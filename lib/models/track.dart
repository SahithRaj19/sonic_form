/// Represents a local audio track chosen by the user.
class AudioTrack {
  final String id;
  final String title;
  final String artist;
  final String path;
  final int? sizeInBytes;
  final Duration? duration;

  const AudioTrack({
    required this.id,
    required this.title,
    this.artist = 'Local Audio',
    required this.path,
    this.sizeInBytes,
    this.duration,
  });

  String get formattedSize {
    if (sizeInBytes == null || sizeInBytes == 0) return '';
    final kb = sizeInBytes! / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }
}

/// Equalizer presets supported by SonicForm.
enum EqualizerPresetType {
  flat(
    label: 'Flat',
    description: 'Neutral, uncolored frequency balance across the spectrum',
    // Normalized 5-band gain offsets in dB (-15dB to +15dB scale)
    baseGains: [0.0, 0.0, 0.0, 0.0, 0.0],
  ),
  warm(
    label: 'Warm',
    description: 'Boosted bass and low-mids with relaxed, smooth treble rolloff',
    baseGains: [4.0, 2.5, 1.0, -1.0, -2.5],
  ),
  vocal(
    label: 'Vocal',
    description: 'Highlighted mid frequencies for clear voices and podcast dialogue',
    baseGains: [-2.0, 1.5, 4.5, 3.0, 0.5],
  ),
  bright(
    label: 'Bright',
    description: 'Crisp treble boost and sparkling air with clean low mud reduction',
    baseGains: [-1.5, 0.0, 2.0, 4.5, 6.0],
  ),
  deep(
    label: 'Deep',
    description: 'Thumping sub-bass and low rumble with softened high end',
    baseGains: [6.5, 4.0, 1.0, -1.5, -3.0],
  ),
  custom(
    label: 'Custom',
    description: 'Tailored manually with custom frequency sliders',
    baseGains: [0.0, 0.0, 0.0, 0.0, 0.0],
  );

  final String label;
  final String description;
  final List<double> baseGains;

  const EqualizerPresetType({
    required this.label,
    required this.description,
    required this.baseGains,
  });
}

/// Unified Equalizer Band model representing hardware or simulated bands.
class EqualizerBandModel {
  final int index;
  final double centerFrequency;
  final double lowerFrequency;
  final double upperFrequency;
  double gain; // in decibels

  EqualizerBandModel({
    required this.index,
    required this.centerFrequency,
    required this.lowerFrequency,
    required this.upperFrequency,
    required this.gain,
  });

  /// Human-friendly display label (e.g. "60 Hz", "1 kHz", "14 kHz").
  String get frequencyLabel {
    if (centerFrequency >= 1000) {
      final khz = centerFrequency / 1000;
      if (khz == khz.roundToDouble()) {
        return '${khz.toStringAsFixed(0)} kHz';
      }
      return '${khz.toStringAsFixed(1)} kHz';
    }
    return '${centerFrequency.toStringAsFixed(0)} Hz';
  }

  /// Calculates gain mapped from 5-point preset curve based on band center frequency
  static double interpolatePresetGain(
    EqualizerPresetType preset,
    int bandIndex,
    int totalBands,
    double centerFreq,
  ) {
    if (preset == EqualizerPresetType.custom) return 0.0;
    final curve = preset.baseGains;
    if (totalBands == 5 && bandIndex >= 0 && bandIndex < 5) {
      return curve[bandIndex];
    }

    // Frequency-based mapping for hardware equalizers with variable band counts
    if (centerFreq <= 120) {
      return curve[0]; // Sub bass
    } else if (centerFreq <= 350) {
      return curve[1]; // Bass / Low Mid
    } else if (centerFreq <= 1800) {
      return curve[2]; // Mid
    } else if (centerFreq <= 5500) {
      return curve[3]; // Upper Mid / Presence
    } else {
      return curve[4]; // Treble / Brilliance
    }
  }
}
