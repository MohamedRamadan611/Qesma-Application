#!/usr/bin/env bash
# Qesma project scaffold: folders, agent rules, skills, prompts (as commands/workflows), docs.
# Usage: bash setup.sh [target-dir] [--tool=claude|antigravity|both] [--extras] [--ux] [--force] [--no-git]
# Works on Linux, macOS, WSL, and Git Bash on Windows. Never overwrites existing files unless --force.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="./qesma"
TOOL="both"
EXTRAS=0
UX=0
FORCE=0
GIT=1

usage() {
  cat <<USAGE
Usage: bash setup.sh [target-dir] [options]

  target-dir            Where to create the project (default: ./qesma)
  --tool=claude         Set up for Claude Code only (.claude/, CLAUDE.md)
  --tool=antigravity    Set up for Antigravity only (.agent/, GEMINI.md)
  --tool=both           Both (default)
  --extras              Also install the 10 optional skills (review-migration, audit, code-review, ...)
  --ux                  Also install 7 UI/UX skills (design-critique, accessibility-review, ux-copy, design-handoff, design-system, user-research, research-synthesis)
  --force               Overwrite existing files/skill folders
  --no-git              Do not run git init / first commit
  -h, --help            Show this help
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --tool=*) TOOL="${1#*=}" ;;
    --extras) EXTRAS=1 ;;
    --ux) UX=1 ;;
    --force) FORCE=1 ;;
    --no-git) GIT=0 ;;
    -h|--help) usage; exit 0 ;;
    -*) echo "Unknown option: $1"; usage; exit 1 ;;
    *) TARGET="$1" ;;
  esac
  shift
done

case "$TOOL" in claude|antigravity|both) ;; *) echo "Invalid --tool value: $TOOL"; exit 1 ;; esac
WANT_CLAUDE=0; WANT_AG=0
if [ "$TOOL" = "claude" ] || [ "$TOOL" = "both" ]; then WANT_CLAUDE=1; fi
if [ "$TOOL" = "antigravity" ] || [ "$TOOL" = "both" ]; then WANT_AG=1; fi

for need in templates skills prompts docs; do
  [ -d "$SRC/$need" ] || { echo "Missing '$need' folder next to setup.sh. Re-extract the package."; exit 1; }
done

CREATED=0; SKIPPED=0
put_file() { # src dest
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [ -e "$dest" ] && [ "$FORCE" -eq 0 ]; then
    SKIPPED=$((SKIPPED+1)); echo "  skip   ${dest#$TARGET/} (exists)"
  else
    cp "$src" "$dest"; CREATED=$((CREATED+1)); echo "  create ${dest#$TARGET/}"
  fi
}
put_dir() { # src_dir dest_dir
  local src="$1" dest="$2"
  if [ -e "$dest" ] && [ "$FORCE" -eq 0 ]; then
    SKIPPED=$((SKIPPED+1)); echo "  skip   ${dest#$TARGET/}/ (exists)"
  else
    mkdir -p "$(dirname "$dest")"; rm -rf "$dest"; cp -R "$src" "$dest"
    CREATED=$((CREATED+1)); echo "  create ${dest#$TARGET/}/"
  fi
}

echo "Setting up Qesma in: $TARGET  (tool: $TOOL, extras: $EXTRAS, ux: $UX)"
mkdir -p "$TARGET"
TARGET="$(cd "$TARGET" && pwd)"

echo "== Folders and root files"
mkdir -p "$TARGET/backend" "$TARGET/mobile" "$TARGET/fixtures" "$TARGET/docs/adr" "$TARGET/docs/design/screens" "$TARGET/docs/prompts" "$TARGET/.github/workflows"
put_file "$SRC/templates/AGENTS.md"       "$TARGET/AGENTS.md"
put_file "$SRC/templates/README.md"       "$TARGET/README.md"
put_file "$SRC/templates/gitignore"       "$TARGET/.gitignore"
put_file "$SRC/templates/editorconfig"    "$TARGET/.editorconfig"
put_file "$SRC/templates/backend-AGENTS.md" "$TARGET/backend/AGENTS.md"
put_file "$SRC/templates/mobile-AGENTS.md"  "$TARGET/mobile/AGENTS.md"
put_file "$SRC/templates/fixtures-README.md" "$TARGET/fixtures/README.md"
put_file "$SRC/templates/adr-README.md"     "$TARGET/docs/adr/README.md"
put_file "$SRC/templates/design-README.md"  "$TARGET/docs/design/README.md"
put_file "$SRC/templates/screens-README.md" "$TARGET/docs/design/screens/README.md"
[ -e "$TARGET/.github/workflows/.gitkeep" ] || : > "$TARGET/.github/workflows/.gitkeep"

