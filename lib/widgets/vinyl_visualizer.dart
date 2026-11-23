import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/track.dart';
import '../theme/app_theme.dart';

class VinylVisualizer extends StatefulWidget {
  final bool isPlaying;
  final AudioTrack? currentTrack;
  final VoidCallback onPickFiles;

  const VinylVisualizer({
    super.key,
    required this.isPlaying,
    required this.currentTrack,
    required this.onPickFiles,
  });

  @override
  State<VinylVisualizer> createState() => _VinylVisualizerState();
}

class _VinylVisualizerState extends State<VinylVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant VinylVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isPlaying && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasTrack = widget.currentTrack != null;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320, maxHeight: 320),
        child: AspectRatio(
          aspectRatio: 1,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: hasTrack
                ? AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _controller.value * 2 * math.pi,
                        child: child,
                      );
                    },
                    child: _buildVinylDisc(),
                  )
                : _buildEmptyState(),
          ),
        ),
      ),
    );
  }

  Widget _buildVinylDisc() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [
            Color(0xFF262E3B),
            Color(0xFF141820),
            Color(0xFF0C0E12),
            Color(0xFF1E2530),
            Color(0xFF0F1217),
          ],
          stops: [0.0, 0.45, 0.75, 0.9, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: widget.isPlaying
                ? AppTheme.limeAccent.withValues(alpha: 0.22)
                : Colors.black.withValues(alpha: 0.5),
            blurRadius: widget.isPlaying ? 28 : 14,
            spreadRadius: widget.isPlaying ? 4 : 0,
          ),
        ],
        border: Border.all(
          color: widget.isPlaying
              ? AppTheme.limeAccent.withValues(alpha: 0.4)
              : AppTheme.darkBorder,
          width: 2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Grooves
          ...List.generate(4, (index) {
            final radiusFactor = 0.45 + (index * 0.12);
            return FractionallySizedBox(
              widthFactor: radiusFactor,
              heightFactor: radiusFactor,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.04),
                    width: 1,
                  ),
                ),
              ),
            );
          }),

          // Center Label (Electric Lime Vinyl Core)
          FractionallySizedBox(
            widthFactor: 0.38,
            heightFactor: 0.38,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [
                    AppTheme.limeAccent,
                    AppTheme.limeMuted,
                    Color(0xFF5B7F00),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFF111827),
                  width: 3,
                ),
              ),
              child: Center(
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0C0E12),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkSurfaceVariant,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.darkBorder, width: 1.5),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.limeSubtle,
                  border: Border.all(color: AppTheme.limeAccent.withValues(alpha: 0.3)),
                ),
                child: const Icon(
                  Icons.audio_file_rounded,
                  size: 30,
                  color: AppTheme.limeAccent,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'No Track Selected',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Choose local audio files to start playback',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: widget.onPickFiles,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.limeAccent,
                  foregroundColor: const Color(0xFF111827),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.folder_open_rounded, size: 16),
                label: const Text(
                  'Select Audio',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
