# Accessibility audit (WCAG 2.1 AA) — mobile app after FL8, light and dark

**Standard:** WCAG 2.1 AA, plus the project rules (48 px targets, 2.0x text, RTL, colour never the only signal) | **Scope:** every screen FL0–FL8 | **Method:** computed contrast for both palettes, Flutter's accessibility guidelines run on the key screens in both themes and both languages, code review of every interactive widget, widget tests at 2.0x text.

## Summary
**Findings:** 1 major (fixed), 5 minor/nit (listed), 0 blocker. **Not verified by me:** TalkBack / Switch Access on a device, rotation and background/foreground on the phone in dark mode (the phone was locked when the dark build was installed, so the dark theme was verified by widget tests, goldens and computed contrast only).

## Evidence
| Check | How | Result |
|---|---|---|
| Text pairs >= 4.5:1, both palettes | `test/core/theme/contrast_test.dart` (35 text pairs + avatar tints, computed) | PASS. Lowest light pair 4.5+ (see test); lowest dark pair 4.70 (snackbar action), next 5.04 |
| Boundaries / focus >= 3:1, both palettes | same test (6 pairs) | PASS (dark input outline 5.04 on card, 5.48 on canvas) |
| Tap target size, labelled targets, text contrast measured on rendered pixels | `test/a11y/guidelines_test.dart`: groups list, account hub, balances tab, expenses tab, expense details, add expense x light/dark x ar/en = 24 runs | PASS |
| 2.0x text, no overflow | existing per-screen tests (FL3–FL8) and the appearance sheet test | PASS |
| Colour is not the only signal | balance chips carry word + sign + amount; selected chips/rows carry a check icon and the `selected` semantics flag; errors have text next to the red border | PASS (code review + semantics tests) |
| Direction | RTL/LTR switch at runtime (language sheet) with tests; no physical left/right (guard) | PASS |
| Screen-reader names | icon buttons have tooltips (all 11 `IconButton`s reviewed), rows are merged with a spoken label and a tap action, amounts are read in words (`moneySpoken`), sheets are `scopesRoute` with a header | PASS by review; real TalkBack NOT VERIFIED |
| Reduced motion | skeleton fade stops when the system removes animations (FL1 test); theme change has no animation | PASS |

## Findings
| # | Issue | WCAG / rule | Severity | Where | Status |
|---|---|---|---|---|---|
| 1 | The member checkbox in the paid-by sheet had a 40x40 px hit area | 2.5.5 / project 48 px rule | Major | `payers_sheet.dart` (was `kMinTouch - 8`) | **Fixed** (48 px) |
| 2 | Disabled primary button text is 3.86:1 in the light palette (helper text on hairline) | 1.4.3 exempts inactive controls | Minor | `app_theme.dart` disabled style | Listed (exempt; not changed) |
| 3 | The two palettes switch instantly (no cross-fade) | 2.3.3 not applicable; polish | Nit | `QesmaPalette.lerp` | Listed |
| 4 | The offline banner is not dismissible and clears only on the next server answer | 3.3.x usability | Minor | `app.dart` `_OfflineHost` | Listed (by design: never blocks content) |
| 5 | Amount fields keep left-to-right digits inside right-to-left screens | 3.3.2 clarity | Minor | `AmountBox` | Listed (design rule: numerals read left-to-right) |
| 6 | The Account tab's sign-out button needs a scroll at 2.0x text | 2.4.x | Nit | `profile_hub_screen.dart` | Listed |

## Contrast tables
Run `flutter test test/core/theme/contrast_test.dart --reporter expanded` to print every pair with its ratio for both palettes (the test fails with the pair name if any pair drops below 4.5:1 text / 3:1 boundary).

## Dark theme notes
- Derived from the brand teal, not an inversion: navy surfaces, light text, teal fills carry dark text (`onPrimary`), status colours are light-on-dark containers, balance chips keep word + sign + colour, avatars have a dark tint set, the snackbar uses the inverse pair, status-bar icons follow the theme.
- The destructive button uses a dedicated `errorFill` with white text (the bright error colour is for text and outlines only).
- Follow-the-phone is the default; Account > Appearance sets System / Light / Dark and is remembered on the device.

## What is good
Semantics are deliberate (merged rows, spoken amounts, live regions, `selected` flags), all targets are 48 px, copy is Arabic-first, errors are explained in words next to the field, and the whole palette is held to computed contrast in both themes.

## NOT VERIFIED
TalkBack and Switch Access behaviour; the dark theme on the physical phone; rotation and background/foreground during a sheet in dark; system font-size settings above 2.0x on a device.
