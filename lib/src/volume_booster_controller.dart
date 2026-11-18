import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'volume_booster_types.dart';

/// Reactive controller managing volume level, software boost overdrive,
/// multi-band graphic equalizer, bass boost, 3D virtualizer, brickwall limiter,
/// and real-time stereo VU / frequency spectrum telemetry.
class VolumeBoosterController extends ChangeNotifier {
  /// Creates a [VolumeBoosterController].
  ///
  /// - [initialVolume] specifies the initial effective output (`1.0` = `100%`,
  ///   `1.5` = `150%`, etc.).
  /// - [maxBoostMultiplier] defines the maximum amplification cap (`2.0` = `200%`).
  VolumeBoosterController({
    double initialVolume = 1.25,
    this.maxBoostMultiplier = 2.0,
    bool initialMuted = false,
    bool initialBoostEnabled = true,
    bool initialLimiterEnabled = true,
    double initialBassBoost = 0.35,
    double initialVirtualizer = 0.25,
    double initialLoudnessEnhancer = 0.30,
    VolumePreset initialPreset = VolumePreset.custom,
    List<EqualizerBand>? initialBands,
    this.enablePlatformChannel = false,
    this.channelName = 'com.humanize.volume_booster/audio',
  })  : assert(maxBoostMultiplier >= 1.0, 'maxBoostMultiplier must be >= 1.0'),
        _isMuted = initialMuted,
        _isBoostEnabled = initialBoostEnabled,
        _limiterEnabled = initialLimiterEnabled,
        _bassBoost = initialBassBoost.clamp(0.0, 1.0),
        _virtualizer = initialVirtualizer.clamp(0.0, 1.0),
        _loudnessEnhancer = initialLoudnessEnhancer.clamp(0.0, 1.0),
        _activePreset = initialPreset,
        _bands = List<EqualizerBand>.from(initialBands ?? defaultFiveBands()) {
    final clamped = initialVolume.clamp(0.0, maxAllowedVolume);
    _setInternalVolume(clamped);
    _lastNonZeroVolume = clamped > 0.05 ? clamped : 1.0;
    _recomputeSimulatedSpectrum(0.35);
  }

  /// Creates the standard 5-band graphic equalizer (`60Hz`, `230Hz`, `910Hz`,
  /// `3.6kHz`, `14kHz`).
  static List<EqualizerBand> defaultFiveBands() {
    return const <EqualizerBand>[
      EqualizerBand(frequencyHz: 60, label: '60Hz', gainDb: 2.5),
      EqualizerBand(frequencyHz: 230, label: '230Hz', gainDb: 1.5),
      EqualizerBand(frequencyHz: 910, label: '910Hz', gainDb: 0.5),
      EqualizerBand(frequencyHz: 3600, label: '3.6kHz', gainDb: 2.0),
      EqualizerBand(frequencyHz: 14000, label: '14kHz', gainDb: 3.0),
    ];
  }

  /// Maximum amplification multiplier (`2.0` corresponds to `200%`).
  final double maxBoostMultiplier;

  /// Whether changes should also be broadcast over a Flutter [MethodChannel].
  final bool enablePlatformChannel;

  /// Name of the optional platform [MethodChannel].
  final String channelName;

  double _baseVolume = 1.0;
  double _boostGain = 0.25;
  double _lastNonZeroVolume = 1.25;
  bool _isMuted;
  bool _isBoostEnabled;
  bool _limiterEnabled;
  double _bassBoost;
  double _virtualizer;
  double _loudnessEnhancer;
  VolumePreset _activePreset;
  final List<EqualizerBand> _bands;

  double _leftPeak = 0.62;
  double _rightPeak = 0.58;
  double _leftPeakHold = 0.72;
  double _rightPeakHold = 0.68;
  double _simulationPhase = 0.0;
  final List<double> _spectrumBars = List<double>.filled(20, 0.35);

  /// Base hardware volume component (`0.0` to `1.0`).
  double get baseVolume => _isMuted ? 0.0 : _baseVolume;

