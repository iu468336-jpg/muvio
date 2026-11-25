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
        padding: const EdgeInsets.symmetric(vertical: 12),
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
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool loading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line),
            ),
            child: const Icon(LucideIcons.link2, color: AppColors.red),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.addAddonByUrlTitle, style: AppTypography.h2),
                const SizedBox(height: 2),
                Text(l10n.addAddonByUrlSubtitle, style: AppTypography.caption),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: TextField(
                          controller: controller,
                          focusNode: focusNode,
                          style: AppTypography.body.copyWith(fontSize: 13),
                          keyboardType: TextInputType.url,
                          onSubmitted: (_) => onSubmit(),
                          decoration: InputDecoration(
                            hintText: l10n.addAddonHint,
                            hintStyle: AppTypography.caption,
                            filled: true,
                            fillColor: AppColors.bg,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: AppColors.line),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: AppColors.red),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 42,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.red,
                          foregroundColor: Colors.white,
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
                            : Text(l10n.addButton),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddonTileCard extends StatelessWidget {
  const _AddonTileCard({
    required this.addon,
    required this.onTap,
    required this.onInstall,
    required this.onToggleEnabled,
  });

  final InstalledAddon addon;
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
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Color(addon.accentColorHex),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  addon.shortBadge,
                  textAlign: TextAlign.center,
                  style: AppTypography.micro.copyWith(
                    letterSpacing: 0.4,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
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
                            style: AppTypography.h2.copyWith(fontSize: 16.5),
                          ),
                        ),
                        if (addon.isOffline)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
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
                              ),
                            ),
                          )
                        else if (addon.installed) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.success.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              l10n.installedBadge,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          SizedBox(
                            height: 28,
                            child: Switch(
                              value: addon.enabled,
                              onChanged: onToggleEnabled,
                            ),
                          ),
                        ] else
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.red,
                              side: const BorderSide(color: AppColors.red),
                              minimumSize: const Size(86, 34),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: onInstall,
                            child: Text(l10n.installButton),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(addon.categoryLabel, style: AppTypography.caption),
                    const SizedBox(height: 6),
                    Text(
                      addon.manifest.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body.copyWith(
                        fontSize: 13,
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
