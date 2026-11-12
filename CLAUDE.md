@AGENTS.md

# Claude Code Guide — Qesma (project-specific additions)

Qesma is an Arabic-first group expense-splitting app for Egypt. It records who paid what; it never moves money. The rules, invariants, skill routing and stop protocol are in `AGENTS.md` (loaded above). Do not repeat them here.

## Where things are
- Phase 1 spec: `docs/PROJECT_SPEC.md`; roadmap: `docs/PROJECT_PHASES.md`; Phase 2 spec: `docs/PHASE2_SPEC.md`.
- Backend rules: `backend/AGENTS.md`. Mobile rules and screen map: `mobile/AGENTS.md`, `.claude/mobile/SCREEN_MAP.md`.
- Designs: `docs/design/`. Generated API contract: `docs/openapi.json`. Dart client: `mobile/packages/qesma_api` (never edit by hand).

## Commands
- Backend (run from `/backend`, Docker must be running): `./mvnw test`, `./mvnw -q test -Dtest=ClassName`, `./mvnw verify`.
- Milestone prompts live in `.claude/commands/` (`/b0`–`/b19`, `/fl0`–`/fl18`, `/r-review`, `/flr-review`). Run one milestone per fresh session.
- Phase 2 run order and coverage: `docs/prompts/PHASE2_PROMPTS.md`.

## Test output (keep sessions short)
- When running a test suite while developing, print only the failures and the `Tests run:` summary lines. Never paste full logs into the conversation. Example filter: `... 2>&1 | grep -E "Tests run:|FAIL|ERROR\]   "`.
- Run the full suite once at the end of a milestone, not after every edit.
- Flutter: `flutter test <path>` for the files you touched; the full `flutter test` once at the end.

## Local environment quirks
- `./mvnw clean` can fail on Windows if another process locks `backend/target/*.jar`. Then run `./mvnw test-compile failsafe:integration-test failsafe:verify` and say so in the summary.
- Git Bash rewrites arguments that look like paths (for example `--dart-define=INITIAL_ROUTE=/_catalog`): prefix those commands with `MSYS_NO_PATHCONV=1`.
