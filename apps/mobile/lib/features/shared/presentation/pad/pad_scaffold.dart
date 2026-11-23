import 'package:flutter/material.dart';

import '../../../navigation/presentation/floating_bottom_nav.dart';
import '../../../navigation/presentation/navigation_destination.dart';
import '../continue_learning_button.dart';
import 'app_design_tokens.dart';
import 'pad_sidebar.dart';

class PadScaffold extends StatelessWidget {
  const PadScaffold({
    required this.currentDestination,
    required this.body,
    super.key,
    this.topBar,
    this.bottomBar,
    this.useBottomTabWhenPortrait = true,
    this.showNavigation = true,
    this.showContinueLearning = true,
    this.backgroundColor,
  });

  final AppNavDestination currentDestination;
  final Widget body;
  final Widget? topBar;

  /// Optional fixed bar under [body] (e.g. reading progress). When navigation
  /// tabs are shown, this replaces the floating tab bar.
  final Widget? bottomBar;
  final bool useBottomTabWhenPortrait;
  final bool showNavigation;
  final bool showContinueLearning;

  /// When set, replaces the default soft-white / dark canvas (e.g. Jingway cream).
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    final bool isPortrait = size.height > size.width;
    final bool useBottomNavigation = size.width < 840 || isPortrait;
    final Color canvas = backgroundColor ?? AppDesignTokens.softWhite;
    final Widget content = _PadBackdrop(
      backgroundColor: backgroundColor,
      child: Column(
        children: <Widget>[
          if (topBar != null) topBar!,
          Expanded(child: body),
        ],
      ),
    );

    if (showNavigation && useBottomNavigation && useBottomTabWhenPortrait) {
      return Scaffold(
        backgroundColor: canvas,
        floatingActionButton: showContinueLearning
            ? const ContinueLearningButton()
            : null,
        body: SafeArea(top: false, bottom: false, child: content),
        bottomNavigationBar: bottomBar ??
            SafeArea(
              top: false,
              child: FloatingBottomNav(current: currentDestination),
            ),
      );
    }

    return Scaffold(
      backgroundColor: canvas,
      floatingActionButton: showContinueLearning
          ? const ContinueLearningButton()
          : null,
      bottomNavigationBar: bottomBar,
      body: SafeArea(
        top: false,
        child: Row(
          children: <Widget>[
            if (showNavigation) PadSidebar(current: currentDestination),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }
}

class _PadBackdrop extends StatelessWidget {
  const _PadBackdrop({required this.child, this.backgroundColor});

  final Widget child;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.sizeOf(context).width < 840;
    final bool solidCanvas = backgroundColor != null;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: solidCanvas ? backgroundColor : null,
        gradient: solidCanvas
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  AppDesignTokens.isDark
                      ? const Color(0xFF16181E)
                      : const Color(0xFFF7F8FB),
                  AppDesignTokens.isDark
                      ? const Color(0xFF12141A)
                      : const Color(0xFFF0F2F6),
                  AppDesignTokens.softWhite,
                ],
              ),
      ),
      child: Stack(
        children: <Widget>[
          if (!compact && !solidCanvas) ...<Widget>[
            Positioned(
              left: -36,
              top: 88,
              child: _BackdropBubble(
                size: 160,
                color: AppDesignTokens.skyLight.withValues(alpha: 0.72),
              ),
            ),
            Positioned(
              right: 36,
              top: 112,
              child: _BackdropBubble(
                size: 92,
                color: AppDesignTokens.pinkLight.withValues(alpha: 0.6),
              ),
            ),
            Positioned(
              right: -18,
              bottom: 42,
              child: _BackdropBubble(
                size: 144,
                color: AppDesignTokens.purpleLight.withValues(alpha: 0.42),
              ),
            ),
          ],
          child,
        ],
      ),
    );
  }
}

class _BackdropBubble extends StatelessWidget {
  const _BackdropBubble({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
