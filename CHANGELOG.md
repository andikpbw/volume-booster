## 1.0.0

* Initial stable release of `volume_booster`.
* Added `VolumeBoosterDial` featuring a 3D hardware-inspired rotary knob, segmented LED perimeter ticks across 3 safety zones (`Safe 0–100%`, `Turbo Boost 101–155%`, `Overdrive 156–200%+`), pulsing harmonic overdrive rings, live decibel gain readout (`-60.0 dB` to `+18.0 dB`), circular drag, scroll-wheel, keyboard navigation, and quick-jump preset buttons.
* Added `VolumeBoosterSlider` providing a dual-zone linear overdrive slider with a clearly marked `100% (0 dB)` unity gain divider, segmented LED or smooth gradient fill, and inline mute control.
* Added `VolumeEqualizerWidget` with a 5-band graphic equalizer (`60Hz`, `230Hz`, `910Hz`, `3.6kHz`, `14kHz`), real-time cubic-Bezier frequency response curve, 7 acoustic presets (`normal`, `voiceBoost`, `bassExtreme`, `cinema3D`, `gaming`, `maxOverdrive`, `nightLimiter`), Bass Boost, 3D Virtualizer, and Brickwall Anti-Clipping Safety Limiter.
* Added `VolumeSpectrumVisualizer` and `StereoVuMeter` supporting segmented LED spectrum bars, glowing harmonic waveforms, center-mirrored spectrum bars, and dual L/R peak-hold VU telemetry with `CLIP` detection.
* Added `VolumeBoosterConsole` combining all components into a drop-in Studio Volume Booster & Audio DSP deck.
* Added 6 built-in theme presets in `VolumeBoosterStyle`: `cyberNeon`, `studioPro`, `glassmorphic`, `sunsetOverdrive`, `softNeumorphic`, and `modernMaterial`.
* Added `VolumeBoosterController` for reactive programmatic control and optional platform `MethodChannel` bridge synchronization.
* Added animated SVG UI previews in `doc/` and `README.md`.
