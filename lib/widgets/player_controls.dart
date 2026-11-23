import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../services/audio_player_service.dart';
import '../theme/app_theme.dart';

class PlayerControls extends StatelessWidget {
  final AudioPlayerService playerService;

  const PlayerControls({
    super.key,
    required this.playerService,
  });

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final pos = playerService.position;
    final dur = playerService.duration;
    final maxSeconds = dur.inMilliseconds.toDouble();
    final currentSeconds = pos.inMilliseconds.toDouble().clamp(0.0, maxSeconds > 0 ? maxSeconds : 1.0);
    final isPlaying = playerService.isPlaying;
    final isBuffering = playerService.isBuffering;
    final loopMode = playerService.loopMode;
    final shuffle = playerService.shuffleEnabled;
    final hasTracks = playerService.queue.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Seek Slider & Duration counters
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                ),
                child: Slider(
                  value: currentSeconds,
                  min: 0.0,
                  max: maxSeconds > 0 ? maxSeconds : 1.0,
                  onChanged: hasTracks
                      ? (val) {
                          playerService.seek(Duration(milliseconds: val.toInt()));
                        }
                      : null,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(pos),
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      _formatDuration(dur),
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Main Control Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Shuffle
            IconButton(
              icon: Icon(
                Icons.shuffle_rounded,
                color: shuffle ? AppTheme.limeAccent : AppTheme.textTertiary,
                size: 24,
              ),
              tooltip: shuffle ? 'Shuffle On' : 'Shuffle Off',
              onPressed: hasTracks ? playerService.toggleShuffle : null,
            ),

            // Previous
            IconButton(
              icon: const Icon(
                Icons.skip_previous_rounded,
                color: AppTheme.textPrimary,
                size: 36,
              ),
              tooltip: 'Previous Track',
              onPressed: hasTracks ? playerService.previous : null,
            ),

            // Play / Pause Large Glow Button
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: isPlaying
                    ? [
                        BoxShadow(
                          color: AppTheme.limeAccent.withValues(alpha: 0.35),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: Material(
                color: AppTheme.limeAccent,
                shape: const CircleBorder(),
                elevation: 4,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: hasTracks ? playerService.togglePlayPause : null,
                  child: SizedBox(
                    width: 68,
                    height: 68,
                    child: Center(
                      child: isBuffering
                          ? const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Color(0xFF111827),
                              ),
                            )
                          : Icon(
                              isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: 38,
                              color: const Color(0xFF111827),
                            ),
                    ),
                  ),
                ),
              ),
            ),

            // Next
            IconButton(
              icon: const Icon(
                Icons.skip_next_rounded,
                color: AppTheme.textPrimary,
                size: 36,
              ),
              tooltip: 'Next Track',
              onPressed: hasTracks ? playerService.next : null,
            ),

            // Loop mode cycle
            IconButton(
              icon: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    loopMode == LoopMode.one
                        ? Icons.repeat_one_rounded
                        : Icons.repeat_rounded,
                    color: loopMode != LoopMode.off
                        ? AppTheme.limeAccent
                        : AppTheme.textTertiary,
                    size: 24,
                  ),
                ],
              ),
              tooltip: 'Repeat: ${loopMode.name.toUpperCase()}',
              onPressed: hasTracks ? playerService.cycleLoopMode : null,
            ),
          ],
        ),
      ],
    );
  }
}
