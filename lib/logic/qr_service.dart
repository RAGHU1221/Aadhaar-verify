// QR decoding from a static image file (uploaded/scanned document page),
// using the flutter_zxing package (has native Windows desktop support).
//
// This plays the same role as `modules/qr_reader.py`'s pyzbar-based
// decoder in the Python build, but ZXing's own image preprocessing is
// generally solid, so we don't replicate the multi-pass
// threshold/upscale fallback the Python version needed for pyzbar.
//
// CAVEAT: this file was written without access to pub.dev, so the exact
// method/class names below (zx.readBarcodeImagePath, DecodeParams,
// Format.qrCode, result.isValid/.text) are based on the flutter_zxing
// API as documented, but may drift slightly between package versions.
// If `flutter pub get` + `flutter analyze` flags a signature mismatch
// here, check the installed version's example app (in
// `.pub-cache\hosted\pub.dev\flutter_zxing-<version>\example\`) for the
// current method names and adjust this file accordingly - the rest of
// the app only depends on `readQrFromImage()` returning a `QrReadResult?`,
// so a fix here is fully contained to this one file.

import 'dart:io';
import 'package:flutter_zxing/flutter_zxing.dart';

class QrReadResult {
  final String data;
  QrReadResult(this.data);
}

/// Attempts to decode a QR/barcode from the image at [imagePath].
/// Returns null if no QR was found.
Future<QrReadResult?> readQrFromImage(String imagePath) async {
  try {
    final bytes = await File(imagePath).readAsBytes();
    final result = await zx.readBarcodeImagePath(File(imagePath));
    if (result.isValid && result.text != null && result.text!.isNotEmpty) {
      return QrReadResult(result.text!);
    }
    // fall back to raw-bytes decode API in case the path-based one misses
    final result2 = zx.readBarcodesImage(
      bytes,
      DecodeParams(format: Format.qrCode, tryHarder: true, tryInverted: true),
    );
    if (result2.isNotEmpty && result2.first.isValid) {
      return QrReadResult(result2.first.text ?? '');
    }
    return null;
  } catch (_) {
    return null;
  }
}