echo "== Docs"
for f in "$SRC"/docs/*.md; do put_file "$f" "$TARGET/docs/$(basename "$f")"; done
for f in "$SRC"/docs/design/*.md; do put_file "$f" "$TARGET/docs/design/$(basename "$f")"; done
for f in "$SRC"/docs/prompts/*.md; do put_file "$f" "$TARGET/docs/prompts/$(basename "$f")"; done

if [ "$WANT_CLAUDE" -eq 1 ]; then
  echo "== Claude Code"
  put_file "$SRC/templates/CLAUDE.md" "$TARGET/CLAUDE.md"
  put_file "$SRC/templates/claude-settings.json" "$TARGET/.claude/settings.json"
  for f in "$SRC"/prompts/commands/*.md; do put_file "$f" "$TARGET/.claude/commands/$(basename "$f")"; done
  for d in "$SRC"/skills/core/*/; do put_dir "${d%/}" "$TARGET/.claude/skills/$(basename "$d")"; done
  if [ "$EXTRAS" -eq 1 ]; then
    for d in "$SRC"/skills/extras/*/; do put_dir "${d%/}" "$TARGET/.claude/skills/$(basename "$d")"; done
  fi
  if [ "$UX" -eq 1 ]; then
    for d in "$SRC"/skills/ux/*/; do put_dir "${d%/}" "$TARGET/.claude/skills/$(basename "$d")"; done
  fi
fi

if [ "$WANT_AG" -eq 1 ]; then
  echo "== Antigravity"
  put_file "$SRC/templates/GEMINI.md" "$TARGET/GEMINI.md"
  put_file "$SRC/templates/agent-rule.md" "$TARGET/.agent/rules/project.md"
  for f in "$SRC"/prompts/workflows/*.md; do put_file "$f" "$TARGET/.agent/workflows/$(basename "$f")"; done
  for d in "$SRC"/skills/core/*/; do put_dir "${d%/}" "$TARGET/.agent/skills/$(basename "$d")"; done
  if [ "$EXTRAS" -eq 1 ]; then
    for d in "$SRC"/skills/extras/*/; do put_dir "${d%/}" "$TARGET/.agent/skills/$(basename "$d")"; done
  fi
  if [ "$UX" -eq 1 ]; then
    for d in "$SRC"/skills/ux/*/; do put_dir "${d%/}" "$TARGET/.agent/skills/$(basename "$d")"; done
  fi
fi

if [ "$GIT" -eq 1 ]; then
  echo "== Git"
  if ! command -v git >/dev/null 2>&1; then
    echo "  git not found; skipping."
  elif [ -d "$TARGET/.git" ]; then
    echo "  repository already exists; skipping."
  else
    (
      cd "$TARGET"
      git init -q
      git symbolic-ref HEAD refs/heads/main
      git add -A
      if git commit -q -m "chore: scaffold project (structure, agent rules, skills, prompts, docs)"; then
        echo "  initialized repo on 'main' with the first commit."
      else
        echo "  repo initialized, but the first commit failed (set git user.name/user.email, then run: git add -A && git commit)."
      fi
    )
  fi
fi

echo
echo "Done. Created: $CREATED  Skipped: $SKIPPED"
echo "Next steps:"
echo "  1. cd \"$TARGET\" and open it in VS Code (or Antigravity)."
echo "  2. Review AGENTS.md and the installed skills (they are instructions your agent will follow)."
if [ "$WANT_CLAUDE" -eq 1 ]; then echo "  3. Claude Code: start a fresh session and run /b0-bootstrap (plan mode, approve the plan)."; fi
if [ "$WANT_AG" -eq 1 ]; then echo "  3. Antigravity: start a fresh conversation and run the b0-bootstrap workflow."; fi
echo "  4. Order: B0 -> B3 -> B1 -> B2 -> B4 -> B5 -> B6 -> B7 -> B8 (docs/prompts/PHASE1_BACKEND_PROMPTS.md)."
