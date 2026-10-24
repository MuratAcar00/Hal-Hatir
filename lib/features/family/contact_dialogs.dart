import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_state.dart';
import '../../core/ui/app_colors.dart';

/// Call card. Red is used only for the emergency number.
Future<void> showCallDialog(
  BuildContext context, {
  required String name,
  required String phone,
  bool emergency = false,
}) => showDialog<void>(
  context: context,
  builder: (_) => _CallDialog(
    parent: context,
    name: name,
    phone: phone,
    emergency: emergency,
  ),
);

class _CallDialog extends StatelessWidget {
  const _CallDialog({
    required this.parent,
    required this.name,
    required this.phone,
    required this.emergency,
  });

  final BuildContext parent;
  final String name;
  final String phone;
  final bool emergency;

  @override
  Widget build(BuildContext context) {
    final sc = context.sc;
    final accent = emergency ? sc.alert : sc.primary;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: accent.withValues(alpha: 0.14),
                child: Icon(
                  emergency ? Icons.local_hospital : Icons.person,
                  size: 36,
                  color: accent,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                phone.isEmpty
                    ? "Numara eklenmemiş. Ayarlar'dan ekleyin."
                    : phone,
                style: TextStyle(fontSize: 15, color: sc.muted),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.call),
                  label: const Text('Telefonla ara'),
                  onPressed: phone.isEmpty
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final nav = Navigator.of(context);
                          final ok = await launchUrl(
                            Uri(scheme: 'tel', path: phone),
                          );
                          nav.pop();
                          if (!ok) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Arama başlatılamadı.'),
                              ),
                            );
                          }
                        },
                ),
              ),
              if (!emergency) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Mesaj gönder'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      showMessageDialog(parent);
                    },
                  ),
                ),
              ],
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Kapat'),
              ),
              Text(
                'Demo: gerçek arama yalnızca telefonda başlar.',
                style: TextStyle(fontSize: 11, color: sc.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Message to the elderly person; shown on the "Yaşlı" view.
Future<void> showMessageDialog(BuildContext context) =>
    showDialog<void>(context: context, builder: (_) => const _MessageDialog());

class _MessageDialog extends StatefulWidget {
  const _MessageDialog();

  @override
  State<_MessageDialog> createState() => _MessageDialogState();
}

class _MessageDialogState extends State<_MessageDialog> {
  static const _phrases = [
    'Nasılsınız?',
    'Akşam uğrayacağım.',
    'İlacınızı aldınız mı?',
    'Kendinize iyi bakın.',
  ];
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final empty = _c.text.trim().isEmpty;
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
              const Text(
                'Mesaj gönder',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in _phrases)
                    ActionChip(
                      label: Text(p),
                      onPressed: () => setState(() => _c.text = p),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _c,
                maxLines: 3,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Mesajınızı yazın',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Vazgeç'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    icon: const Icon(Icons.send),
                    label: const Text('Gönder'),
                    onPressed: empty
                        ? null
                        : () {
                            final state = context.read<AppState>();
                            final messenger = ScaffoldMessenger.of(context);
                            state.sendFamilyMessage(_c.text.trim());
                            Navigator.of(context).pop();
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Mesaj gönderildi (simüle)'),
                              ),
                            );
                          },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
