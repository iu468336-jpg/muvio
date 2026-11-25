part of 'player_screen.dart';

class _LandscapeFullscreenView extends StatelessWidget {
  const _LandscapeFullscreenView({
    required this.state,
    required this.media,
  });

  final _PlayerScreenState state;
  final MediaItem media;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final activeStream = state._activeStream;

    return Stack(
      fit: StackFit.expand,
      children: [
        Transform.scale(
          scale: state._zoomScale,
          child: state._videoController != null
              ? Video(
                  controller: state._videoController!,
                  controls: null,
                )
              : MuvioImage(
                  imageUrl: media.backdrop ?? media.poster,
                  memCacheWidth: 1400,
                ),
        ),
        if (state._controlsVisible) ...[
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xAA000000),
                  Color(0x18000000),
                  Color(0xCC000000),
                ],
              ),
            ),
          ),
          Positioned(
            top: 14,
            left: 16,
            right: 16,
            child: Row(
              children: [
                IconButton(
                  onPressed: state._saveProgressAndExit,
                  icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      media.title.toUpperCase(),
                      style: AppTypography.h2.copyWith(letterSpacing: 3),
                    ),
                    Row(
                      children: [
                        Text(
                          'S1 · E4 · ${activeStream?.quality ?? '4K'} ${activeStream?.hdrMode ?? 'HDR'}  ',
                          style: AppTypography.caption,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.redDeep.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '● LIVE',
                            style: AppTypography.micro.copyWith(
                              fontSize: 9.5,
                              letterSpacing: 0.6,
                              color: AppColors.redGlow,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    state.ref
                        .read(torrentEngineBridgeProvider)
                        .enterPictureInPicture();
                  },
                  icon: const Icon(LucideIcons.cast, color: Colors.white),
                ),
                InkWell(
                  onTap: () {
                    // ignore: invalid_use_of_protected_member
                    state.setState(
                      () => state._showSourcesOverlay =
                          !state._showSourcesOverlay,
                    );
                  },
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.box,
                          color: AppColors.success,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${activeStream?.addonName ?? 'Torrentio'} · ${activeStream?.quality ?? '4K'}',
                          style: AppTypography.caption.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          LucideIcons.chevronDown,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  onPressed: state._cycleSpeed,
                  icon: const Icon(LucideIcons.settings, color: Colors.white),
                ),
              ],
            ),
          ),
          if (!state._controlsLocked)
            Center(
              child: _GlassTransportRow(
                isPlaying: state._isPlaying,
                onRewind: () => state._seekRelative(-10),
                onPlayPause: state._togglePlayPause,
                onForward: () => state._seekRelative(10),
              ),
            ),
          if (state._showSourcesOverlay && !state._controlsLocked)
            Positioned(
              right: 20,
              bottom: 92,
              width: 268,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bg.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.sourcesCount(state._streams.length),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyMedium.copyWith(
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const Icon(
                          LucideIcons.chevronRight,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    for (final s in state._streams.take(3))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () => state._switchStream(s),
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.layers,
                                color: AppColors.success,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.addonName,
                                      style: AppTypography.caption.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      '${s.quality} · ${s.hdrMode} · ${Formatters.formatBytesFr(s.sizeBytes)}',
                                      style: AppTypography.caption.copyWith(
                                        fontSize: 10.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  color: AppColors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 12,
            child: Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.red,
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.25),
                    thumbColor: AppColors.red,
                    overlayShape: SliderComponentShape.noOverlay,
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: state._position.inSeconds
                        .clamp(0, state._duration.inSeconds.clamp(1, 99999))
                        .toDouble(),
                    max: state._duration.inSeconds.clamp(1, 99999).toDouble(),
                    onChanged: state._controlsLocked
                        ? null
                        : (v) {
                            final d = Duration(seconds: v.round());
                            state._player?.seek(d);
                            // ignore: invalid_use_of_protected_member
                            state.setState(() => state._position = d);
                          },
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '${Formatters.formatDurationClock(state._position)} / '
                      '${Formatters.formatDurationClock(state._duration)}',
                      style:
                          AppTypography.caption.copyWith(color: Colors.white),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        // ignore: invalid_use_of_protected_member
                        state.setState(
                          () => state._subtitlesEnabled =
                              !state._subtitlesEnabled,
                        );
                      },
                      icon: Icon(
                        Icons.closed_caption_off_outlined,
                        color: state._subtitlesEnabled
                            ? AppColors.red
                            : Colors.white,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        // ignore: invalid_use_of_protected_member
                        state.setState(
                          () => state._selectedAudioLabel =
                              state._selectedAudioLabel == 'English'
                                  ? 'Français'
                                  : 'English',
                        );
                      },
                      icon: const Icon(
                        LucideIcons.volume2,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: Text(
                        state._selectedAudioLabel,
                        style: AppTypography.caption.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    _QualityChip(
                      label: activeStream?.quality ?? '4K',
                      selected: true,
                      onTap: () {},
                    ),
                    TextButton(
                      onPressed: state._cycleSpeed,
                      child: Text(
                        '${state._playbackSpeed}x',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        // ignore: invalid_use_of_protected_member
                        state.setState(
                          () => state._controlsLocked = !state._controlsLocked,
                        );
                      },
                      icon: Icon(
                        state._controlsLocked
                            ? LucideIcons.lock
                            : LucideIcons.unlock,
                        color: state._controlsLocked
                            ? AppColors.red
                            : Colors.white,
                        size: 19,
                      ),
                    ),
                    IconButton(
                      onPressed: state._toggleOrientation,
                      icon: const Icon(
                        LucideIcons.smartphone,
                        color: AppColors.red,
                        size: 19,
                      ),
                    ),
                    IconButton(
                      onPressed: state._toggleOrientation,
                      icon: const Icon(
                        LucideIcons.maximize2,
                        color: Colors.white,
                        size: 19,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
