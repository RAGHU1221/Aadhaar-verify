// Bilingual (Tamil + English) PDF verification report - ported from
// Python `modules/pdf_report.py`, using the `pdf` package.
//
// CAVEAT: the Dart `pdf` package does basic glyph layout without full
// complex-script shaping (the kind HarfBuzz/Pango do for Tamil
// conjuncts). Simple/common Tamil text usually renders fine, but dense
// conjunct clusters may not reshape perfectly the way they do in the
// Python build's ReportLab+PIL output (which we hand-solved there with a
// custom mixed-script renderer). If Tamil looks visibly wrong in the
// generated PDF specifically (as opposed to on-screen, which uses
// Flutter's own correctly-shaping text renderer), that's the likely
// cause - worth flagging back if you hit it.

import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../i18n/strings.dart' as i18n;
import '../models/verification_result.dart';

Future<File> generatePdfReport({
  required String outputPath,
  required VerificationResult result,
  required String docLabel,
  required String verifiedBy,
  String? photoPath,
}) async {
  final regularFontData = await rootBundle.load('assets/fonts/NotoSansTamil-Regular.ttf');
  final boldFontData = await rootBundle.load('assets/fonts/NotoSansTamil-Bold.ttf');
  final tamilFont = pw.Font.ttf(regularFontData);
  final tamilFontBold = pw.Font.ttf(boldFontData);

  final doc = pw.Document();

  const statusColors = {
    'VERIFIED': PdfColor.fromInt(0xFF1FB673),
    'VALID_PATTERN': PdfColor.fromInt(0xFF3B82F6),
    'REVIEW': PdfColor.fromInt(0xFFF5A524),
    'SUSPECT': PdfColor.fromInt(0xFFE5484D),
  };
  final statusColor = statusColors[result.overallStatus] ?? PdfColors.grey600;

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Brass-style header band
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFFC9A45A),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(i18n.t('pdf_title', lang: 'en'),
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Text(i18n.t('pdf_title', lang: 'ta'),
                      style: pw.TextStyle(fontSize: 14, font: tamilFontBold)),
                  pw.SizedBox(height: 4),
                  pw.Text(
                      '$docLabel  |  ${i18n.t('pdf_generated', lang: 'en')}: '
                      '${DateTime.now().toString().substring(0, 16)}',
                      style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Overall status banner
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: statusColor,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.DefaultTextStyle(
                style: const pw.TextStyle(color: PdfColors.white),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(i18n.t('pdf_status_${result.overallStatus}', lang: 'en'),
                        style: const pw.TextStyle(fontSize: 12, color: PdfColors.white)),
                    pw.Text(i18n.t('pdf_status_${result.overallStatus}', lang: 'ta'),
                        style: pw.TextStyle(fontSize: 10, font: tamilFontBold, color: PdfColors.white)),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 14),

            pw.Text(i18n.t('pdf_qr_sig_heading', lang: 'en'),
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.Text(i18n.t('pdf_qr_sig_heading', lang: 'ta'),
                style: pw.TextStyle(fontSize: 10, font: tamilFontBold)),
            pw.SizedBox(height: 4),
            pw.Text('QR generation: ${result.qrGeneration}', style: const pw.TextStyle(fontSize: 9)),
            pw.Text('Signature status: ${result.signatureStatus}', style: const pw.TextStyle(fontSize: 9)),
            pw.SizedBox(height: 12),

            pw.Text(i18n.t('pdf_validity_heading', lang: 'en'),
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.Text(i18n.t('pdf_validity_heading', lang: 'ta'),
                style: pw.TextStyle(fontSize: 10, font: tamilFontBold)),
            pw.SizedBox(height: 4),
            pw.Text(
                '${result.expiryStatus}${result.expiryDate != null ? " (${result.expiryDate})" : ""}',
                style: const pw.TextStyle(fontSize: 9)),
            pw.SizedBox(height: 12),

            pw.Text(i18n.t('pdf_extracted_heading', lang: 'en'),
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.Text(i18n.t('pdf_extracted_heading', lang: 'ta'),
                style: pw.TextStyle(fontSize: 10, font: tamilFontBold)),
            pw.SizedBox(height: 6),
            ...result.fields.entries.map((e) {
              final hasKey = i18n.kStrings.containsKey(e.key);
              final labelEn = hasKey ? i18n.t(e.key, lang: 'en') : e.key;
              final labelTa = hasKey ? i18n.t(e.key, lang: 'ta') : '';
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(
                      width: 160,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('$labelEn:',
                              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                          if (labelTa.isNotEmpty)
                            pw.Text(labelTa,
                                style: pw.TextStyle(fontSize: 8, font: tamilFont, color: PdfColors.grey700)),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(e.value,
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
              );
            }),
            pw.SizedBox(height: 10),

            if (result.noteKey.isNotEmpty)
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFFFF6E0),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(i18n.t('pdf_note_heading', lang: 'en'),
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text(i18n.t(result.noteKey, lang: 'en', params: result.noteParams),
                        style: const pw.TextStyle(fontSize: 8.5)),
                    pw.SizedBox(height: 4),
                    pw.Text(i18n.t(result.noteKey, lang: 'ta', params: result.noteParams),
                        style: pw.TextStyle(fontSize: 8.5, font: tamilFont)),
                  ],
                ),
              ),

            pw.Spacer(),
            pw.Divider(color: PdfColors.grey400),
            pw.Text(
              i18n.t('pdf_footer', lang: 'en', params: {'who': verifiedBy}),
              style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
            ),
            pw.Text(
              i18n.t('pdf_footer', lang: 'ta', params: {'who': verifiedBy}),
              style: pw.TextStyle(fontSize: 7, font: tamilFont, color: PdfColors.grey600),
            ),
          ],
        );
      },
    ),
  );

  final file = File(outputPath);
  await file.writeAsBytes(await doc.save());
  return file;
}
