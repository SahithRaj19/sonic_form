import 'package:flutter_test/flutter_test.dart';
import 'package:sonic_form/main.dart';
import 'package:sonic_form/models/track.dart';

void main() {
  testWidgets('SonicForm smoke test - renders app bar and controls',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SonicFormApp());
    await tester.pumpAndSettle();

    // Verify SonicForm title is rendered
    expect(find.text('SonicForm'), findsOneWidget);

    // Verify Active Output badge is rendered
    expect(find.text('Active Output'), findsOneWidget);

    // Verify initial empty state or ready text
    expect(find.text('Ready to Play'), findsOneWidget);
  });

  test('Equalizer presets have distinct frequency profiles', () {
    expect(EqualizerPresetType.flat.baseGains, [0.0, 0.0, 0.0, 0.0, 0.0]);
    // Warm boosts bass, rolls off treble
    expect(EqualizerPresetType.warm.baseGains[0], greaterThan(0));
    expect(EqualizerPresetType.warm.baseGains[4], lessThan(0));

    // Vocal emphasizes midrange
    expect(EqualizerPresetType.vocal.baseGains[2], greaterThan(3.0));

    // Bright boosts highs
    expect(EqualizerPresetType.bright.baseGains[4], greaterThan(4.0));

    // Deep emphasizes sub-bass
    expect(EqualizerPresetType.deep.baseGains[0], greaterThan(5.0));
  });

  test('EqualizerBandModel frequency label formatting', () {
    final bandLow = EqualizerBandModel(
      index: 0,
      centerFrequency: 60.0,
      lowerFrequency: 30.0,
      upperFrequency: 120.0,
      gain: 0.0,
    );
    expect(bandLow.frequencyLabel, '60 Hz');

    final bandMid = EqualizerBandModel(
      index: 2,
      centerFrequency: 1000.0,
      lowerFrequency: 500.0,
      upperFrequency: 2000.0,
      gain: 0.0,
    );
    expect(bandMid.frequencyLabel, '1 kHz');

    final bandHigh = EqualizerBandModel(
      index: 4,
      centerFrequency: 14000.0,
      lowerFrequency: 8000.0,
      upperFrequency: 20000.0,
      gain: 0.0,
    );
    expect(bandHigh.frequencyLabel, '14 kHz');
  });
}
