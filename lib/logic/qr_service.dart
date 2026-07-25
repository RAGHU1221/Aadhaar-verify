// QR decoding from a static image file (uploaded/scanned document page),
// using the flutter_zxing package (has native Windows desktop support).
//
// This plays the same role as `modules/qr_reader.py`'s pyzbar-based
// decoder in the Python build, but ZXing's own image preprocessing is
// generally solid, so we don't replicate the multi-pass
// threshold/upscale fallback the Python version needed for pyzbar.
//
// Zxing.readBarcodeImagePath takes an XFile (not dart:io File) plus a
// non-const DecodeParams (per pub.dev API docs for flutter_zxing 2.x).

import 'package:cross_file/cross_file.dart';
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
      XFile(imagePath),
      DecodeParams(),
    );
    if (result.isValid && result.text != null && result.text!.isNotEmpty) {
      return QrReadResult(result.text!);
    }
    return null;
  } catch (_) {
    return null;
  }
}
