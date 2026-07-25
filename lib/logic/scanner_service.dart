// Real document-scanner integration (Windows Image Acquisition) via a
// Flutter platform channel to native C++ code in windows/runner/.
//
// IMPORTANT: This Dart side is complete and safe to use as-is. The
// native C++ half (windows/runner/scanner_channel.cpp) implements the
// same WIA.DeviceManager approach proven working in the Python build
// (avoiding the deprecated WIA.CommonDialog that raised "Invalid class
// string" on modern Windows), but it has NOT been compiled/tested here -
// there's no Windows C++ toolchain in this sandbox. Build on your Windows
// PC and report any compile errors the same way we debugged the .exe.

import 'package:flutter/services.dart';

class ScannerDevice {
  final String id;
  final String name;
  ScannerDevice(this.id, this.name);
}

class ScannerService {
  static const _channel = MethodChannel('aadhaar_verifier/scanner');

  /// Lists connected scanners. Returns [] if WIA isn't available or no
  /// scanner is connected - the caller should treat that as "not found".
  static Future<List<ScannerDevice>> listScanners() async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('listScanners');
      if (result == null) return [];
      return result
          .map((e) => ScannerDevice((e as Map)['id'] as String, e['name'] as String))
          .toList();
    } on PlatformException {
      return [];
    } on MissingPluginException {
      return [];
    }
  }

  /// Scans one page from the given device and saves it to [outputPath].
  /// Returns true on success.
  static Future<bool> scanPage(String deviceId, String outputPath) async {
    try {
      final ok = await _channel.invokeMethod<bool>('scanPage', {
        'deviceId': deviceId,
        'outputPath': outputPath,
      });
      return ok ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
