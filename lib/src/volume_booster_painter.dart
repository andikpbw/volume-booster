import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'volume_booster_style.dart';
import 'volume_booster_types.dart';

/// Custom painter that renders the 3D rotary boost dial, segmented LED tick
/// ring, multi-zone glowing progress arc, harmonic overdrive pulse rings, and
/// indicator pointer notch.
class RotaryBoostDialPainter extends CustomPainter {
  /// Creates a [RotaryBoostDialPainter].
  const RotaryBoostDialPainter({
    required this.normalizedProgress,
    required this.unityMarkerRatio,
    required this.effectiveVolume,
    required this.maxBoostMultiplier,
    required this.isMuted,
    required this.style,
    this.pulseValue = 0.0,
  });

  /// Current progress across the full dial sweep (`0.0` to `1.0`).
  final double normalizedProgress;

  /// Normalized ratio (`0.0` to `1.0`) corresponding to `100%` (`0 dB` unity).
  final double unityMarkerRatio;

  /// Effective output volume multiplier (`0.0` to [maxBoostMultiplier]).
  final double effectiveVolume;

  /// Maximum amplification multiplier (`2.0` = `200%`).
  final double maxBoostMultiplier;

  /// Whether output is muted.
  final bool isMuted;

  /// Visual theme style configuration.
  final VolumeBoosterStyle style;

  /// Animation phase (`0.0` to `1.0`) for harmonic overdrive ring pulsing.
  final double pulseValue;

  /// Start angle in radians (`135°`, bottom-left).
  static const double startAngle = 3 * math.pi / 4;

  /// Total angular sweep in radians (`270°`).
  static const double sweepAngle = 3 * math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final minDim = math.min(size.width, size.height);
    final outerRadius = minDim / 2;

    final activeColor = style.colorForVolume(
      effectiveVolume,
      maxBoostMultiplier: maxBoostMultiplier,
      isMuted: isMuted,
    );

    // 1. Harmonic Overdrive Pulse Rings when boosted above 100%
    if (!isMuted && effectiveVolume > 1.0 && style.showHarmonicRings) {
      final boostIntensity =
          ((effectiveVolume - 1.0) / math.max(0.1, maxBoostMultiplier - 1.0))
              .clamp(0.0, 1.0);
      final ringRadius =
          outerRadius * (0.86 + 0.11 * pulseValue * boostIntensity);
      final ringAlpha =
          ((1.0 - pulseValue) * 0.35 * boostIntensity * style.glowIntensity)
              .clamp(0.0, 1.0);
      final harmonicPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 + 2.5 * boostIntensity
        ..color = activeColor.withValues(alpha: ringAlpha);
      canvas.drawCircle(center, ringRadius, harmonicPaint);
    }

    // 2. Outer Segmented LED Tick Ring
    final tickCount = style.tickCount.clamp(12, 72);
    final tickOuterR = outerRadius * 0.95;
    final tickInnerR = outerRadius * 0.85;
    final unityTickIndex = (unityMarkerRatio * (tickCount - 1)).round();

    for (var i = 0; i < tickCount; i++) {
      final t = i / (tickCount - 1);
      final angle = startAngle + t * sweepAngle;
      final isLit = !isMuted && t <= normalizedProgress + 0.002;
      final isUnityTick = i == unityTickIndex;

      final tickVol = t * maxBoostMultiplier;
      final zoneColor = style.colorForVolume(
        tickVol,
        maxBoostMultiplier: maxBoostMultiplier,
        isMuted: isMuted,
      );

      final innerR = isUnityTick ? tickInnerR - 4.0 : tickInnerR;
      final outerR = isUnityTick ? tickOuterR + 2.5 : tickOuterR;

      final p1 = Offset(
        center.dx + innerR * math.cos(angle),
        center.dy + innerR * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + outerR * math.cos(angle),
        center.dy + outerR * math.sin(angle),
      );

      if (isLit && style.glowIntensity > 0.05) {
        final glowPaint = Paint()
          ..color = zoneColor.withValues(alpha: 0.32 * style.glowIntensity)
          ..strokeWidth = isUnityTick ? 5.5 : 4.2
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
        canvas.drawLine(p1, p2, glowPaint);
      }

      final tickPaint = Paint()
        ..color = isLit
            ? zoneColor
            : (isUnityTick
                ? style.secondaryTextColor.withValues(alpha: 0.55)
                : style.inactiveTrackColor)
        ..strokeWidth = isUnityTick ? 3.2 : 2.4
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(p1, p2, tickPaint);
    }

