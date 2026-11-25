import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:muvio/core/errors/result.dart';
import 'package:muvio/core/theme/app_colors.dart';
import 'package:muvio/core/theme/app_spacing.dart';
import 'package:muvio/core/theme/app_typography.dart';
import 'package:muvio/data/models/addon_models.dart';
import 'package:muvio/data/providers/app_providers.dart';
import 'package:muvio/l10n/app_localizations.dart';

part 'addons_widgets.dart';

/// Screen 2 — Addons & Plugins:
/// Header "Addons" + red floating +, underlined tabs (Stremio Addons | Nuvio Plugins),
/// "Ajouter un addon via URL" card with manifest validation & preview,
/// addon cards with green Installé badge / red switch / red Installer outline button,
/// swipe-left to delete, tap to inspect raw manifest & capabilities.
class AddonsScreen extends ConsumerStatefulWidget {
  const AddonsScreen({super.key});

  @override
  ConsumerState<AddonsScreen> createState() => _AddonsScreenState();
}

class _AddonsScreenState extends ConsumerState<AddonsScreen> {
  final TextEditingController _urlController = TextEditingController();
  final FocusNode _urlFocusNode = FocusNode();
  AddonKind _selectedTab = AddonKind.stremio;
  bool _loadingPreview = false;

  @override
  void dispose() {
    _urlController.dispose();
    _urlFocusNode.dispose();
    super.dispose();
  }

  Future<void> _validateAndPreviewUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      _urlFocusNode.requestFocus();
      return;
    }

    setState(() => _loadingPreview = true);
    final res =
        await ref.read(addonsControllerProvider.notifier).previewUrl(url);
    if (!mounted) return;
    setState(() => _loadingPreview = false);

    switch (res) {
      case Success<AddonManifest>(:final value):
        await _showManifestPreviewSheet(url, value);
      case Failure<AddonManifest>(:final failure):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
    }
  }

  Future<void> _showManifestPreviewSheet(
    String rawUrl,
    AddonManifest manifest,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.manifestPreviewTitle, style: AppTypography.h1),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${manifest.name} · v${manifest.version}',
              style: AppTypography.h2.copyWith(color: AppColors.red),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(manifest.description, style: AppTypography.body),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final r in manifest.resources)
                  Chip(
                    backgroundColor: AppColors.surface2,
                    label: Text(r, style: AppTypography.caption),
                  ),
                for (final t in manifest.types)
                  Chip(
                    backgroundColor: AppColors.surface2,
                    label: Text('type:$t', style: AppTypography.caption),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text(l10n.confirmInstall),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );

    if (confirmed ?? false) {
      final installRes = await ref
          .read(addonsControllerProvider.notifier)
          .installManifest(rawUrl: rawUrl, manifest: manifest);
      if (!mounted) return;
      if (installRes.isSuccess) {
        _urlController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.addonInstalledSuccess)),
        );
      }
    }
  }

  void _showAddonDetailDialog(InstalledAddon addon) {
    final prettyJson =
        const JsonEncoder.withIndent('  ').convert(addon.manifest.toJson());
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(addon.manifest.name, style: AppTypography.h1),
                ),
                Chip(
                  backgroundColor: AppColors.surface2,
                  label: Text('v${addon.manifest.version}'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(addon.manifestUrl, style: AppTypography.caption),
            const SizedBox(height: AppSpacing.md),
            Text(addon.manifest.description, style: AppTypography.body),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Ressources: ${addon.manifest.resources.join(', ')}',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Catalogues (${addon.manifest.catalogs.length}): '
              '${addon.manifest.catalogs.map((c) => '${c.name} [${c.type}]').join(', ')}',
              style: AppTypography.caption,
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              child: SelectableText(
                prettyJson,
                style: AppTypography.caption.copyWith(
                  fontFamily: 'monospace',
                  color: AppColors.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final addonsAsync = ref.watch(addonsControllerProvider);

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.sm,
              AppSpacing.screenPadding,
              AppSpacing.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MUVIO',
                      style: AppTypography.logo.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: 4),
                    Text(l10n.addonsTitle, style: AppTypography.display),
                  ],
                ),
                Semantics(
                  button: true,
                  label: l10n.addAddonByUrlTitle,
                  child: InkWell(
                    onTap: _urlFocusNode.requestFocus,
                    borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.plus,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _AddonsTabBar(
            selected: _selectedTab,
            stremioLabel: l10n.stremioAddonsTab,
            nuvioLabel: l10n.nuvioPluginsTab,
            onChanged: (tab) => setState(() => _selectedTab = tab),
          ),
          Expanded(
            child: addonsAsync.when(
              data: (allAddons) {
                final filtered = allAddons
                    .where((a) => a.manifest.kind == _selectedTab)
                    .toList();

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    AppSpacing.lg,
                    AppSpacing.screenPadding,
                    110,
                  ),
                  itemCount: filtered.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _AddByUrlCard(
                          controller: _urlController,
                          focusNode: _urlFocusNode,
                          loading: _loadingPreview,
                          onSubmit: _validateAndPreviewUrl,
                        ),
                      );
                    }

                    final addon = filtered[index - 1];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Dismissible(
                        key: ValueKey('addon_${addon.id}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          decoration: BoxDecoration(
                            color: AppColors.redDeep,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.cardRadius),
                          ),
                          child: const Icon(
                            LucideIcons.trash2,
                            color: Colors.white,
                          ),
                        ),
                        onDismissed: (_) {
                          ref
                              .read(addonsControllerProvider.notifier)
                              .deleteAddon(addon.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.addonDeleted)),
                          );
                        },
                        child: _AddonTileCard(
                          addon: addon,
                          onTap: () => _showAddonDetailDialog(addon),
                          onInstall: () => ref
                              .read(addonsControllerProvider.notifier)
                              .toggleInstallProposed(addon),
                          onToggleEnabled: (enabled) => ref
                              .read(addonsControllerProvider.notifier)
                              .toggleEnabled(addon, enabled: enabled),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.red),
              ),
              error: (err, _) => Center(
                child: Text('$err', style: AppTypography.body),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
