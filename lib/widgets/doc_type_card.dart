// A colourful "product card" for the home screen grid - tapping it opens
// the verification screen for that document type. Styled like a
// supermarket app's category tile: bold icon badge, bilingual label,
// soft shadow, rounded corners.

import 'package:flutter/material.dart';
import '../models/verification_result.dart';
import '../i18n/strings.dart' as i18n;

class DocTypeCard extends StatelessWidget {
  final DocType docType;
  final VoidCallback onTap;

  const DocTypeCard({super.key, required this.docType, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 2,
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: docType.color,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  docType.icon,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                i18n.t('doc_${docType.key}', lang: 'en'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                i18n.t('doc_${docType.key}', lang: 'ta'),
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7686)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
