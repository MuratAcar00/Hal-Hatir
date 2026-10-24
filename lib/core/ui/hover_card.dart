import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Lifts its child a little on mouse hover (web). [shadow] deepens the shadow.
class HoverLift extends StatefulWidget {
  const HoverLift({
    super.key,
    required this.child,
    this.radius = 16,
    this.shadow = true,
    this.restShadow = 0.03,
    this.onTap,
  });

  final Widget child;
  final double radius;
  final bool shadow;
  final double restShadow;
  final VoidCallback? onTap;

  @override
  State<HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<HoverLift> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _hover ? -4 : 0, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            boxShadow: widget.shadow
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: _hover ? 0.18 : widget.restShadow),
                      blurRadius: _hover ? 26 : 8,
                      offset: Offset(0, _hover ? 12 : 3),
                    ),
                  ]
                : null,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Dashboard card: bordered surface with hover lift.
class DashCard extends StatelessWidget {
  const DashCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color,
    this.restShadow = 0.03,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double restShadow;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return HoverLift(
      restShadow: restShadow,
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color ?? Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border(Theme.of(context).brightness)),
        ),
        child: child,
      ),
    );
  }
}

/// Gives an existing [Card] based widget the same hover lift (no margin).
class LiftedCard extends StatelessWidget {
  const LiftedCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        cardTheme: theme.cardTheme.copyWith(
          margin: EdgeInsets.zero,
          elevation: 0,
        ),
      ),
      child: HoverLift(child: child),
    );
  }
}
