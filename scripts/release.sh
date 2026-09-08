#!/usr/bin/env bash
# nittim-mcp release — one command for the whole ritual.
#   scripts/release.sh 1.2.0
# Bumps the version in all four manifests (plugin.json, .claude-plugin/plugin.json,
# .claude-plugin/marketplace.json, server.json), validates against the registry, runs the
# gate offline, commits, publishes to the official MCP Registry (DNS login with the key in
# keychain NITTIM_MCP_REGISTRY_DNS_KEY_PEM), tags, pushes, and creates the GitHub release.
# Stops at the first failure; nothing is pushed or published before the gate is green.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
V="${1:-}"; [[ "$V" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "usage: scripts/release.sh <semver>" >&2; exit 1; }
[ -z "$(git status --porcelain)" ] || { echo "working tree not clean — commit or drop changes first" >&2; exit 1; }
git tag | grep -qx "v$V" && { echo "tag v$V already exists" >&2; exit 1; }

echo "── release $V: bump four manifests ──"
V="$V" python3 - <<'PY'
import json,os
v=os.environ["V"]
for f,path in [("plugin.json",["version"]),(".claude-plugin/plugin.json",["version"]),("server.json",["version"]),
               (".claude-plugin/marketplace.json",["metadata","version"]),(".claude-plugin/marketplace.json",["plugins",0,"version"])]:
    d=json.load(open(f)); o=d
    for k in path[:-1]: o=o[k]
    o[path[-1]]=v
    open(f,"w").write(json.dumps(d,indent=2)+"\n")
print("  bumped plugin.json, .claude-plugin/plugin.json, .claude-plugin/marketplace.json (x2), server.json")
PY

echo "── release $V: validate + gate ──"
mcp-publisher validate
./scripts/gate.sh --offline

echo "── release $V: commit ──"
git add plugin.json .claude-plugin/plugin.json .claude-plugin/marketplace.json server.json
git -c user.name=ilanwolberger -c user.email=72649841+ilanwolberger@users.noreply.github.com commit -q -m "Release $V"

echo "── release $V: publish to the MCP Registry ──"
OS=/opt/homebrew/opt/openssl@3/bin/openssl; [ -x "$OS" ] || OS=openssl
PEM="$(mktemp)"; trap 'rm -f "$PEM"' EXIT
security find-generic-password -a "$USER" -s NITTIM_MCP_REGISTRY_DNS_KEY_PEM -w | base64 -d > "$PEM"
PK="$($OS pkey -in "$PEM" -noout -text | grep -A3 'priv:' | tail -n +2 | tr -d ' :\n')"
mcp-publisher login dns --domain nittim.com --private-key "$PK" >/dev/null
mcp-publisher publish

echo "── release $V: tag, push, GitHub release ──"
git tag -a "v$V" -m "nittim MCP listing $V"
git push origin HEAD && git push origin "v$V"
gh release create "v$V" --title "v$V" --notes "nittim MCP listing $V. Connect: https://nittim.com/api/mcp — registry com.nittim/nittim, Claude Code marketplace ilanwolberger/nittim-mcp." >/dev/null
echo "── release $V: done — run scripts/gate.sh (online) in a minute to confirm the registry shows $V ──"
