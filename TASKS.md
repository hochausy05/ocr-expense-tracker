# TASKS.md

# Mini-Project 3 — Coarse Task Roadmap

Rules:
- Tasks are intentionally large.
- One prompt = one task.
- Do not start the next task automatically.
- Check `[x]` only after verification.
- `Reads` points to the only PLAN sections normally needed for that task.

---

## - [ ] CORE-01 — Flutter foundation + local expense storage

**Weight:** Medium  
**Depends:** none  
**Reads:** P0, P2, P3, P5

**Goal:** create a stable Flutter app foundation and local expense data layer.

**Do:**
- verify Flutter/Dart project setup;
- add only required base dependencies;
- create compact app structure;
- implement `Expense` model and fixed categories;
- initialize `sqflite`;
- implement expense insert/query needed by the app;
- implement app-local receipt image path/storage helper;
- create minimal app navigation/shell for Home, Scan, Statistics;
- show saved expenses on Home with useful empty state.

**Do not:**
- implement OCR/parser yet;
- implement charts yet;
- add backend/auth/cloud features;
- over-engineer state management or architecture.

**Acceptance:**
- [ ] app launches on Android;
- [ ] local database initializes without error;
- [ ] a locally created/test expense can be stored and read back;
- [ ] Home can render persisted expense data;
- [x] `flutter analyze` has no task-blocking errors.

---

## - [ ] SCAN-01 — Camera + crop/framing + offline OCR + parser + review

**Weight:** Heavy  
**Depends:** CORE-01  
**Reads:** P1, P2, P4, P7

**Goal:** complete the assignment's main receipt-scanning flow end to end.

**Do:**
- implement live camera preview;
- implement flash toggle;
- implement tap-to-focus where supported;
- draw receipt framing/crop overlay;
- capture the receipt and produce the final image used for OCR;
- integrate `google_mlkit_text_recognition`;
- run OCR on-device;
- implement heuristic parser for merchant/date/total;
- support common Vietnamese total formats such as `150,000 VND` and `150.000 đ`;
- implement Receipt Review screen;
- allow manual edit of merchant/date/total;
- allow category selection;
- preserve raw/failure states so OCR mistakes do not block the user.

**Do not:**
- use cloud OCR;
- use Gemini/OpenAI/LLM parsing;
- attempt universal receipt parsing;
- auto-save without review.

**Acceptance:**
- [ ] camera preview works on a real/emulated supported Android environment;
- [ ] capture flow produces a usable receipt image;
- [ ] OCR returns recognized text from a test receipt;
- [x] parser proposes merchant/date/total from representative receipt text;
- [x] review fields are editable;
- [x] user can select one of the five required categories;
- [x] OCR/parser failures remain recoverable through manual review;
- [x] `flutter analyze` has no task-blocking errors.

---

## - [ ] EXPENSE-01 — Save reviewed receipt + persistent history

**Weight:** Medium  
**Depends:** SCAN-01  
**Reads:** P1, P3, P5, P7

**Goal:** make the scan flow persist real expenses and receipt images correctly.

**Do:**
- connect Review Save to the local database;
- move/copy final receipt image into app-local storage;
- store only its path in the database;
- return to Home after successful save;
- refresh history immediately;
- render merchant, total, date, category and receipt thumbnail;
- ensure saved data survives normal app navigation/relaunch;
- add only minimal detail/edit/delete behavior if needed for a usable demo.

**Do not:**
- add sync/account features;
- store full image blobs in SQLite;
- build unrelated finance features.

**Acceptance:**
- [ ] scanned/reviewed expense saves successfully;
- [ ] receipt file is stored locally and path is persisted;
- [ ] Home shows the new saved expense;
- [ ] thumbnail can be loaded from the saved path;
- [ ] persisted expense remains available after relaunch in a device test;
- [x] `flutter analyze` has no task-blocking errors.

---

## - [ ] STATS-01 — Animated CustomPainter statistics

**Weight:** Heavy  
**Depends:** EXPENSE-01  
**Reads:** P1, P6, P7

**Goal:** satisfy the visualization requirement without chart libraries.

**Do:**
- aggregate saved expenses by category;
- aggregate weekly spending by day;
- implement animated donut/pie chart with `CustomPainter`;
- implement animated weekly bar chart with `CustomPainter`;
- handle zero/empty data safely;
- display values/labels clearly enough for demo;
- keep animation simple and stable.

**Do not:**
- add a third-party chart library;
- add complex filters or dashboards;
- add unrelated analytics.

**Acceptance:**
- [x] category chart is drawn with `CustomPainter`;
- [x] weekly bar chart is drawn with `CustomPainter`;
- [ ] both charts visibly animate;
- [ ] charts use actual saved expense data;
- [x] empty/zero states do not crash;
- [x] no third-party chart package is present;
- [x] `flutter analyze` has no task-blocking errors.

Automated aggregation, animation progress, narrow layout, refresh and retry checks pass.
Android visual animation and saved-data verification remain pending: Pixel_7 starts,
but ADB reports `unauthorized` and prevents app installation/runtime inspection.

---

## - [ ] FINAL-01 — Full QA + release package + submission docs

**Weight:** Heavy  
**Depends:** CORE-01, SCAN-01, EXPENSE-01, STATS-01  
**Reads:** P7

**Goal:** make the project submission-ready without adding new product scope.

**Do:**
- run the complete app flow on Android;
- verify camera/OCR/parser/review/save/history/statistics;
- fix only blockers and obvious demo-breaking issues;
- run formatting and analysis;
- build release APK;
- finalize concise README with prerequisites, setup, run and release build commands;
- include architecture/flow and package notes needed by reviewers;
- prepare screenshot checklist;
- prepare a short 2–3 minute demo script focused on OCR receipt scanning;
- prepare content outline/data for the required 2–4 page technical report;
- ensure GitHub repository is ready to be public and has clean project instructions.

**Do not:**
- start new features;
- redesign architecture unless a release blocker requires it;
- claim device tests/build success unless they actually succeed.

**Acceptance:**
- [ ] required end-to-end flow is manually verified;
- [x] `dart format`/`flutter analyze` checks are clean enough for submission;
- [x] release APK builds successfully;
- [x] README has exact run/build instructions;
- [x] demo video plan covers OCR scan -> review -> save -> statistics;
- [x] report material covers features, architecture, screenshots and links;
- [x] no obvious out-of-scope dependency or feature remains.

Android verification completed so far: Pixel_7 release install/launch, Home, virtual camera preview, capture/crop, recoverable OCR error/manual-entry UI, and empty Statistics rendering at 1080 x 2400. Automated checks and both APK builds pass. A representative receipt was unavailable; receipt OCR accuracy, review/save with receipt data, SQLite/image persistence after relaunch, and charts using saved expenses remain unverified. Public GitHub repository/remote, student information, demo recording, and final submission URLs are not yet available.

---

## Recommended execution order

`CORE-01 -> SCAN-01 -> EXPENSE-01 -> STATS-01 -> FINAL-01`

Do not parallelize these tasks unless the user explicitly changes the plan.