  /// Extra software boost gain component above `1.0` (`0.0` to `maxBoostMultiplier - 1.0`).
  double get boostGain => (_isMuted || !_isBoostEnabled) ? 0.0 : _boostGain;

  /// Maximum currently permitted volume multiplier (`1.0` if boost is disabled,
  /// otherwise [maxBoostMultiplier]).
  double get maxAllowedVolume => _isBoostEnabled ? maxBoostMultiplier : 1.0;

  /// Effective combined output volume from `0.0` to [maxBoostMultiplier].
  double get effectiveVolume =>
      _isMuted ? 0.0 : (_baseVolume + boostGain).clamp(0.0, maxAllowedVolume);

  /// Normalized progress across the full dial/slider range (`0.0` to `1.0`).
  double get normalizedProgress =>
      (effectiveVolume / maxBoostMultiplier).clamp(0.0, 1.0);

  /// Normalized position of the `100%` unity gain marker (`0.0` to `1.0`).
  double get unityMarkerRatio => (1.0 / maxBoostMultiplier).clamp(0.0, 1.0);

  /// Effective output volume rounded to an integer percentage (`0` to `200`+).
  int get effectivePercentage => (effectiveVolume * 100).round();

  /// Whether audio output is currently muted.
  bool get isMuted => _isMuted || effectiveVolume <= 0.0001;

  /// Whether software boost above `100%` is enabled.
  bool get isBoostEnabled => _isBoostEnabled;

  /// Whether the anti-clipping brickwall limiter is enabled.
  bool get limiterEnabled => _limiterEnabled;

  /// Sub-bass resonance enhancer level (`0.0` to `1.0`).
  double get bassBoost => _bassBoost;

  /// 3D spatial stereo virtualizer level (`0.0` to `1.0`).
  double get virtualizer => _virtualizer;

  /// Dynamic range loudness enhancer level (`0.0` to `1.0`).
  double get loudnessEnhancer => _loudnessEnhancer;

  /// Currently active acoustic preset.
  VolumePreset get activePreset => _activePreset;

  /// Unmodifiable list of graphic equalizer frequency bands.
  List<EqualizerBand> get bands => List<EqualizerBand>.unmodifiable(_bands);

  /// Instantaneous left stereo channel VU level (`0.0` to `1.0`).
  double get leftPeak => isMuted ? 0.0 : _leftPeak;

  /// Instantaneous right stereo channel VU level (`0.0` to `1.0`).
  double get rightPeak => isMuted ? 0.0 : _rightPeak;

  /// Peak-hold marker for the left stereo channel (`0.0` to `1.0`).
  double get leftPeakHold => isMuted ? 0.0 : _leftPeakHold;

  /// Peak-hold marker for the right stereo channel (`0.0` to `1.0`).
  double get rightPeakHold => isMuted ? 0.0 : _rightPeakHold;

  /// Current 20-band frequency spectrum magnitudes (`0.0` to `1.0`).
  List<double> get spectrumBars => isMuted
      ? List<double>.filled(_spectrumBars.length, 0.04)
      : List<double>.unmodifiable(_spectrumBars);

  /// Whether the signal is currently at risk of hard clipping.
  bool get isClipping => !isMuted && !_limiterEnabled && effectiveVolume > 1.80;

  /// Computed pre-amp gain in decibels (`-60.0 dB` at mute, `0.0 dB` at `100%`,
  /// up to `+12.0 dB` at `200%`).
  double get decibelGain {
    final vol = effectiveVolume;
    if (vol <= 0.001) return -60.0;
    if (vol <= 1.0) {
      // Logarithmic attenuation from -45 dB up to 0.0 dB at unity (100%).
      final db = 20.0 * (math.log(vol) / math.ln10);
      return db.clamp(-60.0, 0.0);
    } else {
      // Boost region: linear-in-dB mapping where 2.0x (200%) = +12.0 dB.
      final boostRatio = (vol - 1.0) / math.max(0.01, maxBoostMultiplier - 1.0);
      return (boostRatio * 12.0).clamp(0.0, 18.0);
    }
  }

