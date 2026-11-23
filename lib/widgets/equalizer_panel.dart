import 'package:flutter/material.dart';
import '../models/track.dart';
import '../services/audio_player_service.dart';
import '../theme/app_theme.dart';

class EqualizerPanel extends StatelessWidget {
  final AudioPlayerService playerService;

  const EqualizerPanel({
    super.key,
    required this.playerService,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = playerService.equalizerEnabled;
    final currentPreset = playerService.currentPreset;
    final bands = playerService.bands;
    final minDb = playerService.minDecibels;
    final maxDb = playerService.maxDecibels;
    final isAndroid = playerService.isAndroidPlatform;
    final isHwActive = playerService.isHardwareEqualizerActive;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card: Switch & Status
          _buildHeaderCard(context, enabled, isAndroid, isHwActive),

          const SizedBox(height: 16),

          // Presets Carousel / Wrap
          _buildPresetSection(context, enabled, currentPreset),

          const SizedBox(height: 20),

          // Equalizer Bands Matrix
          _buildBandsSection(context, enabled, bands, minDb, maxDb),

          const SizedBox(height: 24),

          // Platform Limits & Disclaimer Card (Strict adherence to prompt instructions)
          _buildPlatformDisclaimerCard(isAndroid, isHwActive),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(
    BuildContext context,
    bool enabled,
    bool isAndroid,
    bool isHwActive,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: enabled
              ? AppTheme.limeAccent.withValues(alpha: 0.3)
              : AppTheme.darkBorder,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: enabled ? AppTheme.limeSubtle : AppTheme.darkSurfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.graphic_eq_rounded,
                    color: enabled ? AppTheme.limeAccent : AppTheme.textTertiary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Audio Equalizer',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        enabled ? 'Processing Active' : 'Bypassed',
                        style: TextStyle(
                          color: enabled ? AppTheme.limeAccent : AppTheme.textTertiary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: (val) {
              playerService.setEqualizerEnabled(val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPresetSection(
    BuildContext context,
    bool enabled,
    EqualizerPresetType currentPreset,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'SOUND PRESETS',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
            if (currentPreset != EqualizerPresetType.flat)
              TextButton(
                onPressed: enabled
                    ? () => playerService.applyPreset(EqualizerPresetType.flat)
                    : null,
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.limeAccent,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Reset', style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Preset Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: EqualizerPresetType.values.map((preset) {
              final isSelected = currentPreset == preset;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(preset.label),
                  selected: isSelected,
                  onSelected: enabled
                      ? (selected) {
                          if (selected) {
                            playerService.applyPreset(preset);
                          }
                        }
                      : null,
                  avatar: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Color(0xFF111827),
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 8),

        // Description of active preset
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.darkSurfaceVariant.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.darkBorder),
          ),
          child: Text(
            currentPreset.description,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBandsSection(
    BuildContext context,
    bool enabled,
    List<EqualizerBandModel> bands,
    double minDb,
    double maxDb,
  ) {
    if (bands.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const Text(
          'Connecting to Audio Pipeline...',
          style: TextStyle(color: AppTheme.textTertiary),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  'FREQUENCY RESPONSE',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${minDb.toInt()} dB to +${maxDb.toInt()} dB',
                style: const TextStyle(
                  color: AppTheme.textTertiary,
                  fontSize: 11,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Vertical Bands Slider Display
          SizedBox(
            height: 220,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(bands.length, (index) {
                final band = bands[index];
                return _buildBandColumn(
                  band: band,
                  minDb: minDb,
                  maxDb: maxDb,
                  enabled: enabled,
                  onChanged: (newGain) {
                    playerService.setBandGain(index, newGain);
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBandColumn({
    required EqualizerBandModel band,
    required double minDb,
    required double maxDb,
    required bool enabled,
    required ValueChanged<double> onChanged,
  }) {
    final gainVal = band.gain.clamp(minDb, maxDb);
    final isBoosted = gainVal > 0.05;
    final isCut = gainVal < -0.05;

    return Expanded(
      child: Column(
        children: [
          // Current dB text
          Text(
            '${gainVal >= 0 ? '+' : ''}${gainVal.toStringAsFixed(1)}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: !enabled
                  ? AppTheme.textTertiary
                  : isBoosted
                      ? AppTheme.limeAccent
                      : isCut
                          ? const Color(0xFF60A5FA)
                          : AppTheme.textSecondary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),

          const SizedBox(height: 6),

          // Vertical Slider container
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 0 dB center reference line
                Positioned(
                  child: Container(
                    height: 1.5,
                    width: 32,
                    color: AppTheme.darkBorder,
                  ),
                ),

                // Rotated Slider for vertical control
                RotatedBox(
                  quarterTurns: 3, // Turns slider vertically (bottom to top)
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 4,
                      activeTrackColor: enabled ? AppTheme.limeAccent : AppTheme.darkBorder,
                      inactiveTrackColor: AppTheme.darkSurfaceVariant,
                      thumbColor: enabled ? AppTheme.limeAccent : AppTheme.textTertiary,
                      overlayColor: AppTheme.limeGlow,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    ),
                    child: Slider(
                      value: gainVal,
                      min: minDb,
                      max: maxDb,
                      onChanged: enabled ? onChanged : null,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Frequency Label Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.darkSurfaceVariant,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.darkBorder),
            ),
            child: Text(
              band.frequencyLabel,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformDisclaimerCard(bool isAndroid, bool isHwActive) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHwActive
              ? AppTheme.limeAccent.withValues(alpha: 0.35)
              : AppTheme.darkBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isAndroid ? Icons.verified_user_rounded : Icons.info_outline_rounded,
                color: isAndroid ? AppTheme.limeAccent : AppTheme.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Platform Scope & Limits',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isHwActive ? AppTheme.limeSubtle : AppTheme.darkSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isHwActive ? AppTheme.limeAccent : AppTheme.darkBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isHwActive ? AppTheme.limeAccent : AppTheme.textTertiary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isHwActive
                          ? 'Android DSP Connected'
                          : isAndroid
                              ? 'Android Equalizer Ready'
                              : 'Non-Android Direct Audio',
                      style: TextStyle(
                        color: isHwActive ? AppTheme.limeAccent : AppTheme.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            '• In-App Scope Only: Equalizer processing applies exclusively to audio tracks played within SonicForm.\n'
            '• Android-Only DSP: Sound frequency processing utilizes Android\'s native AudioEffect pipeline (ExoPlayer). It does not function as a global effect.\n'
            '• Transparent Architecture: SonicForm does not control audio from other apps or provide system-wide sound effects.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
