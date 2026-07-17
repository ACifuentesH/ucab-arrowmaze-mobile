import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

/// Regression test for a real bug found while investigating "no audio in
/// the app": pubspec.yaml's `assets:` list declared `assets/audio/`
/// (non-recursive) but never `assets/audio/sfx/`, so Flutter's asset
/// bundler silently excluded every SFX file from the build. Every
/// `playSfx()` call then hit an exception that AudioService's old bare
/// `catch (_) {}` swallowed with zero trace, so SFX simply never played and
/// nothing in the logs said why.
///
/// This loads every path AudioService actually references straight from
/// the real Flutter asset bundle (no fake, no mocked audio backend — this
/// is exactly the pubspec.yaml → AssetManifest wiring that broke), so it
/// fails loudly if a future asset addition repeats the same mistake.
void main() {
  group('AudioService asset bundling (regression: pubspec.yaml assets:)', () {
    const paths = [
      'assets/audio/background.wav',
      'assets/audio/sfx/arrow_escaped.wav',
      'assets/audio/sfx/move_blocked.wav',
      'assets/audio/sfx/level_cleared.wav',
      'assets/audio/sfx/game_over.wav',
      'assets/audio/sfx/button_tap.wav',
    ];

    for (final path in paths) {
      testWidgets('should_bundle_${path}_as_a_flutter_asset', (tester) async {
        final data = await rootBundle.load(path);
        expect(data.lengthInBytes, greaterThan(0));
      });
    }
  });
}