  /// Human-readable formatted decibel gain string (e.g., `'+6.0 dB'`, `'0.0 dB'`, `'MUTE'`).
  String get formattedDecibels {
    if (isMuted) return 'MUTE';
    final db = decibelGain;
    if (db.abs() < 0.05) return '0.0 dB';
    final sign = db > 0 ? '+' : '';
    return '$sign${db.toStringAsFixed(1)} dB';
  }

  /// Computed safety zone for the current amplification state.
  VolumeSafetyLevel get safetyLevel {
    if (isMuted) return VolumeSafetyLevel.muted;
    final pct = effectivePercentage;
    if (pct <= 100) return VolumeSafetyLevel.safe;
    if (pct <= 155) return VolumeSafetyLevel.turboBoost;
    return VolumeSafetyLevel.overdriveDanger;
  }

  /// Captures an immutable [VolumeBoosterSnapshot] of the current state.
  VolumeBoosterSnapshot get snapshot => VolumeBoosterSnapshot(
        baseVolume: baseVolume,
        boostGain: boostGain,
        effectiveVolume: effectiveVolume,
        maxBoostMultiplier: maxBoostMultiplier,
        effectivePercentage: effectivePercentage,
        decibelGain: decibelGain,
        isMuted: isMuted,
        isBoostEnabled: isBoostEnabled,
        limiterEnabled: limiterEnabled,
        isClipping: isClipping,
        bassBoost: bassBoost,
        virtualizer: virtualizer,
        loudnessEnhancer: loudnessEnhancer,
        activePreset: activePreset,
        safetyLevel: safetyLevel,
        bands: bands,
        leftPeak: leftPeak,
        rightPeak: rightPeak,
      );

  void _setInternalVolume(double target) {
    final clamped = target.clamp(0.0, maxAllowedVolume);
    if (clamped <= 1.0) {
      _baseVolume = clamped;
      _boostGain = 0.0;
    } else {
      _baseVolume = 1.0;
      _boostGain = clamped - 1.0;
    }
    if (clamped > 0.01) {
      _lastNonZeroVolume = clamped;
    }
  }

  /// Sets the effective output volume (`0.0` to [maxBoostMultiplier]).
  void setEffectiveVolume(double value, {bool markCustomPreset = false}) {
    final clamped = value.clamp(0.0, maxAllowedVolume);
    _isMuted = clamped <= 0.0001;
    _setInternalVolume(clamped);
    if (markCustomPreset) {
      _activePreset = VolumePreset.custom;
    }
    _recomputeSimulatedSpectrum(_simulationPhase);
    _dispatchPlatformSync();
    notifyListeners();
  }

  /// Sets the effective output volume from a percentage (`0` to `200`+).
  void setPercentage(int percentage) {
    setEffectiveVolume(percentage / 100.0);
  }

  /// Sets the effective output volume from a normalized ratio (`0.0` to `1.0`).
  void setNormalizedProgress(double normalized) {
    setEffectiveVolume(normalized.clamp(0.0, 1.0) * maxBoostMultiplier);
  }

  /// Increments the effective volume by [step] (default `0.05` = `5%`).
  void stepUp([double step = 0.05]) {
    if (_isMuted) {
      _isMuted = false;
    }
    setEffectiveVolume(effectiveVolume + step);
  }

  /// Decrements the effective volume by [step] (default `0.05` = `5%`).
  void stepDown([double step = 0.05]) {
    setEffectiveVolume(effectiveVolume - step);
  }

  /// Toggles mute on or off, restoring the previous non-zero volume when unmuted.
  void toggleMute() {
    if (isMuted) {
      _isMuted = false;
      final restore = _lastNonZeroVolume.clamp(0.1, maxAllowedVolume);
      _setInternalVolume(restore);
    } else {
      _isMuted = true;
    }
    _recomputeSimulatedSpectrum(_simulationPhase);
    _dispatchPlatformSync();
    notifyListeners();
  }

