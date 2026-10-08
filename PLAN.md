# PLAN.md

# Mini-Project 3 — OCR Expense Tracker & Receipt Parser

## P0 — Goal

Build a small Android Flutter expense tracker that scans physical receipts, recognizes text offline with Google ML Kit, extracts merchant/date/total using heuristic parsing, lets the user correct the result, stores expenses locally, and visualizes spending using animated `CustomPainter` charts.

Primary goal: **meet the assignment exactly and finish quickly**.

---

## P1 — Required user flow

### Main flow

`Home -> Scan -> Camera -> Capture/Crop -> OCR -> Parse -> Review/Edit -> Save -> Home`

### Statistics flow

`Home/Statistics -> query local expenses -> category donut/pie + weekly bar chart`

### Required screens

1. **Home / Expenses**
   - recent saved expenses
   - merchant, amount, date, category
   - access to scan and statistics

2. **Camera / Scan**
   - live preview
   - flash toggle
   - tap-to-focus when supported by the camera API
   - receipt framing/crop overlay
   - capture action

3. **Receipt Review**
   - receipt preview/thumbnail
   - editable merchant
   - editable date
   - editable total
   - category selection
   - save/cancel

4. **Statistics**
   - category distribution donut/pie
   - weekly spending bar chart
   - animated rendering
   - implemented directly with `CustomPainter`

An Expense Detail screen is optional unless needed to support a clean history flow.

---

## P2 — Technology

### Required
- Flutter 3.x
- Dart 3
- `camera`
- `google_mlkit_text_recognition`
- `sqflite`
- app-local file storage
- `CustomPainter`

### Supporting packages
Only add lightweight packages when they directly support a required feature, such as:
- path/path_provider for local file locations
- image/cropping helper if required by the chosen capture implementation
- intl for display formatting if useful

Avoid unnecessary dependencies.

### Explicitly excluded
- backend
- Supabase/Firebase
- authentication
- cloud OCR
- LLM parsing
- third-party chart libraries

---

## P3 — Data model

Use one main local entity.

```text
Expense
- id
- merchant
- amount
- transactionDate
- category
- receiptImagePath
- createdAt
```

Categories are fixed:

```text
Food
Study
Travel
Gear
Entertainment
```

The database stores the image path, not image bytes.

Receipt images or cached thumbnails live in app-local storage.

---

## P4 — OCR and receipt parser

### OCR

Input:
- captured/cropped receipt image

Process:
- Google ML Kit Text Recognition on-device

Output:
- raw recognized text

No server call is needed.

### Parser output

```text
ParsedReceipt
- merchant?
- date?
- total?
- rawText
```

### Total heuristic

Prioritize monetary values near total-related keywords:
- TOTAL
- GRAND TOTAL
- TỔNG
- TỔNG CỘNG
- THANH TOÁN

Normalize common Vietnamese formats:
- `150,000 VND`
- `150.000 đ`
- plain digit totals when context is strong

Do not blindly choose the largest number if a stronger total keyword match exists.

### Date heuristic

At minimum support:
- `DD/MM/YYYY`

Cheap variations such as `DD-MM-YYYY` may also be supported.

### Merchant heuristic

Use early meaningful text lines and reject obvious:
- phone numbers
- addresses when recognizable
- tax/code-only lines
- date/amount-only lines
- generic receipt labels

Accuracy does not need to be universal because the review screen is the required correction step.

---

## P5 — Local persistence

Use `sqflite`.

Required operations:
- initialize database
- insert expense
- query expenses
- query data needed for statistics

Edit/delete may be implemented only if they are naturally needed by the current UI; they are not a reason to expand the project.

Receipt image handling:
1. capture/crop image;
2. copy/store final image in app storage;
3. save path in database;
4. display thumbnail from that path.

---

## P6 — Statistics

Charts must be drawn directly with Flutter canvas APIs.

### Category chart
Animated donut or pie chart:
- group expense totals by category
- calculate proportion
- animate sweep/progress
- draw using `CustomPainter`

### Weekly chart
Animated bar chart:
- aggregate spending by day for the displayed week
- scale bar height to max value
- draw bars/labels with `CustomPainter`

Do **not** use:
- `fl_chart`
- Syncfusion charts
- `charts_flutter`
- any other chart library

---

## P7 — Quality and delivery

### Functional verification
The final demo must prove:

1. camera opens;
2. flash control works when device supports it;
3. user can capture a receipt inside a framing overlay;
4. OCR reads text without cloud OCR;
5. parser proposes merchant/date/total;
6. user can correct parsed data;
7. category can be selected;
8. expense persists locally;
9. saved expense appears after app navigation/restart as applicable;
10. statistics use saved data;
11. both charts are `CustomPainter` and animated.

### Delivery

Required final package:
- Android `app-release.apk`
- public GitHub repository
- README with setup/build instructions
- short OCR demo video
- technical report PDF, 2–4 pages

Suggested report content:
- project overview
- feature checklist
- architecture/data flow
- OCR + heuristic parser explanation
- local database/storage
- CustomPainter charts
- screenshots
- GitHub/APK/demo links

### Priority

When time is limited:

`required behavior > device stability > verification > simple UI polish > optional enhancements`
