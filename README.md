# nittim MCP

nittim audits code before it ships.

Connect over MCP and your agent can:

- Scan a repo or a handful of posted files for committed secrets and known vulnerable dependencies — free, no key needed.
- List every check nittim runs, in plain English.
- Read the free self-review checklist (`get_loop`) — free, no key needed.
- Price a GitHub repo or a set of files before anything runs — free, no upload required.
- Run a full audit and get back a verdict — Production Ready, Production Ready with Conditions, High Risk, or Not Safe — with security, privacy, reliability, and architecture findings, each paired with a fix.
- Get a second opinion on any piece of work from an independent judge.
- Flag a finding that looks wrong, for a person to review.

A paid audit quotes its price before it runs. Nothing is charged until you confirm.

## Connect

```
claude mcp add --transport http nittim https://nittim.com/api/mcp
```

Or add it to any MCP client as:

```json
{
  "nittim": {
    "type": "streamable-http",
    "url": "https://nittim.com/api/mcp"
  }
}
```

The free tools work right away, no account needed. Paid tools need a key — mint one at [nittim.com/keys](https://nittim.com/keys).

## Skills

`skills/nittim-loop` is a free, local self-review — it walks your assistant
through [nittim's public checklist](https://nittim.com/selfcheck.md) over a
repository you own, on your own model, with nothing uploaded. It reads the
checklist via the `get_loop` MCP tool when one is connected, or by fetching
`https://nittim.com/selfcheck.md` directly otherwise.

**Claude Code** — try it from this repo:

```
git clone https://github.com/ilanwolberger/nittim-mcp
claude --plugin-dir ./nittim-mcp
```

then run `/nittim:nittim-loop` inside a project you want reviewed. Loading the
plugin also connects the nittim MCP server (from `.mcp.json`), so `get_loop` and
the free scanners are available in the same session. Or install the skill on
its own, available in every project:

```
mkdir -p ~/.claude/skills/nittim-loop && curl -fsSL https://nittim.com/skills/nittim-loop/SKILL.md -o ~/.claude/skills/nittim-loop/SKILL.md
```

**Cursor** — the same checklist as a project rule (`skills/nittim-loop/nittim-loop.mdc`), also served live at `https://nittim.com/skills/nittim-loop/nittim-loop.mdc`:

```
mkdir -p .cursor/rules && curl -fsSL https://nittim.com/skills/nittim-loop/nittim-loop.mdc -o .cursor/rules/nittim-loop.mdc
```

**Any other MCP client** — call the `get_loop` tool directly; no install needed.

## Learn more

Full reference, for people and for agents: [nittim.com/agents](https://nittim.com/agents)

---

This repository holds the [Open Plugins](https://agent-plugins.org) manifest for nittim's MCP server — `plugin.json` and `.mcp.json`, pointing at the live endpoint above — plus a Claude Code plugin manifest (`.claude-plugin/plugin.json`) and the `nittim-loop` skill (`SKILL.md` for Claude Code, `nittim-loop.mdc` for Cursor). It carries no other application code. `scripts/gate.sh` checks the repo's own consistency — manifests agree, both skill copies identical, every URL above resolves — and `hooks/pre-push` runs a secret scan before anything reaches GitHub (`git config core.hooksPath hooks` once per clone).
