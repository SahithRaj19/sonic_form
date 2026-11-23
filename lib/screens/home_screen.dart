import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/track.dart';
import '../services/audio_player_service.dart';
import '../services/web_url_helper.dart';
import '../theme/app_theme.dart';
import '../widgets/equalizer_panel.dart';
import '../widgets/player_controls.dart';
import '../widgets/track_list_sheet.dart';
import '../widgets/vinyl_visualizer.dart';
import '../widgets/volume_slider.dart';

class HomeScreen extends StatefulWidget {
  final AudioPlayerService playerService;

  const HomeScreen({
    super.key,
    required this.playerService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedMobileTab = 0; // 0: Player, 1: Equalizer, 2: Queue

  Future<void> _pickAudioFiles() async {
    try {
      // Android runtime permissions check
      if (!kIsWeb && Platform.isAndroid) {
        // Android 13+ uses READ_MEDIA_AUDIO (Permission.audio)
        var audioStatus = await Permission.audio.status;
        if (!audioStatus.isGranted) {
          audioStatus = await Permission.audio.request();
        }

        // Android 12 and lower fallback
        if (!audioStatus.isGranted) {
          var storageStatus = await Permission.storage.status;
          if (!storageStatus.isGranted) {
            await Permission.storage.request();
          }
        }
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: true,
        withData: kIsWeb, // Ensures audio bytes are loaded into memory in browsers
      );

      if (result != null && result.files.isNotEmpty) {
        final newTracks = <AudioTrack>[];

        for (final f in result.files) {
          final filename = f.name;
          final title = filename.contains('.')
              ? filename.substring(0, filename.lastIndexOf('.'))
              : filename;

          String audioSourceUrl;
          if (kIsWeb) {
            if (f.bytes == null || f.bytes!.isEmpty) continue;
            final isWav = filename.toLowerCase().endsWith('.wav');
            final mimeType = isWav ? 'audio/wav' : 'audio/mpeg';
            audioSourceUrl = createBlobUrl(f.bytes!, mimeType);
          } else {
            if (f.path == null) continue;
            audioSourceUrl = f.path!;
          }

          newTracks.add(
            AudioTrack(
              id: audioSourceUrl,
              title: title,
              artist: 'Local Audio',
              path: audioSourceUrl,
              sizeInBytes: f.size,
            ),
          );
        }

        if (newTracks.isNotEmpty) {
          await widget.playerService.addTracks(newTracks);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Added ${newTracks.length} track${newTracks.length > 1 ? 's' : ''} to queue',
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('File picker error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load audio files: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.darkSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppTheme.darkBorder),
          ),
          title: const Row(
            children: [
              Icon(Icons.graphic_eq_rounded, color: AppTheme.limeAccent),
              SizedBox(width: 10),
              Text(
                'About SonicForm',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SonicForm is an Android local music player engineered with just_audio for clean audio playback and native hardware equalizer processing.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
                ),
                SizedBox(height: 14),
                Text(
                  'Audio Routing:',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Audio routes through the active device output, dynamically switching between phone speakers, 3.5mm wired headphones, USB-C DACs, and Bluetooth headphones.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.35),
                ),
                SizedBox(height: 14),
                Text(
                  'Platform Limits & Transparency:',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '• Equalizer processing strictly applies to audio tracks played within SonicForm.\n'
                  '• Equalizer DSP hardware effects are Android-specific.\n'
                  '• SonicForm does not control audio from other apps or alter system-wide sound.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.35),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Got It',
                style: TextStyle(color: AppTheme.limeAccent, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.playerService,
      builder: (context, child) {
        final currentTrack = widget.playerService.currentTrack;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.limeSubtle,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.limeAccent.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(
                    Icons.graphic_eq_rounded,
                    color: AppTheme.limeAccent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'SonicForm',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            actions: [
              // Output Routing Badge
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.darkSurfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.darkBorder),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.headphones_rounded,
                      size: 14,
                      color: AppTheme.limeAccent,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Active Output',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Select Files Button
              IconButton(
                icon: const Icon(Icons.folder_open_rounded, color: AppTheme.limeAccent),
                tooltip: 'Select Audio Files',
                onPressed: _pickAudioFiles,
              ),
              // Info Button
              IconButton(
                icon: const Icon(Icons.info_outline_rounded, color: AppTheme.textSecondary),
                tooltip: 'About SonicForm',
                onPressed: _showInfoDialog,
              ),
              const SizedBox(width: 6),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;

              if (isWide) {
                return _buildWideLayout();
              } else {
                return _buildMobileLayout(currentTrack);
              }
            },
          ),
          bottomNavigationBar: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 720) return const SizedBox.shrink();
              return NavigationBar(
                selectedIndex: _selectedMobileTab,
                backgroundColor: AppTheme.darkSurface,
                indicatorColor: AppTheme.limeAccent,
                onDestinationSelected: (index) {
                  setState(() {
                    _selectedMobileTab = index;
                  });
                },
                destinations: [
                  const NavigationDestination(
                    icon: Icon(Icons.music_note_rounded),
                    selectedIcon: Icon(Icons.music_note_rounded, color: Color(0xFF111827)),
                    label: 'Player',
                  ),
                  NavigationDestination(
                    icon: Badge(
                      isLabelVisible: widget.playerService.equalizerEnabled,
                      backgroundColor: AppTheme.limeAccent,
                      smallSize: 8,
                      child: const Icon(Icons.equalizer_rounded),
                    ),
                    selectedIcon: const Icon(Icons.equalizer_rounded, color: Color(0xFF111827)),
                    label: 'Equalizer',
                  ),
                  NavigationDestination(
                    icon: Badge(
                      label: Text('${widget.playerService.queue.length}'),
                      isLabelVisible: widget.playerService.queue.isNotEmpty,
                      backgroundColor: AppTheme.limeAccent,
                      textColor: const Color(0xFF111827),
                      child: const Icon(Icons.queue_music_rounded),
                    ),
                    selectedIcon: const Icon(Icons.queue_music_rounded, color: Color(0xFF111827)),
                    label: 'Queue',
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  /// Two-column responsive layout for tablets and landscape
  Widget _buildWideLayout() {
    final currentTrack = widget.playerService.currentTrack;

    return Row(
      children: [
        // Left Column: Player, Controls, Volume
        SizedBox(
          width: 380,
          child: Container(
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: AppTheme.darkDivider)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  VinylVisualizer(
                    isPlaying: widget.playerService.isPlaying,
                    currentTrack: currentTrack,
                    onPickFiles: _pickAudioFiles,
                  ),
                  _buildErrorBanner(),
                  const SizedBox(height: 12),
                  _buildTrackMeta(currentTrack),
                  const SizedBox(height: 16),
                  PlayerControls(playerService: widget.playerService),
                  const SizedBox(height: 16),
                  VolumeSlider(playerService: widget.playerService),
                ],
              ),
            ),
          ),
        ),

        // Right Column: Tabbed Equalizer Studio & Queue
        Expanded(
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(
                  dividerColor: AppTheme.darkDivider,
                  indicatorColor: AppTheme.limeAccent,
                  labelColor: AppTheme.limeAccent,
                  unselectedLabelColor: AppTheme.textSecondary,
                  tabs: [
                    Tab(
                      icon: Icon(Icons.graphic_eq_rounded, size: 18),
                      text: 'Equalizer Studio',
                    ),
                    Tab(
                      icon: Icon(Icons.queue_music_rounded, size: 18),
                      text: 'Queue',
                    ),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      EqualizerPanel(playerService: widget.playerService),
                      TrackListSheet(
                        playerService: widget.playerService,
                        onPickFiles: _pickAudioFiles,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Mobile layout with tab switching and persistent mini-player
  Widget _buildMobileLayout(AudioTrack? currentTrack) {
    return Column(
      children: [
        Expanded(
          child: IndexedStack(
            index: _selectedMobileTab,
            children: [
              // Tab 0: Main Player
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                child: Column(
                  children: [
                    VinylVisualizer(
                      isPlaying: widget.playerService.isPlaying,
                      currentTrack: currentTrack,
                      onPickFiles: _pickAudioFiles,
                    ),
                    _buildErrorBanner(),
                    const SizedBox(height: 14),
                    _buildTrackMeta(currentTrack),
                    const SizedBox(height: 18),
                    PlayerControls(playerService: widget.playerService),
                    const SizedBox(height: 18),
                    VolumeSlider(playerService: widget.playerService),
                    const SizedBox(height: 14),
                  ],
                ),
              ),

              // Tab 1: Equalizer Panel
              EqualizerPanel(playerService: widget.playerService),

              // Tab 2: Queue
              TrackListSheet(
                playerService: widget.playerService,
                onPickFiles: _pickAudioFiles,
              ),
            ],
          ),
        ),

        // Persistent Mini Player when on Equalizer or Queue tabs
        if (_selectedMobileTab != 0 && currentTrack != null)
          _buildPersistentMiniPlayer(currentTrack),
      ],
    );
  }

  Widget _buildErrorBanner() {
    final error = widget.playerService.lastErrorMessage;
    if (error == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF3B1212),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF4444)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Playback Error',
                  style: TextStyle(
                    color: Color(0xFFFCA5A5),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  error,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFFEE2E2),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: widget.playerService.play,
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.limeAccent,
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFFFCA5A5)),
            onPressed: widget.playerService.clearError,
            visualDensity: VisualDensity.compact,
            tooltip: 'Dismiss',
          ),
        ],
      ),
    );
  }

  Widget _buildTrackMeta(AudioTrack? currentTrack) {
    if (currentTrack == null) {
      return const Column(
        children: [
          Text(
            'Ready to Play',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Tap folder icon to select audio',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textTertiary,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Text(
          currentTrack.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              currentTrack.artist,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.limeAccent,
              ),
            ),
            if (currentTrack.formattedSize.isNotEmpty) ...[
              const Text('  •  ', style: TextStyle(color: AppTheme.textTertiary)),
              Text(
                currentTrack.formattedSize,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildPersistentMiniPlayer(AudioTrack currentTrack) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.darkSurfaceVariant,
        border: Border(top: BorderSide(color: AppTheme.darkBorder)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.limeSubtle,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.limeAccent.withValues(alpha: 0.3)),
              ),
              child: const Icon(
                Icons.music_note_rounded,
                color: AppTheme.limeAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currentTrack.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    currentTrack.artist,
                    style: const TextStyle(
                      color: AppTheme.limeAccent,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.skip_previous_rounded, size: 22),
              color: AppTheme.textPrimary,
              onPressed: widget.playerService.previous,
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              icon: Icon(
                widget.playerService.isPlaying
                    ? Icons.pause_circle_filled_rounded
                    : Icons.play_circle_filled_rounded,
                size: 32,
                color: AppTheme.limeAccent,
              ),
              onPressed: widget.playerService.togglePlayPause,
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              icon: const Icon(Icons.skip_next_rounded, size: 22),
              color: AppTheme.textPrimary,
              onPressed: widget.playerService.next,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}
