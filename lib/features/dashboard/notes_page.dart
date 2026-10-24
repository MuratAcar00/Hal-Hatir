import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/ui/app_colors.dart';
import '../../core/ui/hover_card.dart';
import 'dashboard_widgets.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key, required this.author});

  /// Shown on new notes ("Aile Üyesi" or "Bakıcı").
  final String author;

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _add(AppState s) {
    final t = _c.text.trim();
    if (t.isEmpty) return;
    s.addNote(t, widget.author);
    _c.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final notes = s.notes.reversed.toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      children: [
        DashCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Yeni not',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _c,
                maxLines: 2,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Hekim, bakıcı veya aile için not yazın',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Not ekle'),
                  onPressed: _c.text.trim().isEmpty ? null : () => _add(s),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (notes.isEmpty)
          Text('Henüz not yok.', style: TextStyle(color: context.sc.muted)),
        for (final n in notes)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DashCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: context.sc.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.sticky_note_2_outlined,
                      size: 20,
                      color: context.sc.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n.text, style: const TextStyle(fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(
                          '${n.author} · ${timeOrDate(n.time, s.now)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.sc.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Notu sil',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => s.deleteNote(n),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
