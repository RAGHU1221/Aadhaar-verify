import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:pdfx/pdfx.dart' as pdfx;

import '../i18n/strings.dart' as i18n;
import '../models/verification_result.dart';
import '../theme/app_theme.dart';
import '../logic/qr_service.dart';
import '../logic/ocr_service.dart' as ocr;
import '../logic/aadhaar_qr_parser.dart';
import '../logic/text_qr_parser.dart' as tqr;
import '../logic/validators.dart';
import '../logic/matcher.dart' as matcher;
import '../logic/scanner_service.dart';
import '../logic/pdf_report.dart';

class VerifyScreen extends StatefulWidget {
  final DocType docType;
  const VerifyScreen({super.key, required this.docType});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  List<String> _imagePaths = [];
  String? _fileLabel;
  bool _verifying = false;
  bool _scanning = false;
  VerificationResult? _result;
  String? _statusMessage;

  final _declaredNameCtrl = TextEditingController();
  final _declaredYearCtrl = TextEditingController();
  final _declaredParentCtrl = TextEditingController();
  Map<String, String>? _compareResults; // rowKey -> status

  @override
  void dispose() {
    _declaredNameCtrl.dispose();
    _declaredYearCtrl.dispose();
    _declaredParentCtrl.dispose();
    super.dispose();
  }

