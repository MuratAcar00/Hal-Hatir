import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/models.dart';
import '../../core/ui/app_scaffold.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.embedded = false});

  /// True inside the web dashboard (no own Scaffold).
  final bool embedded;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final _nameCtrl = TextEditingController(
    text: context.read<AppState>().settings.secondContactName,
  );

  late final _phoneCtrl = TextEditingController(
    text: context.read<AppState>().settings.secondContactPhone,
  );
  late final _familyPhoneCtrl = TextEditingController(
    text: context.read<AppState>().settings.familyPhone,
  );

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _familyPhoneCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final st = s.settings;
    DropdownButton<int> hourPicker(int value, ValueChanged<int> onChanged) =>
        DropdownButton<int>(
          value: value,
          items: [
            for (var h = 0; h < 24; h++)
              DropdownMenuItem(value: h, child: Text('${two(h)}:00')),
          ],
          onChanged: (v) => onChanged(v!),
        );
    final list = ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
        children: [
          Text(
            'İzleme saatleri',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Text('Bu saatlerin dışında yeni uyarı gönderilmez.'),
          Row(
            children: [
              const Text('Başlangıç '),
              hourPicker(
                st.startHour,
                (v) => s.updateSettings(st.copyWith(startHour: v)),
              ),
              const SizedBox(width: 24),
              const Text('Bitiş '),
              hourPicker(
                st.endHour,
                (v) => s.updateSettings(st.copyWith(endHour: v)),
              ),
            ],
          ),
          if (st.startHour == st.endHour)
            const Text('Başlangıç ve bitiş aynı: tüm gün izlenir.'),
          const Divider(height: 32),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Ziyaretçi / tatil modu'),
            subtitle: const Text('Açıkken uyarılar duraklatılır.'),
            value: st.paused,
            onChanged: (v) => s.updateSettings(st.copyWith(paused: v)),
          ),
          const Divider(height: 32),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'İkinci kişinin adı',
              helperText:
                  'Aile 30 dakika içinde dönmezse bu kişiye haber verilir.',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) =>
                s.updateSettings(st.copyWith(secondContactName: v.trim())),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'İkinci kişinin telefonu',
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(),
            ),
            onChanged: (v) =>
                s.updateSettings(st.copyWith(secondContactPhone: v.trim())),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _familyPhoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Yaşlı yakınınızın telefonu',
              helperText: 'Uyarıda tek dokunuşla aranır.',
              prefixIcon: Icon(Icons.phone_in_talk),
              border: OutlineInputBorder(),
            ),
            onChanged: (v) =>
                s.updateSettings(st.copyWith(familyPhone: v.trim())),
          ),
        ],
    );
    return widget.embedded
        ? list
        : AppScaffold(title: 'Ayarlar', roleSwitch: false, body: list);
  }
}
