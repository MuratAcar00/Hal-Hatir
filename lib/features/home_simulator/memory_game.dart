import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/ui/app_colors.dart';

/// 6-pair card matching game. Pops with the score (40-100), or null if closed.
class MemoryGameDialog extends StatefulWidget {
  const MemoryGameDialog({super.key});

  @override
  State<MemoryGameDialog> createState() => _MemoryGameDialogState();
}

class _MemoryGameDialogState extends State<MemoryGameDialog> {
  static const _icons = [
    Icons.wb_sunny,
    Icons.local_florist,
    Icons.pets,
    Icons.coffee,
    Icons.music_note,
    Icons.directions_bike,
  ];

  late final List<int> _cards = [
    for (var i = 0; i < _icons.length; i++) ...[i, i],
  ]..shuffle();
  final Set<int> _matched = {};
  int? _first;
  int? _second;
  bool _lock = false;
  int _moves = 0;
  Timer? _timer;

  bool get _done => _matched.length == _cards.length;

  // 6 moves is perfect; each extra move costs 6 points.
  int get _score => (100 - (_moves - _icons.length) * 6).clamp(40, 100).toInt();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tap(int i) {
    if (_lock || _matched.contains(i) || i == _first) return;
    setState(() {
      if (_first == null) {
        _first = i;
        return;
      }
      _second = i;
      _moves++;
      if (_cards[_first!] == _cards[i]) {
        _matched
          ..add(_first!)
          ..add(i);
        _first = null;
        _second = null;
      } else {
        _lock = true;
        _timer = Timer(const Duration(milliseconds: 750), () {
          if (!mounted) return;
          setState(() {
            _first = null;
            _second = null;
            _lock = false;
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sc = context.sc;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.psychology, color: sc.primary),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Hafıza Oyunu',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    'Hamle: $_moves',
                    style: TextStyle(fontSize: 13, color: sc.muted),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Eşleşen kartları bulun.',
                style: TextStyle(fontSize: 13, color: sc.muted),
              ),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: [
                  for (var i = 0; i < _cards.length; i++)
                    _CardTile(
                      icon: _icons[_cards[i]],
                      faceUp:
                          _matched.contains(i) || i == _first || i == _second,
                      matched: _matched.contains(i),
                      onTap: () => _tap(i),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              if (_done) ...[
                Text(
                  'Tamamlandı: skor %$_score, $_moves hamle',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Kapat'),
                  ),
                  if (_done) ...[
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(_score),
                      child: const Text('Sonucu Kaydet'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({
    required this.icon,
    required this.faceUp,
    required this.matched,
    required this.onTap,
  });

  final IconData icon;
  final bool faceUp;
  final bool matched;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sc = context.sc;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: matched
              ? sc.primary.withValues(alpha: 0.18)
              : faceUp
              ? Theme.of(context).colorScheme.surface
              : sc.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: sc.primary.withValues(alpha: faceUp ? 0.6 : 0.25),
          ),
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: faceUp
                ? Icon(icon, key: const ValueKey('up'), size: 30, color: sc.primary)
                : Icon(
                    Icons.help_outline,
                    key: const ValueKey('down'),
                    size: 24,
                    color: sc.primary.withValues(alpha: 0.5),
                  ),
          ),
        ),
      ),
    );
  }
}
