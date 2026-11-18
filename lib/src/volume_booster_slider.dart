import 'package:flutter/material.dart';
import 'volume_booster_controller.dart';
import 'volume_booster_style.dart';

/// A sleek dual-zone volume and overdrive boost slider bar with a clearly
/// marked `100%` (`0 dB`) unity gain boundary, segmented LED or smooth gradient
/// fill, mute toggle button, and live decibel badge.
class VolumeBoosterSlider extends StatefulWidget {
  /// Creates a [VolumeBoosterSlider].
  const VolumeBoosterSlider({
    super.key,
    this.controller,
    this.initialVolume = 1.25,
    this.maxBoostMultiplier = 2.0,
    this.style,
    this.label = 'Master Boost Output',
    this.segmentedLedTrack = true,
    this.showHeader = true,
    this.showMuteButton = true,
    this.trackHeight = 20.0,
    this.onChanged,
  }) : assert(maxBoostMultiplier >= 1.0, 'maxBoostMultiplier must be >= 1.0');

  /// Optional external [VolumeBoosterController].
  final VolumeBoosterController? controller;

  /// Initial effective volume multiplier when [controller] is null.
  final double initialVolume;

  /// Maximum amplification multiplier (`2.0` = `200%`) when [controller] is null.
  final double maxBoostMultiplier;

  /// Visual theme style configuration.
  final VolumeBoosterStyle? style;

  /// Title text displayed above the slider track.
  final String label;

  /// Whether to render discrete segmented LED blocks instead of a continuous bar.
  final bool segmentedLedTrack;

  /// Whether to render the top label, decibel pill, and percentage readout.
  final bool showHeader;

  /// Whether to display the leading mute toggle button.
  final bool showMuteButton;

  /// Height of the interactive slider track in logical pixels.
  final double trackHeight;

  /// Callback fired when the user drags or taps the slider.
  final ValueChanged<double>? onChanged;

  @override
  State<VolumeBoosterSlider> createState() => _VolumeBoosterSliderState();
}

class _VolumeBoosterSliderState extends State<VolumeBoosterSlider> {
  VolumeBoosterController? _internalController;

  VolumeBoosterController get _effectiveController =>
      widget.controller ?? _internalController!;

