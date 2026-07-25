# Aadhaar Document Verifier — Flutter (Windows Desktop) Edition

A from-scratch Flutter rewrite of the Python/Tkinter "Verification Desk"
app, redesigned with a bright, modern **"supermarket app" style UI**
(colourful category cards, clean Material 3 design) instead of the
skeuomorphic wood/leather/ledger look. Same features: Aadhaar/PAN/Voter
ID/Passport/DL/Ration Card/Birth Cert/TN Community-Nativity Certificate
verification, real scanner (WIA) + PDF upload + multi-page support, QR
reading (including structured-text QR cross-checking), bilingual
Tamil/English throughout, PDF report export.

---
## ⚠️ Read this first — what's tested vs. not

**This project was written entirely without a Flutter SDK, without
internet access to pub.dev, and without a Windows C++ compiler in the
build sandbox.** That means:

| Piece | Confidence | Why |
|---|---|---|
| Business logic (`lib/logic/*.dart` except qr/ocr/scanner services, `lib/i18n/strings.dart`) | **High** | Ported 1:1 from the already-tested Python code; the fuzzy-match algorithm (`matcher.dart`) was verified to produce identical output to Python's `difflib` on 6 test cases. All 124 bilingual strings were auto-generated from the proven `i18n.py`, not hand-retyped, so there's no risk of Tamil text corruption there. |
| UI screens (`lib/screens/*`, `lib/widgets/*`, `lib/theme/*`) | **Medium** | Written using standard, well-known Flutter widget patterns, but never run through `flutter analyze` or an emulator - there could be small API mistakes (wrong parameter name, etc.) that only show up when you build. |
| PDF generation (`lib/logic/pdf_report.dart`) | **Medium** | Uses the well-known `pdf` package. Tamil complex-script shaping in generated PDFs is a known weak spot for this package family (see note in that file) - on-screen Tamil (which uses Flutter's own text renderer) should look fine regardless. |
| QR decode (`lib/logic/qr_service.dart`) | **Medium-low** | Uses `flutter_zxing`, but its exact API surface was written from memory/documentation, not verified against the installed package version. |
| **Scanner integration (`windows/runner/scanner_channel.cpp`)** | **Lowest** | Hand-written native C++ WIA/COM code, never compiled. This is the single most likely thing to need debugging - Windows COM/WIA C++ is genuinely fiddly even for experienced Windows devs. |

**Expect this to take real back-and-forth to get building**, the same
way we iterated through the Python `.exe` build errors (numpy version,
pyzbar DLL, Python version, etc.) — except this time starting from
scratch instead of a working build. Send build error screenshots the
same way and they'll get fixed the same way.

---
## 🚀 Recommended: build via GitHub Actions instead of locally

Since this code has never actually been compiled, building on **GitHub's
own Windows runner** is a better first try than your local PC — it has a
real Flutter SDK, real pub.dev access, and a real Visual Studio C++
toolchain, so it can catch every error in one go instead of the
install-something/hit-next-error cycle we went through with the Python
build.

1. Create a new GitHub repo and push this whole folder to it (matches
   your usual GitHub-web workflow):
   ```
   git init
   git add .
   git commit -m "Flutter Aadhaar verifier - initial port"
   git branch -M main
   git remote add origin https://github.com/<your-username>/<repo-name>.git
   git push -u origin main
   ```
2. Go to the repo's **Actions** tab on github.com (works fine from
   mobile browser). The **"Build Windows app"** workflow
   (`.github/workflows/build-windows.yml`) runs automatically on push,
   or click **"Run workflow"** to trigger it manually any time.
3. It will: scaffold the `windows/` runner project fresh (via
   `scripts/patch_windows_project.ps1`, which also wires in the WIA
   scanner code), `flutter pub get`, `flutter analyze`, then
   `flutter build windows --release`.
4. When it finishes (green ✅ or red ❌), open the run and scroll to
   **Artifacts** at the bottom — a **"AadhaarDocVerifier-windows"** zip
   will be there containing the built `.exe` and its dependencies,
   ready to download and copy to any Windows PC (Tesseract-OCR still
   needs installing separately on the target PC, same as always).
5. **If it fails (red ❌)**: click into the failed step to see the exact
   error, screenshot it and send it over — same debugging process as
   the Python `.exe` build, except now every error is a real compiler/
   package error instead of something guessed at.

