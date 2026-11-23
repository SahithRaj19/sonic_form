import 'package:flutter/material.dart';
import '../services/audio_player_service.dart';
import '../theme/app_theme.dart';

class TrackListSheet extends StatelessWidget {
  final AudioPlayerService playerService;
  final VoidCallback onPickFiles;

  const TrackListSheet({
    super.key,
    required this.playerService,
    required this.onPickFiles,
  });

  @override
  Widget build(BuildContext context) {
    final queue = playerService.queue;
    final currentIndex = playerService.currentIndex;
    final isPlaying = playerService.isPlaying;

    if (queue.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppTheme.darkSurfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.queue_music_rounded,
                  size: 48,
                  color: AppTheme.limeAccent,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Queue is Empty',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select local MP3, WAV, FLAC, or AAC files from your device storage.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onPickFiles,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.limeAccent,
                  foregroundColor: const Color(0xFF111827),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.file_upload_outlined, size: 20),
                label: const Text(
                  'Browse Files',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Queue Header Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'PLAYBACK QUEUE',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.limeSubtle,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.limeAccent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '${queue.length}',
                      style: const TextStyle(
                        color: AppTheme.limeAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: onPickFiles,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.limeAccent,
                  side: const BorderSide(color: AppTheme.limeAccent),
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text(
                  'Add Files',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),

        // List of Tracks
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            itemCount: queue.length,
            separatorBuilder: (context, index) => const Divider(
              color: AppTheme.darkDivider,
              height: 1,
            ),
            itemBuilder: (context, index) {
              final track = queue[index];
              final isSelected = index == currentIndex;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: isSelected
                    ? AppTheme.limeSubtle
                    : Colors.transparent,
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.limeAccent
                        : AppTheme.darkSurfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: isSelected
                        ? Icon(
                            isPlaying
                                ? Icons.volume_up_rounded
                                : Icons.play_arrow_rounded,
                            color: const Color(0xFF111827),
                            size: 22,
                          )
                        : Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                  ),
                ),
                title: Text(
                  track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? AppTheme.limeAccent : AppTheme.textPrimary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  track.formattedSize.isNotEmpty
                      ? '${track.artist} • ${track.formattedSize}'
                      : track.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppTheme.textTertiary,
                  ),
                  tooltip: 'Remove',
                  onPressed: () => playerService.removeTrack(index),
                ),
                onTap: () {
                  playerService.playTrackAt(index);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
