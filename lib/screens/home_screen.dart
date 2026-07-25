import 'package:flutter/material.dart';
import '../models/verification_result.dart';
import '../i18n/strings.dart' as i18n;
import '../widgets/doc_type_card.dart';
import '../theme/app_theme.dart';
import 'verify_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(i18n.t('app_title', lang: 'en'),
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Text(i18n.t('app_title', lang: 'ta'), style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(i18n.t('sidebar_heading', lang: 'en'),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kTextDark)),
              Text(i18n.t('sidebar_heading', lang: 'ta'),
                  style: const TextStyle(fontSize: 15, color: kTextMuted)),
              const SizedBox(height: 6),
              Text(
                i18n.t('app_subtitle', lang: 'en'),
                style: const TextStyle(fontSize: 12, color: kTextMuted),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: GridView.builder(
                  itemCount: kDocTypes.length,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    mainAxisExtent: 150,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemBuilder: (context, index) {
                    final doc = kDocTypes[index];
                    return DocTypeCard(
                      docType: doc,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => VerifyScreen(docType: doc)),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                i18n.biStack('footer_note'),
                style: const TextStyle(fontSize: 10, color: kTextMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
