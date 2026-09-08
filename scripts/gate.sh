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

echo "── gate: registry + marketplace manifests ──"
python3 - <<'PY2' || fail=1
import json
v=json.load(open("plugin.json"))["version"]
s=json.load(open("server.json")); m=json.load(open(".claude-plugin/marketplace.json"))
bad=[]
if s["version"]!=v: bad.append(f"server.json version {s['version']} != {v}")
if s["name"]!="com.nittim/nittim": bad.append("server.json name changed")
if s["remotes"][0]["url"]!="https://nittim.com/api/mcp": bad.append("server.json remote url changed")
if len(s["description"])>100: bad.append("server.json description > 100 chars (registry rejects)")
p=m["plugins"][0]
if p["version"]!=v or m["metadata"]["version"]!=v: bad.append("marketplace.json version drift")
if p["source"]!="./" or p["name"]!="nittim" or m["name"]!="nittim": bad.append("marketplace.json plugin entry changed")
for b in bad: print("  ✗ "+b)
if bad: raise SystemExit(1)
print(f"  ✓ server.json and marketplace.json agree on version {v}, name, endpoint")
PY2
if command -v mcp-publisher >/dev/null; then mcp-publisher validate >/dev/null 2>&1 && ok "server.json valid against the registry schema" || bad "mcp-publisher validate failed"; fi

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
  echo "── gate: badges and listing ──"
  for u in "https://cursor.com/install-mcp?name=nittim&config=eyJ1cmwiOiJodHRwczovL25pdHRpbS5jb20vYXBpL21jcCJ9" https://cursor.com/deeplink/mcp-install-dark.svg; do
    code=$(curl -s -o /dev/null -w '%{http_code}' -m 15 -A Mozilla/5.0 "$u"); [ "$code" = 200 ] && ok "$code ${u:0:60}" || bad "$code $u"
  done
  code=$(curl -s -o /dev/null -w '%{http_code}' -m 15 "https://vscode.dev/redirect/mcp/install?name=nittim&config=%7B%22type%22%3A%22http%22%2C%22url%22%3A%22https%3A%2F%2Fnittim.com%2Fapi%2Fmcp%22%7D"); [ "$code" = 302 ] && ok "302 vscode.dev redirect" || bad "$code vscode.dev redirect (expected 302)"
  grep -qE 'cursor://|\(vscode:' README.md && bad "README links a raw cursor:// or vscode: scheme (GitHub strips those; use the https wrappers)" || ok "README badge links use https wrappers"
  listed=$(curl -s -m 15 "https://registry.modelcontextprotocol.io/v0/servers?search=com.nittim/nittim" | python3 -c 'import sys,json; d=json.load(sys.stdin); print(",".join(x.get("server",x).get("version","?") for x in d.get("servers",[])))')
  [ -n "$listed" ] && ok "MCP Registry lists com.nittim/nittim (versions: $listed)" || bad "MCP Registry does not list com.nittim/nittim"
  dig +short TXT nittim.com @8.8.8.8 | grep -q 'v=MCPv1' && ok "nittim.com apex TXT carries the registry DNS proof" || bad "registry DNS proof TXT missing from nittim.com apex"
  echo "── gate: served skill copies match the repo ──"
  curl -s -m 15 https://nittim.com/skills/nittim-loop/SKILL.md | diff -q - skills/nittim-loop/SKILL.md >/dev/null && ok "live SKILL.md == repo" || bad "live SKILL.md differs from repo (fis serves it — sync one side)"
  curl -s -m 15 https://nittim.com/skills/nittim-loop/nittim-loop.mdc | diff -q - skills/nittim-loop/nittim-loop.mdc >/dev/null && ok "live nittim-loop.mdc == repo" || bad "live nittim-loop.mdc differs from repo"
fi

if [ "$fail" = 0 ]; then echo "── gate: PASS ──"; else echo "── gate: FAIL ──" >&2; exit 1; fi
