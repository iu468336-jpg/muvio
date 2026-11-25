import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:muvio/core/theme/app_colors.dart';
import 'package:muvio/core/theme/app_spacing.dart';
import 'package:muvio/core/theme/app_typography.dart';
import 'package:muvio/l10n/app_localizations.dart';

/// Standardized 5-tab blurred bottom navigation bar (64px + safe area)
/// consistent across all main screens per section 3.4 of the spec:
/// 1. Accueil | 2. Recherche | 3. Addons | 4. Bibliothèque | 5. Profil
class MuvioBottomShell extends StatelessWidget {
  const MuvioBottomShell({
    required this.currentIndex,
    required this.onSelectTab,
    required this.child,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onSelectTab;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = <_NavSpec>[
      _NavSpec(icon: LucideIcons.home, label: l10n.navHome),
      _NavSpec(icon: LucideIcons.search, label: l10n.navSearch),
      _NavSpec(icon: LucideIcons.puzzle, label: l10n.navAddons),
      _NavSpec(icon: LucideIcons.library, label: l10n.navLibrary),
      _NavSpec(icon: LucideIcons.user, label: l10n.navProfile),
    ];

    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.bg.withValues(alpha: 0.90),
              border: const Border(
                top: BorderSide(color: AppColors.line),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: AppSpacing.bottomNavHeight,
                child: Row(
                  children: List.generate(items.length, (index) {
                    final spec = items[index];
                    final active = index == currentIndex;
                    final color = active ? AppColors.red : AppColors.textMuted;

                    return Expanded(
                      child: Semantics(
                        button: true,
                        selected: active,
                        label: spec.label,
                        child: InkWell(
                          onTap: () => onSelectTab(index),
                          child: SizedBox(
                            height: AppSpacing.bottomNavHeight,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(spec.icon, size: 22, color: color),
                                const SizedBox(height: 4),
                                Text(
                                  spec.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.caption.copyWith(
                                    fontSize: 11,
                                    fontWeight: active
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavSpec {
  const _NavSpec({required this.icon, required this.label});

  final IconData icon;
  final String label;
}
