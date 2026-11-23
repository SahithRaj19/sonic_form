import 'dart:async';
import 'dart:io';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/track.dart';

class AudioPlayerService extends ChangeNotifier {
  late final AudioPlayer _player;
  AndroidEqualizer? _androidEqualizer;
  AudioPipeline? _audioPipeline;

  // Track Queue Management
  final List<AudioTrack> _queue = [];
  int _currentIndex = -1;

  // Playback state cache
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Duration _bufferedPosition = Duration.zero;
  PlayerState _playerState = PlayerState(false, ProcessingState.idle);
  double _volume = 1.0;
  bool _isMuted = false;
  double _preMuteVolume = 1.0;
  LoopMode _loopMode = LoopMode.off;
  bool _shuffleEnabled = false;

  // Error Tracking
  String? _lastErrorMessage;

  // Equalizer State
  bool _equalizerEnabled = true;
  EqualizerPresetType _currentPreset = EqualizerPresetType.flat;
  List<EqualizerBandModel> _bands = [];
  double _minDecibels = -15.0;
  double _maxDecibels = 15.0;
  bool _hardwareEqualizerInitialized = false;
  AndroidEqualizerParameters? _hardwareParams;

  // Stream Subscriptions
  final List<StreamSubscription> _subscriptions = [];

  // Getters
  List<AudioTrack> get queue => List.unmodifiable(_queue);
  int get currentIndex => _currentIndex;
  AudioTrack? get currentTrack =>
      (_currentIndex >= 0 && _currentIndex < _queue.length)
          ? _queue[_currentIndex]
          : null;

  Duration get position => _position;
  Duration get duration => _duration;
  Duration get bufferedPosition => _bufferedPosition;
  PlayerState get playerState => _playerState;
  bool get isPlaying => _playerState.playing;
  bool get isBuffering =>
      _playerState.processingState == ProcessingState.buffering ||
      _playerState.processingState == ProcessingState.loading;
  bool get isCompleted =>
      _playerState.processingState == ProcessingState.completed;

  double get volume => _volume;
  bool get isMuted => _isMuted;
  LoopMode get loopMode => _loopMode;
  bool get shuffleEnabled => _shuffleEnabled;
  String? get lastErrorMessage => _lastErrorMessage;

  bool get equalizerEnabled => _equalizerEnabled;
  EqualizerPresetType get currentPreset => _currentPreset;
  List<EqualizerBandModel> get bands => List.unmodifiable(_bands);
  double get minDecibels => _minDecibels;
  double get maxDecibels => _maxDecibels;
  bool get isAndroidPlatform => !kIsWeb && Platform.isAndroid;
  bool get isHardwareEqualizerActive =>
      isAndroidPlatform && _hardwareEqualizerInitialized;

  AudioPlayerService() {
    _initAudio();
  }

  Future<void> _initAudio() async {
    // 1. Initialize Equalizer & Pipeline strictly on Android where the native DSP exists
    if (isAndroidPlatform) {
      _androidEqualizer = AndroidEqualizer();
      _audioPipeline = AudioPipeline(androidAudioEffects: [_androidEqualizer!]);
      _player = AudioPlayer(audioPipeline: _audioPipeline);
    } else {
      _player = AudioPlayer();
    }

    // 2. Setup baseline 5-band representation
    _setupDefaultBands();

    // 3. Configure AudioSession only on platforms that support it (Android, iOS, macOS)
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      await _configureAudioSession();
    }

    // 4. Bind player streams
    _subscriptions.add(
      _player.positionStream.listen((pos) {
        _position = pos;
        notifyListeners();
      }),
    );

    _subscriptions.add(
      _player.durationStream.listen((dur) {
        _duration = dur ?? Duration.zero;
        notifyListeners();
      }),
    );

    _subscriptions.add(
      _player.bufferedPositionStream.listen((buf) {
        _bufferedPosition = buf;
        notifyListeners();
      }),
    );

