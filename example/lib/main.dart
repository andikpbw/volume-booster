import 'package:flutter/material.dart';
import 'package:volume_booster/volume_booster.dart';

void main() {
  runApp(const VolumeBoosterShowcaseApp());
}

/// Interactive showcase application demonstrating all widgets and theme presets
/// included in the `volume_booster` package.
class VolumeBoosterShowcaseApp extends StatefulWidget {
  /// Creates a [VolumeBoosterShowcaseApp].
  const VolumeBoosterShowcaseApp({super.key});

  @override
  State<VolumeBoosterShowcaseApp> createState() =>
      _VolumeBoosterShowcaseAppState();
}

class _VolumeBoosterShowcaseAppState extends State<VolumeBoosterShowcaseApp> {
  late final VolumeBoosterController _controller;
  int _selectedThemeIndex = 0;

  static final List<(String, VolumeBoosterStyle)> _themes = [
    ('Cyber Neon', VolumeBoosterStyle.cyberNeon()),
    ('Studio Pro', VolumeBoosterStyle.studioPro()),
    ('Glassmorphic', VolumeBoosterStyle.glassmorphic()),
    ('Sunset Overdrive', VolumeBoosterStyle.sunsetOverdrive()),
    ('Soft Neumorphic', VolumeBoosterStyle.softNeumorphic()),
    ('Modern Material', VolumeBoosterStyle.modernMaterial()),
  ];

  @override
  void initState() {
    super.initState();
    _controller = VolumeBoosterController(
      initialVolume: 1.45,
      maxBoostMultiplier: 2.0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeTheme = _themes[_selectedThemeIndex].$2;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Volume Booster Pro Showcase',
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        backgroundColor: activeTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: activeTheme.cardColor,
          title: Text(
            'volume_booster • Humanize AI',
            style: TextStyle(
              color: activeTheme.primaryTextColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  '${_controller.effectivePercentage}% (${_controller.formattedDecibels})',
                  style: TextStyle(
                    color: activeTheme.safeZoneColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildThemeSelector(activeTheme),
                  const SizedBox(height: 16),
                  VolumeBoosterConsole(
                    controller: _controller,
                    style: activeTheme,
                    autoAnimateVisualizer: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeSelector(VolumeBoosterStyle style) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List<Widget>.generate(_themes.length, (i) {
          final isSelected = i == _selectedThemeIndex;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_themes[i].$1),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedThemeIndex = i),
            ),
          );
        }),
      ),
    );
  }
}