  Future<Directory> _outputScansDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'AadhaarVerifier_Reports', 'scans'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  // -------------------------------------------------------------- upload
  Future<void> _uploadDocument() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'bmp', 'tiff'],
    );
    if (picked == null || picked.files.isEmpty) return;
    final path = picked.files.single.path;
    if (path == null) return;

    if (path.toLowerCase().endsWith('.pdf')) {
      setState(() => _statusMessage = i18n.bi('converting_pdf'));
      try {
        final pages = await _pdfToPageImages(path);
        if (pages.isEmpty) throw Exception('no pages');
        setState(() {
          _imagePaths = pages;
          _fileLabel = pages.length == 1
              ? p.basename(path)
              : '${p.basename(path)}  (${pages.length} pages)';
          _statusMessage = null;
        });
      } catch (e) {
        setState(() => _statusMessage = null);
        _showError(i18n.bi('pdf_convert_failed'));
      }
    } else {
      setState(() {
        _imagePaths = [path];
        _fileLabel = p.basename(path);
      });
    }
  }

  Future<List<String>> _pdfToPageImages(String pdfPath) async {
    final doc = await pdfx.PdfDocument.openFile(pdfPath);
    final outDir = await _outputScansDir();
    final base = p.basenameWithoutExtension(pdfPath);
    final paths = <String>[];
    for (var i = 1; i <= doc.pagesCount; i++) {
      final page = await doc.getPage(i);
      final rendered = await page.render(
        width: page.width * 3,
        height: page.height * 3,
        format: pdfx.PdfPageImageFormat.png,
      );
      await page.close();
      if (rendered != null) {
        final outPath = p.join(outDir.path, '${base}_page$i.png');
        await File(outPath).writeAsBytes(rendered.bytes);
        paths.add(outPath);
      }
    }
    await doc.close();
    return paths;
  }

  // --------------------------------------------------------------- scan
  Future<void> _scanDocument() async {
    final devices = await ScannerService.listScanners();
    if (devices.isEmpty) {
      _showError(i18n.bi('no_scanner_found'));
      return;
    }
    final chosen = await _showDeviceSelectDialog(devices);
    if (chosen == null) return;

    final outDir = await _outputScansDir();
    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    final pages = <String>[];
    var pageNum = 1;

    setState(() => _statusMessage = i18n.bi('scanning_in_progress'));

    while (true) {
      final outPath = p.join(outDir.path, 'scan_${sessionId}_page$pageNum.png');
      setState(() => _scanning = true);
      final scanResult = await ScannerService.scanPage(chosen.id, outPath);
      setState(() => _scanning = false);
      if (!scanResult.success) {
        if (pages.isEmpty) {
          final detail = scanResult.error;
          _showError(
            detail == null || detail.isEmpty
                ? i18n.bi('scan_failed')
                : '${i18n.bi('scan_failed')}\n$detail',
          );
        }
        break;
      }
      pages.add(outPath);
      final again = await _showScanNextPageDialog();
      if (!again) break;
      pageNum++;
      setState(() => _statusMessage = i18n.bi('scanning_in_progress'));
    }

    if (pages.isEmpty) {
      setState(() => _statusMessage = null);
      return;
    }
    setState(() {
      _imagePaths = pages;
      _fileLabel = pages.length == 1
          ? p.basename(pages.first)
          : '${p.basename(pages.first)}  (+${pages.length - 1} more page${pages.length > 2 ? "s" : ""})';
      _statusMessage = i18n.bi('scan_captured');
    });
  }

  Future<ScannerDevice?> _showDeviceSelectDialog(List<ScannerDevice> devices) {
    return showDialog<ScannerDevice>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(i18n.biStack('select_scanner_question')),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: devices
                .map((d) => Card(
                      child: ListTile(
                        title: Text(d.name),
                        onTap: () => Navigator.of(ctx).pop(d),
                      ),
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: Text(i18n.t('cancel_scan_selection')),
          ),
        ],
      ),
    );
  }

  Future<bool> _showScanNextPageDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(i18n.biStack('scan_next_page_question')),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(i18n.t('scan_next_page_no')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(i18n.t('scan_next_page_yes')),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // ------------------------------------------------------------ verify
  Future<void> _runVerification() async {
    if (_imagePaths.isEmpty) return;
    setState(() {
      _verifying = true;
      _statusMessage = i18n.bi('scanning');
      _compareResults = null;
    });

    final result = await _verifyDocument(_imagePaths, widget.docType.key);

    setState(() {
      _result = result;
      _verifying = false;
      _statusMessage = i18n.t('done');
    });
  }

  Future<VerificationResult> _verifyDocument(List<String> imagePaths, String docType) async {
    QrReadResult? qrResult;
    final textParts = <String>[];
    String? ocrError;
    for (final path in imagePaths) {
      qrResult ??= await readQrFromImage(path);
      final ocrResult = await ocr.extractText(path, lang: 'eng');
      textParts.add(ocrResult.text);
      ocrError ??= ocrResult.error;
    }
    final text = textParts.join('\n');

    final result = VerificationResult()..docType = docType;

    if (docType == 'AADHAAR') {
      if (qrResult != null) {
        final parsed = parseAadhaarQr(qrResult.data);
        result.qrGeneration = parsed.qrGeneration;
        result.signatureStatus = parsed.signatureStatus;
        result.fields = parsed.fields;
        result.noteKey = parsed.noteKey;
        result.noteParams = parsed.noteParams;
        result.overallStatus = parsed.signatureStatus == 'STRUCTURE_ONLY'
            ? 'VALID_PATTERN'
            : (parsed.signatureStatus == 'NOT_CHECKED' ? 'REVIEW' : 'SUSPECT');
      } else {
        result.overallStatus = 'SUSPECT';
        result.noteKey = 'note_no_qr_aadhaar';
      }
    } else {
      final idNumber = ocr.findIdNumber(text, docType) ?? '';
      final validatorFn = kValidators[docType];
      if (validatorFn != null) {
        final v = validatorFn(idNumber);
        result.overallStatus = v.status;
        result.noteKey = v.detailKey;
        result.noteParams = v.params;
        result.fields['field_detected_number'] = idNumber.isNotEmpty ? idNumber : '-';
      } else {
        result.overallStatus = 'REVIEW';
        result.noteKey = 'note_no_validator';
        result.fields['field_ocr_excerpt'] =
            text.length > 120 ? text.substring(0, 120).replaceAll('\n', ' ') : text.replaceAll('\n', ' ');
      }

      if ((docType == 'COMMUNITY_NATIVITY' || docType == 'RATION_CARD') && validatorFn != null) {
        result.fields['field_ocr_excerpt'] =
            text.length > 150 ? text.substring(0, 150).replaceAll('\n', ' ') : text.replaceAll('\n', ' ');
      }

      // If OCR never actually ran, or ran but found nothing, say so plainly
      // instead of leaving the excerpt/detected-number blank with no clue
      // why - this is a setup/scan-quality problem, not silence.
      if (ocrError != null && text.trim().isEmpty) {
        result.fields['field_ocr_excerpt'] = ocrError;
      }

      if (qrResult != null) {
        result.qrGeneration = 'DOC_QR_PRESENT';
        final qrData = qrResult.data;
        if (qrData.startsWith('http://') || qrData.startsWith('https://')) {
          result.fields['field_verify_url'] = qrData;
        } else if (tqr.looksLikeKeyValueText(qrData)) {
          final qrFields = tqr.parseKeyValueQr(qrData);
          if (qrFields.isNotEmpty) {
            qrFields.forEach((k, v) => result.fields.putIfAbsent(k, () => v));
            final qrCertNo = tqr.extractNumberField(qrFields);
            if (qrCertNo != null && idNumber.isNotEmpty) {
              String norm(String s) => s.toUpperCase().replaceAll(' ', '').replaceAll('-', '');
              if (norm(qrCertNo) == norm(idNumber)) {
                result.overallStatus = 'VALID_PATTERN';
                result.noteKey = 'structured_qr_match';
                result.noteParams = {'qr_no': qrCertNo};
              } else {
                result.overallStatus = 'SUSPECT';
                result.noteKey = 'structured_qr_mismatch';
                result.noteParams = {'qr_no': qrCertNo, 'printed_no': idNumber};
              }
            }
          } else {
            result.fields['field_qr_raw'] = qrData.length > 80 ? qrData.substring(0, 80) : qrData;
          }
        } else {
          result.fields['field_qr_raw'] = qrData.length > 80 ? qrData.substring(0, 80) : qrData;
        }
      }

      final (expStatus, expDate) = ocr.guessExpiryStatus(text, docType);
      result.expiryStatus = expStatus;
      result.expiryDate = expDate;
    }

    return result;
  }

  // --------------------------------------------------------- cross-check
  void _runCompare() {
    if (_result == null) return;
    final f = _result!.fields;
    final extractedName = f['field_name'] ?? '';
    final extractedYear = (f['field_yob']?.isNotEmpty ?? false) ? f['field_yob']! : (f['field_dob'] ?? '');
    final extractedParent = f['field_address_co'] ?? '';

    setState(() {
      _compareResults = {
        'match_name_row': matcher.matchStatus(_declaredNameCtrl.text, extractedName),
        'match_year_row': matcher.yearMatchStatus(_declaredYearCtrl.text, extractedYear),
        'match_parent_row': matcher.matchStatus(_declaredParentCtrl.text, extractedParent, isParentField: true),
      };
    });
  }

  // -------------------------------------------------------------- export
  Future<void> _exportPdf() async {
    if (_result == null) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final outDir = Directory(p.join(dir.path, 'AadhaarVerifier_Reports'));
      if (!await outDir.exists()) await outDir.create(recursive: true);
      final fileName = 'verification_${widget.docType.key}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final outPath = p.join(outDir.path, fileName);

      await generatePdfReport(
        outputPath: outPath,
        result: _result!,
        docLabel: i18n.bi('doc_${widget.docType.key}'),
        verifiedBy: 'CSC Operator',
        photoPath: _imagePaths.isNotEmpty ? _imagePaths.first : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(i18n.t('exported_msg', params: {'path': outPath}))),
        );
      }
    } catch (e) {
      _showError('$e');
    }
  }

  Future<void> _openVerifyLink() async {
    final url = _result?.fields['field_digilocker_verify_url'] ?? _result?.fields['field_verify_url'];
    if (url == null) return;
    // NOTE: url_launcher isn't in pubspec yet - add it if you want this to
    // actually open the browser (dependency: url_launcher: ^6.3.0, then
    // `import 'package:url_launcher/url_launcher.dart'; await launchUrl(Uri.parse(url));`).
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(url)));
  }

  // ---------------------------------------------------------------- UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(i18n.t('doc_${widget.docType.key}', lang: 'en'), style: const TextStyle(fontSize: 16)),
            Text(i18n.t('doc_${widget.docType.key}', lang: 'ta'), style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildActionButtonsCard(),
            const SizedBox(height: 14),
            _buildCrossCheckCard(),
            const SizedBox(height: 14),
            if (_result != null) _buildResultsCard() else _buildPlaceholderCard(),
            const SizedBox(height: 14),
            if (_result != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _exportPdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: Text(i18n.bi('export_btn')),
                  style: ElevatedButton.styleFrom(backgroundColor: kAccentOrange),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtonsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: _scanning ? null : _uploadDocument,
                  icon: const Icon(Icons.upload_file),
                  label: Text(i18n.bi('upload_btn')),
                ),
                OutlinedButton.icon(
                  onPressed: _scanning ? null : _scanDocument,
                  icon: _scanning
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.document_scanner),
                  label: Text(i18n.bi('scan_btn')),
                ),
                ElevatedButton.icon(
                  onPressed: (_imagePaths.isNotEmpty && !_verifying && !_scanning) ? _runVerification : null,
                  icon: _verifying
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.fact_check),
                  label: Text(i18n.bi('verify_btn')),
                ),
                if (_result?.fields.containsKey('field_digilocker_verify_url') == true ||
                    _result?.fields.containsKey('field_verify_url') == true)
                  OutlinedButton.icon(
                    onPressed: _openVerifyLink,
                    icon: const Icon(Icons.link),
                    label: Text(i18n.bi('open_link_btn')),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(_fileLabel ?? i18n.t('no_file'),
                style: const TextStyle(color: kTextMuted, fontStyle: FontStyle.italic)),
            if (_statusMessage != null) ...[
              const SizedBox(height: 4),
              Text(_statusMessage!, style: const TextStyle(color: kPrimaryGreen, fontSize: 12)),
            ],
            if (_scanning) ...[
              const SizedBox(height: 8),
              const ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(4)),
                child: LinearProgressIndicator(
                  minHeight: 6,
                  color: kPrimaryGreen,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCrossCheckCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(i18n.bi('cross_check_heading'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _declaredField(_declaredNameCtrl, 'label_declared_name')),
                const SizedBox(width: 10),
                Expanded(child: _declaredField(_declaredYearCtrl, 'label_declared_year')),
                const SizedBox(width: 10),
                Expanded(child: _declaredField(_declaredParentCtrl, 'label_declared_parent')),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _result != null ? _runCompare : null,
              child: Text(i18n.bi('compare_btn')),
            ),
            if (_compareResults != null) ...[
              const SizedBox(height: 14),
              ..._compareResults!.entries.map((e) {
                final color = kStatusColors[e.value] ?? Colors.grey;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(width: 160, child: Text(i18n.bi(e.key))),
                      StatusChip(
                        labelEn: i18n.t('match_${e.value}', lang: 'en'),
                        labelTa: i18n.t('match_${e.value}', lang: 'ta'),
                        color: color,
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _declaredField(TextEditingController ctrl, String labelKey) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(labelText: i18n.bi(labelKey)),
    );
  }

  Widget _buildPlaceholderCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            i18n.biStack('placeholder'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: kTextMuted),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsCard() {
    final r = _result!;
    final statusColor = kStatusColors[r.overallStatus] ?? Colors.grey;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatusChip(
              labelEn: i18n.t('status_${r.overallStatus}', lang: 'en'),
              labelTa: i18n.t('status_${r.overallStatus}', lang: 'ta'),
              color: statusColor,
            ),
            const SizedBox(height: 12),
            if (r.noteKey.isNotEmpty) ...[
              Text(i18n.t(r.noteKey, lang: 'en', params: r.noteParams)),
              const SizedBox(height: 4),
              Text(i18n.t(r.noteKey, lang: 'ta', params: r.noteParams),
                  style: const TextStyle(color: kTextMuted)),
              const SizedBox(height: 12),
            ],
            const Divider(),
            const SizedBox(height: 8),
            Text(i18n.bi('extracted_details'), style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...r.fields.entries.map((e) {
              final hasKey = i18n.kStrings.containsKey(e.key);
              final label = hasKey ? i18n.bi(e.key) : e.key;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: Text('$label:', style: const TextStyle(color: kTextMuted))),
                    Expanded(flex: 3, child: Text(e.value, style: const TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
