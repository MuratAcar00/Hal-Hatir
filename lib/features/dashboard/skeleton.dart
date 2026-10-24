import 'dart:async';

import 'package:flutter/material.dart';

/// Shows pulsing placeholders for a moment, then fades [child] in.
class SkeletonGate extends StatefulWidget {
  const SkeletonGate({
    super.key,
    required this.child,
    this.delay = const Duration(milliseconds: 700),
  });

  final Widget child;
  final Duration delay;

  @override
  State<SkeletonGate> createState() => _SkeletonGateState();
}

class _SkeletonGateState extends State<SkeletonGate> {
  Timer? _timer;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay, () {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      layoutBuilder: (current, previous) =>
          Stack(fit: StackFit.expand, children: [...previous, ?current]),
      child: _ready
          ? KeyedSubtree(key: const ValueKey('content'), child: widget.child)
          : const _SkeletonLayout(key: ValueKey('skeleton')),
    );
  }
}

class _SkeletonLayout extends StatefulWidget {
  const _SkeletonLayout({super.key});

  @override
  State<_SkeletonLayout> createState() => _SkeletonLayoutState();
}

class _SkeletonLayoutState extends State<_SkeletonLayout>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = dark ? Colors.white : Colors.black;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final color = base.withValues(alpha: 0.05 + 0.06 * _c.value);
        Widget box(double h) => Container(
          height: h,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
          ),
        );
        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            children: [
              box(130),
              const SizedBox(height: 16),
              Row(
                children: [
                  for (var i = 0; i < 4; i++) ...[
                    if (i > 0) const SizedBox(width: 16),
                    Expanded(child: box(110)),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(flex: 3, child: box(300)),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: box(300)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
