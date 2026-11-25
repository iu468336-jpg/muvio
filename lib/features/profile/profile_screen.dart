import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:muvio/core/network/dio_client.dart';
import 'package:muvio/core/storage/secure_storage_service.dart';
import 'package:muvio/core/theme/app_colors.dart';
import 'package:muvio/core/theme/app_spacing.dart';
import 'package:muvio/core/theme/app_typography.dart';
import 'package:muvio/data/models/addon_models.dart';
import 'package:muvio/data/models/app_settings.dart';
import 'package:muvio/data/providers/app_providers.dart';
import 'package:muvio/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

part 'profile_sheets.dart';

/// Screen 6 — Paramètres & Profil:
/// Round avatar with red ring + "Muvio User" + "</> Open Source" red outline badge,
/// Grouped settings list: Compte, Lecture & Qualité, Sous-titres & Langues,
/// Addons installés (count) + red "Gérer", Thème (red/black circle), Mises à jour, À propos de Muvio,
/// Featured "Muvio est open source" GitHub card + red "Voir sur GitHub" button,
/// Footer "v1.0.0 · Open Source", and all functional settings bottom sheets.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const String githubRepoUrl = 'https://github.com/iu468336-jpg/muvio';

  Future<void> _openGithub() async {
    final uri = Uri.parse(githubRepoUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final addons = ref.watch(addonsControllerProvider).valueOrNull ??
        const <InstalledAddon>[];
    final installedCount = addons.where((a) => a.installed).length;
    final settings = ref.watch(appSettingsControllerProvider).valueOrNull ??
        const AppSettings();

    return SafeArea(
      bottom: false,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.lg,
          AppSpacing.screenPadding,
          110,
        ),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 112,
                  height: 112,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.red, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.red.withValues(alpha: 0.25),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [AppColors.redDeep, AppColors.surface],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'M',
                        style: AppTypography.display.copyWith(fontSize: 42),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(l10n.profileUser, style: AppTypography.h1),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.red),
                  ),
                  child: Text(
                    '</> ${l10n.openSourceBadge}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.red,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              children: [
                _SettingsRow(
                  icon: LucideIcons.user,
                  label: l10n.settingsAccount,
                  onTap: () => _showAccountSheet(context, ref),
                ),
                const Divider(),
                _SettingsRow(
                  icon: LucideIcons.playSquare,
                  label: l10n.settingsPlaybackQuality,
                  trailingText: settings.qualityLabel,
                  onTap: () => _showPlaybackSheet(context, ref, settings),
                ),
                const Divider(),
                _SettingsRow(
                  icon: Icons.closed_caption_off_outlined,
                  label: l10n.settingsSubtitlesLanguages,
                  trailingText: settings.localeCode.toUpperCase(),
                  onTap: () => _showLanguageSubtitlesSheet(
                    context,
                    ref,
                    settings,
                  ),
                ),
                const Divider(),
                _SettingsRow(
                  icon: LucideIcons.puzzle,
                  label: l10n.settingsInstalledAddons(installedCount),
                  trailingText: l10n.manageAction,
                  trailingHighlight: true,
                  onTap: () => context.go('/addons'),
                ),
                const Divider(),
                _SettingsRow(
                  icon: LucideIcons.palette,
                  label: l10n.settingsTheme,
                  customTrailing: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.line),
                      gradient: const LinearGradient(
                        stops: [0.5, 0.5],
                        colors: [AppColors.red, Colors.black],
                      ),
                    ),
                  ),
                  onTap: () {
                    ref
                        .read(appSettingsControllerProvider.notifier)
                        .updateSettings(
                          settings.copyWith(
                            pureAmoledBlack: !settings.pureAmoledBlack,
                          ),
                        );
                  },
                ),
                const Divider(),
                _SettingsRow(
                  icon: LucideIcons.refreshCw,
                  label: l10n.settingsUpdates,
                  onTap: () => _showCacheAndUpdatesSheet(context, ref),
                ),
                const Divider(),
                _SettingsRow(
                  icon: LucideIcons.info,
                  label: l10n.settingsAbout,
                  onTap: () => _showAboutDialog(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              border: Border.all(color: AppColors.red.withValues(alpha: 0.45)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.github,
                        color: Colors.black,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.openSourceCardTitle,
                              style: AppTypography.h2),
                          const SizedBox(height: 4),
                          Text(
                            l10n.openSourceCardBody,
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _openGithub,
                    icon: const Icon(LucideIcons.externalLink, size: 15),
                    label: Text(l10n.viewOnGithub),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Text(l10n.versionFooter, style: AppTypography.caption),
          ),
        ],
      ),
    );
  }
}
