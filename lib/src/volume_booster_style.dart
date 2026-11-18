import 'package:flutter/material.dart';
import 'volume_booster_types.dart';

/// Defines the visual styling, zone colors, glow intensity, and surface
/// aesthetics for `VolumeBoosterDial`, `VolumeBoosterSlider`,
/// `VolumeEqualizerWidget`, `VolumeSpectrumVisualizer`, and `VolumeBoosterConsole`.
@immutable
class VolumeBoosterStyle {
  /// Creates a custom [VolumeBoosterStyle].
  const VolumeBoosterStyle({
    this.backgroundColor = const Color(0xFF0B0F19),
    this.cardColor = const Color(0xFF131B2E),
    this.surfaceColor = const Color(0xFF1E293B),
    this.borderColor = const Color(0xFF334155),
    this.safeZoneColor = const Color(0xFF00F5D4),
    this.boostZoneColor = const Color(0xFFA855F7),
    this.dangerZoneColor = const Color(0xFFF43F5E),
    this.mutedColor = const Color(0xFF64748B),
    this.knobBaseColor = const Color(0xFF0F172A),
    this.knobRimColor = const Color(0xFF334155),
    this.primaryTextColor = const Color(0xFFF8FAFC),
    this.secondaryTextColor = const Color(0xFF94A3B8),
    this.inactiveTrackColor = const Color(0xFF1E293B),
    this.tickCount = 36,
    this.glowIntensity = 0.75,
    this.borderRadius = 24.0,
    this.borderWidth = 1.4,
    this.showHarmonicRings = true,
    this.showTickLabels = true,
  });

  /// High-contrast dark cyber deck with electric cyan safe zone (`#00F5D4`),
  /// neon violet boost zone (`#A855F7`), and crimson overdrive (`#F43F5E`).
  factory VolumeBoosterStyle.cyberNeon({
    Color safeZoneColor = const Color(0xFF00F5D4),
    Color boostZoneColor = const Color(0xFFA855F7),
    Color dangerZoneColor = const Color(0xFFF43F5E),
    int tickCount = 36,
  }) {
    return VolumeBoosterStyle(
      backgroundColor: const Color(0xFF070A12),
      cardColor: const Color(0xFF0F172A),
      surfaceColor: const Color(0xFF1E293B),
      borderColor: const Color(0xFF334155),
      safeZoneColor: safeZoneColor,
      boostZoneColor: boostZoneColor,
      dangerZoneColor: dangerZoneColor,
      mutedColor: const Color(0xFF64748B),
      knobBaseColor: const Color(0xFF0B1120),
      knobRimColor: const Color(0xFF38BDF8),
      primaryTextColor: const Color(0xFFF8FAFC),
      secondaryTextColor: const Color(0xFF94A3B8),
      inactiveTrackColor: const Color(0xFF1E293B),
      tickCount: tickCount,
      glowIntensity: 0.9,
      borderRadius: 24.0,
      borderWidth: 1.5,
      showHarmonicRings: true,
    );
  }

  /// Professional hardware audio mastering console with emerald green safe LEDs,
  /// warm amber boost drive, and ruby peak indicators on brushed gunmetal.
  factory VolumeBoosterStyle.studioPro({
    int tickCount = 40,
  }) {
    return VolumeBoosterStyle(
      backgroundColor: const Color(0xFF121316),
      cardColor: const Color(0xFF18191E),
      surfaceColor: const Color(0xFF23252C),
      borderColor: const Color(0xFF383B47),
      safeZoneColor: const Color(0xFF10B981),
      boostZoneColor: const Color(0xFFF59E0B),
      dangerZoneColor: const Color(0xFFEF4444),
      mutedColor: const Color(0xFF71717A),
      knobBaseColor: const Color(0xFF141519),
      knobRimColor: const Color(0xFF52525B),
      primaryTextColor: const Color(0xFFFAFAFA),
      secondaryTextColor: const Color(0xFFA1A1AA),
      inactiveTrackColor: const Color(0xFF27272A),
      tickCount: tickCount,
      glowIntensity: 0.55,
      borderRadius: 20.0,
      borderWidth: 1.2,
      showHarmonicRings: true,
    );
  }

