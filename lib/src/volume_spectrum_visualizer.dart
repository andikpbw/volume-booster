import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'volume_booster_controller.dart';
import 'volume_booster_painter.dart';
import 'volume_booster_style.dart';
import 'volume_booster_types.dart';

/// A real-time audio frequency spectrum visualizer and stereo L/R VU peak meter
/// supporting segmented LED bars, glowing harmonic waveforms, and center-mirrored
/// spectrum rendering.
class VolumeSpectrumVisualizer extends StatefulWidget {
  /// Creates a [VolumeSpectrumVisualizer].
  const VolumeSpectrumVisualizer({
    super.key,
    this.controller,
    this.style,
    this.initialMode = VisualizerMode.ledBars,
    this.height = 100.0,
    this.autoAnimate = false,
    this.showModeSelector = true,
    this.showStereoVuMeters = true,
  });

  /// Optional external [VolumeBoosterController].
  final VolumeBoosterController? controller;

  /// Visual theme style configuration.
  final VolumeBoosterStyle? style;

  /// Initial rendering mode (`ledBars`, `smoothWave`, or `dualMirror`).
  final VisualizerMode initialMode;

  /// Height of the frequency spectrum canvas in logical pixels.
  final double height;

  /// Whether to run an internal animation ticker that drives simulated
  /// acoustic spectrum updates on the controller.
  final bool autoAnimate;

  /// Whether to display the mode toggle pills (`LED`, `Wave`, `Mirror`).
  final bool showModeSelector;

  /// Whether to render the dual Stereo L/R VU peak meters beneath the spectrum.
  final bool showStereoVuMeters;

  @override
  State<VolumeSpectrumVisualizer> createState() =>
      _VolumeSpectrumVisualizerState();
}

