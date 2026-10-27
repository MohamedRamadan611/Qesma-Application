# Qesma (working title)
A mobile app (Android first, Flutter) that lets a group of friends track shared spending on trips, shared housing, and outings, and shows who owes whom at the end. All interaction happens inside the app (no WhatsApp/chat integration). Primary language: Egyptian Arabic (RTL), secondary: English. Default currency: EGP.

Group expense-splitting app (trips, shared housing, outings) — Arabic-first.

- Specs: `docs/PROJECT_SPEC.md` (Phase 1 detail), `docs/PROJECT_PHASES.md` (whole project)
- Agent rules: `AGENTS.md` · Prompts: `.claude/commands/` or `.agent/workflows/` · Reference copy: `docs/prompts/`
- Backend: `backend/` · Mobile: `mobile/` · Shared test vectors: `fixtures/`

## Start
1. Open this folder in VS Code (or Antigravity).
2. Run prompt **B0** (`/b0-bootstrap` in Claude Code) in a fresh session, approve its plan, review the result.
3. Continue in the order: B0 → B3 → B1 → B2 → B4 → B5 → B6 → B7 → B8 (see `docs/prompts/PHASE1_BACKEND_PROMPTS.md`).
