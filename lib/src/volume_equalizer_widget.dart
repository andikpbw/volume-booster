import 'package:flutter/material.dart';
import 'volume_booster_controller.dart';
import 'volume_booster_painter.dart';
import 'volume_booster_style.dart';
import 'volume_booster_types.dart';

/// An interactive multi-band graphic equalizer and acoustic enhancer deck
/// featuring a real-time cubic-Bezier frequency response curve, vertical band
/// faders, preset selector chips, Bass Boost, 3D Virtualizer, and Brickwall Limiter.
class VolumeEqualizerWidget extends StatefulWidget {
  /// Creates a [VolumeEqualizerWidget].
  const VolumeEqualizerWidget({
    super.key,
    this.controller,
    this.style,
    this.height = 170.0,
    this.showPresets = true,
    this.showEnhancers = true,
    this.onPresetChanged,
    this.onBandChanged,
  });

  /// Optional external [VolumeBoosterController].
  final VolumeBoosterController? controller;

  /// Visual theme style configuration.
  final VolumeBoosterStyle? style;

  /// Height of the equalizer curve and vertical fader area.
  final double height;

  /// Whether to render the top scrollable preset selector strip.
  final bool showPresets;

  /// Whether to render the bottom Bass Boost, 3D Virtualizer, and Limiter controls.
  final bool showEnhancers;

  /// Callback fired when the user selects an acoustic preset.
  final ValueChanged<VolumePreset>? onPresetChanged;

  /// Callback fired when a frequency band gain is adjusted (`index`, `gainDb`).
  final void Function(int index, double gainDb)? onBandChanged;

  @override
  State<VolumeEqualizerWidget> createState() => _VolumeEqualizerWidgetState();
}

class _VolumeEqualizerWidgetState extends State<VolumeEqualizerWidget> {
  VolumeBoosterController? _internalController;

  VolumeBoosterController get _effectiveController =>
      widget.controller ?? _internalController!;

  VolumeBoosterStyle get _effectiveStyle =>
      widget.style ?? VolumeBoosterStyle.cyberNeon();

