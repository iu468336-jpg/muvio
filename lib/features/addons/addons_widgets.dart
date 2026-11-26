part of 'addons_screen.dart';

class _AddonsTabBar extends StatelessWidget {
  const _AddonsTabBar({
    required this.selected,
    required this.stremioLabel,
    required this.nuvioLabel,
    required this.onChanged,
  });

  final AddonKind selected;
  final String stremioLabel;
  final String nuvioLabel;
  final ValueChanged<AddonKind> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              label: stremioLabel,
              active: selected == AddonKind.stremio,
              onTap: () => onChanged(AddonKind.stremio),
            ),
          ),
          Expanded(
            child: _TabButton(
              label: nuvioLabel,
              active: selected == AddonKind.nuvio,
              onTap: () => onChanged(AddonKind.nuvio),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? AppColors.red : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodyMedium.copyWith(
            color: active ? AppColors.red : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _AddByUrlCard extends StatelessWidget {
  const _AddByUrlCard({
    required this.controller,
    required this.focusNode,
    required this.loading,
    required this.onPaste,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool loading;
  final VoidCallback onPaste;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.line),
                ),
                child: const Icon(
                  LucideIcons.link2,
                  color: AppColors.red,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.addAddonByUrlTitle, style: AppTypography.h2),
                    Text(
                      l10n.addAddonByUrlSubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Coller',
                visualDensity: VisualDensity.compact,
                onPressed: onPaste,
                icon: const Icon(
                  LucideIcons.clipboardPaste,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    style: AppTypography.body.copyWith(fontSize: 12.5),
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => onSubmit(),
                    decoration: InputDecoration(
                      hintText: l10n.addAddonHint,
                      hintStyle: AppTypography.caption,
                      filled: true,
                      fillColor: AppColors.bg,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.line),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.red),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: loading ? null : onSubmit,
                child: loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(l10n.addButton, style: AppTypography.bodyMedium),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddonTileCard extends StatelessWidget {
  const _AddonTileCard({
    required this.addon,
    required this.installing,
    required this.onTap,
    required this.onInstall,
    required this.onToggleEnabled,
  });

  final InstalledAddon addon;
  final bool installing;
  final VoidCallback onTap;
  final VoidCallback onInstall;
  final ValueChanged<bool> onToggleEnabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return RepaintBoundary(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Color(addon.accentColorHex),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  addon.shortBadge,
                  textAlign: TextAlign.center,
                  style: AppTypography.micro.copyWith(
                    letterSpacing: 0.3,
                    fontWeight: FontWeight.w900,
                    fontSize: 10.5,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            addon.manifest.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.h2.copyWith(fontSize: 15),
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (addon.isOffline)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.redDeep.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.red),
                            ),
                            child: Text(
                              l10n.offlineBadge,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.redGlow,
                                fontSize: 10.5,
                              ),
                            ),
                          )
                        else if (addon.installed) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.success.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              l10n.installedBadge,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w700,
                                fontSize: 10.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 2),
                          SizedBox(
                            height: 28,
                            width: 44,
                            child: Transform.scale(
                              scale: 0.82,
                              child: Switch(
                                value: addon.enabled,
                                onChanged: onToggleEnabled,
                              ),
                            ),
                          ),
                        ] else
                          SizedBox(
                            height: 32,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.red,
                                side: const BorderSide(color: AppColors.red),
                                minimumSize: const Size(74, 32),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: installing ? null : onInstall,
                              child: installing
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.red,
                                      ),
                                    )
                                  : Text(
                                      l10n.installButton,
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.red,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(addon.categoryLabel, style: AppTypography.caption),
                    const SizedBox(height: 4),
                    Text(
                      addon.manifest.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body.copyWith(
                        fontSize: 12.2,
                        color: AppColors.text.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
