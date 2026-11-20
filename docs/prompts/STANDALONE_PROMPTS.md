# Standalone release — prompt index

The first public release is a standalone Android app for one organizer: no deployed server, $0 running cost. The app serves the existing `/api/v1` contract in-process from SQLite (a `LocalBackend` `HttpClientAdapter`) using a Dart port of the engine. The Java backend is frozen and returns in the server phase. Spec: `docs/STANDALONE_SPEC.md` (written by SA0); decision: ADR-011; dependencies: ADR-012.

Discipline (same as Phase 1 and 2): one prompt per fresh session; Step 0 plan and wait for approval; tests first for money; Stop protocol; commit; then `/flr-review` and `/flv-verify` (or `/r-review` and `/v-verify` for BSA1) in new sessions.

## Before the first prompt
- FL14 and B17 merged and green. Tag the repo `server-phase-ready` so the server phase can resume from there.
- Decision Log: SA0 wrote A121-A150 (next free id: A151); ADRs: ADR-011 (local-first) and ADR-012 (dependencies) exist after SA0 (ADR-010 stays reserved for FCM). Package versions in ADR-012 were read from pub.dev on 2026-11-17; `sqlite3_flutter_libs` is end-of-life, so SA2 pins `sqlite3` instead.

## Run order

| Order | Command | What | Needs | Money risk |
|---|---|---|---|---|
| 1 | `/sa0-standalone-spec` | Spec, ADR-011/012, Decision Log A121-A150, scope, SCREEN_MAP and guard rules (docs only) | — | rules only |
| 2 | `/sa1-dart-engine` | Pure Dart engine, parity with Java on `fixtures/engine` | SA0 | **high** |
| 3 | `/sa2-local-db` | drift schema, invariants, migrations | SA1 | medium |
| 4 | `/sa3-local-backend` | `LocalBackend` adapter + ported services, conformance suite | SA2 | **high** |
| 5 | `/sa4-app-mode` | `QESMA_MODE`, local onboarding, server-only UI hidden | SA3 | low |
| 6 | `/sa5-backup` | Export/import JSON, auto-backup, reminder | SA4 | medium |
| 7 | `/bsa1-categories-pool-contract` | Java: category, treasurer, paidFromPool, settlement kind, pool meter; regenerate client | SA5, Docker | medium |
| 8 | `/sa6-categories` | Categories in local backend and expense UI | BSA1 | low |
| 9 | `/sa7-my-share` | My share per month × category | SA6 | medium |
| 10 | `/sa8-trip-recap` | Recap image + text summary share | SA7 | low |
| 11 | `/sa9-reminder-tones` | WhatsApp reminder tones | SA8 | none |
| 12 | `/sa10-pool-treasurer` | Pool & treasurer, live meter | SA9 | **high** |
| 13 | `/sa11-khorouga-calculator` | Fuel + tolls and multi-stop ride split | SA10 | **high** |
| 14 | `/sa12-receipt-ocr` | Receipt OCR via Firebase AI Logic + App Check | SA11, Firebase project | medium |
| 15 | `/sa13-release` | Integration, a11y/perf, privacy, Play listing, 1.0.0 | SA12 | — |
| Update 1 | `/sa14-voice-entry` | Egyptian Arabic voice entry | 1.0.0 released | medium |
| 16 | `/bsa2-itemized-v2-contract` | Java: discount, item quantity, service/tax as amounts; migration; OpenAPI; fixtures V9–V16; regenerate client (STANDALONE_SPEC 18, A171–A175) | SA12, Docker | **high** |
| 17 | `/sa15-itemized-v2-local` | Dart engine parity on V9–V16; drift migration; local validator, calculator and backup version | BSA2 | **high** |
| 18 | `/sa16-itemized-editor-ux` | P8-01 revised: by-item / by-person modes, compact cards, member picker sheet, discount and `%`/amount rows, quantity, validation summary, printed-total tolerance (A174), CTA pass, read-only details | SA15 | medium |
| 19 | `/sa17-receipt-ocr-v2` | OCR reads quantity, unit price, discount, merchant (→ title) and category (A176) | SA16 | medium |

Rows 16–19 were added on 2026-11-20 and run before `/sa13-release`. Their command files are in `.claude/commands/`. Verification: `/bsa2` then `/r-review` and `/v-verify bsa2`; `/sa15` then `/flr-review` and `/flv-verify sa15` (money); `/sa16` and `/sa17` then `/flr-review`.

SA9, SA11 and SA12 do not depend on each other's code; the order above only keeps one change in flight at a time. SA12 may move earlier if the Firebase setup is ready.

## Coverage (nothing unowned)

| Feature | Prompt(s) | Design reference |
|---|---|---|
| Groups, members, equal/exact/itemized, multi-payer, revisions, balances, payments (Phase 1) | SA1–SA4 (existing FL0–FL9 screens) | existing P1–P11 |
| No sign-in, local profile | SA4 | P1-02 (adapted) |
| Backup export/import | SA5 | none (derive from DESIGN.md) |
| Categories | BSA1, SA6 | P3-01, P5-01 |
| My share | SA7 | none (derive) |
| Trip recap image + text summary | SA8 | none (derive) |
| Reminder tones | SA9 | P13-04 (reference only) |
| Pool & treasurer | BSA1, SA10 | none (derive) |
| Khorouga calculator | SA11 | none (derive) |
| Receipt OCR | SA12 | none (derive; P8-01 editor receives the draft) |
| Release, privacy, store listing | SA13 | — |
| Voice entry (update 1) | SA14 | none (derive) |

## Server phase (not written yet)
To-buy checklist (members claim items), B18/FL17 push, FL15 notifications/activity, FL16 conflict/delete-account UI, B19/FL18 hardening, and the "upload my local data" import endpoint plus `RemoteRepository` switch (remove the `LocalBackend` override). Server endpoints for My share and the recap are added then (they are local-only computations in the standalone app).

## Known gaps and risks
- No designs exist for backup, My share, recap, pool, calculator and OCR screens: each prompt derives them from `docs/design/DESIGN.md` and lists them in its Step 0.
- Two engines (Java, Dart) must stay equal: every behaviour change adds a fixture vector to both in the same commit.
- OCR depends on Gemini's free tier: shared daily quota, data may be used by Google, no SLA. The feature must degrade to manual entry.
- Data lives only on the phone: backup (SA5) is a launch requirement, not an extra.

## Verification cadence per prompt
- SA1, SA3, SA10, SA11 (money): `/flr-review` then `/flv-verify sa<N>`.
- BSA1: `/r-review` then `/v-verify bsa1`.
- Others: `/flr-review`; `/flv-verify` before SA13.
- Gates are written to `docs/gates/gate-sa<N>.md`.

## Owner decisions recorded in SA0 (for the prompts that depend on them)
- My share is shown per currency (A131). A ride leg with no riders is rejected (A141). The treasurer cannot deposit to themselves (A138). Recap percentage ties follow the category enum order (A133). OCR cap: 20 scans per device per day (A145). Android auto-backup replaces `allowBackup="false"` (A128, SA5). Each feature's guard words/icons are listed in `docs/STANDALONE_SPEC.md` section 15.
