// OCR module - ported from Python `modules/ocr_engine.py`. Extracts raw
// text + pulls common fields (document number, dates) using regex over
// the OCR text. Works for English + Tamil (if the Tamil traineddata is
// installed alongside Tesseract-OCR, else falls back to English only).
//
// IMPORTANT: unlike the Python build (which used pytesseract, a Python
// wrapper around the same underlying Tesseract binary), Flutter has no
// mature first-party OCR plugin for Windows desktop. This calls the
// system `tesseract.exe` command-line binary directly via Process.run -
// the SAME underlying engine pytesseract used, just invoked directly.
// Requires Tesseract-OCR to be installed on the Windows PC and on PATH
// (see README for the installer link) - this is an unavoidable external
// dependency for Windows OCR, same as the Python build needed.

import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const List<String> kDatePatterns = [
  r'\b(\d{2}[/-]\d{2}[/-]\d{4})\b',
  r'\b(\d{2}[/-]\d{2}[/-]\d{2})\b',
  r'\b(\d{4}[/-]\d{2}[/-]\d{2})\b',
];

const Map<String, String> kFieldRegex = {
  'PAN': r'\b([A-Z]{5}[0-9]{4}[A-Z])\b',
  'VOTER_ID': r'\b([A-Z]{3}[0-9]{7})\b',
  'PASSPORT': r'\b([A-PR-WYa-pr-wy][0-9]{7})\b',
  'AADHAAR_NUM': r'\b(\d{4}\s?\d{4}\s?\d{4})\b',
  'COMMUNITY_NATIVITY': r'\b([A-Z]{1,3}-?\d{8,20})\b',
};

/// Grayscales the image (cheap preprocessing that helps Tesseract on
/// phone/scanner photos) and saves it to a temp file, returning that path.
/// If anything goes wrong, falls back to the original path unmodified.
Future<String> preprocessForOcr(String imagePath) async {
  try {
    final bytes = await File(imagePath).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return imagePath;
    final gray = img.grayscale(decoded);
    final tempDir = await getTemporaryDirectory();
    final outPath = p.join(tempDir.path,
        'ocr_pre_${DateTime.now().millisecondsSinceEpoch}.png');
    await File(outPath).writeAsBytes(img.encodePng(gray));
    return outPath;
  } catch (_) {
    return imagePath;
  }
}

class OcrResult {
  final String text;
  /// Set only when OCR could not run/produce text at all, so the caller
  /// can tell "tesseract isn't installed" apart from "ran fine, image had
  /// no readable text" (the latter leaves this null with an empty [text]).
  final String? error;
  OcrResult(this.text, this.error);
}

/// Runs Tesseract on the (optionally preprocessed) image and returns the
/// extracted text. `lang` is 'eng' or 'eng+tam' if the Tamil traineddata
/// is installed.
Future<OcrResult> extractText(String imagePath, {String lang = 'eng'}) async {
  final processedPath = await preprocessForOcr(imagePath);
  try {
    var result = await Process.run('tesseract', [processedPath, 'stdout', '-l', lang]);
    if (result.exitCode != 0) {
      // Tamil traineddata probably not installed - fall back to English only.
      result = await Process.run('tesseract', [processedPath, 'stdout', '-l', 'eng']);
      if (result.exitCode != 0) {
        return OcrResult('', 'Tesseract-OCR ran but failed (exit ${result.exitCode}): ${result.stderr}');
      }
    }
    final text = result.stdout as String;
    if (text.trim().isEmpty) {
      // Exit code 0 with no text usually means Tesseract couldn't find any
      // text region on the page at all (too low contrast, all-graphic
      // page, wrong page segmentation mode for this layout, etc.) -
      // distinct from "not installed", so callers can tell them apart.
      final stderrText = (result.stderr as String).trim();
      return OcrResult(
          '',
          'Tesseract-OCR ran but found no readable text on this page.'
          '${stderrText.isNotEmpty ? ' ($stderrText)' : ''}');
    }
    return OcrResult(text, null);
  } on ProcessException {
    // tesseract not on PATH / not installed
    return OcrResult(
        '', 'Tesseract-OCR is not installed or not on PATH. Install it and add it to PATH (see README), then restart the app.');
  } catch (e) {
    return OcrResult('', 'OCR failed: $e');
  }
}

List<String> findDates(String text) {
  final found = <String>[];
  for (final pat in kDatePatterns) {
    final matches = RegExp(pat).allMatches(text);
    for (final m in matches) {
      final g = m.group(1);
      if (g != null) found.add(g);
    }
  }
  return found;
}

String? findIdNumber(String text, String docType) {
  final pattern = kFieldRegex[docType];
  if (pattern == null) return null;
  final m = RegExp(pattern).firstMatch(text.toUpperCase());
  return m?.group(1);
}

/// Only PASSPORT and DRIVING_LICENSE genuinely expire.
/// Returns (status, detectedDateString) where status is
/// 'CURRENT' | 'EXPIRED' | 'REVIEW' | 'NA'.
(String, String?) guessExpiryStatus(String text, String docType) {
  if (docType != 'PASSPORT' && docType != 'DRIVING_LICENSE') {
    return ('NA', null);
  }

  final dates = findDates(text);
  if (dates.isEmpty) return ('REVIEW', null);

  final parsed = <DateTime>[];
  for (final d in dates) {
    final dt = _tryParseDate(d);
    if (dt != null) parsed.add(dt);
  }

  if (parsed.isEmpty) return ('REVIEW', null);

  // heuristic: the latest date found on the doc is usually "valid until / expiry"
  parsed.sort();
  final latest = parsed.last;
  final formatted = '${latest.day.toString().padLeft(2, '0')}-'
      '${latest.month.toString().padLeft(2, '0')}-${latest.year}';
  if (latest.isBefore(DateTime.now())) {
    return ('EXPIRED', formatted);
  }
  return ('CURRENT', formatted);
}

DateTime? _tryParseDate(String d) {
  // Try dd/mm/yyyy, dd-mm-yyyy, dd/mm/yy, dd-mm-yy, yyyy-mm-dd, yyyy/mm/dd
  final sep = d.contains('/') ? '/' : '-';
  final parts = d.split(sep);
  if (parts.length != 3) return null;
  try {
    if (parts[0].length == 4) {
      // yyyy-mm-dd / yyyy/mm/dd
      return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    }
    // dd-mm-yyyy / dd-mm-yy
    var year = int.parse(parts[2]);
    if (parts[2].length == 2) year += year < 50 ? 2000 : 1900;
    return DateTime(year, int.parse(parts[1]), int.parse(parts[0]));
  } catch (_) {
    return null;
  }
}
