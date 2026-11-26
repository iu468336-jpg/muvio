import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
/// "Ajouter un addon via URL" card with paste helper, manifest validation & preview,
/// real Nuvio/Stremio base addons (Cinemeta + OpenSubtitles v3 installed, community directory),
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
  String? _installingAddonId;

  @override
  void dispose() {
    _urlController.dispose();
    _urlFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isNotEmpty) {
      setState(() => _urlController.text = text);
    }
  }

  Future<void> _validateAndPreviewUrl() async {
    var url = _urlController.text.trim();
    if (url.isEmpty) {
      final clip = await Clipboard.getData(Clipboard.kTextPlain);
      final clipText = clip?.text?.trim() ?? '';
      if (clipText.startsWith('http') || clipText.startsWith('stremio://')) {
        url = clipText;
        _urlController.text = clipText;
      } else {
        _urlFocusNode.requestFocus();
        return;
      }
    }

    FocusScope.of(context).unfocus();
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

  Future<void> _installProposed(InstalledAddon addon) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _installingAddonId = addon.id);
    final res = await ref
        .read(addonsControllerProvider.notifier)
        .toggleInstallProposed(addon);
    if (!mounted) return;
    setState(() => _installingAddonId = null);
    if (res.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${addon.manifest.name} — ${l10n.addonInstalledSuccess}',
          ),
        ),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
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
              Text(
                manifest.description,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body,
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final r in manifest.resources)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      backgroundColor: AppColors.surface2,
                      label: Text(r, style: AppTypography.caption),
                    ),
                  for (final t in manifest.types)
                    Chip(
                      visualDensity: VisualDensity.compact,
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
                      child: Text(
                        l10n.confirmInstall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed ?? false) {
      final installRes = await ref
          .read(addonsControllerProvider.notifier)
          .installManifest(rawUrl: rawUrl, manifest: manifest);
      if (!mounted) return;
      switch (installRes) {
        case Success<InstalledAddon>(:final value):
          _urlController.clear();
          setState(() => _selectedTab = value.manifest.kind);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.addonInstalledSuccess)),
          );
        case Failure<InstalledAddon>(:final failure):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failure.message)),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            Text(
              '${addon.manifest.name} · v${addon.manifest.version}',
              style: AppTypography.h1,
            ),
            const SizedBox(height: AppSpacing.xs),
            SelectableText(addon.manifestUrl, style: AppTypography.caption),
            const SizedBox(height: AppSpacing.sm),
            Text(addon.manifest.description, style: AppTypography.body),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Ressources: ${addon.manifest.resources.join(', ')}',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(10),
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
              AppSpacing.xs,
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
                      style: AppTypography.logo.copyWith(fontSize: 17),
                    ),
                    Text(l10n.addonsTitle, style: AppTypography.display),
                  ],
                ),
                InkWell(
                  onTap: _urlFocusNode.requestFocus,
                  borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.plus,
                      color: Colors.white,
                      size: 20,
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
                    AppSpacing.md,
                    AppSpacing.screenPadding,
                    92,
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
                          onPaste: _pasteFromClipboard,
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
                          padding: const EdgeInsets.only(right: 20),
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
                          installing: _installingAddonId == addon.id,
                          onTap: () => _showAddonDetailDialog(addon),
                          onInstall: () => _installProposed(addon),
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