  /// Explicitly sets the mute state.
  void setMuted(bool muted) {
    if (_isMuted == muted) return;
    toggleMute();
  }

  /// Enables or disables software boost above `100%`.
  void setBoostEnabled(bool enabled) {
    if (_isBoostEnabled == enabled) return;
    _isBoostEnabled = enabled;
    if (!enabled && effectiveVolume > 1.0) {
      _setInternalVolume(1.0);
    }
    _recomputeSimulatedSpectrum(_simulationPhase);
    _dispatchPlatformSync();
    notifyListeners();
  }

  /// Toggles software boost above `100%`.
  void toggleBoostEnabled() => setBoostEnabled(!_isBoostEnabled);

  /// Enables or disables the anti-clipping brickwall limiter.
  void setLimiterEnabled(bool enabled) {
    if (_limiterEnabled == enabled) return;
    _limiterEnabled = enabled;
    _recomputeSimulatedSpectrum(_simulationPhase);
    _dispatchPlatformSync();
    notifyListeners();
  }

  /// Toggles the anti-clipping brickwall limiter.
  void toggleLimiter() => setLimiterEnabled(!_limiterEnabled);

  /// Sets the sub-bass resonance enhancer level (`0.0` to `1.0`).
  void setBassBoost(double value) {
    final next = value.clamp(0.0, 1.0);
    if ((_bassBoost - next).abs() < 0.001) return;
    _bassBoost = next;
    _activePreset = VolumePreset.custom;
    _recomputeSimulatedSpectrum(_simulationPhase);
    _dispatchPlatformSync();
    notifyListeners();
  }

  /// Sets the 3D spatial stereo virtualizer intensity (`0.0` to `1.0`).
  void setVirtualizer(double value) {
    final next = value.clamp(0.0, 1.0);
    if ((_virtualizer - next).abs() < 0.001) return;
    _virtualizer = next;
    _activePreset = VolumePreset.custom;
    _recomputeSimulatedSpectrum(_simulationPhase);
    _dispatchPlatformSync();
    notifyListeners();
  }

  /// Sets the dynamic loudness enhancer level (`0.0` to `1.0`).
  void setLoudnessEnhancer(double value) {
    final next = value.clamp(0.0, 1.0);
    if ((_loudnessEnhancer - next).abs() < 0.001) return;
    _loudnessEnhancer = next;
    _activePreset = VolumePreset.custom;
    _recomputeSimulatedSpectrum(_simulationPhase);
    _dispatchPlatformSync();
    notifyListeners();
  }

  /// Updates the decibel gain of the equalizer band at [index].
  void setBandGain(int index, double gainDb) {
    if (index < 0 || index >= _bands.length) return;
    final current = _bands[index];
    final updated = current.copyWith(gainDb: gainDb);
    if (current == updated) return;
    _bands[index] = updated;
    _activePreset = VolumePreset.custom;
    _recomputeSimulatedSpectrum(_simulationPhase);
    _dispatchPlatformSync();
    notifyListeners();
  }

  /// Resets all equalizer bands to `0.0 dB` flat response.
  void resetEqualizer() {
    for (var i = 0; i < _bands.length; i++) {
      _bands[i] = _bands[i].copyWith(gainDb: 0.0);
    }
    _activePreset = VolumePreset.normal;
    _recomputeSimulatedSpectrum(_simulationPhase);
    _dispatchPlatformSync();
    notifyListeners();
  }