  VolumeBoosterStyle get _effectiveStyle =>
      widget.style ?? VolumeBoosterStyle.cyberNeon();

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _internalController = VolumeBoosterController(
        initialVolume: widget.initialVolume,
        maxBoostMultiplier: widget.maxBoostMultiplier,
      );
    }
    _effectiveController.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(covariant VolumeBoosterSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_handleControllerChanged);
      if (widget.controller == null) {
        _internalController ??= VolumeBoosterController(
          initialVolume: widget.initialVolume,
          maxBoostMultiplier: widget.maxBoostMultiplier,
        );
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

  void _updateFromDx(double dx, double maxWidth) {
    if (maxWidth <= 0) return;
    final ratio = (dx / maxWidth).clamp(0.0, 1.0);
    _effectiveController.setNormalizedProgress(ratio);
    widget.onChanged?.call(_effectiveController.effectiveVolume);
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
        borderRadius: BorderRadius.circular(style.borderRadius * 0.75),
        border: Border.all(
          color: style.borderColor,
          width: style.borderWidth,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showHeader) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      color: style.primaryTextColor,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: activeColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: activeColor.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Text(
                    ctrl.formattedDecibels,
                    style: TextStyle(
                      color: activeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  ctrl.isMuted ? '0%' : '${ctrl.effectivePercentage}%',
                  style: TextStyle(
                    color: style.primaryTextColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              if (widget.showMuteButton) ...[
                InkWell(
                  onTap: () {
                    ctrl.toggleMute();
                    widget.onChanged?.call(ctrl.effectiveVolume);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: ctrl.isMuted
                          ? style.dangerZoneColor.withValues(alpha: 0.18)
                          : style.surfaceColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: ctrl.isMuted
                            ? style.dangerZoneColor
                            : style.borderColor,
                      ),
                    ),
                    child: Icon(
                      ctrl.isMuted
                          ? Icons.volume_off_rounded
                          : (ctrl.effectiveVolume > 1.0
                              ? Icons.volume_up_rounded
                              : Icons.volume_down_rounded),
                      size: 18,
                      color: ctrl.isMuted ? style.dangerZoneColor : activeColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (d) => _updateFromDx(
                          d.localPosition.dx, constraints.maxWidth),
                      onHorizontalDragStart: (d) => _updateFromDx(
                          d.localPosition.dx, constraints.maxWidth),
                      onHorizontalDragUpdate: (d) => _updateFromDx(
                          d.localPosition.dx, constraints.maxWidth),
                      child: SizedBox(
                        height: widget.trackHeight + 14,
                        child: CustomPaint(
                          size: Size(
                            constraints.maxWidth,
                            widget.trackHeight + 14,
                          ),
                          painter: _DualZoneSliderPainter(
                            progress: ctrl.normalizedProgress,
                            unityRatio: ctrl.unityMarkerRatio,
                            maxBoostMultiplier: ctrl.maxBoostMultiplier,
                            isMuted: ctrl.isMuted,
                            segmented: widget.segmentedLedTrack,
                            trackHeight: widget.trackHeight,
                            style: style,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DualZoneSliderPainter extends CustomPainter {
  const _DualZoneSliderPainter({
    required this.progress,
    required this.unityRatio,
    required this.maxBoostMultiplier,
    required this.isMuted,
    required this.segmented,
    required this.trackHeight,
    required this.style,
  });

  final double progress;
  final double unityRatio;
  final double maxBoostMultiplier;
  final bool isMuted;
  final bool segmented;
  final double trackHeight;
  final VolumeBoosterStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    const trackTop = 2.0;
    final trackRect = Rect.fromLTWH(0, trackTop, size.width, trackHeight);

    if (segmented) {
      const segments = 28;
      const gap = 2.5;
      final segWidth = (size.width - (segments - 1) * gap) / segments;

      for (var i = 0; i < segments; i++) {
        final t = (i + 1) / segments;
        final isLit = !isMuted && t <= progress + 0.015;
        final x = i * (segWidth + gap);
        final rrect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, trackTop, segWidth.clamp(2.0, 40.0), trackHeight),
          const Radius.circular(4),
        );

        final zoneColor = style.colorForVolume(
          t * maxBoostMultiplier,
          maxBoostMultiplier: maxBoostMultiplier,
          isMuted: isMuted,
        );

        canvas.drawRRect(
          rrect,
          Paint()
            ..color = isLit
                ? zoneColor
                : style.inactiveTrackColor.withValues(alpha: 0.7),
        );
      }
    } else {
      final bgRRect = RRect.fromRectAndRadius(
        trackRect,
        Radius.circular(trackHeight / 2),
      );
      canvas.drawRRect(bgRRect, Paint()..color = style.inactiveTrackColor);

      if (!isMuted && progress > 0.005) {
        final fillWidth = (size.width * progress).clamp(6.0, size.width);
        final fillRRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(0, trackTop, fillWidth, trackHeight),
          Radius.circular(trackHeight / 2),
        );
        final fillPaint = Paint()
          ..shader = LinearGradient(
            colors: <Color>[
              style.safeZoneColor,
              style.boostZoneColor,
              style.dangerZoneColor,
            ],
            stops: <double>[0.0, unityRatio.clamp(0.2, 0.8), 1.0],
          ).createShader(trackRect);
        canvas.drawRRect(fillRRect, fillPaint);
      }
    }

    // Unity 100% (0 dB) boundary marker line
    final unityX = size.width * unityRatio;
    final markerPaint = Paint()
      ..color = style.primaryTextColor.withValues(alpha: 0.85)
      ..strokeWidth = 2.0;
    canvas.drawLine(
      Offset(unityX, 0),
      Offset(unityX, trackTop + trackHeight + 3),
      markerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DualZoneSliderPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isMuted != isMuted ||
        oldDelegate.segmented != segmented ||
        oldDelegate.style != style;
  }
}