    // 3. Circular Progress Arc Track
    final arcRadius = outerRadius * 0.74;
    final arcRect = Rect.fromCircle(center: center, radius: arcRadius);
    final baseTrackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = minDim * 0.048
      ..strokeCap = StrokeCap.round
      ..color = style.inactiveTrackColor;
    canvas.drawArc(arcRect, startAngle, sweepAngle, false, baseTrackPaint);

    // 4. Active Glowing Progress Arc
    if (!isMuted && normalizedProgress > 0.003) {
      final activeSweep = sweepAngle * normalizedProgress.clamp(0.0, 1.0);
      if (style.glowIntensity > 0.05) {
        final arcGlowPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = minDim * 0.068
          ..strokeCap = StrokeCap.round
          ..color = activeColor.withValues(alpha: 0.36 * style.glowIntensity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
        canvas.drawArc(
          arcRect,
          startAngle,
          activeSweep,
          false,
          arcGlowPaint,
        );
      }

      final activeArcPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = minDim * 0.048
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          center: Alignment.center,
          startAngle: 0.0,
          endAngle: math.pi * 2,
          colors: <Color>[
            style.safeZoneColor,
            style.boostZoneColor,
            style.dangerZoneColor,
            style.safeZoneColor,
          ],
          stops: const <double>[0.0, 0.55, 0.85, 1.0],
          transform: const GradientRotation(startAngle),
        ).createShader(arcRect);

      canvas.drawArc(
        arcRect,
        startAngle,
        activeSweep,
        false,
        activeArcPaint,
      );
    }

    // 5. Inner 3D Rotary Knob Cap
    final knobRadius = outerRadius * 0.61;
    final knobRect = Rect.fromCircle(center: center, radius: knobRadius);

    // Ambient drop shadow behind knob
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0);
    canvas.drawCircle(center.translate(0, 4), knobRadius, shadowPaint);

    // Knob surface fill gradient
    final knobFillPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.25, -0.3),
        radius: 1.1,
        colors: <Color>[
          Color.lerp(style.knobBaseColor, Colors.white, 0.08) ??
              style.knobBaseColor,
          style.knobBaseColor,
        ],
      ).createShader(knobRect);
    canvas.drawCircle(center, knobRadius, knobFillPaint);

    // Subtle concentric brushed groove ring
    final groovePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = style.borderColor.withValues(alpha: 0.45);
    canvas.drawCircle(center, knobRadius * 0.86, groovePaint);

    // Outer metallic/neon bevel rim
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = isMuted
          ? style.mutedColor.withValues(alpha: 0.5)
          : activeColor.withValues(alpha: 0.65);
    canvas.drawCircle(center, knobRadius, rimPaint);

    // 6. Rotary Pointer Notch at Current Angle
    final pointerAngle =
        startAngle + normalizedProgress.clamp(0.0, 1.0) * sweepAngle;
    final notchInner = knobRadius * 0.68;
    final notchOuter = knobRadius * 0.90;
    final notchStart = Offset(
      center.dx + notchInner * math.cos(pointerAngle),
      center.dy + notchInner * math.sin(pointerAngle),
    );
    final notchEnd = Offset(
      center.dx + notchOuter * math.cos(pointerAngle),
      center.dy + notchOuter * math.sin(pointerAngle),
    );

    if (!isMuted && style.glowIntensity > 0.05) {
      final notchGlow = Paint()
        ..color = activeColor.withValues(alpha: 0.7 * style.glowIntensity)
        ..strokeWidth = 6.0
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
      canvas.drawLine(notchStart, notchEnd, notchGlow);
    }

    final notchPaint = Paint()
      ..color = isMuted ? style.mutedColor : activeColor
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(notchStart, notchEnd, notchPaint);
  }

  @override
  bool shouldRepaint(covariant RotaryBoostDialPainter oldDelegate) {
    return oldDelegate.normalizedProgress != normalizedProgress ||
        oldDelegate.effectiveVolume != effectiveVolume ||
        oldDelegate.isMuted != isMuted ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.style != style;
  }
}