This doesn't remove the option to build locally with `flutter run -d
windows` for faster iteration once the CI build is green — see below.

---
## Setup (on your Windows PC, for local development)

1. **Install Flutter SDK**: https://docs.flutter.dev/get-started/install/windows
   Run `flutter doctor` afterwards and make sure it reports Visual
   Studio (with the "Desktop development with C++" workload) is
   installed - that's required for Windows desktop builds.

2. **Run the scaffold/patch script** from the project root (PowerShell):
   ```
   .\scripts\patch_windows_project.ps1
   ```
   This runs `flutter create` to generate the `windows/` runner
   boilerplate fresh, then automatically wires in the WIA scanner
   platform channel (adds `scanner_channel.cpp` to `CMakeLists.txt`,
   and the `#include` + `RegisterScannerChannel(...)` call to
   `flutter_window.cpp`). It prints a clear warning if either patch
   didn't apply (e.g. if a newer Flutter version changed the generated
   file's exact wording) - in that case, open the two files it names
   and add the lines manually (the warning message tells you exactly
   what to add and where).

3. **Install Tesseract-OCR** (same as the Python build needed):
   https://github.com/UB-Mannheim/tesseract/wiki → download the Windows
   installer, tick "Add to PATH" if offered, or manually add
   `C:\Program Files\Tesseract-OCR` to your PATH environment variable.
   Verify with `tesseract --version` in a new Command Prompt.

4. **Set a CMake compatibility flag** (needed for the `pdfx` plugin's
   pdfium download step - newer CMake removed support for the old
   minimum version it declares; this is CMake's own documented fix,
   already applied automatically in the GitHub Actions workflow):
   ```
   $env:CMAKE_POLICY_VERSION_MINIMUM = "3.5"
   ```
   Run this in the same PowerShell window before the commands below (it
   only lasts for that window - re-run it if you open a new terminal).

5. **Fetch packages and run**:
   ```
   flutter pub get
   flutter run -d windows
   ```
   Fix any errors `flutter pub get` or `flutter analyze` reports first
   (most likely: a package version in `pubspec.yaml` needs bumping to
   the latest available, or `flutter_zxing`'s API needs a small
   adjustment - see the caveat comment in `qr_service.dart`).

6. **Build the release .exe**:
   ```
   flutter build windows
   ```
   Output lands in `build\windows\x64\runner\Release\`.

---
## Project structure

```
aadhaar_verifier/
├── .github/workflows/build-windows.yml  # CI build via GitHub Actions (recommended)
├── scripts/patch_windows_project.ps1    # auto-scaffolds + patches windows/ runner
├── lib/
│   ├── main.dart
│   ├── i18n/strings.dart          # 124 bilingual strings, auto-ported from Python
│   ├── theme/app_theme.dart       # "supermarket app" bright Material 3 theme
│   ├── models/verification_result.dart
│   ├── logic/
│   │   ├── aadhaar_qr_parser.dart  # Aadhaar/DigiLocker QR parsing
│   │   ├── text_qr_parser.dart      # TN e-Sevai style "Label: Value" QR parsing
│   │   ├── validators.dart          # PAN/Voter/DL/Passport MRZ/Community checks
│   │   ├── matcher.dart             # fuzzy cross-check (verified vs Python difflib)
│   │   ├── ocr_service.dart         # calls system tesseract.exe
│   │   ├── qr_service.dart          # flutter_zxing wrapper
│   │   ├── scanner_service.dart     # Dart side of the WIA platform channel
│   │   └── pdf_report.dart          # bilingual PDF report generator
│   ├── screens/
│   │   ├── home_screen.dart         # supermarket-style doc-type grid
│   │   └── verify_screen.dart       # upload/scan/verify/cross-check/results
│   └── widgets/doc_type_card.dart
├── windows/runner/
│   ├── scanner_channel.h/.cpp       # native WIA scanner implementation
│   └── (rest generated by the patch script / `flutter create`)
├── assets/fonts/NotoSansTamil-*.ttf
└── pubspec.yaml
```

## What's deliberately NOT included yet

- **`url_launcher` for "Open Verify Link"**: currently just shows the URL
  in a snackbar instead of opening the browser. Add
  `url_launcher: ^6.3.0` to `pubspec.yaml` and swap in the one-line
  `launchUrl()` call noted in `verify_screen.dart` if you want this live.
- **UIDAI signature verification**: same honesty stance as the Python
  build — Secure QR is decompressed and shown as "structure only", never
  claimed as cryptographically "VERIFIED", since that needs UIDAI's
  public certificate.
- **Government portal auto-scraping**: same as before, deliberately not
  built — `field_verify_url` / DigiLocker links are meant to be opened
  for manual confirmation, not auto-fetched.
