import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'volume_booster_controller.dart';
import 'volume_booster_painter.dart';
import 'volume_booster_style.dart';
import 'volume_booster_types.dart';

/// An interactive 3D rotary volume & overdrive boost dial with segmented LED
/// perimeter ticks, multi-zone neon progress arc, harmonic overdrive pulse rings,
/// live decibel readout, and quick-jump preset buttons.
class VolumeBoosterDial extends StatefulWidget {
  /// Creates a [VolumeBoosterDial].
  const VolumeBoosterDial({
    super.key,
    this.controller,
    this.initialVolume = 1.25,
    this.maxBoostMultiplier = 2.0,
    this.size = 240.0,
    this.style,
    this.showQuickButtons = true,
    this.showDecibelBadge = true,
    this.showSafetyBadge = true,
    this.enableHaptics = true,
    this.onChanged,
    this.onMuteChanged,
  }) : assert(maxBoostMultiplier >= 1.0, 'maxBoostMultiplier must be >= 1.0');

  /// Optional external [VolumeBoosterController]. If omitted, an internal
  /// controller is created automatically.
  final VolumeBoosterController? controller;

  /// Initial effective volume multiplier (`1.0` = `100%`) when [controller] is null.
  final double initialVolume;

  /// Maximum amplification multiplier (`2.0` = `200%`) when [controller] is null.
  final double maxBoostMultiplier;

  /// Diameter of the rotary dial in logical pixels.
  final double size;

  /// Visual theme style for the dial. Defaults to [VolumeBoosterStyle.cyberNeon].
  final VolumeBoosterStyle? style;

  /// Whether to render the quick-jump boost buttons (`Mute`, `100%`, `150%`, `Max`)
  /// beneath the rotary dial.
  final bool showQuickButtons;

  /// Whether to display the live decibel gain pill (`+6.0 dB`) inside the dial.
  final bool showDecibelBadge;

  /// Whether to display the safety zone badge (`SAFE GAIN`, `TURBO BOOST`, etc.).
  final bool showSafetyBadge;

  /// Whether to trigger light haptic ticks when crossing boost milestones.
  final bool enableHaptics;

  /// Callback fired whenever the effective volume multiplier changes.
  final ValueChanged<double>? onChanged;

  /// Callback fired whenever the mute state changes.
  final ValueChanged<bool>? onMuteChanged;

  @override
  State<VolumeBoosterDial> createState() => _VolumeBoosterDialState();
}

