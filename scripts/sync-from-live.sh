#!/usr/bin/env bash
# Pull the skill files nittim.com serves into this repo. fis is the source of truth for
# skills/nittim-loop; this repo mirrors it. Run after a skill change ships on nittim.com,
# then commit. scripts/gate.sh fails while the two differ.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
for f in SKILL.md nittim-loop.mdc; do
  curl -fsSL -m 20 "https://nittim.com/skills/nittim-loop/$f" -o "skills/nittim-loop/$f.new"
  [ -s "skills/nittim-loop/$f.new" ] || { echo "empty download for $f" >&2; rm -f "skills/nittim-loop/$f.new"; exit 1; }
  mv "skills/nittim-loop/$f.new" "skills/nittim-loop/$f"
done
git status --short skills/
echo "synced from nittim.com"
