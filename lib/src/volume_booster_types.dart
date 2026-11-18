import 'package:flutter/foundation.dart';

/// Represents the current acoustic safety and amplification zone of the booster.
enum VolumeSafetyLevel {
  /// Audio output is currently muted (`0%`).
  muted,

  /// Standard unamplified volume range (`1%` to `100%`, `<= 0.0 dB`).
  safe,

  /// Moderate software gain boost (`101%` to `155%`, `0.1 dB` to `+7.6 dB`).
  turboBoost,

  /// High overdrive amplification (`> 155%`, `> +7.6 dB`) where limiter
  /// protection is recommended to prevent speaker distortion or clipping.
  overdriveDanger,
}

/// Built-in acoustic and amplification presets for [VolumeBoosterController].
enum VolumePreset {
  /// Unity gain (`100%`) with flat `0.0 dB` equalizer bands.
  normal,

  /// Boosts vocal clarity (`910Hz` and `3.6kHz`) and raises gain to `135%`.
  voiceBoost,

  /// Deep low-end sub-bass punch (`60Hz` and `230Hz`) with `150%` gain.
  bassExtreme,

  /// Wide spatial soundstage with high 3D virtualizer and V-shaped EQ (`145%`).
  cinema3D,

  /// Footstep and positional audio enhancement (`140%` gain + treble clarity).
  gaming,

  /// Maximum safe loudness amplification (`200%`) with brickwall limiter active.
  maxOverdrive,

  /// Compressed dynamic range (`90%`) with gentle high/low roll-off for late night.
  nightLimiter,

  /// User-customized gain or equalizer curve.
  custom,
}

/// Visual rendering mode for `VolumeSpectrumVisualizer`.
enum VisualizerMode {
  /// Segmented multi-zone LED spectrum bars with peak-hold caps.
  ledBars,

  /// Dual-layer glowing harmonic sine/bezier waveform.
  smoothWave,

  /// Symmetrical center-mirrored frequency bars.
  dualMirror,
}

/// Extension providing human-readable metadata for [VolumePreset].
extension VolumePresetExtension on VolumePreset {
  /// Display title of the preset.
  String get label {
    switch (this) {
      case VolumePreset.normal:
        return 'Normal';
      case VolumePreset.voiceBoost:
        return 'Voice Boost';
      case VolumePreset.bassExtreme:
        return 'Bass Extreme';
      case VolumePreset.cinema3D:
        return 'Cinema 3D';
      case VolumePreset.gaming:
        return 'Gaming';
      case VolumePreset.maxOverdrive:
        return 'Max Overdrive';
      case VolumePreset.nightLimiter:
        return 'Night Mode';
      case VolumePreset.custom:
        return 'Custom';
    }
  }

  /// Short badge tag for compact UI headers.
  String get shortTag {
    switch (this) {
      case VolumePreset.normal:
        return 'FLAT';
      case VolumePreset.voiceBoost:
        return 'VOCAL';
      case VolumePreset.bassExtreme:
        return 'BASS+';
      case VolumePreset.cinema3D:
        return '3D SURROUND';
      case VolumePreset.gaming:
        return 'FPS/GAME';
      case VolumePreset.maxOverdrive:
        return 'MAX 200%';
      case VolumePreset.nightLimiter:
        return 'NIGHT';
      case VolumePreset.custom:
        return 'USER EQ';
    }
  }
}

/// Extension providing human-readable labels for [VolumeSafetyLevel].
extension VolumeSafetyLevelExtension on VolumeSafetyLevel {
  /// Uppercase status badge text shown inside dials and headers.
  String get badgeLabel {
    switch (this) {
      case VolumeSafetyLevel.muted:
        return 'MUTED';
      case VolumeSafetyLevel.safe:
        return 'SAFE GAIN';
      case VolumeSafetyLevel.turboBoost:
        return 'TURBO BOOST';
      case VolumeSafetyLevel.overdriveDanger:
        return 'OVERDRIVE MAX';
    }
  }

  /// Advisory description explaining the current amplification zone.
  String get description {
    switch (this) {
      case VolumeSafetyLevel.muted:
        return 'Audio output is muted.';
      case VolumeSafetyLevel.safe:
        return 'Standard hardware volume range (0% – 100%).';
      case VolumeSafetyLevel.turboBoost:
        return 'Active pre-amp gain boost for louder clarity.';
      case VolumeSafetyLevel.overdriveDanger:
        return 'High overdrive output. Keep brickwall limiter enabled.';
    }
  }
}

/// Represents a single frequency band in the graphic equalizer.
@immutable
class EqualizerBand {
  /// Creates an [EqualizerBand] with the given [frequencyHz], [label], and [gainDb].
  const EqualizerBand({
    required this.frequencyHz,
    required this.label,
    this.gainDb = 0.0,
    this.minGainDb = -12.0,
    this.maxGainDb = 12.0,
  });