/// Custom painter that renders the smooth cubic-Bezier graphic equalizer
/// frequency response curve and dB reference grid.
class EqualizerCurvePainter extends CustomPainter {
  /// Creates an [EqualizerCurvePainter].
  const EqualizerCurvePainter({
    required this.bands,
    required this.style,
    required this.accentColor,
  });

  /// Equalizer frequency bands to plot.
  final List<EqualizerBand> bands;

  /// Active visual theme style.
  final VolumeBoosterStyle style;

  /// Primary curve stroke and glow accent color.
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (bands.isEmpty || size.width <= 0 || size.height <= 0) return;

    // 1. Horizontal reference dB grid lines (+12, +6, 0, -6, -12 dB)
    final gridPaint = Paint()
      ..color = style.borderColor.withValues(alpha: 0.35)
      ..strokeWidth = 1.0;

    final unityPaint = Paint()
      ..color = style.safeZoneColor.withValues(alpha: 0.38)
      ..strokeWidth = 1.2;

    for (var i = 0; i <= 4; i++) {
      final y = size.height * (i / 4.0);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        i == 2 ? unityPaint : gridPaint,
      );
    }

    // 2. Compute control coordinates for each band
    final points = <Offset>[];
    final count = bands.length;
    final colWidth = size.width / count;

    for (var i = 0; i < count; i++) {
      final x = colWidth * (i + 0.5);
      final y = size.height * (1.0 - bands[i].normalized).clamp(0.06, 0.94);
      points.add(Offset(x, y));
    }

    // 3. Build smooth cubic-Bezier spline path
    final curvePath = Path();
    curvePath.moveTo(0, points.first.dy);
    curvePath.lineTo(points.first.dx, points.first.dy);

    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final midX = (p0.dx + p1.dx) / 2;
      curvePath.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }
    curvePath.lineTo(size.width, points.last.dy);

    // 4. Fill area beneath the curve
    final fillPath = Path.from(curvePath)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          accentColor.withValues(alpha: 0.30),
          style.boostZoneColor.withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawPath(fillPath, fillPaint);

    // 5. Glowing curve stroke
    if (style.glowIntensity > 0.05) {
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0
        ..color = accentColor.withValues(alpha: 0.35 * style.glowIntensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
      canvas.drawPath(curvePath, glowPaint);
    }

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..color = accentColor;
    canvas.drawPath(curvePath, strokePaint);

    // 6. Band node circles
    for (final pt in points) {
      canvas.drawCircle(
        pt,
        5.5,
        Paint()..color = style.cardColor,
      );
      canvas.drawCircle(
        pt,
        4.2,
        Paint()..color = accentColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant EqualizerCurvePainter oldDelegate) {
    return oldDelegate.bands != bands ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.style != style;
  }
}

/// Custom painter that renders the real-time frequency spectrum bars or
/// harmonic waveform inside `VolumeSpectrumVisualizer`.
class SpectrumVisualizerPainter extends CustomPainter {
  /// Creates a [SpectrumVisualizerPainter].
  const SpectrumVisualizerPainter({
    required this.bars,
    required this.mode,
    required this.style,
    required this.effectiveVolume,
    required this.maxBoostMultiplier,
    required this.isMuted,
  });

  /// Normalized frequency magnitudes (`0.0` to `1.0`).
  final List<double> bars;

  /// Active rendering mode (`ledBars`, `smoothWave`, or `dualMirror`).
  final VisualizerMode mode;

  /// Visual theme style configuration.
  final VolumeBoosterStyle style;

  /// Current effective output multiplier.
  final double effectiveVolume;

  /// Maximum amplification multiplier.
  final double maxBoostMultiplier;

  /// Whether output is muted.
  final bool isMuted;

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty || size.width <= 0 || size.height <= 0) return;

    switch (mode) {
      case VisualizerMode.ledBars:
        _paintLedBars(canvas, size);
      case VisualizerMode.smoothWave:
        _paintSmoothWave(canvas, size);
      case VisualizerMode.dualMirror:
        _paintDualMirror(canvas, size);
    }
  }

  void _paintLedBars(Canvas canvas, Size size) {
    final count = bars.length;
    final slotWidth = size.width / count;
    final barWidth = (slotWidth * 0.68).clamp(3.0, 22.0);
    const segmentCount = 10;
    const segmentGap = 2.0;
    final segmentHeight =
        (size.height - (segmentCount - 1) * segmentGap) / segmentCount;

    for (var i = 0; i < count; i++) {
      final level = isMuted ? 0.05 : bars[i].clamp(0.05, 1.0);
      final litSegments = (level * segmentCount).ceil().clamp(1, segmentCount);
      final x = i * slotWidth + (slotWidth - barWidth) / 2;

      for (var s = 0; s < segmentCount; s++) {
        final segRatio = (s + 1) / segmentCount;
        final y = size.height - (s + 1) * segmentHeight - s * segmentGap;
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, math.max(1.5, segmentHeight)),
          const Radius.circular(2.5),
        );

        Color segColor;
        if (segRatio <= 0.6) {
          segColor = style.safeZoneColor;
        } else if (segRatio <= 0.82) {
          segColor = style.boostZoneColor;
        } else {
          segColor = style.dangerZoneColor;
        }

        final isLit = !isMuted && s < litSegments;
        final paint = Paint()
          ..color = isLit
              ? segColor
              : style.inactiveTrackColor.withValues(alpha: 0.45);
        canvas.drawRRect(rect, paint);
      }
    }
  }

  void _paintSmoothWave(Canvas canvas, Size size) {
    final activeColor = style.colorForVolume(
      effectiveVolume,
      maxBoostMultiplier: maxBoostMultiplier,
      isMuted: isMuted,
    );

    final points = <Offset>[];
    for (var i = 0; i < bars.length; i++) {
      final x = (i / math.max(1, bars.length - 1)) * size.width;
      final mag = isMuted ? 0.06 : bars[i].clamp(0.05, 1.0);
      final y = size.height * (1.0 - mag * 0.88);
      points.add(Offset(x, y));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final midX = (p0.dx + p1.dx) / 2;
      path.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          activeColor.withValues(alpha: 0.42),
          style.boostZoneColor.withValues(alpha: 0.12),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawPath(fillPath, fillPaint);

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..color = activeColor;
    canvas.drawPath(path, strokePaint);
  }

  void _paintDualMirror(Canvas canvas, Size size) {
    final count = bars.length;
    final slotWidth = size.width / count;
    final barWidth = (slotWidth * 0.64).clamp(3.0, 20.0);
    final midY = size.height / 2;

    for (var i = 0; i < count; i++) {
      final level = isMuted ? 0.05 : bars[i].clamp(0.05, 1.0);
      final halfH = (level * midY * 0.92).clamp(2.0, midY);
      final x = i * slotWidth + (slotWidth - barWidth) / 2;

      final color = level <= 0.6
          ? style.safeZoneColor
          : (level <= 0.82 ? style.boostZoneColor : style.dangerZoneColor);

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, midY - halfH, barWidth, halfH * 2),
        Radius.circular(barWidth / 2),
      );
      canvas.drawRRect(rect, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant SpectrumVisualizerPainter oldDelegate) {
    return oldDelegate.bars != bars ||
        oldDelegate.mode != mode ||
        oldDelegate.effectiveVolume != effectiveVolume ||
        oldDelegate.isMuted != isMuted ||
        oldDelegate.style != style;
  }
}