  /// Applies a built-in [VolumePreset], configuring volume boost, EQ bands,
  /// bass boost, 3D virtualizer, and brickwall limiter simultaneously.
  void applyPreset(VolumePreset preset) {
    _activePreset = preset;
    _isMuted = false;
    switch (preset) {
      case VolumePreset.normal:
        _isBoostEnabled = true;
        _setInternalVolume(1.0);
        _bassBoost = 0.0;
        _virtualizer = 0.0;
        _loudnessEnhancer = 0.0;
        _limiterEnabled = true;
        _applyBandGains(const [0.0, 0.0, 0.0, 0.0, 0.0]);
      case VolumePreset.voiceBoost:
        _isBoostEnabled = true;
        _setInternalVolume(1.35);
        _bassBoost = 0.15;
        _virtualizer = 0.20;
        _loudnessEnhancer = 0.45;
        _limiterEnabled = true;
        _applyBandGains(const [-2.0, 1.5, 6.0, 5.5, 2.0]);
      case VolumePreset.bassExtreme:
        _isBoostEnabled = true;
        _setInternalVolume(1.55);
        _bassBoost = 0.90;
        _virtualizer = 0.35;
        _loudnessEnhancer = 0.60;
        _limiterEnabled = true;
        _applyBandGains(const [8.5, 6.0, -1.0, 1.5, 3.0]);
      case VolumePreset.cinema3D:
        _isBoostEnabled = true;
        _setInternalVolume(1.45);
        _bassBoost = 0.65;
        _virtualizer = 0.95;
        _loudnessEnhancer = 0.55;
        _limiterEnabled = true;
        _applyBandGains(const [5.5, 3.0, 1.0, 4.5, 6.5]);
      case VolumePreset.gaming:
        _isBoostEnabled = true;
        _setInternalVolume(1.40);
        _bassBoost = 0.45;
        _virtualizer = 0.85;
        _loudnessEnhancer = 0.50;
        _limiterEnabled = true;
        _applyBandGains(const [3.5, 1.0, 3.0, 7.0, 5.5]);
      case VolumePreset.maxOverdrive:
        _isBoostEnabled = true;
        _setInternalVolume(maxBoostMultiplier);
        _bassBoost = 0.80;
        _virtualizer = 0.60;
        _loudnessEnhancer = 0.95;
        _limiterEnabled = true;
        _applyBandGains(const [7.0, 4.5, 3.5, 6.0, 7.5]);
      case VolumePreset.nightLimiter:
        _isBoostEnabled = true;
        _setInternalVolume(0.85);
        _bassBoost = 0.10;
        _virtualizer = 0.30;
        _loudnessEnhancer = 0.70;
        _limiterEnabled = true;
        _applyBandGains(const [-4.5, -1.5, 3.0, 2.0, -3.0]);
      case VolumePreset.custom:
        break;
    }
    _recomputeSimulatedSpectrum(_simulationPhase);
    _dispatchPlatformSync();
    notifyListeners();
  }

  void _applyBandGains(List<double> gains) {
    for (var i = 0; i < _bands.length && i < gains.length; i++) {
      _bands[i] = _bands[i].copyWith(gainDb: gains[i]);
    }
  }

  /// Resets the controller to `100%` unity gain and flat equalizer response.
  void reset() {
    applyPreset(VolumePreset.normal);
  }

  /// Feeds real-time stereo peak levels and optional spectrum magnitudes from
  /// an external audio stream or analyzer.
  void updateAudioFrame({
    required double left,
    required double right,
    List<double>? spectrum,
  }) {
    _leftPeak = left.clamp(0.0, 1.0);
    _rightPeak = right.clamp(0.0, 1.0);
    _leftPeakHold = math.max(_leftPeak, _leftPeakHold * 0.96);
    _rightPeakHold = math.max(_rightPeak, _rightPeakHold * 0.96);

    if (spectrum != null && spectrum.isNotEmpty) {
      for (var i = 0; i < _spectrumBars.length; i++) {
        final srcIdx = (i * spectrum.length ~/ _spectrumBars.length)
            .clamp(0, spectrum.length - 1);
        _spectrumBars[i] = spectrum[srcIdx].clamp(0.0, 1.0);
      }
    }
    notifyListeners();
  }