  /// Center frequency in Hertz (e.g., `60`, `230`, `910`, `3600`, `14000`).
  final int frequencyHz;

  /// Compact human-readable frequency label (e.g., `'60Hz'`, `'3.6kHz'`).
  final String label;

  /// Current band gain in decibels (`-12.0` to `+12.0`).
  final double gainDb;

  /// Minimum allowed gain in decibels.
  final double minGainDb;

  /// Maximum allowed gain in decibels.
  final double maxGainDb;

  /// Normalized value between `0.0` (at [minGainDb]) and `1.0` (at [maxGainDb]).
  double get normalized {
    final span = maxGainDb - minGainDb;
    if (span <= 0) return 0.5;
    return ((gainDb - minGainDb) / span).clamp(0.0, 1.0);
  }

  /// Formatted decibel string such as `'+4.5 dB'` or `'0.0 dB'`.
  String get formattedDb {
    final prefix = gainDb > 0.05 ? '+' : '';
    return '$prefix${gainDb.toStringAsFixed(1)} dB';
  }

  /// Returns a copy of this [EqualizerBand] with updated fields.
  EqualizerBand copyWith({
    int? frequencyHz,
    String? label,
    double? gainDb,
    double? minGainDb,
    double? maxGainDb,
  }) {
    final nextMin = minGainDb ?? this.minGainDb;
    final nextMax = maxGainDb ?? this.maxGainDb;
    final nextGain = (gainDb ?? this.gainDb).clamp(nextMin, nextMax);
    return EqualizerBand(
      frequencyHz: frequencyHz ?? this.frequencyHz,
      label: label ?? this.label,
      gainDb: nextGain,
      minGainDb: nextMin,
      maxGainDb: nextMax,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EqualizerBand &&
        other.frequencyHz == frequencyHz &&
        other.label == label &&
        other.gainDb == gainDb &&
        other.minGainDb == minGainDb &&
        other.maxGainDb == maxGainDb;
  }

  @override
  int get hashCode =>
      Object.hash(frequencyHz, label, gainDb, minGainDb, maxGainDb);
}

/// An immutable snapshot of the complete [VolumeBoosterController] state.
@immutable
class VolumeBoosterSnapshot {
  /// Creates a [VolumeBoosterSnapshot].
  const VolumeBoosterSnapshot({
    required this.baseVolume,
    required this.boostGain,
    required this.effectiveVolume,
    required this.maxBoostMultiplier,
    required this.effectivePercentage,
    required this.decibelGain,
    required this.isMuted,
    required this.isBoostEnabled,
    required this.limiterEnabled,
    required this.isClipping,
    required this.bassBoost,
    required this.virtualizer,
    required this.loudnessEnhancer,
    required this.activePreset,
    required this.safetyLevel,
    required this.bands,
    required this.leftPeak,
    required this.rightPeak,
  });

  /// Hardware/base volume level from `0.0` (`0%`) to `1.0` (`100%`).
  final double baseVolume;

  /// Software amplification gain above `1.0` (`0.0` up to `maxBoostMultiplier - 1.0`).
  final double boostGain;

  /// Combined output level from `0.0` up to [maxBoostMultiplier] (e.g., `2.0` for `200%`).
  final double effectiveVolume;

  /// Maximum amplification multiplier allowed (default `2.0` = `200%`).
  final double maxBoostMultiplier;

  /// Effective output volume expressed as an integer percentage (`0` to `200`+).
  final int effectivePercentage;

  /// Computed pre-amp gain in decibels (`-60.0 dB` to `+18.0 dB`).
  final double decibelGain;

  /// Whether output is currently muted.
  final bool isMuted;

  /// Whether software boost above `100%` is enabled.
  final bool isBoostEnabled;

  /// Whether the anti-clipping brickwall limiter is active.
  final bool limiterEnabled;

  /// Whether the output signal is currently clipping (`> 185%` without limiter).
  final bool isClipping;

  /// Sub-bass resonance boost amount (`0.0` to `1.0`).
  final double bassBoost;

  /// 3D spatial stereo virtualizer intensity (`0.0` to `1.0`).
  final double virtualizer;

  /// Dynamic loudness enhancer intensity (`0.0` to `1.0`).
  final double loudnessEnhancer;

  /// Currently active acoustic preset.
  final VolumePreset activePreset;

  /// Computed safety zone for the current output level.
  final VolumeSafetyLevel safetyLevel;

  /// Unmodifiable list of graphic equalizer frequency bands.
  final List<EqualizerBand> bands;

  /// Left stereo channel instantaneous VU level (`0.0` to `1.0`).
  final double leftPeak;

  /// Right stereo channel instantaneous VU level (`0.0` to `1.0`).
  final double rightPeak;
}