class _VolumeSpectrumVisualizerState extends State<VolumeSpectrumVisualizer>
    with SingleTickerProviderStateMixin {
  VolumeBoosterController? _internalController;
  late VisualizerMode _mode;
  Ticker? _ticker;
  Duration _lastTick = Duration.zero;

  VolumeBoosterController get _effectiveController =>
      widget.controller ?? _internalController!;

  VolumeBoosterStyle get _effectiveStyle =>
      widget.style ?? VolumeBoosterStyle.cyberNeon();

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    if (widget.controller == null) {
      _internalController = VolumeBoosterController();
    }
    _effectiveController.addListener(_handleControllerChanged);
    _syncTicker();
  }

  @override
  void didUpdateWidget(covariant VolumeSpectrumVisualizer oldWidget) {
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
    if (oldWidget.autoAnimate != widget.autoAnimate) {
      _syncTicker();
    }
  }

  void _syncTicker() {
    _ticker?.dispose();
    _ticker = null;
    if (widget.autoAnimate) {
      _ticker = createTicker((elapsed) {
        if (elapsed - _lastTick >= const Duration(milliseconds: 55)) {
          _lastTick = elapsed;
          _effectiveController.stepSimulation(0.22);
        }
      })
        ..start();
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: style.cardColor,
        borderRadius: BorderRadius.circular(style.borderRadius * 0.8),
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
              Icon(Icons.graphic_eq_rounded, size: 17, color: activeColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Real-Time Spectrum & VU Telemetry',
                  style: TextStyle(
                    color: style.primaryTextColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (widget.showModeSelector) _buildModePills(style, activeColor),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: widget.height,
            child: CustomPaint(
              painter: SpectrumVisualizerPainter(
                bars: ctrl.spectrumBars,
                mode: _mode,
                style: style,
                effectiveVolume: ctrl.effectiveVolume,
                maxBoostMultiplier: ctrl.maxBoostMultiplier,
                isMuted: ctrl.isMuted,
              ),
            ),
          ),
          if (widget.showStereoVuMeters) ...[
            const SizedBox(height: 12),
            StereoVuMeter(
              controller: ctrl,
              style: style,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModePills(VolumeBoosterStyle style, Color activeColor) {
    const items = <(VisualizerMode, String)>[
      (VisualizerMode.ledBars, 'LED'),
      (VisualizerMode.smoothWave, 'Wave'),
      (VisualizerMode.dualMirror, 'Mirror'),
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: items.map((entry) {
        final selected = _mode == entry.$1;
        return Padding(
          padding: const EdgeInsets.only(left: 4),
          child: InkWell(
            onTap: () => setState(() => _mode = entry.$1),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: selected
                    ? activeColor.withValues(alpha: 0.22)
                    : style.surfaceColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected ? activeColor : style.borderColor,
                ),
              ),
              child: Text(
                entry.$2,
                style: TextStyle(
                  color: selected ? activeColor : style.secondaryTextColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Dual-channel Left/Right stereo VU decibel LED bar meter with peak-hold
/// indicator and clipping warning badge.
class StereoVuMeter extends StatelessWidget {
  /// Creates a [StereoVuMeter].
  const StereoVuMeter({
    super.key,
    required this.controller,
    this.style,
  });

  /// Controller providing stereo channel peak levels.
  final VolumeBoosterController controller;

  /// Optional theme style configuration.
  final VolumeBoosterStyle? style;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = style ?? VolumeBoosterStyle.cyberNeon();
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final clipping = controller.isClipping;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ChannelVuRow(
              channelLabel: 'L',
              level: controller.leftPeak,
              peakHold: controller.leftPeakHold,
              isClipping: clipping,
              style: effectiveStyle,
            ),
            const SizedBox(height: 6),
            _ChannelVuRow(
              channelLabel: 'R',
              level: controller.rightPeak,
              peakHold: controller.rightPeakHold,
              isClipping: clipping,
              style: effectiveStyle,
            ),
          ],
        );
      },
    );
  }
}

class _ChannelVuRow extends StatelessWidget {
  const _ChannelVuRow({
    required this.channelLabel,
    required this.level,
    required this.peakHold,
    required this.isClipping,
    required this.style,
  });

  final String channelLabel;
  final double level;
  final double peakHold;
  final bool isClipping;
  final VolumeBoosterStyle style;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 16,
          child: Text(
            channelLabel,
            style: TextStyle(
              color: style.secondaryTextColor,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: SizedBox(
            height: 10,
            child: CustomPaint(
              painter: _VuLedStripPainter(
                level: level,
                peakHold: peakHold,
                style: style,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
          decoration: BoxDecoration(
            color: isClipping
                ? style.dangerZoneColor.withValues(alpha: 0.25)
                : style.surfaceColor,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: isClipping ? style.dangerZoneColor : style.borderColor,
            ),
          ),
          child: Text(
            isClipping ? 'CLIP' : 'OK',
            style: TextStyle(
              color:
                  isClipping ? style.dangerZoneColor : style.secondaryTextColor,
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _VuLedStripPainter extends CustomPainter {
  const _VuLedStripPainter({
    required this.level,
    required this.peakHold,
    required this.style,
  });

  final double level;
  final double peakHold;
  final VolumeBoosterStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    const segments = 24;
    const gap = 2.0;
    final segW = (size.width - (segments - 1) * gap) / segments;
    final holdIdx = (peakHold.clamp(0.0, 1.0) * (segments - 1)).round();

    for (var i = 0; i < segments; i++) {
      final ratio = (i + 1) / segments;
      final isLit = ratio <= level + 0.015;
      final isHold = level > 0.02 && i == holdIdx;
      final x = i * (segW + gap);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, 0, segW.clamp(1.5, 25.0), size.height),
        const Radius.circular(2),
      );

      Color color;
      if (ratio <= 0.62) {
        color = style.safeZoneColor;
      } else if (ratio <= 0.84) {
        color = style.boostZoneColor;
      } else {
        color = style.dangerZoneColor;
      }

      canvas.drawRRect(
        rect,
        Paint()
          ..color = (isLit || isHold)
              ? color
              : style.inactiveTrackColor.withValues(alpha: 0.55),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VuLedStripPainter oldDelegate) {
    return oldDelegate.level != level ||
        oldDelegate.peakHold != peakHold ||
        oldDelegate.style != style;
  }
}
