import 'package:flutter/material.dart';
import '../services/audio_player_service.dart';
import '../theme/app_theme.dart';

class VolumeSlider extends StatelessWidget {
  final AudioPlayerService playerService;

  const VolumeSlider({
    super.key,
    required this.playerService,
  });

  IconData _getVolumeIcon(double volume, bool isMuted) {
    if (isMuted || volume == 0.0) return Icons.volume_off_rounded;
    if (volume < 0.35) return Icons.volume_mute_rounded;
    if (volume < 0.7) return Icons.volume_down_rounded;
    return Icons.volume_up_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final vol = playerService.volume;
    final isMuted = playerService.isMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.darkSurfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: playerService.toggleMute,
            icon: Icon(
              _getVolumeIcon(vol, isMuted),
              color: isMuted ? AppTheme.textTertiary : AppTheme.limeAccent,
              size: 22,
            ),
            tooltip: isMuted ? 'Unmute' : 'Mute',
            splashRadius: 20,
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3.5,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              ),
              child: Slider(
                value: isMuted ? 0.0 : vol,
                min: 0.0,
                max: 1.0,
                onChanged: (val) {
                  playerService.setVolume(val);
                },
              ),
            ),
          ),
          SizedBox(
            width: 42,
            child: Text(
              isMuted ? '0%' : '${(vol * 100).toInt()}%',
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
