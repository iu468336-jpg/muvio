import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:muvio/core/theme/app_colors.dart';
import 'package:muvio/core/theme/app_spacing.dart';
import 'package:muvio/core/theme/app_typography.dart';
import 'package:muvio/core/utils/formatters.dart';
import 'package:muvio/data/models/app_settings.dart';
import 'package:muvio/data/models/media_models.dart';
import 'package:muvio/data/providers/app_providers.dart';
import 'package:muvio/data/providers/torrent_engine_bridge.dart';
import 'package:muvio/l10n/app_localizations.dart';
import 'package:muvio/shared/widgets/muvio_image.dart';

part 'player_portrait_view.dart';
part 'player_landscape_view.dart';
part 'player_controls.dart';

/// Screens 3 & 7 — Portrait Video Player + Fullscreen Landscape 16:9 Player:
/// Powered by `media_kit` (`libmpv`) + `libtorrent4j` piece-accurate HTTP stream bridge.
class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({
    required this.mediaType,
    required this.mediaId,
    super.key,
    this.initialStream,
    this.enableNativePlayer = true,
  });

  final String mediaType;
  final String mediaId;
  final StreamSource? initialStream;
  final bool enableNativePlayer;

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  Player? _player;
  VideoController? _videoController;
  late final TorrentEngineBridge _torrentBridge;

  MediaItem? _media;
  List<StreamSource> _streams = const [];
  StreamSource? _activeStream;

  bool _isLandscapeMode = false;
  bool _controlsVisible = true;
  bool _controlsLocked = false;
  bool _showSourcesOverlay = false;
  bool _subtitlesEnabled = true;
  bool _isBuffering = true;
  String? _statusBanner;
  TorrentStreamTelemetry _telemetry = const TorrentStreamTelemetry();
  int _sessionToken = 0;

  String _selectedAudioLabel = 'Audio';
  double _playbackSpeed = 1;
  double _zoomScale = 1;
  double _brightnessLevel = 0.75;
  double _volumeLevel = 0.85;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = true;

  Timer? _hideControlsTimer;
  Timer? _telemetryTimer;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration>? _durSub;
  StreamSubscription<bool>? _playSub;
  StreamSubscription<bool>? _bufSub;
  StreamSubscription<String>? _errSub;

  @override
  void initState() {
    super.initState();
    _torrentBridge = ref.read(torrentEngineBridgeProvider);
    _initPlayerAndCatalog();
  }

  String _extractBaseMediaId(String rawId) {
    if (rawId.startsWith('kitsu:')) {
      final parts = rawId.split(':');
      return parts.length >= 2 ? '${parts[0]}:${parts[1]}' : rawId;
    }
    if (rawId.startsWith('tmdb:')) {
      final parts = rawId.split(':');
      return parts.length >= 2 ? '${parts[0]}:${parts[1]}' : rawId;
    }
    if (rawId.contains(':')) {
      return rawId.split(':').first;
    }
    return rawId;
  }

  bool _isEpisodeVideoId(String rawId, String baseId) => rawId != baseId;

  Future<void> _initPlayerAndCatalog() async {
    final addons = await ref.read(addonsControllerProvider.future);
    final catalogRepo = ref.read(catalogRepositoryProvider);
    final rawId = Uri.decodeComponent(widget.mediaId);
    final baseId = _extractBaseMediaId(rawId);
    final isEp = _isEpisodeVideoId(rawId, baseId);

    final media = await catalogRepo.resolveMediaDetail(
      mediaId: baseId,
      type: widget.mediaType,
      activeAddons: addons,
    );
    final streams = await catalogRepo.fetchStreamsForMedia(
      media: media,
      activeAddons: addons,
      episodeVideoId: isEp ? rawId : null,
    );

    final history = ref.read(watchHistoryControllerProvider).valueOrNull ??
        const <WatchProgressItem>[];
    final savedEntry = history.where((e) => e.media.id == media.id).firstOrNull;
    if (savedEntry != null && savedEntry.positionSeconds > 0) {
      _position = Duration(seconds: savedEntry.positionSeconds);
      if (savedEntry.durationSeconds > 0) {
        _duration = Duration(seconds: savedEntry.durationSeconds);
      }
    }

    final chosen =
        widget.initialStream ?? (streams.isNotEmpty ? streams.first : null);

    if (!mounted) return;
    setState(() {
      _media = media;
      _streams = streams;
      _activeStream = chosen;
      _isBuffering = chosen != null;
    });

    if (widget.enableNativePlayer && chosen != null) {
      await _setupMediaKit(chosen);
    }
    _scheduleAutoHide();
  }

  Future<void> _setupMediaKit(StreamSource source) async {
    final token = ++_sessionToken;
    _telemetryTimer?.cancel();
    setState(() {
      _isBuffering = true;
      _statusBanner = source.isTorrent
          ? 'Connexion aux pairs et préparation du flux…'
          : 'Ouverture du flux vidéo…';
      _telemetry = const TorrentStreamTelemetry();
    });

    try {
      final settings = ref.read(appSettingsControllerProvider).valueOrNull ??
          const AppSettings();
      _player ??= Player(
        configuration: const PlayerConfiguration(
          title: 'Muvio Player',
          bufferSize: 32 * 1024 * 1024,
        ),
      );
      _videoController ??= VideoController(
        _player!,
        configuration: VideoControllerConfiguration(
          enableHardwareAcceleration:
              settings.decoderMode == VideoDecoderMode.hardware,
        ),
      );

      await _posSub?.cancel();
      await _durSub?.cancel();
      await _playSub?.cancel();
      await _bufSub?.cancel();
      await _errSub?.cancel();

      _posSub = _player!.stream.position.listen((pos) {
        if (mounted && pos.inSeconds > 0) {
          setState(() {
            _position = pos;
            _isBuffering = false;
            _statusBanner = null;
          });
        }
      });
      _durSub = _player!.stream.duration.listen((dur) {
        if (mounted && dur.inSeconds > 0) {
          setState(() => _duration = dur);
        }
      });
      _playSub = _player!.stream.playing.listen((playing) {
        if (mounted) {
          setState(() => _isPlaying = playing);
        }
      });
      _bufSub = _player!.stream.buffering.listen((buffering) {
        if (mounted) {
          setState(() => _isBuffering = buffering);
        }
      });
      _errSub = _player!.stream.error.listen((err) {
        if (mounted && err.trim().isNotEmpty) {
          setState(() {
            _statusBanner = 'Erreur flux : essayez une autre source ci-dessous';
            _isBuffering = false;
          });
        }
      });

      var playableUrl = source.url;
      if (source.isTorrent) {
        final resolved = await _torrentBridge.resolveMagnetOrInfoHash(
          magnetOrUrl: source.url,
          infoHash: source.infoHash,
          fileIdx: source.fileIdx,
          sources: source.sources,
        );
        if (!mounted || token != _sessionToken) return;
        final localUrl = resolved.valueOrNull;
        if (localUrl == null) {
          setState(() {
            _isBuffering = false;
            _statusBanner = 'Impossible de démarrer le moteur torrent.';
          });
          return;
        }
        playableUrl = localUrl;

        // Wait until metadata + initial header pieces are verified BEFORE opening mpv!
        final ready = await _waitUntilTorrentReady(token);
        if (!mounted || token != _sessionToken) return;
        if (!ready) {
          setState(() {
            _isBuffering = false;
            _statusBanner =
                'Trop peu de pairs actifs sur cette source. Choisissez une source 1080p plus populaire.';
          });
          return;
        }

        _telemetryTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
          final snap = await _torrentBridge.pollTelemetry();
          if (mounted && token == _sessionToken) {
            setState(() => _telemetry = snap);
          }
        });
      }

      final headers = <String, String>{
        'User-Agent': 'Mozilla/5.0 (Linux; Android 14; Mobile) '
            'AppleWebKit/537.36 (KHTML, like Gecko) '
            'Chrome/131.0.0.0 Mobile Safari/537.36',
        ...source.httpHeaders,
      };

      await _player!.open(
        Media(playableUrl, httpHeaders: headers),
      );
      if (_position.inSeconds > 5 && !source.isTorrent) {
        await _player!.seek(_position);
      }
      await _player!.setRate(_playbackSpeed);
      if (mounted && token == _sessionToken) {
        setState(() => _statusBanner = null);
      }
    } catch (_) {
      if (mounted && token == _sessionToken) {
        setState(() {
          _isBuffering = false;
        });
      }
    }
  }

  Future<bool> _waitUntilTorrentReady(int token) async {
    final deadline = DateTime.now().add(const Duration(seconds: 40));
    while (mounted && token == _sessionToken && DateTime.now().isBefore(deadline)) {
      final snap = await _torrentBridge.pollTelemetry();
      if (!mounted || token != _sessionToken) return false;

      final speedKb = (snap.downloadSpeedBytesPerSec / 1024).round();
      final msg = !snap.hasMetadata
          ? 'Recherche des pairs (${snap.peers} connectés)…'
          : 'Mise en mémoire tampon (${(snap.bufferedBytes / (1024 * 1024)).toStringAsFixed(1)} Mo · $speedKb Ko/s · ${snap.peers} pairs)…';

      setState(() {
        _telemetry = snap;
        _statusBanner = msg;
      });

      if (snap.readyToPlay) {
        return true;
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    final lastSnap = await _torrentBridge.pollTelemetry();
    return lastSnap.hasMetadata && lastSnap.bufferedBytes > 0;
  }

  void _scheduleAutoHide() {
    _hideControlsTimer?.cancel();
    if (!_isLandscapeMode) return;
    _hideControlsTimer = Timer(AppDurations.controlsAutoHide, () {
      if (mounted && _isPlaying && !_isBuffering) {
        setState(() => _controlsVisible = false);
      }
    });
  }

  void _revealControls() {
    setState(() => _controlsVisible = true);
    _scheduleAutoHide();
  }

  Future<void> _toggleOrientation() async {
    final nextLandscape = !_isLandscapeMode;
    setState(() {
      _isLandscapeMode = nextLandscape;
      _controlsVisible = true;
    });
    if (nextLandscape) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      _scheduleAutoHide();
    } else {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }
  }

  Future<void> _seekRelative(int deltaSeconds) async {
    final targetSec = (_position.inSeconds + deltaSeconds)
        .clamp(0, _duration.inSeconds > 0 ? _duration.inSeconds : 10800);
    final target = Duration(seconds: targetSec);
    setState(() => _position = target);
    await _player?.seek(target);
    _revealControls();
  }

  Future<void> _togglePlayPause() async {
    setState(() => _isPlaying = !_isPlaying);
    await _player?.playOrPause();
    _revealControls();
  }

  Future<void> _switchStream(StreamSource stream) async {
    setState(() {
      _activeStream = stream;
      _position = Duration.zero;
    });
    if (widget.enableNativePlayer) {
      await _setupMediaKit(stream);
    }
  }

  Future<void> _cycleSpeed() async {
    const speeds = <double>[0.5, 1, 1.25, 1.5, 2];
    final idx = speeds.indexOf(_playbackSpeed);
    final next = speeds[(idx + 1) % speeds.length];
    setState(() => _playbackSpeed = next);
    await _player?.setRate(next);
  }

  Future<void> _saveProgressAndExit() async {
    _sessionToken++;
    _telemetryTimer?.cancel();
    final media = _media;
    if (media != null && _activeStream != null && _position.inSeconds > 5) {
      await ref.read(watchHistoryControllerProvider.notifier).saveProgress(
            WatchProgressItem(
              media: media,
              positionSeconds: _position.inSeconds,
              durationSeconds: _duration.inSeconds,
              updatedAt: DateTime.now(),
              episodeBadge: Formatters.formatRemainingShort(
                _duration - _position,
              ),
              lastStreamUrl: _activeStream?.url,
            ),
          );
    }
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    if (mounted) {
      context.pop();
    }
  }

  @override
  void dispose() {
    _sessionToken++;
    _hideControlsTimer?.cancel();
    _telemetryTimer?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _playSub?.cancel();
    _bufSub?.cancel();
    _errSub?.cancel();
    _player?.dispose();
    _torrentBridge.stopAllStreams();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = _media;
    if (media == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.red),
        ),
      );
    }

    return OrientationBuilder(
      builder: (context, orientation) {
        final effectiveLandscape =
            _isLandscapeMode || orientation == Orientation.landscape;

        return Scaffold(
          backgroundColor: Colors.black,
          body: GestureDetector(
            onTap: _revealControls,
            onDoubleTapDown: (details) {
              if (_controlsLocked) return;
              final width = MediaQuery.sizeOf(context).width;
              if (details.localPosition.dx < width / 2) {
                _seekRelative(-10);
              } else {
                _seekRelative(10);
              }
            },
            onVerticalDragUpdate: (details) {
              if (_controlsLocked) return;
              final size = MediaQuery.sizeOf(context);
              final delta = -(details.primaryDelta ?? 0) / size.height;
              if (details.localPosition.dx < size.width / 2) {
                setState(
                  () => _brightnessLevel =
                      (_brightnessLevel + delta).clamp(0.1, 1.0),
                );
              } else {
                final nextVol = (_volumeLevel + delta).clamp(0.0, 1.0);
                setState(() => _volumeLevel = nextVol);
                _player?.setVolume(nextVol * 100);
              }
            },
            onVerticalDragEnd: (details) {
              if ((details.primaryVelocity ?? 0) > 900 && !_controlsLocked) {
                _saveProgressAndExit();
              }
            },
            onScaleUpdate: (details) {
              if (_controlsLocked) return;
              setState(
                () => _zoomScale = details.scale.clamp(1.0, 2.0),
              );
            },
            child: effectiveLandscape
                ? _LandscapeFullscreenView(state: this, media: media)
                : _PortraitPlayerView(state: this, media: media),
          ),
        );
      },
    );
  }
}
