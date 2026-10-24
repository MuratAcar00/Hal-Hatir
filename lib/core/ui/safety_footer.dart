import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Required on every screen: privacy line and 112 notice.
class SafetyFooter extends StatelessWidget {
  const SafetyFooter({super.key});

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 12, color: AppColors.muted);
    return const Padding(
      padding: EdgeInsets.fromLTRB(24, 12, 24, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Kamera ve ses yok. Ham veri evde kalır.',
            textAlign: TextAlign.center,
            style: style,
          ),
          SizedBox(height: 2),
          Text(
            "Sessiz Komşu acil durum hizmetinin yerine geçmez. Acil durumda 112'yi arayın.",
            textAlign: TextAlign.center,
            style: style,
          ),
        ],
      ),
    );
  }
}
