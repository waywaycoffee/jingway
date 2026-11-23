import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../flavors/app_flavor.dart';
import '../../jingway/presentation/jingway_colors.dart';
import '../../shared/presentation/pad/app_design_tokens.dart';
import 'navigation_destination.dart';

/// Bottom-nav chrome: Jingway uses rice-paper / terracotta; AE keeps green toys.
class _NavChrome {
  const _NavChrome({
    required this.pill,
    required this.selectedFill,
    required this.selectedIconBg,
    required this.selectedIcon,
    required this.selectedLabel,
    required this.idleIcon,
    required this.idleLabel,
    required this.selectedShadow,
  });

  final Color pill;
  final Color selectedFill;
  final Color selectedIconBg;
  final Color selectedIcon;
  final Color selectedLabel;
  final Color idleIcon;
  final Color idleLabel;
  final List<BoxShadow> selectedShadow;

  static _NavChrome of() {
    if (FlavorConfig.isJingwayProduct) {
      return const _NavChrome(
        pill: Color(0xF0F8F0DA),
        selectedFill: JingwayColors.accent,
        selectedIconBg: JingwayColors.surface,
        selectedIcon: JingwayColors.accentStrong,
        selectedLabel: Color(0xFFFFF8F0),
        idleIcon: JingwayColors.hint,
        idleLabel: JingwayColors.hint,
        selectedShadow: <BoxShadow>[
          BoxShadow(
            color: JingwayColors.accentStrong,
            offset: Offset(0, 4),
          ),
        ],
      );
    }
    return _NavChrome(
      pill: AppDesignTokens.appWhite.withValues(alpha: 0.94),
      selectedFill: AppDesignTokens.brandGreen,
      selectedIconBg: AppDesignTokens.onAccent,
      selectedIcon: AppDesignTokens.brandGreenDark,
      selectedLabel: AppDesignTokens.onAccent,
      idleIcon: AppDesignTokens.textSecondary,
      idleLabel: AppDesignTokens.textSecondary,
      selectedShadow: AppDesignTokens.toyButtonShadow,
    );
  }
}

class FloatingBottomNav extends StatelessWidget {
  const FloatingBottomNav({required this.current, super.key});

  final AppNavDestination current;

  /// 景行语文考试向底栏：备考首页 / 诗文 / 复习 / 专项 / 我的
  static const List<AppNavDestination> _jingwayPrimaryDestinations =
      <AppNavDestination>[
        AppNavDestination.home,
        AppNavDestination.reading,
        AppNavDestination.review,
        AppNavDestination.exam,
        AppNavDestination.settings,
      ];

  /// AcquireEnglish 底栏（保留英语主路径）
  static const List<AppNavDestination> _aePrimaryDestinations =
      <AppNavDestination>[
        AppNavDestination.home,
        AppNavDestination.reading,
        AppNavDestination.review,
        AppNavDestination.exam,
        AppNavDestination.settings,
      ];

  static List<AppNavDestination> get _primaryDestinations =>
      FlavorConfig.isJingwayProduct
      ? _jingwayPrimaryDestinations
      : _aePrimaryDestinations;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    final double width = size.width;
    final bool compact = width < 768;
    final bool portrait = size.height > size.width;
    final List<AppNavDestination> allDestinations = AppNavDestination.values
        .where((AppNavDestination destination) => destination.isVisibleForCurrentProduct)
        .toList(growable: false);
    final List<AppNavDestination> destinations = allDestinations
        .where((AppNavDestination destination) => destination.showInBottomNav)
        .toList(growable: false);
    final List<AppNavDestination> primary = _primaryDestinations
        .where((AppNavDestination destination) => destination.isVisibleForCurrentProduct)
        .toList(growable: false);
    final List<AppNavDestination> secondaryDestinations = allDestinations
        .where(
          (AppNavDestination destination) => !primary.contains(destination),
        )
        .toList(growable: false);
    final bool useMoreMenu =
        portrait && secondaryDestinations.isNotEmpty;
    final List<AppNavDestination> visibleDestinations = useMoreMenu
        ? primary
        : destinations;

