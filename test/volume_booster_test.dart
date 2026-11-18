import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:volume_booster/volume_booster.dart';

void main() {
  group('VolumeBoosterController', () {
    test('computes base volume, boost gain, percentage, and dB accurately', () {
      final controller = VolumeBoosterController(
        initialVolume: 1.5,
        maxBoostMultiplier: 2.0,
      );

      expect(controller.baseVolume, closeTo(1.0, 0.001));
      expect(controller.boostGain, closeTo(0.5, 0.001));
      expect(controller.effectiveVolume, closeTo(1.5, 0.001));
      expect(controller.effectivePercentage, 150);
      expect(controller.decibelGain, closeTo(6.0, 0.05));
      expect(controller.formattedDecibels, '+6.0 dB');
      expect(controller.safetyLevel, VolumeSafetyLevel.turboBoost);

      controller.setPercentage(100);
      expect(controller.effectiveVolume, closeTo(1.0, 0.001));
      expect(controller.boostGain, closeTo(0.0, 0.001));
      expect(controller.decibelGain, closeTo(0.0, 0.01));
      expect(controller.formattedDecibels, '0.0 dB');
      expect(controller.safetyLevel, VolumeSafetyLevel.safe);

      controller.setPercentage(190);
      expect(controller.effectivePercentage, 190);
      expect(controller.safetyLevel, VolumeSafetyLevel.overdriveDanger);
      expect(controller.isClipping, isFalse); // Limiter is enabled by default

      controller.setLimiterEnabled(false);
      expect(controller.isClipping, isTrue);
    });

    test('toggles mute and restores previous non-zero volume on unmute', () {
      final controller = VolumeBoosterController(initialVolume: 1.4);
      expect(controller.isMuted, isFalse);
      expect(controller.effectivePercentage, 140);

      controller.toggleMute();
      expect(controller.isMuted, isTrue);
      expect(controller.effectiveVolume, 0.0);
      expect(controller.formattedDecibels, 'MUTE');
      expect(controller.safetyLevel, VolumeSafetyLevel.muted);

      controller.toggleMute();
      expect(controller.isMuted, isFalse);
      expect(controller.effectivePercentage, 140);
    });

    test('caps volume at 100% when software boost is disabled', () {
      final controller = VolumeBoosterController(initialVolume: 1.75);
      expect(controller.effectivePercentage, 175);

      controller.setBoostEnabled(false);
      expect(controller.isBoostEnabled, isFalse);
      expect(controller.effectivePercentage, 100);

      controller.setPercentage(160);
      expect(controller.effectivePercentage, 100);

      controller.toggleBoostEnabled();
      expect(controller.isBoostEnabled, isTrue);
      controller.setPercentage(160);
      expect(controller.effectivePercentage, 160);
    });

    test('manages 5-band equalizer, presets, and acoustic enhancers', () {
      final controller = VolumeBoosterController();
      expect(controller.bands.length, 5);

      controller.setBandGain(0, 9.5);
      expect(controller.bands[0].gainDb, closeTo(9.5, 0.01));
      expect(controller.activePreset, VolumePreset.custom);

      controller.applyPreset(VolumePreset.bassExtreme);
      expect(controller.activePreset, VolumePreset.bassExtreme);
      expect(controller.effectivePercentage, 155);
      expect(controller.bassBoost, closeTo(0.90, 0.01));

      controller.applyPreset(VolumePreset.voiceBoost);
      expect(controller.activePreset, VolumePreset.voiceBoost);
      expect(controller.effectivePercentage, 135);

      controller.applyPreset(VolumePreset.cinema3D);
      expect(controller.virtualizer, closeTo(0.95, 0.01));

      controller.applyPreset(VolumePreset.gaming);
      expect(controller.effectivePercentage, 140);

      controller.applyPreset(VolumePreset.maxOverdrive);
      expect(controller.effectivePercentage, 200);

      controller.applyPreset(VolumePreset.nightLimiter);
      expect(controller.effectivePercentage, 85);

      controller.resetEqualizer();
      for (final band in controller.bands) {
        expect(band.gainDb, 0.0);
      }
      expect(controller.activePreset, VolumePreset.normal);
    });

    test('updates audio frames and steps simulation telemetry', () {
      final controller = VolumeBoosterController(initialVolume: 1.3);
      controller.updateAudioFrame(
        left: 0.82,
        right: 0.76,
        spectrum: List<double>.filled(20, 0.65),
      );
      expect(controller.leftPeak, closeTo(0.82, 0.01));
      expect(controller.rightPeak, closeTo(0.76, 0.01));
      expect(controller.spectrumBars.first, closeTo(0.65, 0.01));

      controller.stepSimulation(0.35);
      expect(controller.spectrumBars.length, 20);
      expect(controller.snapshot.effectivePercentage, 130);
    });
  });

  group('VolumeBoosterStyle & EqualizerBand', () {
    test('creates all 6 theme presets and interpolates zone colors', () {
      final presets = <VolumeBoosterStyle>[
        VolumeBoosterStyle.cyberNeon(),
        VolumeBoosterStyle.studioPro(),
        VolumeBoosterStyle.glassmorphic(),
        VolumeBoosterStyle.modernMaterial(),
        VolumeBoosterStyle.sunsetOverdrive(),
        VolumeBoosterStyle.softNeumorphic(),
      ];

      for (final style in presets) {
        expect(style.tickCount, greaterThanOrEqualTo(12));
        expect(
          style.colorForVolume(0.0, isMuted: true),
          equals(style.mutedColor),
        );
        expect(
          style.colorForVolume(0.8),
          equals(style.safeZoneColor),
        );
        expect(
          style.colorForSafetyLevel(VolumeSafetyLevel.overdriveDanger),
          equals(style.dangerZoneColor),
        );
      }

      final copied = VolumeBoosterStyle.cyberNeon().copyWith(tickCount: 48);
      expect(copied.tickCount, 48);
    });

    test('EqualizerBand computes normalized value and formatted dB', () {
      const band = EqualizerBand(frequencyHz: 60, label: '60Hz', gainDb: 6.0);
      expect(band.normalized, closeTo(0.75, 0.001));
      expect(band.formattedDb, '+6.0 dB');

      final updated = band.copyWith(gainDb: -6.0);
      expect(updated.normalized, closeTo(0.25, 0.001));
      expect(updated.formattedDb, '-6.0 dB');
      expect(updated == band, isFalse);
    });
  });

  group('VolumeBooster Widgets', () {
    testWidgets(
        'VolumeBoosterDial renders and responds to quick buttons & keys',
        (tester) async {
      final controller = VolumeBoosterController(initialVolume: 1.0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: VolumeBoosterDial(
                controller: controller,
                enableHaptics: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('100%'), findsWidgets);
      expect(find.text('SAFE GAIN'), findsOneWidget);

      await tester.tap(find.text('150%'));
      await tester.pump();
      expect(controller.effectivePercentage, 150);
      expect(find.text('TURBO BOOST'), findsOneWidget);

      await tester.tap(find.text('MAX 200%'));
      await tester.pump();
      expect(controller.effectivePercentage, 200);
      expect(find.text('OVERDRIVE MAX'), findsOneWidget);

      await tester.tap(find.text('Mute'));
      await tester.pump();
      expect(controller.isMuted, isTrue);
      expect(find.text('MUTED'), findsOneWidget);

      await tester.tap(find.text('Unmute'));
      await tester.pump();
      expect(controller.isMuted, isFalse);

      // Focus and press ArrowDown
      await tester.tapAt(tester.getCenter(find.byType(VolumeBoosterDial)));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(controller.effectivePercentage, lessThan(200));
    });

    testWidgets('VolumeBoosterSlider toggles mute and updates via drag',
        (tester) async {
      final controller = VolumeBoosterController(initialVolume: 1.2);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VolumeBoosterSlider(
              controller: controller,
            ),
          ),
        ),
      );

      expect(find.text('120%'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.volume_up_rounded));
      await tester.pump();
      expect(controller.isMuted, isTrue);
      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('VolumeEqualizerWidget switches presets and toggles limiter',
        (tester) async {
      final controller = VolumeBoosterController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VolumeEqualizerWidget(
                controller: controller,
              ),
            ),
          ),
        ),
      );

      expect(find.text('5-Band Graphic Equalizer & DSP'), findsOneWidget);
      expect(find.text('PROTECTED'), findsOneWidget);

      await tester.tap(find.text('Bass Extreme'));
      await tester.pump();
      expect(controller.activePreset, VolumePreset.bassExtreme);

      await tester.tap(find.text('Flat 0dB'));
      await tester.pump();
      expect(controller.activePreset, VolumePreset.normal);

      await tester.tap(find.text('PROTECTED'));
      await tester.pump();
      expect(controller.limiterEnabled, isFalse);
      expect(find.text('BYPASSED'), findsOneWidget);
    });

    testWidgets('VolumeSpectrumVisualizer switches between LED, Wave, Mirror',
        (tester) async {
      final controller = VolumeBoosterController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VolumeSpectrumVisualizer(
              controller: controller,
            ),
          ),
        ),
      );

      expect(find.text('LED'), findsOneWidget);
      expect(find.text('Wave'), findsOneWidget);
      expect(find.text('Mirror'), findsOneWidget);

      await tester.tap(find.text('Wave'));
      await tester.pump();

      await tester.tap(find.text('Mirror'));
      await tester.pump();
    });

    testWidgets('VolumeBoosterConsole renders full stack and overdrive alert',
        (tester) async {
      final controller = VolumeBoosterController(initialVolume: 1.85);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VolumeBoosterConsole(
                controller: controller,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Volume Booster Pro'), findsOneWidget);
      expect(find.text('BOOST ON'), findsOneWidget);
      expect(find.textContaining('Overdrive zone active'), findsOneWidget);

      await tester.tap(find.text('BOOST ON'));
      await tester.pump();
      expect(controller.isBoostEnabled, isFalse);
      expect(find.text('100% CAP'), findsOneWidget);
    });
  });
}
