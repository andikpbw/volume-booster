import 'package:flutter/material.dart';
import 'volume_booster_controller.dart';
import 'volume_booster_dial.dart';
import 'volume_booster_slider.dart';
import 'volume_booster_style.dart';
import 'volume_booster_types.dart';
import 'volume_equalizer_widget.dart';
import 'volume_spectrum_visualizer.dart';

/// An all-in-one flagship Volume Booster & Audio DSP Studio Console combining
/// `VolumeBoosterDial`, `VolumeBoosterSlider`, `VolumeSpectrumVisualizer`,
/// `VolumeEqualizerWidget`, and an automatic overdrive hearing-safety advisory.
class VolumeBoosterConsole extends StatefulWidget {
  /// Creates a [VolumeBoosterConsole].
  const VolumeBoosterConsole({
    super.key,
    this.controller,
    this.title = 'Volume Booster Pro',
    this.subtitle = 'Pre-Amp Overdrive • 5-Band EQ • Brickwall Limiter',
    this.style,
    this.dialSize = 215.0,
    this.showSlider = true,
    this.showVisualizer = true,
    this.showEqualizer = true,
    this.autoAnimateVisualizer = false,
    this.showSafetyWarningBanner = true,
    this.onVolumeChanged,
  });

  /// Optional external [VolumeBoosterController].
  final VolumeBoosterController? controller;

  /// Primary console title displayed in the header bar.
  final String title;

  /// Subtitle displayed below [title] in the header bar.
  final String subtitle;

  /// Visual theme style configuration. Defaults to [VolumeBoosterStyle.cyberNeon].
  final VolumeBoosterStyle? style;

  /// Diameter of the rotary boost dial.
  final double dialSize;

  /// Whether to render the dual-zone linear slider below the rotary dial.
  final bool showSlider;

  /// Whether to render the frequency spectrum and stereo VU meters.
  final bool showVisualizer;

  /// Whether to render the 5-band graphic equalizer and acoustic enhancers.
  final bool showEqualizer;

  /// Whether the embedded visualizer should auto-animate continuously.
  final bool autoAnimateVisualizer;

  /// Whether to show an automatic hearing/speaker advisory banner when boosted
  /// into the high overdrive zone (`> 155%`).
  final bool showSafetyWarningBanner;

  /// Callback fired whenever the effective output volume changes.
  final ValueChanged<double>? onVolumeChanged;

  @override
  State<VolumeBoosterConsole> createState() => _VolumeBoosterConsoleState();
}

class _VolumeBoosterConsoleState extends State<VolumeBoosterConsole> {
  VolumeBoosterController? _internalController;

  VolumeBoosterController get _effectiveController =>
      widget.controller ?? _internalController!;

  VolumeBoosterStyle get _effectiveStyle =>
      widget.style ?? VolumeBoosterStyle.cyberNeon();

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _internalController = VolumeBoosterController();
    }
    _effectiveController.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(covariant VolumeBoosterConsole oldWidget) {
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

  @override
  Widget build(BuildContext context) {
    final ctrl = _effectiveController;
    final style = _effectiveStyle;
    final activeColor = style.colorForVolume(
      ctrl.effectiveVolume,
      maxBoostMultiplier: ctrl.maxBoostMultiplier,
      isMuted: ctrl.isMuted,
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: BorderRadius.circular(style.borderRadius),
        border: Border.all(
          color: style.borderColor,
          width: style.borderWidth,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(ctrl, style, activeColor),
          const SizedBox(height: 16),
          Center(
            child: VolumeBoosterDial(
              controller: ctrl,
              size: widget.dialSize,
              style: style,
              onChanged: widget.onVolumeChanged,
            ),
          ),
          if (widget.showSafetyWarningBanner &&
              ctrl.safetyLevel == VolumeSafetyLevel.overdriveDanger) ...[
            const SizedBox(height: 14),
            _buildOverdriveAdvisory(ctrl, style),
          ],
          if (widget.showSlider) ...[
            const SizedBox(height: 14),
            VolumeBoosterSlider(
              controller: ctrl,
              style: style,
              onChanged: widget.onVolumeChanged,
            ),
          ],
          if (widget.showVisualizer) ...[
            const SizedBox(height: 14),
            VolumeSpectrumVisualizer(
              controller: ctrl,
              style: style,
              autoAnimate: widget.autoAnimateVisualizer,
            ),
          ],
          if (widget.showEqualizer) ...[
            const SizedBox(height: 14),
            VolumeEqualizerWidget(
              controller: ctrl,
              style: style,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(
    VolumeBoosterController ctrl,
    VolumeBoosterStyle style,
    Color activeColor,
  ) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: activeColor.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: activeColor.withValues(alpha: 0.5),
            ),
          ),
          child: Icon(
            Icons.speaker_rounded,
            color: activeColor,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: TextStyle(
                  color: style.primaryTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.subtitle,
                style: TextStyle(
                  color: style.secondaryTextColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: ctrl.toggleBoostEnabled,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: ctrl.isBoostEnabled
                  ? activeColor.withValues(alpha: 0.18)
                  : style.surfaceColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: ctrl.isBoostEnabled ? activeColor : style.borderColor,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bolt_rounded,
                  size: 14,
                  color: ctrl.isBoostEnabled
                      ? activeColor
                      : style.secondaryTextColor,
                ),
                const SizedBox(width: 4),
                Text(
                  ctrl.isBoostEnabled ? 'BOOST ON' : '100% CAP',
                  style: TextStyle(
                    color: ctrl.isBoostEnabled
                        ? activeColor
                        : style.secondaryTextColor,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverdriveAdvisory(
    VolumeBoosterController ctrl,
    VolumeBoosterStyle style,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: style.dangerZoneColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: style.dangerZoneColor.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: style.dangerZoneColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              ctrl.limiterEnabled
                  ? 'Overdrive zone active (${ctrl.effectivePercentage}%). Brickwall limiter is protecting speakers from clipping.'
                  : 'High clipping risk (${ctrl.effectivePercentage}%)! Enable the Brickwall Limiter to prevent distortion.',
              style: TextStyle(
                color: style.primaryTextColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
