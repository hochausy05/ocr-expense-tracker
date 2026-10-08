# OCR Expense Tracker & Receipt Parser

Mini-Project 3 built with Flutter 3 and Dart 3. The app scans a receipt, recognizes text on-device, proposes expense fields for review, saves the receipt image and expense locally, and summarizes spending.

## Required features

- [x] Camera preview, receipt framing, capture, crop, flash control, and tap-to-focus where supported
- [x] Offline Google ML Kit text recognition and heuristic merchant/date/total parsing
- [x] Editable review form and the five fixed categories: Food, Study, Travel, Gear, Entertainment
- [x] SQLite expense history and app-local receipt image paths
- [x] Animated category donut and weekly spending charts drawn with Flutter `CustomPainter`
- [ ] Complete camera-to-statistics workflow visually verified on Android (pending manual QA)

## Technology and architecture

- Flutter 3.47.6 / Dart 3.13.5
- `camera` and `image_cropper` capture and crop the receipt.
- `google_mlkit_text_recognition` processes the cropped image locally on the device. No OCR service or network API is used by the app.
- `ReceiptParser` uses keyword and format heuristics to propose merchant, date, and total. The review form is the correction path.
- `DatabaseService` stores expense fields in SQLite. `ImageStorageService` copies receipt files under app documents storage; SQLite stores the file path.
- `ExpenseStatistics` aggregates saved records; `CategoryDonutChart` and `WeeklyBarChart` render animated charts with `CustomPainter`.
- Screens: Home/history, Camera/Scan and Review, and Statistics.

## Dependencies

Runtime packages: `camera`, `image_cropper`, `google_mlkit_text_recognition`, `sqflite`, `path`, `path_provider`, and `intl`. Tests use Flutter's `flutter_test`; static analysis uses `flutter_lints`. There is no third-party chart package.

## Setup and run

Requirements: Flutter 3.x with Dart 3, Android Studio/Android SDK, an Android emulator or device, accepted Android SDK licenses, and a camera-capable Android device/emulator for scan QA. Ensure `ANDROID_HOME` and `ANDROID_SDK_ROOT` point to the same SDK installation.

```bash
flutter doctor -v
flutter pub get
flutter run
```

Run automated checks:

```bash
dart format lib test
flutter analyze
flutter test
```

Build the Android release APK:

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`. The current release build uses Android's debug signing configuration for a test APK. Configure a private release keystore before production or store distribution; never commit signing secrets.

## Verification status

Verified on 2026-10-08: `dart format lib test` (25 files, no changes), `flutter analyze` (no issues), `flutter test` (28 tests passed), and successful debug and release APK builds. The release APK installed and launched on the Pixel_7 emulator. Home, the virtual camera preview, capture/crop UI, and empty Statistics rendered; an emulator scene (not a receipt) reached the recoverable OCR error/manual-entry screen. A real receipt was not available, so OCR accuracy, saving/history with receipt data, relaunch persistence, and charts using saved expenses remain unverified. See the screenshots in `docs/screenshots/` and details in `CHANGELOG.md`.

## Known limitations

- A real receipt has not been used to verify on-device OCR accuracy. Saving, history, image persistence after relaunch, and data-backed chart updates still require manual Android end-to-end verification.
- OCR parsing is heuristic; check and correct the proposed values before saving.
- Release signing is configured with a debug key and is only appropriate for a test APK.
- Student/course information and final GitHub, APK, and demo URLs are not provided yet.

## Submission links

- Public GitHub repository: **TODO — create/publish repository**
- Release APK: **TODO — upload final APK**
- Demo video: **TODO — record and upload demo**
- Technical report: `output/pdf/technical_report.pdf` (source: `docs/TECHNICAL_REPORT.md`)

## Submission documents

- [Demo script](docs/DEMO_SCRIPT.md)
- [Technical report source](docs/TECHNICAL_REPORT.md)
- Actual emulator screenshots: [Home](docs/screenshots/home.png), [camera preview](docs/screenshots/camera_preview.png), [crop](docs/screenshots/crop_review.png), [OCR fallback](docs/screenshots/review_fallback.png), [empty Statistics](docs/screenshots/statistics_empty.png)
