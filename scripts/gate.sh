#!/usr/bin/env bash
# nittim-mcp gate — run before merging a session branch into main (/close runs it).
#
# This repo is seven files of prose and manifests with three ways to drift silently:
# two manifests that must agree, two copies of one skill that must stay identical, and
# a set of URLs on nittim.com that the README promises resolve. This script checks all
# of it. Pass --offline to skip the network checks.
#
# Exit 1 on the first failure; prints every check as it goes.

set -uo pipefail
cd "$(git rev-parse --show-toplevel)"

fail=0
ok()   { printf '  ✓ %s\n' "$1"; }
bad()  { printf '  ✗ %s\n' "$1" >&2; fail=1; }
offline=0; [ "${1:-}" = "--offline" ] && offline=1

echo "── gate: hook installed ──"
if [ "$(git config --get core.hooksPath || true)" = "hooks" ]; then ok "core.hooksPath = hooks"
else bad "core.hooksPath is not 'hooks' — run: git config core.hooksPath hooks"; fi
[ -x hooks/pre-push ] && ok "hooks/pre-push is executable" || bad "hooks/pre-push missing or not executable"

echo "── gate: manifests agree ──"
v_open=$(python3 -c 'import json;print(json.load(open("plugin.json"))["version"])')
v_cc=$(python3 -c 'import json;print(json.load(open(".claude-plugin/plugin.json"))["version"])')
[ "$v_open" = "$v_cc" ] && ok "version $v_open in both manifests" || bad "version drift: plugin.json=$v_open .claude-plugin/plugin.json=$v_cc"
python3 - <<'PY' || fail=1
import json
a=json.load(open("plugin.json")); b=json.load(open(".claude-plugin/plugin.json"))
for k in ("name","description","author","homepage","repository","license","keywords"):
    if a.get(k)!=b.get(k):
        print(f"  ✗ manifests differ on {k!r}"); raise SystemExit(1)
print("  ✓ name/description/author/homepage/repository/license/keywords identical")
m=json.load(open(".mcp.json"))
s=m["mcpServers"]["nittim"]
assert s["url"]=="https://nittim.com/api/mcp" and s["type"]=="streamable-http", ".mcp.json endpoint changed"
print("  ✓ .mcp.json points at https://nittim.com/api/mcp (streamable-http)")
PY

echo "── gate: skill copies identical ──"
body() { awk 'f;/^---$/{c++} c==2&&!f{f=1}' "$1"; }
if diff -q <(body skills/nittim-loop/SKILL.md) <(body skills/nittim-loop/nittim-loop.mdc) >/dev/null; then ok "SKILL.md and nittim-loop.mdc bodies identical"
else bad "SKILL.md and nittim-loop.mdc bodies differ (frontmatter excluded)"; fi
d1=$(sed -n 's/^description: //p' skills/nittim-loop/SKILL.md); d2=$(sed -n 's/^description: //p' skills/nittim-loop/nittim-loop.mdc)
[ "$d1" = "$d2" ] && ok "skill descriptions identical" || bad "skill descriptions differ"

echo "── gate: nothing that must never be here ──"
if grep -rnE '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[a-z]{2,}' --exclude-dir=.git --exclude-dir=hooks --exclude-dir=scripts . | grep -v 'users.noreply.github.com' ; then bad "an email address is committed"; else ok "no email address"; fi
if grep -rnE '\$[0-9]|[0-9]+ ?(USD|credits?)\b' --exclude-dir=.git --exclude-dir=scripts README.md skills plugin.json .claude-plugin >/dev/null; then bad "a price is in public copy"; else ok "no prices"; fi
if command -v gitleaks >/dev/null; then
  if gitleaks detect --source . --config .gitleaks.toml --no-git --redact --no-banner >/dev/null 2>&1; then ok "gitleaks clean over the working tree"; else bad "gitleaks found a secret in the working tree"; fi
  rules=$(grep -c '^\[\[rules\]\]' .gitleaks.toml); grep -q 'useDefault = true' .gitleaks.toml && ok ".gitleaks.toml extends defaults (+$rules custom rule)" || bad ".gitleaks.toml lacks [extend] useDefault = true — zero rules loaded"
else bad "gitleaks not installed"; fi

echo "── gate: commit identity ──"
if git log --format='%ae' | grep -v 'users.noreply.github.com' | head -1 | grep -q .; then bad "a commit carries a non-noreply author email"; else ok "every commit uses the GitHub no-reply identity"; fi

if command -v claude >/dev/null; then
  echo "── gate: claude plugin validate ──"
  claude plugin validate . >/dev/null 2>&1 && ok "Claude Code plugin manifest valid" || bad "claude plugin validate failed"
fi

if [ "$offline" = 0 ]; then
  echo "── gate: live URLs ──"
  for u in https://nittim.com/selfcheck.md https://nittim.com/keys https://nittim.com/agents \
           https://nittim.com/skills/nittim-loop/SKILL.md https://nittim.com/skills/nittim-loop/nittim-loop.mdc \
           https://agent-plugins.org/schemas/1.0.0/plugin.schema.json https://agent-plugins.org/schemas/1.0.0/mcp.schema.json; do
    code=$(curl -s -o /dev/null -w '%{http_code}' -m 15 "$u"); [ "$code" = 200 ] && ok "$code $u" || bad "$code $u"
  done
  # The MCP endpoint answers POST only; a GET 405 is the healthy signal.
  code=$(curl -s -o /dev/null -w '%{http_code}' -m 15 https://nittim.com/api/mcp); [ "$code" = 405 ] && ok "405 (POST-only, alive) https://nittim.com/api/mcp" || bad "$code https://nittim.com/api/mcp (expected 405)"
  init=$(curl -s -m 20 -X POST https://nittim.com/api/mcp -H content-type:application/json -H accept:application/json,text/event-stream \
    -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-03-26","capabilities":{},"clientInfo":{"name":"nittim-mcp-gate","version":"0"}}}')
  echo "$init" | grep -q '"serverInfo":{"name":"nittim"' && ok "MCP initialize answered by nittim" || bad "MCP initialize did not answer as nittim"
  echo "── gate: served skill copies match the repo ──"
  curl -s -m 15 https://nittim.com/skills/nittim-loop/SKILL.md | diff -q - skills/nittim-loop/SKILL.md >/dev/null && ok "live SKILL.md == repo" || bad "live SKILL.md differs from repo (fis serves it — sync one side)"
  curl -s -m 15 https://nittim.com/skills/nittim-loop/nittim-loop.mdc | diff -q - skills/nittim-loop/nittim-loop.mdc >/dev/null && ok "live nittim-loop.mdc == repo" || bad "live nittim-loop.mdc differs from repo"
fi

if [ "$fail" = 0 ]; then echo "── gate: PASS ──"; else echo "── gate: FAIL ──" >&2; exit 1; fi
