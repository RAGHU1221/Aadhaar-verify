// Native Windows implementation of the 'aadhaar_verifier/scanner' method
// channel - talks to real scanners via WIA.DeviceManager (NOT the
// deprecated WIA.CommonDialog, which raises COM error -2147221005
// "Invalid class string" on many current Windows 10/11 installs since
// Microsoft removed the old Scanner/Camera Wizard it depended on).
//
// SETUP (after `flutter create .` has generated windows/runner/):
//   1. Copy this file and scanner_channel.cpp into windows/runner/
//   2. Open windows/runner/CMakeLists.txt and add "scanner_channel.cpp"
//      to the `add_executable(${BINARY_NAME} WIN32 ... )` file list,
//      alongside the existing flutter_window.cpp / main.cpp entries.
//   3. In windows/runner/flutter_window.cpp, inside
//      FlutterWindow::OnCreate() after the FlutterViewController is
//      created (look for `flutter_controller_->engine()`), add:
//          RegisterScannerChannel(flutter_controller_->engine());
//      (declare `void RegisterScannerChannel(flutter::FlutterEngine*
//      engine);` near the top of flutter_window.cpp, matching the
//      signature in scanner_channel.h)
//   4. Rebuild: flutter run -d windows (or flutter build windows)
//
// This wasn't compiled/tested in this sandbox (no Windows C++ toolchain
// available) - if `flutter build windows` reports errors here, share
// the exact error text and it can be fixed the same way we iterated on
// the Python .exe build errors.

#ifndef RUNNER_SCANNER_CHANNEL_H_
#define RUNNER_SCANNER_CHANNEL_H_

#include <flutter/flutter_engine.h>

void RegisterScannerChannel(flutter::FlutterEngine* engine);

#endif  // RUNNER_SCANNER_CHANNEL_H_