class _VolumeBoosterDialState extends State<VolumeBoosterDial>
    with SingleTickerProviderStateMixin {
  VolumeBoosterController? _internalController;
  late final AnimationController _pulseController;
  final FocusNode _focusNode = FocusNode(debugLabel: 'VolumeBoosterDial');
  int _lastHapticPercentage = -1;

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
    _lastHapticPercentage = _effectiveController.effectivePercentage;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant VolumeBoosterDial oldWidget) {
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
    _pulseController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (!mounted) return;
    final pct = _effectiveController.effectivePercentage;
    if (widget.enableHaptics && (pct - _lastHapticPercentage).abs() >= 10) {
      _lastHapticPercentage = pct;
      HapticFeedback.selectionClick();
    }
    setState(() {});
  }

  void _updateVolumeFromLocalOffset(Offset localPosition) {
    final center = Offset(widget.size / 2, widget.size / 2);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    // Ignore accidental touches right at the dead-center mute area
    if (distance < widget.size * 0.14) return;

    var angle = math.atan2(dy, dx);
    if (angle < 0) {
      angle += 2 * math.pi;
    }

    // Normalize angle relative to startAngle (135 deg = 3*pi/4)
    var relative = angle - RotaryBoostDialPainter.startAngle;
    if (relative < 0) {
      relative += 2 * math.pi;
    }

    // Dead-zone at bottom between 270 deg sweep and 360 deg (45 deg dead zone)
    if (relative > RotaryBoostDialPainter.sweepAngle) {
      const deadMid = RotaryBoostDialPainter.sweepAngle +
          (2 * math.pi - RotaryBoostDialPainter.sweepAngle) / 2;
      relative = relative < deadMid ? RotaryBoostDialPainter.sweepAngle : 0.0;
    }

    final normalized =
        (relative / RotaryBoostDialPainter.sweepAngle).clamp(0.0, 1.0);
    _effectiveController.setNormalizedProgress(normalized);
    widget.onChanged?.call(_effectiveController.effectiveVolume);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowRight) {
      _effectiveController.stepUp(0.05);
      widget.onChanged?.call(_effectiveController.effectiveVolume);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowLeft) {
      _effectiveController.stepDown(0.05);
      widget.onChanged?.call(_effectiveController.effectiveVolume);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyM) {
      _effectiveController.toggleMute();
      widget.onMuteChanged?.call(_effectiveController.isMuted);
      widget.onChanged?.call(_effectiveController.effectiveVolume);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
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

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Listener(
            onPointerSignal: (pointerSignal) {
              if (pointerSignal is PointerScrollEvent) {
                if (pointerSignal.scrollDelta.dy < 0) {
                  ctrl.stepUp(0.04);
                } else if (pointerSignal.scrollDelta.dy > 0) {
                  ctrl.stepDown(0.04);
                }
                widget.onChanged?.call(ctrl.effectiveVolume);
              }
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) {
                _focusNode.requestFocus();
                _updateVolumeFromLocalOffset(details.localPosition);
              },
              onPanStart: (details) {
                _focusNode.requestFocus();
                _updateVolumeFromLocalOffset(details.localPosition);
              },
              onPanUpdate: (details) {
                _updateVolumeFromLocalOffset(details.localPosition);
              },
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, _) {
                        return CustomPaint(
                          size: Size(widget.size, widget.size),
                          painter: RotaryBoostDialPainter(
                            normalizedProgress: ctrl.normalizedProgress,
                            unityMarkerRatio: ctrl.unityMarkerRatio,
                            effectiveVolume: ctrl.effectiveVolume,
                            maxBoostMultiplier: ctrl.maxBoostMultiplier,
                            isMuted: ctrl.isMuted,
                            style: style,
                            pulseValue: _pulseController.value,
                          ),
                        );
                      },
                    ),
                    _buildCenterReadout(ctrl, style, activeColor),
                    if (style.showTickLabels)
                      _buildPerimeterLabels(ctrl, style),
                  ],
                ),
              ),
            ),
          ),
          if (widget.showQuickButtons) ...[
            const SizedBox(height: 12),
            _buildQuickBoostButtons(ctrl, style, activeColor),
          ],
        ],
      ),
    );
  }

  Widget _buildCenterReadout(
    VolumeBoosterController ctrl,
    VolumeBoosterStyle style,
    Color activeColor,
  ) {
    final pct = ctrl.effectivePercentage;
    final safety = ctrl.safetyLevel;
    final scale = (widget.size / 240.0).clamp(0.65, 1.5);

    return SizedBox(
      width: widget.size * 0.54,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showSafetyBadge)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 8.0 * scale,
                vertical: 2.5 * scale,
              ),
              decoration: BoxDecoration(
                color: activeColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: activeColor.withValues(alpha: 0.45),
                  width: 1,
                ),
              ),
              child: Text(
                safety.badgeLabel,
                style: TextStyle(
                  color: activeColor,
                  fontSize: 9.0 * scale,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          SizedBox(height: 4.0 * scale),
          Text(
            ctrl.isMuted ? '0%' : '$pct%',
            style: TextStyle(
              color: style.primaryTextColor,
              fontSize: 32.0 * scale,
              fontWeight: FontWeight.w900,
              height: 1.05,
              letterSpacing: -0.8,
            ),
          ),
          if (widget.showDecibelBadge) ...[
            SizedBox(height: 4.0 * scale),
            Text(
              ctrl.formattedDecibels,
              style: TextStyle(
                color: ctrl.effectiveVolume > 1.0 && !ctrl.isMuted
                    ? activeColor
                    : style.secondaryTextColor,
                fontSize: 11.5 * scale,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPerimeterLabels(
    VolumeBoosterController ctrl,
    VolumeBoosterStyle style,
  ) {
    final maxPct = (ctrl.maxBoostMultiplier * 100).round();
    return IgnorePointer(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          children: [
            Positioned(
              left: widget.size * 0.14,
              bottom: widget.size * 0.04,
              child: Text(
                '0%',
                style: TextStyle(
                  color: style.secondaryTextColor,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: style.surfaceColor.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '100% (0dB)',
                    style: TextStyle(
                      color: style.safeZoneColor,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: widget.size * 0.10,
              bottom: widget.size * 0.04,
              child: Text(
                '$maxPct%',
                style: TextStyle(
                  color: style.dangerZoneColor,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickBoostButtons(
    VolumeBoosterController ctrl,
    VolumeBoosterStyle style,
    Color activeColor,
  ) {
    final maxPct = (ctrl.maxBoostMultiplier * 100).round();
    final midBoostPct =
        ((1.0 + (ctrl.maxBoostMultiplier - 1.0) * 0.5) * 100).round();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _QuickPillButton(
          label: ctrl.isMuted ? 'Unmute' : 'Mute',
          icon: ctrl.isMuted
              ? Icons.volume_off_rounded
              : Icons.volume_mute_rounded,
          isSelected: ctrl.isMuted,
          accentColor: style.dangerZoneColor,
          style: style,
          onTap: () {
            ctrl.toggleMute();
            widget.onMuteChanged?.call(ctrl.isMuted);
            widget.onChanged?.call(ctrl.effectiveVolume);
          },
        ),
        _QuickPillButton(
          label: '100%',
          isSelected: !ctrl.isMuted && ctrl.effectivePercentage == 100,
          accentColor: style.safeZoneColor,
          style: style,
          onTap: () {
            ctrl.setPercentage(100);
            widget.onChanged?.call(ctrl.effectiveVolume);
          },
        ),
        if (ctrl.isBoostEnabled && ctrl.maxBoostMultiplier > 1.05) ...[
          _QuickPillButton(
            label: '$midBoostPct%',
            isSelected:
                !ctrl.isMuted && ctrl.effectivePercentage == midBoostPct,
            accentColor: style.boostZoneColor,
            style: style,
            onTap: () {
              ctrl.setPercentage(midBoostPct);
              widget.onChanged?.call(ctrl.effectiveVolume);
            },
          ),
          _QuickPillButton(
            label: 'MAX $maxPct%',
            icon: Icons.bolt_rounded,
            isSelected: !ctrl.isMuted && ctrl.effectivePercentage == maxPct,
            accentColor: style.dangerZoneColor,
            style: style,
            onTap: () {
              ctrl.setPercentage(maxPct);
              widget.onChanged?.call(ctrl.effectiveVolume);
            },
          ),
        ],
      ],
    );
  }
}

class _QuickPillButton extends StatelessWidget {
  const _QuickPillButton({
    required this.label,
    required this.isSelected,
    required this.accentColor,
    required this.style,
    required this.onTap,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final bool isSelected;
  final Color accentColor;
  final VolumeBoosterStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor.withValues(alpha: 0.22)
                : style.surfaceColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? accentColor : style.borderColor,
              width: isSelected ? 1.4 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: isSelected ? accentColor : style.secondaryTextColor,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? accentColor : style.primaryTextColor,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