    _subscriptions.add(
      _player.playerStateStream.listen((state) {
        _playerState = state;
        if (state.processingState == ProcessingState.completed) {
          _handleTrackCompleted();
        }
        notifyListeners();
      }),
    );

    _subscriptions.add(
      _player.playbackEventStream.listen(
        (event) {},
        onError: (Object e, StackTrace stackTrace) {
          debugPrint('Playback event stream error: $e');
          _lastErrorMessage = 'Playback error: $e';
          notifyListeners();
        },
      ),
    );

    _subscriptions.add(
      _player.volumeStream.listen((vol) {
        _volume = vol;
        _isMuted = vol == 0.0;
        notifyListeners();
      }),
    );

    // Enable equalizer effect on Android
    if (isAndroidPlatform && _androidEqualizer != null) {
      try {
        await _androidEqualizer!.setEnabled(_equalizerEnabled);
      } catch (e) {
        debugPrint('Equalizer setEnabled initial error: $e');
      }
    }
  }

  /// Sets up default 5-band spectrum (60Hz, 230Hz, 910Hz, 3.6kHz, 14kHz)
  void _setupDefaultBands() {
    final defaultFrequencies = [60.0, 230.0, 910.0, 3600.0, 14000.0];
    final defaultLower = [30.0, 120.0, 500.0, 2000.0, 8000.0];
    final defaultUpper = [120.0, 500.0, 2000.0, 8000.0, 20000.0];

    _bands = List.generate(5, (i) {
      return EqualizerBandModel(
        index: i,
        centerFrequency: defaultFrequencies[i],
        lowerFrequency: defaultLower[i],
        upperFrequency: defaultUpper[i],
        gain: 0.0,
      );
    });
  }

  /// Configures AudioSession for active device routing (speakers, wired headphones, Bluetooth)
  Future<void> _configureAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      // Auto pause when headphones are unplugged (Becoming noisy event)
      session.becomingNoisyEventStream.listen((_) {
        pause();
      });
    } catch (e) {
      debugPrint('AudioSession configuration error: $e');
    }
  }

  /// Attempts to fetch Android hardware equalizer bands and parameters safely
  Future<void> _tryInitializeHardwareEqualizer() async {
    if (!isAndroidPlatform || _androidEqualizer == null) return;

    try {
      final params = await _androidEqualizer!.parameters.timeout(
        const Duration(seconds: 3),
      );
      _hardwareParams = params;
      _minDecibels = params.minDecibels;
      _maxDecibels = params.maxDecibels;

      // Update bands from hardware
      _bands = params.bands.map((hwBand) {
        return EqualizerBandModel(
          index: hwBand.index,
          centerFrequency: hwBand.centerFrequency,
          lowerFrequency: hwBand.lowerFrequency,
          upperFrequency: hwBand.upperFrequency,
          gain: hwBand.gain,
        );
      }).toList();

      _hardwareEqualizerInitialized = true;
      // Re-apply preset if already selected
      await applyPreset(_currentPreset);
      notifyListeners();
    } catch (e) {
      debugPrint('Equalizer parameters not yet ready or timed out: $e');
    }
  }

  void clearError() {
    _lastErrorMessage = null;
    notifyListeners();
  }

  // ==========================
  // Track & Playback Controls
  // ==========================

  Future<void> loadPlaylist(List<AudioTrack> tracks, {int startIndex = 0}) async {
    if (tracks.isEmpty) return;
    _queue.clear();
    _queue.addAll(tracks);
    _currentIndex = startIndex.clamp(0, _queue.length - 1);
    notifyListeners();
    await _loadAndPlayCurrent();
  }

  Future<void> addTracks(List<AudioTrack> tracks) async {
    if (tracks.isEmpty) return;
    final wasEmpty = _queue.isEmpty;
    _queue.addAll(tracks);

    if (wasEmpty || _currentIndex == -1) {
      _currentIndex = 0;
      notifyListeners();
      await _loadAndPlayCurrent();
    } else {
      notifyListeners();
    }
  }

  Future<void> removeTrack(int index) async {
    if (index < 0 || index >= _queue.length) return;

    if (index == _currentIndex) {
      if (_queue.length > 1) {
        _queue.removeAt(index);
        if (_currentIndex >= _queue.length) {
          _currentIndex = _queue.length - 1;
        }
        await _loadAndPlayCurrent();
      } else {
        await _player.stop();
        _queue.clear();
        _currentIndex = -1;
        _position = Duration.zero;
        _duration = Duration.zero;
        notifyListeners();
      }
    } else {
      _queue.removeAt(index);
      if (index < _currentIndex) {
        _currentIndex--;
      }
      notifyListeners();
    }
  }

  Future<void> playTrackAt(int index) async {
    if (index < 0 || index >= _queue.length) return;
    _currentIndex = index;
    notifyListeners();
    await _loadAndPlayCurrent();
  }

  Future<void> _loadAndPlayCurrent() async {
    final track = currentTrack;
    if (track == null) return;

    try {
      _lastErrorMessage = null;
      notifyListeners();

      debugPrint('SonicForm: Loading track: "${track.title}" at "${track.path}"');

      Uri audioUri;
      if (track.path.startsWith('blob:') ||
          track.path.startsWith('data:') ||
          track.path.startsWith('content://') ||
          track.path.startsWith('file://') ||
          track.path.startsWith('http://') ||
          track.path.startsWith('https://')) {
        audioUri = Uri.parse(track.path);
      } else {
        if (!kIsWeb) {
          final file = File(track.path);
          final exists = await file.exists();
          if (!exists) {
            throw Exception('Audio file was not found on device storage:\n${track.path}');
          }
          audioUri = Uri.file(track.path);
        } else {
          audioUri = Uri.parse(track.path);
        }
      }

      // Stop previous playback to release decoder before loading next track
      await _player.stop();

      // Load audio source with progressive streaming
      await _player.setAudioSource(
        AudioSource.uri(audioUri),
        preload: true,
      );

      // Ensure volume is synchronized
      await _player.setVolume(_isMuted ? 0.0 : _volume);

      // On Android, loading audio activates the equalizer effect
      if (isAndroidPlatform && !_hardwareEqualizerInitialized) {
        unawaited(_tryInitializeHardwareEqualizer());
      }

      // Play audio
      await _player.play();
      debugPrint('SonicForm: Playback active for: "${track.title}"');
    } catch (e, stack) {
      debugPrint('SonicForm Playback Error for "${track.title}": $e\n$stack');
      _lastErrorMessage = 'Failed to play "${track.title}": $e';
      notifyListeners();
    }
  }

  Future<void> play() async {
    if (_queue.isEmpty) return;

    if (_currentIndex < 0 || _currentIndex >= _queue.length) {
      _currentIndex = 0;
    }

    try {
      _lastErrorMessage = null;
      if (_player.audioSource == null ||
          _playerState.processingState == ProcessingState.idle) {
        await _loadAndPlayCurrent();
      } else if (_playerState.processingState == ProcessingState.completed) {
        await seek(Duration.zero);
        await _player.play();
      } else {
        await _player.play();
      }
    } catch (e) {
      debugPrint('SonicForm play() error: $e');
      _lastErrorMessage = 'Playback error: $e';
      notifyListeners();
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> next() async {
    if (_queue.isEmpty) return;
    if (_currentIndex < _queue.length - 1) {
      _currentIndex++;
      await _loadAndPlayCurrent();
    } else if (_loopMode == LoopMode.all) {
      _currentIndex = 0;
      await _loadAndPlayCurrent();
    }
  }

  Future<void> previous() async {
    if (_queue.isEmpty) return;
    if (_position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }
    if (_currentIndex > 0) {
      _currentIndex--;
      await _loadAndPlayCurrent();
    } else if (_loopMode == LoopMode.all) {
      _currentIndex = _queue.length - 1;
      await _loadAndPlayCurrent();
    } else {
      await seek(Duration.zero);
    }
  }

  Future<void> setVolume(double newVolume) async {
    final clamped = newVolume.clamp(0.0, 1.0);
    _volume = clamped;
    if (clamped > 0) {
      _isMuted = false;
      _preMuteVolume = clamped;
    } else {
      _isMuted = true;
    }
    await _player.setVolume(clamped);
    notifyListeners();
  }

  Future<void> toggleMute() async {
    if (_isMuted) {
      final restoreVol = _preMuteVolume > 0 ? _preMuteVolume : 0.7;
      await setVolume(restoreVol);
    } else {
      _preMuteVolume = _volume;
      await setVolume(0.0);
    }
  }

  Future<void> cycleLoopMode() async {
    switch (_loopMode) {
      case LoopMode.off:
        _loopMode = LoopMode.all;
        break;
      case LoopMode.all:
        _loopMode = LoopMode.one;
        break;
      case LoopMode.one:
        _loopMode = LoopMode.off;
        break;
    }
    await _player.setLoopMode(_loopMode);
    notifyListeners();
  }

  Future<void> toggleShuffle() async {
    _shuffleEnabled = !_shuffleEnabled;
    await _player.setShuffleModeEnabled(_shuffleEnabled);
    notifyListeners();
  }

  void _handleTrackCompleted() {
    if (_loopMode == LoopMode.one) {
      seek(Duration.zero);
      play();
    } else if (_currentIndex < _queue.length - 1) {
      next();
    } else if (_loopMode == LoopMode.all) {
      _currentIndex = 0;
      _loadAndPlayCurrent();
    }
  }

  // ==========================
  // Equalizer & Sound Processing
  // ==========================

  Future<void> setEqualizerEnabled(bool enabled) async {
    _equalizerEnabled = enabled;
    if (isAndroidPlatform && _androidEqualizer != null) {
      try {
        await _androidEqualizer!.setEnabled(enabled);
      } catch (e) {
        debugPrint('Failed to set equalizer enabled: $e');
      }
    }
    notifyListeners();
  }

  /// Sets gain for an individual band in decibels
  Future<void> setBandGain(int bandIndex, double gain) async {
    if (bandIndex < 0 || bandIndex >= _bands.length) return;

    final clampedGain = gain.clamp(_minDecibels, _maxDecibels);
    _bands[bandIndex].gain = clampedGain;
    _currentPreset = EqualizerPresetType.custom;

    if (isAndroidPlatform && _hardwareParams != null) {
      try {
        final hwBands = _hardwareParams!.bands;
        if (bandIndex < hwBands.length) {
          await hwBands[bandIndex].setGain(clampedGain);
        }
      } catch (e) {
        debugPrint('Error setting hardware band gain: $e');
      }
    }

    notifyListeners();
  }

  /// Applies one of the standard presets (Flat, Warm, Vocal, Bright, Deep)
  Future<void> applyPreset(EqualizerPresetType preset) async {
    _currentPreset = preset;

    for (int i = 0; i < _bands.length; i++) {
      final band = _bands[i];
      final targetGain = EqualizerBandModel.interpolatePresetGain(
        preset,
        i,
        _bands.length,
        band.centerFrequency,
      ).clamp(_minDecibels, _maxDecibels);

      band.gain = targetGain;

      if (isAndroidPlatform && _hardwareParams != null) {
        try {
          final hwBands = _hardwareParams!.bands;
          if (i < hwBands.length) {
            await hwBands[i].setGain(targetGain);
          }
        } catch (e) {
          debugPrint('Error applying preset to hardware band $i: $e');
        }
      }
    }

    notifyListeners();
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _player.dispose();
    super.dispose();
  }
}