    final _NavChrome chrome = _NavChrome.of();
    // Keep the floating pill compact. System inset is owned by Scaffold /
    // SafeArea around the page body — padding here was the ~74px overflow.
    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 10 : 16,
        compact ? 6 : 10,
        compact ? 10 : 16,
        compact ? 8 : 12,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(compact ? 22 : 28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: chrome.pill,
              borderRadius: BorderRadius.circular(compact ? 22 : 28),
              border: FlavorConfig.isJingwayProduct
                  ? Border.all(color: JingwayColors.chipBorder)
                  : null,
              boxShadow: FlavorConfig.isJingwayProduct
                  ? const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x1A7C2D12),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ]
                  : AppDesignTokens.toyCardShadow,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 2 : 6,
                vertical: compact ? 4 : 6,
              ),
              child: Row(
                children: <Widget>[
                  ...visibleDestinations.map<Widget>(
                    (AppNavDestination destination) => Expanded(
                      child: _NavItem(
                        destination: destination,
                        selected: destination == current,
                        chrome: chrome,
                      ),
                    ),
                  ),
                  if (useMoreMenu)
                    Expanded(
                      child: _MoreNavItem(
                        selected: secondaryDestinations.contains(current),
                        destinations: secondaryDestinations,
                        chrome: chrome,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MoreNavItem extends StatelessWidget {
  const _MoreNavItem({
    required this.selected,
    required this.destinations,
    required this.chrome,
  });

  final bool selected;
  final List<AppNavDestination> destinations;
  final _NavChrome chrome;

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.sizeOf(context).width < 768;
    return InkWell(
      key: const Key('bottom-nav-more'),
      borderRadius: BorderRadius.circular(compact ? 16 : 20),
      onTap: () => _showMoreMenu(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 2 : 4,
          vertical: compact ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: selected ? chrome.selectedFill : Colors.transparent,
          borderRadius: BorderRadius.circular(compact ? 16 : 20),
          boxShadow: selected ? chrome.selectedShadow : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: compact ? 28 : 32,
              height: compact ? 28 : 32,
              child: selected
                  ? DecoratedBox(
                      decoration: BoxDecoration(
                        color: chrome.selectedIconBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.grid_view_rounded,
                        size: compact ? 17 : 19,
                        color: chrome.selectedIcon,
                      ),
                    )
                  : Icon(
                      Icons.grid_view_outlined,
                      size: compact ? 17 : 19,
                      color: chrome.idleIcon,
                    ),
            ),
            SizedBox(height: compact ? 2 : 3),
            Text(
              '更多',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? chrome.selectedLabel : chrome.idleLabel,
                fontSize: compact ? 10 : 11,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMoreMenu(BuildContext context) async {
    final bool jingway = FlavorConfig.isJingwayProduct;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: jingway ? JingwayColors.surface : null,
      builder: (BuildContext sheetContext) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '更多功能',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: jingway ? JingwayColors.title : null,
                ),
              ),
              const SizedBox(height: 12),
              ...destinations.map(
                (AppNavDestination destination) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  iconColor: jingway ? JingwayColors.accent : null,
                  textColor: jingway ? JingwayColors.body : null,
                  leading: Icon(destination.icon),
                  title: Text(destination.label),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    context.go(destination.route);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.chrome,
  });

  final AppNavDestination destination;
  final bool selected;
  final _NavChrome chrome;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final bool compact = width < 768;

    return InkWell(
      borderRadius: BorderRadius.circular(compact ? 16 : 20),
      onTap: () => context.go(destination.route),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 2 : 4,
          vertical: compact ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: selected ? chrome.selectedFill : Colors.transparent,
          borderRadius: BorderRadius.circular(compact ? 16 : 20),
          boxShadow: selected ? chrome.selectedShadow : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: compact ? 28 : 32,
              height: compact ? 28 : 32,
              child: selected
                  ? DecoratedBox(
                      decoration: BoxDecoration(
                        color: chrome.selectedIconBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        destination.activeIcon,
                        size: compact ? 17 : 19,
                        color: chrome.selectedIcon,
                      ),
                    )
                  : Icon(
                      destination.icon,
                      size: compact ? 17 : 19,
                      color: chrome.idleIcon,
                    ),
            ),
            SizedBox(height: compact ? 2 : 3),
            Text(
              destination.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? chrome.selectedLabel : chrome.idleLabel,
                fontSize: compact ? 10 : 11,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
