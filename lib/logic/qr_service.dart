// QR decoding from a static image file (uploaded/scanned document page),
// using the flutter_zxing package (has native Windows desktop support).
//
// This plays the same role as `modules/qr_reader.py`'s pyzbar-based
// decoder in the Python build, but ZXing's own image preprocessing is
// generally solid, so we don't replicate the multi-pass
// threshold/upscale fallback the Python version needed for pyzbar.
//
// UPDATE: the first version of this file guessed the flutter_zxing API
// without pub.dev access and got it wrong in two ways, caught by the
// real Windows compiler on GitHub Actions:
//   1. readBarcodeImagePath needs a second positional DecodeParams arg.
//   2. There is no `readBarcodesImage` method on `Zxing` at all - the
//      byte-based fallback call was removed rather than re-guessed
//      again, to keep this to a single, more likely to be correct, call.
// If `readBarcodeImagePath` still doesn't match, check
// `.pub-cache\hosted\pub.dev\flutter_zxing-<version>\lib\` on the build
// machine (the CI workflow now also prints every `readBarcode`-related
// method signature it finds there before building, so the Actions log
// itself will show the real API if this guess is still off).

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
    final result = await zx.readBarcodeImagePath(
      File(imagePath),
      const DecodeParams(),
    );
    if (result.isValid && result.text != null && result.text!.isNotEmpty) {
      return QrReadResult(result.text!);
    }
    return null;
  } catch (_) {
    return null;
  }
}