  /// Frosted translucent glassmorphic console with sky-blue and indigo glow.
  factory VolumeBoosterStyle.glassmorphic({
    int tickCount = 36,
  }) {
    return VolumeBoosterStyle(
      backgroundColor: const Color(0xFF0F172A),
      cardColor: const Color(0xCC1E293B),
      surfaceColor: const Color(0x99334155),
      borderColor: const Color(0x6694A3B8),
      safeZoneColor: const Color(0xFF38BDF8),
      boostZoneColor: const Color(0xFF818CF8),
      dangerZoneColor: const Color(0xFFFB7185),
      mutedColor: const Color(0xFF94A3B8),
      knobBaseColor: const Color(0xFF1E293B),
      knobRimColor: const Color(0xFF60A5FA),
      primaryTextColor: const Color(0xFFFFFFFF),
      secondaryTextColor: const Color(0xFFCBD5E1),
      inactiveTrackColor: const Color(0x66334155),
      tickCount: tickCount,
      glowIntensity: 0.7,
      borderRadius: 28.0,
      borderWidth: 1.4,
      showHarmonicRings: true,
    );
  }

  /// Clean Material 3 light/tonal surface ideal for daytime media applications.
  factory VolumeBoosterStyle.modernMaterial({
    int tickCount = 32,
  }) {
    return VolumeBoosterStyle(
      backgroundColor: const Color(0xFFF8FAFC),
      cardColor: const Color(0xFFFFFFFF),
      surfaceColor: const Color(0xFFF1F5F9),
      borderColor: const Color(0xFFE2E8F0),
      safeZoneColor: const Color(0xFF4F46E5),
      boostZoneColor: const Color(0xFF9333EA),
      dangerZoneColor: const Color(0xFFE11D48),
      mutedColor: const Color(0xFF94A3B8),
      knobBaseColor: const Color(0xFFFFFFFF),
      knobRimColor: const Color(0xFFCBD5E1),
      primaryTextColor: const Color(0xFF0F172A),
      secondaryTextColor: const Color(0xFF64748B),
      inactiveTrackColor: const Color(0xFFE2E8F0),
      tickCount: tickCount,
      glowIntensity: 0.35,
      borderRadius: 22.0,
      borderWidth: 1.2,
      showHarmonicRings: false,
    );
  }

  /// High-energy sunset plasma aesthetic combining gold, orange, and hot pink.
  factory VolumeBoosterStyle.sunsetOverdrive({
    int tickCount = 36,
  }) {
    return VolumeBoosterStyle(
      backgroundColor: const Color(0xFF140B1C),
      cardColor: const Color(0xFF1F112B),
      surfaceColor: const Color(0xFF2E1A3E),
      borderColor: const Color(0xFF4C2863),
      safeZoneColor: const Color(0xFFFBBF24),
      boostZoneColor: const Color(0xFFF97316),
      dangerZoneColor: const Color(0xFFEC4899),
      mutedColor: const Color(0xFF7E6891),
      knobBaseColor: const Color(0xFF170D21),
      knobRimColor: const Color(0xFFF97316),
      primaryTextColor: const Color(0xFFFFF7ED),
      secondaryTextColor: const Color(0xFFD8B4FE),
      inactiveTrackColor: const Color(0xFF331C45),
      tickCount: tickCount,
      glowIntensity: 0.85,
      borderRadius: 24.0,
      borderWidth: 1.5,
      showHarmonicRings: true,
    );
  }

  /// Tactile soft-UI / neumorphic hardware surface with smooth contours.
  factory VolumeBoosterStyle.softNeumorphic({
    int tickCount = 32,
  }) {
    return VolumeBoosterStyle(
      backgroundColor: const Color(0xFF1A202C),
      cardColor: const Color(0xFF212936),
      surfaceColor: const Color(0xFF2A3444),
      borderColor: const Color(0xFF374357),
      safeZoneColor: const Color(0xFF2DD4BF),
      boostZoneColor: const Color(0xFF6366F1),
      dangerZoneColor: const Color(0xFFF43F5E),
      mutedColor: const Color(0xFF64748B),
      knobBaseColor: const Color(0xFF1E2532),
      knobRimColor: const Color(0xFF475569),
      primaryTextColor: const Color(0xFFF1F5F9),
      secondaryTextColor: const Color(0xFF94A3B8),
      inactiveTrackColor: const Color(0xFF181E29),
      tickCount: tickCount,
      glowIntensity: 0.5,
      borderRadius: 26.0,
      borderWidth: 1.0,
      showHarmonicRings: true,
    );
  }

  /// Outer scaffold/backdrop color.
  final Color backgroundColor;

  /// Main console card fill color.
  final Color cardColor;

  /// Secondary control surface color (chips, fader wells, badges).
  final Color surfaceColor;

  /// Card and widget stroke color.
  final Color borderColor;

  /// Accent color for the standard `0% – 100%` unity gain range.
  final Color safeZoneColor;

  /// Accent color for the `101% – 155%` turbo boost amplification zone.
  final Color boostZoneColor;

  /// Accent color for the `156% – 200%+` maximum overdrive zone.
  final Color dangerZoneColor;