  static const List<VolumePreset> _selectablePresets = <VolumePreset>[
    VolumePreset.normal,
    VolumePreset.voiceBoost,
    VolumePreset.bassExtreme,
    VolumePreset.cinema3D,
    VolumePreset.gaming,
    VolumePreset.maxOverdrive,
    VolumePreset.nightLimiter,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _internalController = VolumeBoosterController();
    }
    _effectiveController.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(covariant VolumeEqualizerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_handleControllerChanged);
      if (widget.controller == null) {
        _internalController ??= VolumeBoosterController();
      } else {
        _internalController?.dispose();
        _internalController = null;
      }
      _effectiveController.addListener(_handleControllerChanged);
    }
  }

  @override
  void dispose() {
    _effectiveController.removeListener(_handleControllerChanged);
    _internalController?.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _updateBandFromDy(
    int index,
    EqualizerBand band,
    double dy,
    double maxHeight,
  ) {
    if (maxHeight <= 0) return;
    final inverted = 1.0 - (dy / maxHeight).clamp(0.0, 1.0);
    final newGain =
        band.minGainDb + inverted * (band.maxGainDb - band.minGainDb);
    final snappedGain = newGain.abs() < 0.45 ? 0.0 : newGain;
    _effectiveController.setBandGain(index, snappedGain);
    widget.onBandChanged?.call(index, _effectiveController.bands[index].gainDb);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _effectiveController;
    final style = _effectiveStyle;
    final accentColor = style.colorForVolume(
      ctrl.effectiveVolume,
      maxBoostMultiplier: ctrl.maxBoostMultiplier,
      isMuted: ctrl.isMuted,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: style.cardColor,
        borderRadius: BorderRadius.circular(style.borderRadius * 0.85),
        border: Border.all(
          color: style.borderColor,
          width: style.borderWidth,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.equalizer_rounded, size: 18, color: accentColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '5-Band Graphic Equalizer & DSP',
                  style: TextStyle(
                    color: style.primaryTextColor,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              InkWell(
                onTap: ctrl.resetEqualizer,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Text(
                    'Flat 0dB',
                    style: TextStyle(
                      color: style.safeZoneColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (widget.showPresets) ...[
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _selectablePresets.map((preset) {
                  final selected = ctrl.activePreset == preset;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      onTap: () {
                        ctrl.applyPreset(preset);
                        widget.onPresetChanged?.call(preset);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? accentColor.withValues(alpha: 0.22)
                              : style.surfaceColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected ? accentColor : style.borderColor,
                          ),
                        ),
                        child: Text(
                          preset.label,
                          style: TextStyle(
                            color: selected
                                ? accentColor
                                : style.secondaryTextColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            height: widget.height,
            child: Column(
              children: [
                // Top dB readouts per band
                Row(
                  children: ctrl.bands.map((band) {
                    final isPositive = band.gainDb > 0.1;
                    return Expanded(
                      child: Center(
                        child: Text(
                          '${isPositive ? '+' : ''}${band.gainDb.toStringAsFixed(1)}',
                          style: TextStyle(
                            color: isPositive
                                ? accentColor
                                : style.secondaryTextColor,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 4),
                // Interactive Bezier Curve + Vertical Faders
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final faderHeight = constraints.maxHeight;
                      return Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: EqualizerCurvePainter(
                                bands: ctrl.bands,
                                style: style,
                                accentColor: accentColor,
                              ),
                            ),
                          ),
                          Row(
                            children: List<Widget>.generate(
                              ctrl.bands.length,
                              (index) {
                                final band = ctrl.bands[index];
                                return Expanded(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTapDown: (d) => _updateBandFromDy(
                                      index,
                                      band,
                                      d.localPosition.dy,
                                      faderHeight,
                                    ),
                                    onVerticalDragStart: (d) =>
                                        _updateBandFromDy(
                                      index,
                                      band,
                                      d.localPosition.dy,
                                      faderHeight,
                                    ),
                                    onVerticalDragUpdate: (d) =>
                                        _updateBandFromDy(
                                      index,
                                      band,
                                      d.localPosition.dy,
                                      faderHeight,
                                    ),
                                    child: _BandFaderRail(
                                      band: band,
                                      accentColor: accentColor,
                                      style: style,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 6),
                // Bottom frequency labels
                Row(
                  children: ctrl.bands.map((band) {
                    return Expanded(
                      child: Center(
                        child: Text(
                          band.label,
                          style: TextStyle(
                            color: style.secondaryTextColor,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          if (widget.showEnhancers) ...[
            const SizedBox(height: 14),
            _buildAcousticEnhancers(ctrl, style, accentColor),
          ],
        ],
      ),
    );
  }

  Widget _buildAcousticEnhancers(
    VolumeBoosterController ctrl,
    VolumeBoosterStyle style,
    Color accentColor,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _EnhancerMiniBar(
                label: 'Bass Boost',
                value: ctrl.bassBoost,
                color: style.boostZoneColor,
                style: style,
                onChanged: ctrl.setBassBoost,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _EnhancerMiniBar(
                label: '3D Virtualizer',
                value: ctrl.virtualizer,
                color: style.safeZoneColor,
                style: style,
                onChanged: ctrl.setVirtualizer,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: ctrl.toggleLimiter,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: style.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ctrl.limiterEnabled
                    ? style.safeZoneColor.withValues(alpha: 0.6)
                    : style.borderColor,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.shield_rounded,
                  size: 16,
                  color: ctrl.limiterEnabled
                      ? style.safeZoneColor
                      : style.secondaryTextColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Brickwall Anti-Clipping Safety Limiter',
                    style: TextStyle(
                      color: style.primaryTextColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: ctrl.limiterEnabled
                        ? style.safeZoneColor.withValues(alpha: 0.2)
                        : style.dangerZoneColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ctrl.limiterEnabled ? 'PROTECTED' : 'BYPASSED',
                    style: TextStyle(
                      color: ctrl.limiterEnabled
                          ? style.safeZoneColor
                          : style.dangerZoneColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BandFaderRail extends StatelessWidget {
  const _BandFaderRail({
    required this.band,
    required this.accentColor,
    required this.style,
  });

  final EqualizerBand band;
  final Color accentColor;
  final VolumeBoosterStyle style;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final thumbY = (h * (1.0 - band.normalized)).clamp(8.0, h - 8.0);
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 3,
              height: h,
              decoration: BoxDecoration(
                color: style.inactiveTrackColor.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Positioned(
              top: thumbY - 7,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: style.cardColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accentColor,
                    width: 2.6,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EnhancerMiniBar extends StatelessWidget {
  const _EnhancerMiniBar({
    required this.label,
    required this.value,
    required this.color,
    required this.style,
    required this.onChanged,
  });

  final String label;
  final double value;
  final Color color;
  final VolumeBoosterStyle style;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final pct = (value * 100).round();
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: style.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: style.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: style.primaryTextColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$pct%',
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (d) {
                  if (constraints.maxWidth > 0) {
                    onChanged(d.localPosition.dx / constraints.maxWidth);
                  }
                },
                onHorizontalDragUpdate: (d) {
                  if (constraints.maxWidth > 0) {
                    onChanged(d.localPosition.dx / constraints.maxWidth);
                  }
                },
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: style.inactiveTrackColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: value.clamp(0.04, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