  /// Advances the built-in acoustic spectrum & stereo VU meter simulation by
  /// one tick so visualizers animate smoothly in real time.
  void stepSimulation([double deltaPhase = 0.18]) {
    _simulationPhase = (_simulationPhase + deltaPhase) % (math.pi * 200);
    _recomputeSimulatedSpectrum(_simulationPhase);
    notifyListeners();
  }

  void _recomputeSimulatedSpectrum(double phase) {
    if (isMuted) {
      _leftPeak = 0.0;
      _rightPeak = 0.0;
      _leftPeakHold = 0.0;
      _rightPeakHold = 0.0;
      for (var i = 0; i < _spectrumBars.length; i++) {
        _spectrumBars[i] = 0.04;
      }
      return;
    }

    final gainFactor = (effectiveVolume / maxBoostMultiplier).clamp(0.05, 1.0);
    var sumEnergy = 0.0;

    for (var i = 0; i < _spectrumBars.length; i++) {
      final normX = i / (_spectrumBars.length - 1);
      // Interpolate influence from the 5 EQ bands
      final bandPos = normX * (_bands.length - 1);
      final b0 = bandPos.floor().clamp(0, _bands.length - 1);
      final b1 = (b0 + 1).clamp(0, _bands.length - 1);
      final frac = bandPos - b0;
      final eqNormalized =
          _bands[b0].normalized * (1.0 - frac) + _bands[b1].normalized * frac;

      // Add low-frequency energy from bassBoost
      final bassEnvelope = math.pow(1.0 - normX, 2.2) * _bassBoost * 0.42;

      // Dynamic harmonic wave oscillation
      final wave1 = math.sin(phase * 1.7 + i * 0.55) * 0.14;
      final wave2 = math.cos(phase * 2.9 - i * 0.85) * 0.09;

      var bar = (0.28 + eqNormalized * 0.48 + bassEnvelope + wave1 + wave2) *
          (0.35 + gainFactor * 0.85);
      if (_limiterEnabled && bar > 0.94) {
        bar = 0.94;
      }
      _spectrumBars[i] = bar.clamp(0.06, 1.0);
      sumEnergy += _spectrumBars[i];
    }

    final avgEnergy = sumEnergy / _spectrumBars.length;
    final stereoSpread = 0.04 + _virtualizer * 0.08;
    final rawLeft = avgEnergy * 1.12 + math.sin(phase * 2.1) * stereoSpread;
    final rawRight = avgEnergy * 1.10 + math.cos(phase * 2.3) * stereoSpread;

    final cap = _limiterEnabled ? 0.95 : 1.0;
    _leftPeak = rawLeft.clamp(0.05, cap);
    _rightPeak = rawRight.clamp(0.05, cap);
    _leftPeakHold =
        math.max(_leftPeak, (_leftPeakHold - 0.015).clamp(0.0, 1.0));
    _rightPeakHold =
        math.max(_rightPeak, (_rightPeakHold - 0.015).clamp(0.0, 1.0));
  }

  Future<void> _dispatchPlatformSync() async {
    if (!enablePlatformChannel) return;
    final channel = MethodChannel(channelName);
    try {
      await channel.invokeMethod<void>('setBoosterState', <String, Object>{
        'baseVolume': baseVolume,
        'boostGain': boostGain,
        'effectiveVolume': effectiveVolume,
        'decibelGain': decibelGain,
        'isMuted': isMuted,
        'isBoostEnabled': isBoostEnabled,
        'limiterEnabled': limiterEnabled,
        'bassBoost': bassBoost,
        'virtualizer': virtualizer,
        'loudnessEnhancer': loudnessEnhancer,
        'bands': _bands
            .map((b) => <String, Object>{
                  'frequencyHz': b.frequencyHz,
                  'gainDb': b.gainDb,
                })
            .toList(),
      });
    } on MissingPluginException {
      // Pure Flutter fallback when no native host plugin is registered.
    } on PlatformException {
      // Ignore host audio hardware errors in UI preview mode.
    }
  }
}
