# Mini-Project 3 — OCR Expense Tracker & Receipt Parser

**Technical report source — 2026-10-08**  
**Student:** [TODO: full name] · **Student ID:** [TODO] · **Course/class:** [TODO]  
**GitHub:** [TODO: public repository URL] · **APK:** [TODO: downloadable APK URL] · **Demo:** [TODO: video URL]

## 1. Objective and features

This Android application records expenses from photographed receipts. The user captures and crops a receipt, receives offline OCR and heuristic field suggestions, corrects the result, chooses a category, and saves it locally. Home displays expense history; Statistics summarizes category totals and spending by day for the current week.

The implemented flow is Camera → framing/capture → crop → on-device OCR → heuristic parser → editable review → SQLite save and local receipt image → history → statistics. The fixed categories are Food, Study, Travel, Gear, and Entertainment. The application does not use a backend, cloud OCR, account service, or third-party chart library.

## 2. Architecture and data flow

The Flutter UI is organized into Home, Camera/Scan with Review, and Statistics screens. `CameraScreen` manages camera lifecycle, capture, crop and OCR. `OcrService` calls Google ML Kit Text Recognition on a local image path. `ReceiptParser` proposes merchant, transaction date and total from recognized text. The review screen lets the user correct these fields and select a category before saving.

`Expense` is the persisted data model. `DatabaseService` initializes a versioned SQLite database and stores merchant, integer VND amount, transaction date, category, optional receipt path, and creation timestamp. `ImageStorageService` copies the cropped image into the app documents directory under `receipts/`; only the resulting path is stored in SQLite. Statistics loads expenses and aggregates category totals and local transaction dates. `CategoryDonutChart` and `WeeklyBarChart` paint the animated visuals directly on Flutter canvas.

## 3. Camera, offline OCR, and parser

The app selects the back camera when available, shows a receipt framing overlay, supports flash where available and tap-to-focus, and observes app lifecycle changes to release/reinitialize the camera. The captured image is cropped before recognition. ML Kit processes that file on-device; it does not upload receipt text or images to a server.

The parser is deliberately heuristic. It checks date patterns with slash or hyphen separators, normalizes common Vietnamese total keywords, and recognizes grouped amounts such as `150,000 VND` and `150.000 đ`. It prioritizes total-related lines over subtotal, discount, tax and unrelated amounts. Merchant/date/total suggestions may be absent or incorrect; the editable review screen is the correction step, and saving requires validated fields.

## 4. Local persistence and statistics

SQLite stores structured expense fields; receipt images remain ordinary files in application storage. The history screen reads saved expenses and displays their fields and image thumbnail when the path is available. The database supports local history without network access.

Statistics aggregates amounts by the five categories and by Monday through Sunday for the current week. Both charts animate and use custom `CustomPainter` implementations. Empty data is represented safely; no sample expenses are injected. Visual correctness and updates against saved Android data still require device-level QA.

## 5. Verification and limitations

Automated verification on 2026-10-08: `dart format lib test` formatted no files; `flutter analyze` reported no issues; `flutter test` passed all 28 tests; debug and release APK builds succeeded. The 81.3 MiB (85.2 MB) release APK installed and launched on the Pixel_7 Android emulator and passed `apksigner verify`. It is signed with the Android debug certificate, not a production key.

Emulator QA confirmed Home launch, permission request, live virtual camera preview, capture, crop UI, and return to a recoverable manual-review screen after the emulator scene produced an OCR error. The virtual room scene was not a receipt. Empty Statistics rendered at 1080 x 2400 without visible overflow. A representative receipt OCR result, expense save, image thumbnail, relaunch persistence, and statistics based on saved data were not verified. Camera behavior and data-backed chart animation still need real receipt/device QA.

**Actual emulator screenshots:** [Home](screenshots/home.png), [camera preview](screenshots/camera_preview.png), [crop screen](screenshots/crop_review.png), [OCR fallback/review](screenshots/review_fallback.png), and [empty Statistics](screenshots/statistics_empty.png). Camera screenshots show the emulator's virtual scene, not a receipt.

**Screenshot checklist for final demo:**

- [x] Home screen
- [x] Live camera preview and crop interface (emulator virtual scene)
- [x] Recoverable OCR error/manual-entry option and empty Statistics
- [ ] Real receipt OCR with proposed fields
- [ ] Corrected review, saved history with thumbnail, and Statistics populated from the saved expense

**Distribution:** Student identity and final GitHub/APK/demo URLs remain TODO placeholders. No Git repository or remote is present in the workspace. The demo video has not been recorded. The APK is a test artifact; configure a private release keystore for production distribution.
