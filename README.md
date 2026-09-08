# nittim MCP

[![Add to Cursor](https://cursor.com/deeplink/mcp-install-dark.svg)](https://cursor.com/install-mcp?name=nittim&config=eyJ1cmwiOiJodHRwczovL25pdHRpbS5jb20vYXBpL21jcCJ9)
[![Install in VS Code](https://img.shields.io/badge/VS_Code-Install_nittim-0098FF?style=flat-square&logo=visualstudiocode&logoColor=white)](https://vscode.dev/redirect/mcp/install?name=nittim&config=%7B%22type%22%3A%22http%22%2C%22url%22%3A%22https%3A%2F%2Fnittim.com%2Fapi%2Fmcp%22%7D)
[![MCP Registry](https://img.shields.io/badge/MCP_Registry-com.nittim%2Fnittim-333?style=flat-square)](https://registry.modelcontextprotocol.io/v0/servers?search=com.nittim/nittim)

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

## Try it in 30 seconds

Connect (below), then ask your agent:

> Run nittim's `get_loop` and review this repo against it.

That reads the free checklist and reviews your code on your own model. Nothing is uploaded and no key is needed. Or ask it to `scan_source` a file for committed secrets and vulnerable dependencies. Also free.

## Connect

**Claude Code**, as a plugin (adds the server and the `nittim-loop` skill):

```
/plugin marketplace add ilanwolberger/nittim-mcp
/plugin install nittim@nittim
```

or just the server:

```
claude mcp add --transport http nittim https://nittim.com/api/mcp
```

**Cursor** or **VS Code**: the buttons at the top, or `nittim` → `https://nittim.com/api/mcp` in your MCP settings.

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

**Claude Code** — install the plugin (see Connect above), then run
`/nittim:nittim-loop` inside a project you want reviewed. Or install the skill
on its own, available in every project:

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

This repository holds the listing manifests for nittim's MCP server, all pointing at the live endpoint above: [Open Plugins](https://agent-plugins.org) (`plugin.json`, `.mcp.json`), the [MCP Registry](https://registry.modelcontextprotocol.io) (`server.json`), a Claude Code plugin and marketplace (`.claude-plugin/`), and the `nittim-loop` skill (`SKILL.md` for Claude Code, `nittim-loop.mdc` for Cursor). It carries no other application code. `scripts/gate.sh` checks the repo's own consistency — manifests agree, both skill copies identical, every URL above resolves — and `hooks/pre-push` runs a secret scan before anything reaches GitHub (`git config core.hooksPath hooks` once per clone).