  /// Color used when audio output is muted.
  final Color mutedColor;

  /// Fill color of the central rotary dial cap.
  final Color knobBaseColor;

  /// Rim highlight color of the rotary dial cap.
  final Color knobRimColor;

  /// Primary readout and heading text color.
  final Color primaryTextColor;

  /// Subtitle, frequency label, and unit text color.
  final Color secondaryTextColor;

  /// Color of unlit LED ticks and unfilled slider tracks.
  final Color inactiveTrackColor;

  /// Number of outer segmented LED ticks around `VolumeBoosterDial`.
  final int tickCount;

  /// Glow bloom intensity from `0.0` (none) to `1.0` (maximum neon bloom).
  final double glowIntensity;

  /// Corner radius for cards and panels.
  final double borderRadius;

  /// Border stroke width for cards and panels.
  final double borderWidth;

  /// Whether to render pulsing harmonic energy rings when boosted above `100%`.
  final bool showHarmonicRings;

  /// Whether to render outer percentage markers (`0%`, `100%`, `200%`).
  final bool showTickLabels;

  /// Returns the zone accent color corresponding to [safetyLevel].
  Color colorForSafetyLevel(VolumeSafetyLevel safetyLevel) {
    switch (safetyLevel) {
      case VolumeSafetyLevel.muted:
        return mutedColor;
      case VolumeSafetyLevel.safe:
        return safeZoneColor;
      case VolumeSafetyLevel.turboBoost:
        return boostZoneColor;
      case VolumeSafetyLevel.overdriveDanger:
        return dangerZoneColor;
    }
  }

  /// Smoothly interpolates the active zone color for a given [effectiveVolume]
  /// (`0.0` to [maxBoostMultiplier], where `1.0` is `100%` unity gain).
  Color colorForVolume(
    double effectiveVolume, {
    double maxBoostMultiplier = 2.0,
    bool isMuted = false,
  }) {
    if (isMuted || effectiveVolume <= 0.001) {
      return mutedColor;
    }
    if (effectiveVolume <= 1.0) {
      return safeZoneColor;
    }
    final boostSpan = (maxBoostMultiplier - 1.0).clamp(0.1, 10.0);
    final boostProgress = ((effectiveVolume - 1.0) / boostSpan).clamp(0.0, 1.0);
    if (boostProgress <= 0.55) {
      final t = (boostProgress / 0.55).clamp(0.0, 1.0);
      return Color.lerp(safeZoneColor, boostZoneColor, t) ?? boostZoneColor;
    } else {
      final t = ((boostProgress - 0.55) / 0.45).clamp(0.0, 1.0);
      return Color.lerp(boostZoneColor, dangerZoneColor, t) ?? dangerZoneColor;
    }
  }

  /// Creates a copy of this [VolumeBoosterStyle] with selectively overridden properties.
  VolumeBoosterStyle copyWith({
    Color? backgroundColor,
    Color? cardColor,
    Color? surfaceColor,
    Color? borderColor,
    Color? safeZoneColor,
    Color? boostZoneColor,
    Color? dangerZoneColor,
    Color? mutedColor,
    Color? knobBaseColor,
    Color? knobRimColor,
    Color? primaryTextColor,
    Color? secondaryTextColor,
    Color? inactiveTrackColor,
    int? tickCount,
    double? glowIntensity,
    double? borderRadius,
    double? borderWidth,
    bool? showHarmonicRings,
    bool? showTickLabels,
  }) {
    return VolumeBoosterStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      cardColor: cardColor ?? this.cardColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      borderColor: borderColor ?? this.borderColor,
      safeZoneColor: safeZoneColor ?? this.safeZoneColor,
      boostZoneColor: boostZoneColor ?? this.boostZoneColor,
      dangerZoneColor: dangerZoneColor ?? this.dangerZoneColor,
      mutedColor: mutedColor ?? this.mutedColor,
      knobBaseColor: knobBaseColor ?? this.knobBaseColor,
      knobRimColor: knobRimColor ?? this.knobRimColor,
      primaryTextColor: primaryTextColor ?? this.primaryTextColor,
      secondaryTextColor: secondaryTextColor ?? this.secondaryTextColor,
      inactiveTrackColor: inactiveTrackColor ?? this.inactiveTrackColor,
      tickCount: tickCount ?? this.tickCount,
      glowIntensity: glowIntensity ?? this.glowIntensity,
      borderRadius: borderRadius ?? this.borderRadius,
      borderWidth: borderWidth ?? this.borderWidth,
      showHarmonicRings: showHarmonicRings ?? this.showHarmonicRings,
      showTickLabels: showTickLabels ?? this.showTickLabels,
    );
  }
}
