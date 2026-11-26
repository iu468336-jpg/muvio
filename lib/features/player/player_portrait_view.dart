part of 'player_screen.dart';

class _PortraitPlayerView extends StatelessWidget {
  const _PortraitPlayerView({
    required this.state,
    required this.media,
  });

  final _PlayerScreenState state;
  final MediaItem media;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final activeStream = state._activeStream;

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            flex: 6,
            child: Stack(
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
                          memCacheWidth: 1080,
                        ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xAA000000),
                        Color(0x22000000),
                        Color(0xDD000000),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  right: 12,
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: state._saveProgressAndExit,
                        icon: const Icon(
                          LucideIcons.arrowLeft,
                          color: Colors.white,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              media.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.h2,
                            ),
                            Text(
                              '${media.year} · ${activeStream?.quality ?? 'HD'}',
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                      ),
                      if (activeStream != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.line),
                          ),
                          child: Text(
                            '👤 ${activeStream.seeders} · '
                            '${Formatters.formatBytesFr(activeStream.sizeBytes)}',
                            style: AppTypography.caption.copyWith(fontSize: 11),
                          ),
                        ),
                    ],
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (state._isBuffering && activeStream != null)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.red,
                            ),
                          ),
                        ),
                      _GlassTransportRow(
                        isPlaying: state._isPlaying,
                        onRewind: () => state._seekRelative(-10),
                        onPlayPause: state._togglePlayPause,
                        onForward: () => state._seekRelative(10),
                      ),
                      if (state._statusBanner != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.line),
                          ),
                          child: Text(
                            state._statusBanner!,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                              color: Colors.white,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (state._position.inSeconds < media.introEndSeconds)
                  Positioned(
                    right: 16,
                    bottom: 84,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.black.withValues(alpha: 0.6),
                        side: const BorderSide(color: AppColors.red),
                      ),
                      onPressed: () => state._seekRelative(
                        media.introEndSeconds - state._position.inSeconds,
                      ),
                      child: const Text('Passer l’intro'),
                    ),
                  ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 8,
                  child: Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.red,
                          inactiveTrackColor:
                              Colors.white.withValues(alpha: 0.24),
                          thumbColor: AppColors.red,
                          overlayShape: SliderComponentShape.noOverlay,
                          trackHeight: 4,
                        ),
                        child: Slider(
                          value: state._position.inSeconds
                              .clamp(
                                  0, state._duration.inSeconds.clamp(1, 99999))
                              .toDouble(),
                          max: state._duration.inSeconds
                              .clamp(1, 99999)
                              .toDouble(),
                          onChanged: (v) {
                            final d = Duration(seconds: v.round());
                            state._player?.seek(d);
                            // ignore: invalid_use_of_protected_member
                            state.setState(() => state._position = d);
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: RichText(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                style: AppTypography.caption,
                                children: [
                                  TextSpan(
                                    text: Formatters.formatDurationClock(
                                      state._position,
                                    ),
                                    style: const TextStyle(
                                      color: AppColors.red,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        ' / ${Formatters.formatDurationClock(state._duration)}',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _ControlPillButton(
                            icon: Icons.subtitles_outlined,
                            active: state._subtitlesEnabled,
                            onTap: () {
                              // ignore: invalid_use_of_protected_member
                              state.setState(
                                () => state._subtitlesEnabled =
                                    !state._subtitlesEnabled,
                              );
                            },
                          ),
                          const SizedBox(width: 6),
                          _ControlPillButton(
                            icon: LucideIcons.volume2,
                            onTap: () {},
                          ),
                          const SizedBox(width: 6),
                          _QualityChip(
                            label: '4K',
                            selected: activeStream?.quality == '4K',
                            onTap: () {
                              final s4k = state._streams
                                  .where((s) => s.quality == '4K')
                                  .firstOrNull;
                              if (s4k != null) state._switchStream(s4k);
                            },
                          ),
                          const SizedBox(width: 6),
                          _QualityChip(
                            label: '1080p',
                            selected: activeStream?.quality == '1080p',
                            onTap: () {
                              final s1080 = state._streams
                                  .where((s) => s.quality == '1080p')
                                  .firstOrNull;
                              if (s1080 != null) state._switchStream(s1080);
                            },
                          ),
                          const SizedBox(width: 6),
                          _ControlPillButton(
                            icon: LucideIcons.maximize,
                            onTap: state._toggleOrientation,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Container(
              margin: const EdgeInsets.all(14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.line,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.selectSourceTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.h2,
                            ),
                            Text(
                              l10n.selectSourceSubtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: state._toggleOrientation,
                        icon: const Icon(
                          LucideIcons.smartphone,
                          color: AppColors.red,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: state._streams.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Aucune source active pour ce titre.',
                                  style: AppTypography.bodyMedium,
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Activez Torrentio, Pipe, Peerflix ou Pluto TV dans Addons.',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.caption,
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: state._streams.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                        final s = state._streams[index];
                        final selected = s.id == activeStream?.id;
                        return InkWell(
                          onTap: () => state._switchStream(s),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface2,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color:
                                    selected ? AppColors.red : AppColors.line,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? AppColors.red
                                        : AppColors.redDeep,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    LucideIcons.radio,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: AppTypography.bodyMedium,
                                      children: [
                                        TextSpan(text: '${s.addonName} · '),
                                        TextSpan(
                                          text: '${s.quality} ${s.hdrMode}',
                                          style: TextStyle(
                                            color: s.quality == '4K'
                                                ? AppColors.red
                                                : AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: const BoxDecoration(
                                    color: AppColors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
