import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/models.dart';
import '../../core/ui/app_colors.dart';
import '../../core/ui/hover_card.dart';

/// Equal-width responsive grid: as many columns as [minItemWidth] allows.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minItemWidth = 240,
    this.gap = 16,
  });

  final List<Widget> children;
  final double minItemWidth;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final fit = ((c.maxWidth + gap) / (minItemWidth + gap)).floor();
        final cols = math.max(1, math.min(fit, children.length));
        final w = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final ch in children) SizedBox(width: w, child: ch),
          ],
        );
      },
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
    this.valueColor,
    this.progress,
  });

  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final Color color; // accent: icon and progress bar
  final Color? valueColor;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return DashCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                    color: context.sc.muted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontSize: 40,
                height: 1.05,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
                color: valueColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12.5, color: context.sc.muted),
          ),
          if (progress != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                color: color,
                backgroundColor: color.withValues(alpha: 0.15),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Elapsed time as "9 sa 17 dk" for a non-negative [d].
String ago(Duration d) {
  if (d.inMinutes < 1) return 'Şimdi';
  if (d.inMinutes < 60) return '${d.inMinutes} dk';
  if (d.inHours < 24) return '${d.inHours} sa ${d.inMinutes % 60} dk';
  return '${d.inDays} gün';
}

/// Share of today's already-due expectations that happened.
({int pct, int due, int done}) routineScore(AppState s) {
  final now = s.now;
  final today = s.eventsOn(now);
  final due = s.rhythm
      .forDay(now)
      .where((e) => !now.isBefore(e.deadlineOn(now)))
      .toList();
  final done = due.where((e) => today.any((ev) => ev.type == e.type)).length;
  final pct = due.isEmpty ? 100 : (done * 100 / due.length).round();
  return (pct: pct, due: due.length, done: done);
}

/// "07:15" today, "23.10 07:15" on another day.
String timeOrDate(DateTime t, DateTime now) =>
    sameDay(t, now) ? hm(t) : '${two(t.day)}.${two(t.month)} ${hm(t)}';
