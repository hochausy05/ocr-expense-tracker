# AGENTS.md

## 1. Purpose

This file is the AI working contract for **Mini-Project 3 — OCR Expense Tracker & Receipt Parser**.

Goal: finish the required project quickly, correctly, and within the assignment scope.

## 2. Source priority

When instructions conflict, use this order:

1. Current user prompt
2. `AGENTS.md`
3. Current task in `TASKS.md`
4. Referenced sections in `PLAN.md`
5. Latest entries in `CHANGELOG.md`
6. `README.md`

Do not silently expand scope.

## 3. Reading rule

Use progressive disclosure. Do **not** scan every document or the whole repository by default.

For each implementation prompt:

1. Read this file.
2. Read only the target task in `TASKS.md`.
3. Read only the `PLAN.md` sections listed by that task's `Reads`.
4. Read the latest 1–3 relevant entries in `CHANGELOG.md`.
5. Inspect only source files needed for the current task.

If the current prompt already provides enough context, avoid unnecessary repository-wide searches.

## 4. Execution contract

- One prompt = one `TASK-ID`.
- Work only on that task.
- Prefer the smallest correct implementation that satisfies the assignment.
- Do not start the next task automatically.
- Do not add speculative features.
- Reuse existing project structure when reasonable.
- Keep Flutter/Dart code simple, readable, and demo-safe.
- Do not refactor unrelated code.
- Do not install unrelated packages.
- Do not commit or push unless the user explicitly asks.
- Never claim a test passed unless it was actually run and passed.

Before editing:
- inspect current code relevant to the task;
- identify existing behavior;
- avoid replacing working code without a reason.

After editing:
- run the most relevant checks available;
- fix only issues caused by or blocking the current task;
- report changed files, checks performed, and any remaining risk;
- update `TASKS.md` only when acceptance criteria are actually met;
- add a Vietnamese entry to `CHANGELOG.md` for meaningful completed work.

## 5. Strict project scope

Required product flow:

`Camera -> receipt framing/crop -> on-device OCR -> heuristic parser -> review/edit -> local save -> history -> statistics`

Required technologies / constraints:
- Flutter 3.x
- Dart 3
- Google ML Kit Text Recognition
- OCR must run on-device/offline
- Local persistence with `sqflite`
- Receipt images/thumbnails stored in app storage; database stores paths
- Expense categories: `Food`, `Study`, `Travel`, `Gear`, `Entertainment`
- Charts drawn with Flutter `CustomPainter`
- No third-party chart library
- Android release APK
- Public GitHub repository
- README build instructions
- Short technical report PDF, 2–4 pages
- Demo video showing receipt OCR flow

Do not add unless the user explicitly requests it:
- login/authentication
- Supabase/Firebase/backend
- cloud sync
- cloud OCR
- LLM/Gemini/OpenAI
- budget planning
- notifications
- multi-user support
- multi-currency system
- complex analytics
- unnecessary architecture layers

## 6. Parsing scope

The parser is heuristic, not AI-based.

It must extract or reasonably infer:
- merchant name
- transaction date
- total amount

At minimum, amount parsing must handle common forms such as:
- `150,000 VND`
- `150.000 đ`

Date parsing must support at least:
- `DD/MM/YYYY`
- common separator variations if cheap to support

Prefer total-related keywords such as:
- `TOTAL`
- `GRAND TOTAL`
- `TỔNG`
- `TỔNG CỘNG`
- `THANH TOÁN`

The review screen is the correction fallback. Do not over-engineer the parser to cover every receipt format.

## 7. UI rule

The app only needs the screens required for a complete demo:

- Expense/Home
- Camera/Scan
- Receipt Review
- Expense Detail if needed by the implementation
- Statistics

Keep visual design clean and usable. Functional correctness has higher priority than decorative work.

## 8. Verification rule

A task may be checked `[x]` only when its acceptance criteria are verified.

Preferred checks:
- `dart format`
- `flutter analyze`
- relevant automated tests if present
- Android build/run when the task touches native plugins
- manual device/emulator verification for camera, OCR, storage, animation, or release behavior

If hardware/device verification cannot be performed, state that explicitly and leave the relevant acceptance item unresolved.

## 9. Documentation rule

Developer-facing project docs are written in English for compactness and consistency.

`CHANGELOG.md` is Vietnamese only.

Do not rewrite old changelog history. Add a new entry under the log header, newest first.

## 10. Stop condition

When the current task is complete:
1. verify it;
2. update task status;
3. update changelog;
4. summarize result;
5. stop.

Do not continue into another `TASK-ID` without a new user instruction.
