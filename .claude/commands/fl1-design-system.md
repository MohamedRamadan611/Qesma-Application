---
description: "FL1 — Design system in Flutter: tokens, RTL, shared widgets, Arabic copy, accessibility"
---

Read AGENTS.md, mobile/AGENTS.md, `.claude/mobile/SCREEN_MAP.md`, docs/design/DESIGN.md (tokens: colours, type, radius, spacing), docs/design/design.md_qesma_english_design_system_vibe_coding_edition.md, docs/STITCH_PROMPTS.md (shared sample data, copy tone) and open these screens (read the images): `P3-01-Group-Home & Expenses-Tab.png`, `P9-01-Balance-Tab.png`, `P9-02-Pay.png`, `P4-Add-Member.png`, `P11-01-No-Internet.png`, `P11-02-Generic-Error.png`, `P11-03-Loading-pattern.png`. Prerequisite: FL0 merged. Skills (max 4): ui-ux-pro-max, design-system, accessibility-review, ux-copy. Forbidden: backend skills.

Step 0 (plan, wait for approval): the token mapping from DESIGN.md to `ThemeData`/`ColorScheme`/`TextTheme`/theme extensions (one table); the font decision (Cairo or IBM Plex Sans Arabic per DESIGN.md: **bundle** the font files from an open licence in `assets/fonts` with the licence file, no runtime download); the component list below with the screen each is taken from; which strings you will write in Arabic copy (Egyptian, friendly, short) and the ARB naming scheme.

Implement (light theme only; Phase 1):
1. Theme from tokens; Western digits with tabular figures for amounts; 16 px card radius, 12 px inputs, 28 px sheets, 8 px grid, 48 px minimum touch targets (from the design notes).
2. `core/widgets`: `AppScaffold`/app bar (back arrow mirrors in RTL), primary/secondary/destructive buttons with loading state, text field (error text, counter such as 8/60, clear button), selectable chips and segmented tabs (RTL order), status chips for balances (**owed = green with "+" and the word, owes = orange-red with "-" and the word, settled = neutral**; colour is never the only signal), `MoneyText` (signed, `ج.م`, tabular figures), initials avatar (deterministic colour from the member id), card, bottom-sheet scaffold (handle, close, title), confirm and blocked dialogs, snackbar helper, empty state, error state with retry and `requestId`, no-internet state (P11-01), skeleton blocks (P11-03, no shimmer package), offline banner.
3. A debug-only component catalogue route (`/_catalog`, not in release) showing every component in ar/RTL and en/LTR at 1.0x and 2.0x text scale.
4. All shared strings in ARB (ar and en) written with the ux-copy skill; error-code copy table from `SCREEN_MAP.md` section 7 as ARB keys.
5. Accessibility: semantic labels for icon buttons and money values ("minus 80 pounds", not symbols), focus order in RTL, contrast checked for every token pair used for text (script or test, WCAG AA), no information by colour alone.

Tests: widget tests per component (ar and en, text scale 2.0, no overflow), golden tests for 6 key components at 360x800 (store goldens, document how to update), a contrast test over the token pairs, semantics tests for `MoneyText` and status chips, guard tests from FL0 still green. Compare your catalogue against the screen images and list every deliberate deviation.
Constraints: no feature screens, no API calls, no new dependency without the ADR; keep widgets free of business logic. Done when `flutter analyze` and `flutter test` pass. Then follow the Stop protocol; do NOT start FL2 here.
