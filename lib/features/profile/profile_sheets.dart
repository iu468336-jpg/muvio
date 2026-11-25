part of 'profile_screen.dart';

Future<void> _showAccountSheet(BuildContext context, WidgetRef ref) async {
  final sec = ref.read(secureStorageProvider);
  final existingTrakt = await sec.getTraktToken() ?? '';
  final existingDebrid = await sec.getDebridApiKey() ?? '';
  if (!context.mounted) return;

  final traktCtrl = TextEditingController(text: existingTrakt);
  final debridCtrl = TextEditingController(text: existingDebrid);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.viewInsetsOf(ctx).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tokens sécurisés (Keystore)', style: AppTypography.h2),
          const SizedBox(height: 12),
          TextField(
            controller: traktCtrl,
            decoration: const InputDecoration(
              labelText: 'Token Trakt.tv (optionnel)',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: debridCtrl,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Clé API Real-Debrid (optionnelle)',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.red),
              onPressed: () async {
                await sec.setTraktToken(traktCtrl.text);
                await sec.setDebridApiKey(debridCtrl.text);
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Enregistrer de façon chiffrée'),
            ),
          ),
        ],
      ),
    ),
  );
  traktCtrl.dispose();
  debridCtrl.dispose();
}

void _showPlaybackSheet(
  BuildContext context,
  WidgetRef ref,
  AppSettings settings,
) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Lecture & Décodeur', style: AppTypography.h2),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final q in DefaultVideoQuality.values)
                ChoiceChip(
                  label: Text(q.name.toUpperCase()),
                  selected: settings.defaultQuality == q,
                  selectedColor: AppColors.red,
                  onSelected: (_) {
                    ref
                        .read(appSettingsControllerProvider.notifier)
                        .updateSettings(
                          settings.copyWith(defaultQuality: q),
                        );
                    Navigator.of(ctx).pop();
                  },
                ),
            ],
          ),
          const SizedBox(height: 14),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Décodage matériel (libmpv HW+)'),
            value: settings.decoderMode == VideoDecoderMode.hardware,
            onChanged: (hw) {
              ref.read(appSettingsControllerProvider.notifier).updateSettings(
                    settings.copyWith(
                      decoderMode: hw
                          ? VideoDecoderMode.hardware
                          : VideoDecoderMode.software,
                    ),
                  );
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    ),
  );
}

void _showLanguageSubtitlesSheet(
  BuildContext context,
  WidgetRef ref,
  AppSettings settings,
) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Langue & Sous-titres', style: AppTypography.h2),
          const SizedBox(height: 12),
          Row(
            children: [
              ChoiceChip(
                label: const Text('Français (FR)'),
                selected: settings.localeCode == 'fr',
                selectedColor: AppColors.red,
                onSelected: (_) {
                  ref
                      .read(appSettingsControllerProvider.notifier)
                      .updateSettings(settings.copyWith(localeCode: 'fr'));
                  Navigator.of(ctx).pop();
                },
              ),
              const SizedBox(width: 10),
              ChoiceChip(
                label: const Text('English (EN)'),
                selected: settings.localeCode == 'en',
                selectedColor: AppColors.red,
                onSelected: (_) {
                  ref
                      .read(appSettingsControllerProvider.notifier)
                      .updateSettings(settings.copyWith(localeCode: 'en'));
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Taille police sous-titres: ${settings.subtitleFontSize.round()} pt',
            style: AppTypography.body,
          ),
          Slider(
            value: settings.subtitleFontSize,
            min: 14,
            max: 28,
            activeColor: AppColors.red,
            onChanged: (val) {
              ref
                  .read(appSettingsControllerProvider.notifier)
                  .updateSettings(settings.copyWith(subtitleFontSize: val));
            },
          ),
        ],
      ),
    ),
  );
}

void _showCacheAndUpdatesSheet(BuildContext context, WidgetRef ref) {
  final l10n = AppLocalizations.of(context);
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.settingsUpdates, style: AppTypography.h2),
          const SizedBox(height: 8),
          Text(l10n.upToDate, style: AppTypography.body),
          const SizedBox(height: 8),
          Text(l10n.privacyNotice, style: AppTypography.caption),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () async {
              await ref.read(dioCacheStoreProvider).clean();
              PaintingBinding.instance.imageCache.clear();
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.cacheCleared)),
                );
              }
            },
            icon: const Icon(LucideIcons.trash2, size: 16),
            label: Text(l10n.clearCache),
          ),
        ],
      ),
    ),
  );
}

void _showAboutDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('MUVIO · v1.0.0', style: AppTypography.h1),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.appTagline, style: AppTypography.bodyMedium),
          const SizedBox(height: 12),
          Text(l10n.legalDisclaimer, style: AppTypography.caption),
          const SizedBox(height: 12),
          Text(l10n.privacyNotice, style: AppTypography.caption),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Fermer'),
        ),
      ],
    ),
  );
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailingText,
    this.trailingHighlight = false,
    this.customTrailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? trailingText;
  final bool trailingHighlight;
  final Widget? customTrailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Icon(icon, color: AppColors.text, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label, style: AppTypography.bodyMedium),
            ),
            if (customTrailing != null) ...[
              customTrailing!,
              const SizedBox(width: 8),
            ] else if (trailingText != null) ...[
              Text(
                trailingText!,
                style: AppTypography.bodyMedium.copyWith(
                  color:
                      trailingHighlight ? AppColors.red : AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 6),
            ],
            const Icon(
              LucideIcons.chevronRight,
              color: AppColors.textMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
